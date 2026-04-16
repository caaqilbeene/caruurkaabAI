import 'package:flutter/material.dart';

class AwardsScreen extends StatefulWidget {
  const AwardsScreen({super.key});

  @override
  State<AwardsScreen> createState() => _AwardsScreenState();
}

class _AwardsScreenState extends State<AwardsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Awards')),
      body: const Center(child: Text('Awards UI goes here')),
    );
  }
}
