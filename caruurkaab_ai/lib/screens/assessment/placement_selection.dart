import 'package:flutter/material.dart';

class PlacementSelectionScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String locale;

  const PlacementSelectionScreen({
    super.key,
    required this.onNext,
    this.onBack,
    required this.locale,
  });

  @override
  State<PlacementSelectionScreen> createState() => _PlacementSelectionScreenState();
}

class _PlacementSelectionScreenState extends State<PlacementSelectionScreen> {

  @override
  Widget build(BuildContext context) {
    bool isSomali = widget.locale == 'so';

    String title1 = isSomali
        ? "Dooro Meesha Aad Ka Bilaabayso"
        : "Choose Where to Start";
    String title2 = isSomali
        ? "Choose Where to Start"
        : "Dooro Meesha Aad Ka Bilaabayso";

    String description1 = isSomali
        ? "Aan kuu helno casharrada kuugu"
        : "Let's find the best lessons for you";
    String description2 = isSomali ? "habboon." : "to get started.";
    String description3 = isSomali
        ? "Let's find the best lessons for you."
        : "Aan kuu helno casharrada kuugu habboon.";

    String btn1TitleSom = isSomali
        ? "Bilow\nImtixaanka"
        : "Start\nPlacement Test";
    String btn1TitleEng = isSomali
        ? "START PLACEMENT\nTEST"
        : "BILOW\nIMTIXAANKA";
    String btn1Desc = isSomali
        ? "Waxaan ku caawin doonaa inaad hesho heerka saxda ah."
        : "We will help you find the right level.";

    String btn2TitleSom = isSomali
        ? "Horey ayaan u\ngaranayaa"
        : "I Already Know\nMy Level";
    String btn2TitleEng = isSomali
        ? "I ALREADY KNOW MY\nLEVEL"
        : "HOREY AYAAN U\nGARANAYAA";
    String btn2Desc = isSomali
        ? "Si toos ah u dooro casharkaaga."
        : "Directly choose your lesson.";

    String footer = isSomali
        ? "Luqad kale ma rabtaa? / Need another language?"
        : "Need another language? / Luqad kale ma rabtaa?";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    onPressed: widget.onBack,
                  ),

                  // Progress bar
                  SizedBox(
                    width: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        value: 0.25,
                        minHeight: 6,
                        backgroundColor: Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1D5AFF),
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE5EDFF),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        size: 18,
                        color: Color(0xFF1D5AFF),
                      ),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Character Image
                    Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEEF2FF),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://images.unsplash.com/photo-1611162617474-5b21e879e113?q=80&w=200&auto=format&fit=crop', // Temporary placeholder icon
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Titles
                    Text(
                      title1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D1333),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D5AFF),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "$description1\n$description2\n$description3",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Button 1 (Blue Card)
                    GestureDetector(
                      onTap: widget.onNext,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D5AFF),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF1D5AFF,
                              ).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.auto_fix_high,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    btn1TitleSom,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    btn1TitleEng,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    btn1Desc,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Button 2 (White Card)
                    GestureDetector(
                      onTap: () {
                        // Alternate path if needed, usually skips the quiz
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.emoji_events,
                                color: Color(0xFF10B981),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    btn2TitleSom,
                                    style: const TextStyle(
                                      color: Color(0xFF111827),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    btn2TitleEng,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    btn2Desc,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFFD1D5DB),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.translate,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          footer,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
