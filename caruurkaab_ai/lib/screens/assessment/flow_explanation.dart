import 'package:flutter/material.dart';

class FlowExplanationScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String locale;

  const FlowExplanationScreen({
    super.key,
    required this.onNext,
    this.onBack,
    required this.locale,
  });

  @override
  State<FlowExplanationScreen> createState() => _FlowExplanationScreenState();
}

class _FlowExplanationScreenState extends State<FlowExplanationScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Empty space taking up the rest of the screen
            const Spacer(),

            // Bottom Action Bar Fixed
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(
                      Icons.ios_share,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    label: const Text(
                      "Export",
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "PREV",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: widget.onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D5AFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "NEXT VERSION",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
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
}
