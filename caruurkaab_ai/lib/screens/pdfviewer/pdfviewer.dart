import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// Haddii aad Lesson class-ka file kale ku riday, halkan import ku soo samee
// import 'lessons_screen.dart';

class PDFViewPage extends StatelessWidget {
  final dynamic lesson; // Waxaad u isticmaali kartaa 'dynamic' ama 'Lesson'
  const PDFViewPage({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: lesson.pdfUrl.isEmpty
          ? Center(child: Text("URL-ka PDF-ka lama helin"))
          : SfPdfViewer.network(lesson.pdfUrl),
    );
  }
}
