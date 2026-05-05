import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'about_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final picker = ImagePicker();
  final logger = Logger();
  File? _image;
  double? realProb;
  double? aiProb;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      String? res = await Tflite.loadModel(
        model: 'assets/model_finetuned.tflite',
        labels: 'assets/labels.txt',
      );
      logger.i("Model loaded: $res");
    } catch (e, stacktrace) {
      logger.e("Failed to load model", error: e, stackTrace: stacktrace);
    }
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        setState(() {
          _image = imageFile;
          isLoading = true;
          realProb = null;
          aiProb = null;
        });
        await classifyImage(imageFile);
        setState(() => isLoading = false);
      }
    } catch (e, stacktrace) {
      logger.e("Error picking image", error: e, stackTrace: stacktrace);
      setState(() => isLoading = false);
    }
  }

  Future<void> classifyImage(File imageFile) async {
    try {
      img.Image image = img.decodeImage(await imageFile.readAsBytes())!;
      img.Image resized = img.copyResize(image, width: 256, height: 256);

      List<double> imageAsFloats = [];
      for (int y = 0; y < 256; y++) {
        for (int x = 0; x < 256; x++) {
          final pixel = resized.getPixel(x, y);
          imageAsFloats.add(pixel.r / 255.0);
          imageAsFloats.add(pixel.g / 255.0);
          imageAsFloats.add(pixel.b / 255.0);
        }
      }

      var inputBytes = Float32List.fromList(imageAsFloats);

      var result = await Tflite.runModelOnBinary(
        binary: inputBytes.buffer.asUint8List(),
        numResults: 2,
        threshold: 0.0,
      );

      if (result == null || result.isEmpty) {
        logger.w("No result from model");
        return;
      }

      logger.i("Inference result: $result");

      double real = 0.0;
      double ai = 0.0;
      for (var res in result) {
        final label = res["label"]?.toString().toLowerCase();
        final conf = res["confidence"] ?? 0.0;

        if (label != null) {
          if (label.contains("real")) {
            real = conf;
          } else if (label.contains("generated") ||
              label.contains("ai-generated") ||
              label.contains("ai")) {
            ai = conf;
          }
        }
      }
      setState(() {
        realProb = real;
        aiProb = ai;
      });
    } catch (e, stacktrace) {
      logger.e("Error during classification", error: e, stackTrace: stacktrace);
    }
  }

  Widget buildResultBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ${(value * 100).toStringAsFixed(1)}%",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 14,
            color: color,
            backgroundColor: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildEducationalCard({
    required String title,
    required String content,
    String? imageAssetPath,
    IconData? icon,
  }) {
    Widget leading;

    if (imageAssetPath != null) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imageAssetPath,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      );
    } else if (icon != null) {
      leading = Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Icon(icon, size: 32, color: Colors.redAccent)),
      );
    } else {
      leading = const SizedBox(width: 60, height: 60);
    }

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIntroContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        buildEducationalCard(
          title: "The Rise of AI-Generated Images",
          content:
              "AI-generated images are becoming more realistic and harder to detect. They are often used in deepfakes, fake news, and identity fraud.",
          imageAssetPath: "assets/images/rise_ai.jpg",
        ),
        buildEducationalCard(
          title: "Potential Risks",
          content:
              "These images can spread misinformation and manipulate public opinion. It's important to detect them before they cause harm.",
          imageAssetPath: "assets/images/risk_ai.jpg",
        ),
        buildEducationalCard(
          title: "How LenzAi Helps",
          content:
              "LenzAi uses a lightweight neural network to estimate whether an image is real or AI-generated. Try it out!",
          icon: Icons.visibility,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("LenzAi"),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 50),
            elevation: 8,
            onSelected: (value) {
              if (value == 'about') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'about',
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text(
                      "About LenzAi",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.image_search, size: 28),
              label: const Text("Pick an Image from Gallery"),
            ),
            const SizedBox(height: 30),

            if (_image == null && !isLoading) buildIntroContent(),

            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_image!, height: 240, fit: BoxFit.cover),
              ),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(30.0),
                child: CircularProgressIndicator(
                  color: Colors.redAccent,
                  strokeWidth: 4,
                ),
              ),

           if (realProb != null && aiProb != null) ...[
              Card(
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(top: 10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Confidence Bars",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildResultBar("Real", realProb!, Colors.greenAccent),
                      buildResultBar("AI-Generated", aiProb!, Colors.redAccent),
                      const Divider(color: Colors.white24, thickness: 1),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          (realProb! >= aiProb!)
                              ? "✅ This Image is Real"
                              : "🤖 This Image is AI-Generated",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: (realProb! >= aiProb!)
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
