import 'package:flutter/material.dart';

import 'placement_selection.dart';
// import 'quiz_question.dart';
import 'quiz_result.dart';
import 'grade_assigned.dart';
import 'flow_explanation.dart';
import '../learning/student_dashboard.dart';

class AssessmentFlow extends StatefulWidget {
  final String initialLocale;

  const AssessmentFlow({super.key, this.initialLocale = 'so'});

  @override
  State<AssessmentFlow> createState() => _AssessmentFlowState();
}

class _AssessmentFlowState extends State<AssessmentFlow> {
late PageController _pageController;
  late String _locale;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _locale = widget.initialLocale;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_pageController.hasClients && _pageController.page! < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_pageController.hasClients && _pageController.page! > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Exit Assessment Flow if on first screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disables swiping; buttons control flow
        children: [
          // Screen 1
          PlacementSelectionScreen(
            onNext: _nextPage,
            onBack: _previousPage,
            locale: _locale,
          ),

          // Screen 2
          // QuizQuestionScreen(
          //   onNext: _nextPage,
          //   onBack: _previousPage,
          //   locale: _locale,
          // ),

          // Screen 3
          QuizResultScreen(
            onNext: _nextPage,
            onBack: _previousPage,
            locale: _locale,
          ),

          // Screen 4
          GradeAssignedScreen(
            onNext: _nextPage,
            onBack: _previousPage,
            locale: _locale,
          ),

          // Screen 5
          FlowExplanationScreen(
            onNext: () {
              // Finished flow completely, navigate to the Dashboard
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentDashboardScreen(),
                ),
              );
            },
            onBack: _previousPage,
            locale: _locale,
          ),
        ],
      ),
    );
  }
}
