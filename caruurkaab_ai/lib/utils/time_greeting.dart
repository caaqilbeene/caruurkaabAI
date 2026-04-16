class TimeGreeting {
  static String bilingual([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;

    if (hour < 12) {
      return 'Subax wanaagsan!';
    }
    if (hour < 18) {
      return 'Galab wanaagsan!';
    }
    return 'Habeen wanaagsan!';
  }
}
// class TimeGreeting {
//   static String bilingual([DateTime? now]) {
//     final hour = (now ?? DateTime.now()).hour;

//     if (hour < 12) {
//       return 'Good Morning! / Subax wanaagsan!';
//     } else if (hour < 18) {
//       return 'Good Afternoon! / Galab wanaagsan!';
//     } else {
//       return 'Good Evening! / Habeen wanaagsan!';
//     }
//   }
// }
