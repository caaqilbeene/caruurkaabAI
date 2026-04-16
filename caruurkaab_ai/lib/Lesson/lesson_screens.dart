import 'package:caruurkaab_ai/screens/pdfviewer/pdfviewer.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Lesson {
  final int id;
  final String title;
  final String pdfUrl;

  Lesson({required this.id, required this.title, required this.pdfUrl});

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'],
      title: map['title'] ?? 'Magac malaha',
      pdfUrl: map['pdf_url'] ?? '',
    );
  }
}

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Casharrada Afsomali")),
      body: FutureBuilder<List<Lesson>>(
        future: Supabase.instance.client
            .from('lessons')
            .select()
            .then(
              (data) => (data as List).map((e) => Lesson.fromMap(e)).toList(),
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Cillad ayaa dhacday: ${snapshot.error}"),
            );
          }

          final lessons = snapshot.data!;
          return ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return ListTile(
                leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(lesson.title),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PDFViewPage(lesson: lesson),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
