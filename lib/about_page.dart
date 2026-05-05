// about_page.dart
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About LenzAi"),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.visibility, size: 80, color: Colors.redAccent),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "LenzAi",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent.shade100,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "About the App",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "LenzAi is an AI-powered image classification app designed to detect whether an image is Real or AI-Generated. "
              "Using a CNN model, the app analyzes image features and gives confidence scores to help users identify synthetic content.",
              style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 20),
            const Text(
              "Features",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const FeatureItem(text: "🔍 Classify images from your gallery"),
            const FeatureItem(text: "📊 Confidence bars for Real and AI-Generated detection"),
            const FeatureItem(text: "⚡ Fast on-device inference using TensorFlow Lite"),
            const FeatureItem(text: "🎯 Intuitive, modern interface"),
            const SizedBox(height: 30),
            const Text(
              "Developer",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "Created by: Desvanto\nVersion: 1.0.0",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final String text;

  const FeatureItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.white70),
      ),
    );
  }
}
