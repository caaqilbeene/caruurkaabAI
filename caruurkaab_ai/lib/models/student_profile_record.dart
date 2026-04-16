class StudentProfileRecord {
  final String userId;
  final int studentNo;
  final DateTime joinedAt;
  final String? fullName;
  final String? email;

  const StudentProfileRecord({
    required this.userId,
    required this.studentNo,
    required this.joinedAt,
    this.fullName,
    this.email,
  });

  String get studentId => 'STD${studentNo.toString().padLeft(6, '0')}';
}
