import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'quiz_intro_screen.dart';

class LessonViewerScreen extends StatefulWidget {
  final String lessonTitle;
  final String subjectName;
  final String lessonId;
  final int classLevel;
  final String? chapterId;
  final String? nextLessonId;
  final String? nextLessonTitle;
  final String? nextLessonChapterId;

  const LessonViewerScreen({
    super.key,
    required this.lessonTitle,
    required this.subjectName,
    required this.lessonId,
    required this.classLevel,
    this.chapterId,
    this.nextLessonId,
    this.nextLessonTitle,
    this.nextLessonChapterId,
  });

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = true;
  List<_LessonSlide> _slides = [];

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final data = await Supabase.instance.client
          .from('lessons')
          .select('title, desc, items, image_url')
          .eq('id', widget.lessonId)
          .maybeSingle();

      final List<_LessonSlide> slides = [];
      final items = data?['items'];
      final List<String> textItems = [];
      final List<Map<String, String>> imageItems = [];

      if (items is List) {
        for (final raw in items) {
          if (raw is! Map) continue;
          final type = raw['type']?.toString();
          if (type == 'text') {
            final text = raw['text']?.toString().trim() ?? '';
            if (text.isNotEmpty) textItems.add(text);
          } else if (type == 'image') {
            final imageUrl = raw['imageUrl']?.toString().trim() ?? '';
            final caption = raw['caption']?.toString().trim() ?? '';
            if (imageUrl.isNotEmpty) {
              imageItems.add({'url': imageUrl, 'caption': caption});
            }
          }
        }
      }

      if (textItems.isNotEmpty || imageItems.isNotEmpty) {
        final combinedText = textItems.join('\n\n');
        final imageUrls = imageItems
            .map((item) => item['url'] ?? '')
            .where((url) => url.trim().isNotEmpty)
            .toList();
        final imageCaptions = imageItems
            .map((item) => item['caption'] ?? '')
            .toList();

        slides.add(
          _LessonSlide(
            title: data?['title']?.toString() ?? widget.lessonTitle,
            content: combinedText,
            imageUrls: imageUrls,
            imageCaptions: imageCaptions,
          ),
        );
      }

      if (slides.isEmpty) {
        final desc = data?['desc']?.toString().trim() ?? '';
        slides.add(
          _LessonSlide(
            title: data?['title']?.toString() ?? widget.lessonTitle,
            content: desc.isEmpty
                ? 'Casharkan wali xog badan laguma darin.'
                : desc,
            imageUrls:
                (data?['image_url']?.toString().trim().isEmpty ?? true)
                    ? const []
                    : [data?['image_url']?.toString().trim() ?? ''],
          ),
        );
      }

      if (mounted) {
        setState(() {
          _slides = slides;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _slides = [
          _LessonSlide(
            title: widget.lessonTitle,
            content: 'Casharkan wali xog badan laguma darin.',
          ),
        ];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Last page -> Go to Quiz Intro
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizIntroScreen(
            lessonTitle: widget.lessonTitle,
            subjectName: widget.subjectName,
            classLevel: widget.classLevel,
            chapterId: widget.chapterId,
            lessonId: widget.lessonId,
            nextLessonId: widget.nextLessonId,
            nextLessonTitle: widget.nextLessonTitle,
            nextLessonChapterId: widget.nextLessonChapterId,
          ),
        ),
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSlides = _slides.isEmpty ? 1 : _slides.length;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 20),
            child: Text(
              "${_currentPage + 1} / $totalSlides",
              style: const TextStyle(
                color: Color(0xFF1D5AFF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  totalSlides,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF1D5AFF)
                          : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        return _buildSlide(_slides[index]);
                      },
                    ),
            ),

            // Bottom Controls
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  if (_currentPage > 0)
                    InkWell(
                      onTap: _prevPage,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: Color(0xFF1D5AFF),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Dib",
                              style: TextStyle(
                                color: Color(0xFF1D5AFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 80), // Placeholder to keep alignment
                  // Next / Start Quiz Button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: InkWell(
                        onTap: _nextPage,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D5AFF),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF1D5AFF,
                                ).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _currentPage == _slides.length - 1
                                ? "U Gudub Quiz"
                                : "Horay - Next Page",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
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

  Widget _buildSlide(_LessonSlide slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slide.title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            if ((slide.content ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                // Copy helper so students can copy text easily.
                child: TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: slide.content ?? ''),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Qoraalka waa la koobiyey!')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Text'),
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                slide.content!,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ],
            if (slide.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 20),
              ...slide.imageUrls.asMap().entries.map((entry) {
                final idx = entry.key;
                final url = entry.value;
                final caption = idx < slide.imageCaptions.length
                    ? slide.imageCaptions[idx]
                    : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          url,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (caption.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          caption,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: url));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sawirka link-kiisa waa la koobiyey!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.link, size: 16),
                        label: const Text('Copy Image Link'),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 60,
                    color: Color(0xFF9CA3AF),
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

class _LessonSlide {
  final String title;
  final String? content;
  final List<String> imageUrls;
  final List<String> imageCaptions;

  const _LessonSlide({
    required this.title,
    this.content,
    this.imageUrls = const [],
    this.imageCaptions = const [],
  });
}
