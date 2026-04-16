import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/student_profile_record.dart';
import '../../services/lesson_completion_progress_service.dart';
import '../../services/profile_avatar_service.dart';
import '../../services/student_class_service.dart';
import '../../services/student_profile_service.dart';
import '../auth/login_signup.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded;
  const ProfileScreen({super.key, this.isEmbedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // CHANGED: Name-ka profile hadda wuxuu ka imanayaa Firebase Auth (signup displayName).
  String _userName = "User";
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  StudentProfileRecord? _studentProfile;
  String _assignedClass = 'Class --';
  final ImagePicker _imagePicker = ImagePicker();

  int _totalLessonsCount = 0;
  final int _starsEarned = 450;
  final int _badgesEarned = 5;
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    _loadProfileName();
    _loadProfilePhoto();
    _loadStudentProfile();
    _loadAssignedClass();
    _loadTotalLessonsCount();
  }

  Future<void> _loadProfileName() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    final displayName = refreshed?.displayName?.trim();
    final email = refreshed?.email?.trim();

    if (!mounted) return;
    setState(() {
      if (displayName != null && displayName.isNotEmpty) {
        _userName = displayName;
      } else if (email != null && email.contains('@')) {
        _userName = email.split('@').first;
      } else {
        _userName = "User";
      }
    });
  }

  Future<void> _loadProfilePhoto() async {
    final url = await ProfileAvatarService.fetchAvatarUrl();
    if (!mounted) return;
    setState(() {
      _avatarUrl = url;
    });
  }

  Future<void> _loadStudentProfile() async {
    final profile = await StudentProfileService.fetchOrCreate();
    if (!mounted) return;
    setState(() {
      _studentProfile = profile;
    });
  }

  Future<void> _loadAssignedClass() async {
    final assigned = await StudentClassService.refreshAssignedClassByProgress();
    if (!mounted) return;
    setState(() {
      _assignedClass = assigned;
    });
  }

  Future<void> _loadTotalLessonsCount() async {
    try {
      final progress =
          await LessonCompletionProgressService.fetchForCurrentUser();
      if (!mounted) return;
      setState(() {
        _totalLessonsCount = progress.total;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _totalLessonsCount = 0;
      });
    }
  }

  String _formatJoinedDate(DateTime? date) {
    final fallback = FirebaseAuth.instance.currentUser?.metadata.creationTime
        ?.toLocal();
    final value = date ?? fallback;
    if (value == null) return 'Joined --';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[value.month - 1];
    return 'Joined ${value.day} $month, ${value.year}';
  }

  Future<void> _pickProfilePhoto() async {
    setState(() => _isUploadingAvatar = true);
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) {
      if (mounted) setState(() => _isUploadingAvatar = false);
      return;
    }
    final bytes = await picked.readAsBytes();
    final uploadedUrl = await ProfileAvatarService.uploadAvatar(bytes);
    if (!mounted) return;
    setState(() {
      _avatarUrl = uploadedUrl ?? _avatarUrl;
      _isUploadingAvatar = false;
    });
    if (uploadedUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sawirka lama kaydin karin. Fadlan isku day mar kale.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // Light off-white background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isEmbedded
            ? const SizedBox()
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF14204B),
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          'Xubintaada / Profile',
          style: TextStyle(
            color: Color(0xFF14204B),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF14204B)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // Profile Image & Edit Button
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3276FF),
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE5E9F2),
                    backgroundImage: _avatarUrl != null
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: (_avatarUrl == null)
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF94A3B8),
                          )
                        : null,
                  ),
                ),
                GestureDetector(
                  onTap: _isUploadingAvatar ? null : _pickProfilePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3276FF),
                      shape: BoxShape.circle,
                    ),
                    child: _isUploadingAvatar
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showEditProfileDialog(context),
                        child: const Icon(
                          Icons.edit,
                          color: Color(0xFF3276FF),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        color: Color(0xFF64748B),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _assignedClass,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        color: Color(0xFF64748B),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ID ${_studentProfile?.studentId ?? 'STD------'}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        color: Color(0xFF64748B),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatJoinedDate(_studentProfile?.joinedAt),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(_totalLessonsCount.toString(), 'LESSONS'),
                _buildStatCard(_starsEarned.toString(), 'STARS'),
                _buildStatCard(_badgesEarned.toString(), 'BADGES'),
              ],
            ),
            const SizedBox(height: 32),

            // Logout Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFFF4D4D,
                  ), // Red color for logout
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      // Dummy Bottom Navigation to match UI
      bottomNavigationBar: widget.isEmbedded ? null : _buildBottomNav(),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D5AFF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E9F2))),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1D5AFF),
        unselectedItemColor: const Color(0xFF94A3B8),
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
        currentIndex: 3, // Profile selected
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'LEARN',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports_rounded),
            label: 'GAMES',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    // CHANGED: Controller-kan wuxuu qaadanayaa magaca hadda jira.
    final nameController = TextEditingController(text: _userName);
    final rootContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Bedel Xogta",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Name Field
                  const Text(
                    "Magacaaga",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Old Password
                  const Text(
                    "Password-kii Hore",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // New Password
                  const Text(
                    "Password Cusub",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm New Password
                  const Text(
                    "Ku Celi Password Cusub",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSavingName
                          ? null
                          : () async {
                              // CHANGED: Save magaca cusub Firebase Auth + UI.
                              final newName = nameController.text.trim();
                              if (newName.isEmpty) return;

                              // CHANGED: magaca isla markiiba beddel (fast UX).
                              if (mounted) {
                                setState(() {
                                  _userName = newName;
                                  _isSavingName = true;
                                });
                              }
                              Navigator.pop(dialogContext); // close fast
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Magaca waa la keydiyay.'),
                                  duration: Duration(milliseconds: 900),
                                ),
                              );

                              final user = FirebaseAuth.instance.currentUser;
                              try {
                                await user
                                    ?.updateDisplayName(newName)
                                    .timeout(const Duration(seconds: 4));
                              } catch (_) {}
                              await StudentProfileService.updateDisplayName(
                                newName,
                              );
                              try {
                                await user?.reload().timeout(
                                  const Duration(seconds: 4),
                                );
                              } catch (_) {}
                              await _loadStudentProfile();

                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                _isSavingName = false;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D5AFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSavingName
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Save (Keydi)",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
