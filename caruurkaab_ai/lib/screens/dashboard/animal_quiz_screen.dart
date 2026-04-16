// import 'package:flutter/material.dart';
// // import 'animal_quiz_result_screen.dart'; // We'll create this next

// class AnimalQuizScreen extends StatefulWidget {
//   const AnimalQuizScreen({super.key});

//   @override
//   State<AnimalQuizScreen> createState() => _AnimalQuizScreenState();
// }

// class _AnimalQuizScreenState extends State<AnimalQuizScreen> {
//   int _selectedAnswerIndex = 1; // Default selected to 'B' to match image

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Animals / Xayawaanka',
//           style: TextStyle(
//             color: Color(0xFF0F172A),
//             fontWeight: FontWeight.w800,
//             fontSize: 18,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const SizedBox(height: 16),
//               // Progress Header
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'PROGRESS',
//                         style: TextStyle(
//                           color: Color(0xFF64748B),
//                           fontWeight: FontWeight.w700,
//                           fontSize: 10,
//                           letterSpacing: 1.2,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       const Text(
//                         'Question 3 of 10',
//                         style: TextStyle(
//                           color: Color(0xFF0F172A),
//                           fontWeight: FontWeight.w800,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFEBF2FF),
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: const Text(
//                       '30%',
//                       style: TextStyle(
//                         color: Color(0xFF1D5AFF),
//                         fontWeight: FontWeight.w800,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),

//               // Progress Bar
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: const LinearProgressIndicator(
//                   value: 0.3,
//                   minHeight: 8,
//                   backgroundColor: Color(0xFFE2E8F0),
//                   valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D5AFF)),
//                 ),
//               ),

//               const SizedBox(height: 48),

//               // Sound Icon
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFEBF2FF),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.volume_up,
//                   color: Color(0xFF1D5AFF),
//                   size: 32,
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Question Text
//               RichText(
//                 textAlign: TextAlign.center,
//                 text: const TextSpan(
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.w900,
//                     color: Color(0xFF0F172A),
//                     height: 1.3,
//                   ),
//                   children: [
//                     TextSpan(text: 'Which animal is a\n'),
//                     TextSpan(
//                       text: "'Libàax'",
//                       style: TextStyle(
//                         color: Color(0xFF1D5AFF),
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                     TextSpan(text: ' (Lion)?'),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 40),

//               // Options
//               _buildOptionCard(
//                 letter: 'A',
//                 text: 'Elephant / Maroodi',
//                 index: 0,
//               ),
//               _buildOptionCard(letter: 'B', text: 'Lion / Libàax', index: 1),
//               _buildOptionCard(letter: 'C', text: 'Giraffe / Gari', index: 2),
//               _buildOptionCard(
//                 letter: 'D',
//                 text: 'Zebra / Dameer-faro',
//                 index: 3,
//               ),

//               const Spacer(),

//               // Next Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // Navigate to Result Screen for demonstration
//                     // Navigator.push(
//                     //   context,
//                     //   MaterialPageRoute(
//                     //     builder: (context) => const AnimalQuizResultScreen(),
//                     //   ),
//                     // );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF1D5AFF),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(28),
//                     ),
//                     elevation: 4,
//                     shadowColor: const Color(0xFF1D5AFF).withOpacity(0.5),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: const [
//                       Text(
//                         "Next Question / Su'aas...",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                       SizedBox(width: 8),
//                       Icon(Icons.arrow_forward, color: Colors.white, size: 20),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildOptionCard({
//     required String letter,
//     required String text,
//     required int index,
//   }) {
//     bool isSelected = _selectedAnswerIndex == index;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedAnswerIndex = index;
//         });
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFFEBF2FF) : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: isSelected
//                 ? const Color(0xFF1D5AFF)
//                 : const Color(0xFFE2E8F0),
//             width: isSelected ? 2 : 1,
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 color: isSelected
//                     ? const Color(0xFF1D5AFF)
//                     : const Color(0xFFF1F5F9),
//                 shape: BoxShape.circle,
//               ),
//               alignment: Alignment.center,
//               child: Text(
//                 letter,
//                 style: TextStyle(
//                   color: isSelected ? Colors.white : const Color(0xFF64748B),
//                   fontWeight: FontWeight.w800,
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Text(
//                 text,
//                 style: TextStyle(
//                   color: const Color(0xFF0F172A),
//                   fontWeight: FontWeight.w700,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Container(
//               width: 24,
//               height: 24,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: isSelected
//                     ? const Color(0xFF1D5AFF)
//                     : const Color(0xFFCBD5E1),
//               ),
//               child: isSelected
//                   ? const Center(
//                       child: Icon(Icons.check, size: 16, color: Colors.white),
//                     )
//                   : null,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
