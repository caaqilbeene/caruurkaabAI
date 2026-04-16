import 'package:caruurkaab_ai/screens/dashboard/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../chatbot/student_ai_chatbot_screen.dart';
import '../../services/lesson_completion_progress_service.dart';
import '../../services/profile_avatar_service.dart';
import '../../services/student_class_service.dart';
import '../../services/student_profile_service.dart';
import '../../utils/time_greeting.dart';
import 'lesson_list_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfilePhoto();
    StudentProfileService.fetchOrCreate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadProfilePhoto();
    }
  }

  Future<void> _loadProfilePhoto() async {
    final url = await ProfileAvatarService.fetchAvatarUrl();
    if (!mounted) return;
    setState(() {
      _avatarUrl = url;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    final bytes = await pickedFile.readAsBytes();
    final uploadedUrl = await ProfileAvatarService.uploadAvatar(bytes);
    if (uploadedUrl == null) return;
    if (!mounted) return;
    setState(() {
      _avatarUrl = uploadedUrl;
    });
  }

  ImageProvider? get _avatarProvider {
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return NetworkImage(_avatarUrl!);
    }
    return null;
  }

  List<Widget> get _pages => [
    StudentDashboardBody(
      avatarProvider: _avatarProvider,
      onPickImage: _pickImage,
    ),
    const StudentAiChatbotScreen(),
    const ProfileScreen(isEmbedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex >= _pages.length
              ? _pages.length - 1
              : _currentIndex,
          children: _pages,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      elevation: 0,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF1D5AFF),
      unselectedItemColor: const Color(0xFF9CA3AF),
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 9,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 9,
      ),
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        _loadProfilePhoto();
      },
      items: [
        const BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.home_rounded),
          ),
          label: "Bogga Hore",
        ),
        const BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.smart_toy_rounded),
          ),
          label: "Wadahadal",
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _avatarProvider != null
                ? CircleAvatar(radius: 12, backgroundImage: _avatarProvider)
                : const Icon(Icons.person),
          ),
          activeIcon: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _avatarProvider != null
                ? CircleAvatar(radius: 12, backgroundImage: _avatarProvider)
                : const Icon(Icons.person),
          ),
          label: "Akoonka",
        ),
      ],
    );
  }
}

class StudentDashboardBody extends StatefulWidget {
  final ImageProvider? avatarProvider;
  final VoidCallback onPickImage;

  const StudentDashboardBody({
    super.key,
    required this.avatarProvider,
    required this.onPickImage,
  });

  @override
  State<StudentDashboardBody> createState() => _StudentDashboardBodyState();
}

class _StudentDashboardBodyState extends State<StudentDashboardBody> {
  bool _showLevelDropdown = false;
  String? _selectedLevel;
  int _maxUnlockedLevel = 1;
  List<String> _availableLevels = const ["Fasalka 1"];
  bool _isProgressLoading = true;
  int _completedLessons = 0;
  int _totalLessons = 0;

  //Firebase user displayName//
  String userName = "";
  @override
  void initState() {
    super.initState();
    _getUserName();
    _loadAssignedLevel();
    _loadLearningProgress();
  }

  @override
  void didUpdateWidget(covariant StudentDashboardBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Marka widget-ka isbedelo, xogta dib u cusbooneysii si deggan.
    _getUserName();
    _loadAssignedLevel();
    _loadLearningProgress();
  }

  Future<void> _loadAssignedLevel() async {
    try {
      final assigned =
          await StudentClassService.refreshAssignedClassByProgress();
      final assignedLevel = StudentClassService.extractClassLevel(assigned);
      final assignedFasalka = StudentClassService.toFasalkaLabel(assigned);
      final available = List<String>.generate(
        assignedLevel,
        (index) => 'Fasalka ${index + 1}',
      );

      final previousLevel = _selectedLevel == null
          ? 0
          : StudentClassService.extractClassLevel(_selectedLevel!);
      final nextSelected = previousLevel >= 1 && previousLevel <= assignedLevel
          ? _selectedLevel!
          : assignedFasalka;

      if (!mounted) return;
      setState(() {
        _maxUnlockedLevel = assignedLevel;
        _availableLevels = available;
        _selectedLevel = nextSelected;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _maxUnlockedLevel = 1;
        _availableLevels = const ["Fasalka 1"];
        _selectedLevel = "Fasalka 1";
      });
    }
  }

  Future<void> _getUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (!mounted) return;

      if (user == null) {
        setState(() {
          userName = "user";
        });
        return;
      }

      final displayName = user.displayName?.trim();
      final email = user.email?.trim();

      setState(() {
        if (displayName != null && displayName.isNotEmpty) {
          userName = displayName;
        } else if (email != null && email.contains('@')) {
          userName = email.split('@').first;
        } else {
          userName = "user";
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        userName = "user";
      });
    }
  }

  Future<void> _loadLearningProgress() async {
    try {
      final progress =
          await LessonCompletionProgressService.fetchForCurrentUser();
      if (!mounted) return;
      setState(() {
        _completedLessons = progress.completed;
        _totalLessons = progress.total;
        _isProgressLoading = false;
      });
      await _loadAssignedLevel();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _completedLessons = 0;
        _totalLessons = 0;
        _isProgressLoading = false;
      });
    }
  }

  double get _learningRatio {
    if (_totalLessons <= 0) return 0;
    return (_completedLessons / _totalLessons).clamp(0, 1).toDouble();
  }

  double get _learningPercentage => _learningRatio * 100;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              GestureDetector(
                onTap: widget.onPickImage,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: widget.avatarProvider != null
                        ? DecorationImage(
                            image: widget.avatarProvider!,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: widget.avatarProvider == null
                      ? const Icon(Icons.person, color: Color(0xFF94A3B8))
                      : null,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${userName.trim()} 👋",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      TimeGreeting.bilingual(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Skills Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Xirfadahaaga maanta",
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "YOUR SKILLS TODAY",
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _isProgressLoading
                          ? '--%'
                          : '${_learningPercentage.round()}%',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _isProgressLoading ? 0 : _learningRatio,
                    minHeight: 12,
                    backgroundColor: Color(0xFFEEF2FF),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(
                      Icons.military_tech,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isProgressLoading
                          ? "Progress loading..."
                          : "$_completedLessons / $_totalLessons cashar dhammaatay",
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Start Learning + Dropdown
          _buildLearningLevelSection(),

          const SizedBox(height: 35),

          // Recent Classes Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Xiisadihii dhowaa",
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                "Arag dhamaan",
                style: const TextStyle(
                  color: Color(0xFF1D5AFF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Horizontal List
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildClassCard(
                  imagePath:
                      "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?q=80&w=400&auto=format&fit=crop", // Alphabet
                  title: "Alifbeeda",
                  subtitle: "Barashada Alifbeedada",
                  progress: "80% DHAMMAAD",
                ),
                const SizedBox(width: 15),
                _buildClassCard(
                  imagePath:
                      "https://images.unsplash.com/photo-1509228468518-180dd4864904?q=80&w=400&auto=format&fit=crop", // Numbers
                  title: "Tirada",
                  subtitle: "Tirada & Xisaabta",
                  progress: "20% DHAMMAAD",
                ),
                const SizedBox(width: 15),
                _buildClassCard(
                  imagePath:
                      "https://images.unsplash.com/photo-1516627145497-ae6968895b74?q=80&w=400&auto=format&fit=crop",
                  title: "Midabada",
                  subtitle: "Midabada & Magacyada",
                  progress: "35% DHAMMAAD",
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // AI Suggestion
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FF),
              borderRadius: BorderRadius.circular(40), // Very rounded
              border: Border.all(
                color: const Color(0xFFC7D2FE),
                width: 1.5,
                style: BorderStyle.none,
              ), // Wait, dashed border is tricky, let's use a normal border that matches the color or skip dashed
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D5AFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TALO AI / AI SUGGESTION",
                        style: const TextStyle(
                          color: Color(0xFF1D5AFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Aan barano midabada maanta! Let's learn colors today!",
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _toggleLevelDropdown() {
    setState(() {
      _showLevelDropdown = !_showLevelDropdown;
    });
  }

  BoxDecoration _levelBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFF1D5AFF).withValues(alpha: 0.55),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1D5AFF).withValues(alpha: 0.10),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget _buildLearningLevelSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: _levelBoxDecoration(),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Bilow Waxbarashada",
                  style: TextStyle(
                    color: Color(0xFF1D5AFF),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _toggleLevelDropdown,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _showLevelDropdown
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF1D5AFF),
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showLevelDropdown) ...[
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: _levelBoxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 2),
                  child: Text(
                    "Dooro heerka waxbarasho",
                    style: TextStyle(
                      color: Color(0xFF1D5AFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLevel,
                    hint: const Text("Dooro heerka"),
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: Colors.white,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF1D5AFF),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _availableLevels
                        .map(
                          (level) => DropdownMenuItem<String>(
                            value: level,
                            child: Text(level),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final requestedLevel =
                          StudentClassService.extractClassLevel(value);
                      if (requestedLevel > _maxUnlockedLevel) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Fasalka $requestedLevel wali wuu xiran yahay. '
                              'Marka hore dhammee fasalka $_maxUnlockedLevel.',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _selectedLevel = value;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassSubjectsScreen(
                            className: value,
                            maxUnlockedLevel: _maxUnlockedLevel,
                          ),
                        ),
                      ).then((_) => _loadLearningProgress());
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClassCard({
    required String imagePath,
    required String title,
    required String subtitle,
    required String progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: NetworkImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
          alignment: Alignment.bottomLeft,
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              progress,
              style: const TextStyle(
                color: Color(0xFF1D5AFF),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
      ],
    );
  }
}

class ClassesTabBody extends StatelessWidget {
  const ClassesTabBody({super.key});

  void _openCutub1Pdf(BuildContext context) {
    final url = Supabase.instance.client.storage
        .from('cutubyo')
        .getPublicUrl('cutubka 1aad .pdf');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(title: "Cutubka 1aad", url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "XIISADAHA / CLASSES",
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 15,
            runSpacing: 18,
            children: [
              _ClassCard(
                imagePath:
                    "https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?q=80&w=400&auto=format&fit=crop",
                title: "Cutubka 1aad",
                subtitle: "Fur casharrada PDF",
                progress: "BILAABO",
                onTap: () => _openCutub1Pdf(context),
              ),
              const _ClassCard(
                imagePath:
                    "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?q=80&w=400&auto=format&fit=crop",
                title: "Alifbeeda",
                subtitle: "Barashada Alifbeedada",
                progress: "80% DHAMMAAD",
              ),
              const _ClassCard(
                imagePath:
                    "https://images.unsplash.com/photo-1509228468518-180dd4864904?q=80&w=400&auto=format&fit=crop",
                title: "Tirada",
                subtitle: "Tirada & Xisaabta",
                progress: "20% DHAMMAAD",
              ),
              const _ClassCard(
                imagePath:
                    "https://images.unsplash.com/photo-1516627145497-ae6968895b74?q=80&w=400&auto=format&fit=crop",
                title: "Midabada",
                subtitle: "Midabada & Magacyada",
                progress: "35% DHAMMAAD",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final String progress;
  final VoidCallback? onTap;

  const _ClassCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
            alignment: Alignment.bottomLeft,
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                progress,
                style: const TextStyle(
                  color: Color(0xFF1D5AFF),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: card,
    );
  }
}

class ClassSubjectsScreen extends StatelessWidget {
  final String className;
  final int maxUnlockedLevel;

  const ClassSubjectsScreen({
    super.key,
    required this.className,
    this.maxUnlockedLevel = 1,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLevel = StudentClassService.extractClassLevel(className);
    final isLocked = selectedLevel > maxUnlockedLevel;

    if (isLocked) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F8FA),
          elevation: 0,
          centerTitle: true,
          title: Text(
            className,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Fasalka $selectedLevel wali ma furmin.\n'
              'Marka hore dhammee fasalka $maxUnlockedLevel.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      );
    }

    const subjects = ["Af Soomaali", "English", "Saynis", "Xisaab"];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        centerTitle: true,
        title: Text(
          className,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD6E0FF)),
          ),
          child: Column(
            children: subjects
                .asMap()
                .entries
                .map(
                  (entry) => _SubjectLineItem(
                    title: entry.value,
                    isLast: entry.key == subjects.length - 1,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonListScreen(
                            className: className,
                            subjectName: entry.value,
                          ),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _SubjectLineItem extends StatelessWidget {
  final String title;
  final bool isLast;
  final VoidCallback onTap;

  const _SubjectLineItem({
    required this.title,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            )
          : BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFE6ECFF), width: 1),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1D5AFF),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF1D5AFF),
            ),
          ],
        ),
      ),
    );
  }
}

class LessonDetailScreen extends StatefulWidget {
  final String className;
  final String subjectName;

  const LessonDetailScreen({
    super.key,
    required this.className,
    required this.subjectName,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class PdfViewerScreen extends StatelessWidget {
  final String title;
  final String url;

  const PdfViewerScreen({super.key, required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SfPdfViewer.network(url),
    );
  }
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        title: Text(
          "${widget.className} - ${widget.subjectName}",
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD6E0FF)),
                ),
                child: Text(
                  "Casharrada ${widget.subjectName} - ${widget.className}",
                  style: const TextStyle(
                    color: Color(0xFF1D5AFF),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              Column(
                children: [
                  InkWell(
                    onTap: () async {
                      // 1. Muuji loading dialog inta uu server-ka ka raadinayo
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1D5AFF),
                          ),
                        ),
                      );

                      try {
                        // 2. Ka raadi Table-ka 'lessons' ee Database-ka.
                        // Halkan waxaan kaliya ka raadinaynaa hal PDF per subject.
                        final responses = await Supabase.instance.client
                            .from('lessons')
                            .select('pdf_url')
                            // Hubi in magacu sax yahay (Tusaale: "Afsomali", "Seynis")
                            .eq('subject_name', widget.subjectName)
                            .order('created_at', ascending: false)
                            .limit(1);

                        // Qari loading dialog
                        if (context.mounted) Navigator.pop(context);

                        if (responses.isNotEmpty &&
                            responses.first['pdf_url'] != null) {
                          final pdfUrl = responses.first['pdf_url'] as String;
                          if (pdfUrl.startsWith("http") && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfViewerScreen(
                                  title: "Cutubka 1aad",
                                  url: pdfUrl,
                                ),
                              ),
                            );
                            return; // Guul (Wuu helay linkiga wuu na furay)
                          }
                        }

                        // Haddii uusan helin linkiga PDF-ka
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Kuma jiro PDF-ka ${widget.subjectName}! Hubi inuu ku jiro Supabase 'lessons' table.",
                              ),
                              duration: const Duration(seconds: 4),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      } catch (e) {
                        // Haddii qalad yimaado (Intarnet la'aan ama Database Issue)
                        if (context.mounted) {
                          Navigator.pop(context); // Qari loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Cillad code: $e"),
                              duration: const Duration(seconds: 6),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 80),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF4FF),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "1",
                              style: TextStyle(
                                color: Color(0xFF1D5AFF),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Cutubka 1aad",
                                  style: TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Fasalka 1aad: Cutubka 1aad",
                                  style: TextStyle(
                                    color: Color(0xFF4B5563),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.picture_as_pdf,
                            color: Color(0xFF1D5AFF),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
