import 'package:flutter/material.dart';
import '../../services/final_exam_service.dart';
import '../../services/student_achievement_service.dart';

class AwardsScreen extends StatefulWidget {
  const AwardsScreen({super.key});

  @override
  State<AwardsScreen> createState() => _AwardsScreenState();
}

class _AwardsScreenState extends State<AwardsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;

  // Student achievements
  int _totalPoints = 0;
  List<String> _earnedBadges = [];

  // Active final exams from Database
  List<FinalExamRecord> _allExams = [];

  // Map to hold subject scores for each exam: finalExamId -> SubjectScoreData
  final Map<String, SubjectScoreData> _examScores = {};

  // Selected tab index: 0 = General Badges, 1 = Class 1, 2 = Class 2, 3 = Class 3, 4 = Class 4
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAwardsData();
  }

  Future<void> _loadAwardsData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch general achievements
      final summary = await StudentAchievementService.fetchForCurrentUser();
      _totalPoints = summary.totalPoints;
      _earnedBadges = summary.badges;

      // 2. Fetch all active class final exams
      final exams = await FinalExamService.fetchAllActiveClassFinalExams();
      _allExams = exams;

      // 3. For each active exam, fetch student's score
      _examScores.clear();
      for (final exam in _allExams) {
        final scoreData = await FinalExamService.fetchCombinedSubjectScore(
          exam.subjectName,
          exam.classLevel,
          exam.id,
        );
        if (scoreData != null) {
          _examScores[exam.id] = scoreData;
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D5AFF)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Biladaha & Abaalmarinnada',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  // Points Badge in Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24),Color(0xFFF59E0B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$_totalPoints pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Top Pill Navigation Tabs
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildTabPill(0, 'Biladaha Guud', Icons.emoji_events_outlined),
                    _buildTabPill(1, 'Fasalka 1', Icons.looks_one_outlined),
                    _buildTabPill(2, 'Fasalka 2', Icons.looks_two_outlined),
                    _buildTabPill(3, 'Fasalka 3', Icons.looks_3_outlined),
                    _buildTabPill(4, 'Fasalka 4', Icons.looks_4_outlined),
                  ],
                ),
              ),
            ),

            // Body content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAwardsData,
                color: const Color(0xFF1D5AFF),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildErrorWidget()
                        : _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(int index, String label, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D5AFF) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? const Color(0xFF1D5AFF) : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1D5AFF).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            const Text(
              'Khalad ayaa dhacay',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Lama garanayo cilada.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAwardsData,
              icon: const Icon(Icons.refresh),
              label: const Text('Isku day markale'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D5AFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTabIndex == 0) {
      return _buildGeneralBadgesTab();
    } else {
      return _buildClassAwardsTab(_selectedTabIndex); // 1 = Class 1, etc.
    }
  }

  // 1. GENERAL BADGES TAB
  Widget _buildGeneralBadgesTab() {
    // List of predefined badges we display
    final List<Map<String, dynamic>> predefinedBadges = [
      {
        'name': 'Aasaasi',
        'desc': 'Waxaad bilowday safarkaaga waxbarasho adoo dhibco helay.',
        'icon': Icons.rocket_launch_rounded,
        'color': const Color(0xFF3B82F6),
        'condition': _totalPoints > 0,
      },
      {
        'name': 'Arday Firfircoon',
        'desc': 'Arday dadaal badan oo firfircoon ee fasalada ku dhex jira.',
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFFF59E0B),
        'condition': _earnedBadges.any((b) => b.toLowerCase().contains('firfircoon') || b.toLowerCase().contains('smart') || b.toLowerCase().contains('active')) || _totalPoints >= 100,
      },
      {
        'name': 'Geesiga Xisaabta',
        'desc': 'Waxaad ka gudubtay cutubyada iyo xujooyinka Xisaabta.',
        'icon': Icons.calculate_rounded,
        'color': const Color(0xFF10B981),
        'condition': _earnedBadges.any((b) => b.toLowerCase().contains('xisaab') || b.toLowerCase().contains('math')),
      },
      {
        'name': 'Baari Saynis',
        'desc': 'Waxaad muujisay aqoon sare oo ku saabsan barashada Sayniska.',
        'icon': Icons.science_rounded,
        'color': const Color(0xFF8B5CF6),
        'condition': _earnedBadges.any((b) => b.toLowerCase().contains('saynis') || b.toLowerCase().contains('science')),
      },
      {
        'name': 'Xiddig Af Soomaali',
        'desc': 'Waxaad u gudubtay si heer sare ah barashada luqada Af Soomaaliga.',
        'icon': Icons.auto_stories_rounded,
        'color': const Color(0xFFEC4899),
        'condition': _earnedBadges.any((b) => b.toLowerCase().contains('soomaali') || b.toLowerCase().contains('somali')),
      },
      {
        'name': 'Xariif English',
        'desc': 'Waxaad dhamaysay casharada barashada Af Ingiriiska.',
        'icon': Icons.g_translate_rounded,
        'color': const Color(0xFF06B6D4),
        'condition': _earnedBadges.any((b) => b.toLowerCase().contains('english') || b.toLowerCase().contains('ingiriis')),
      },
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Biladaha Guud ee Quizzes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Dhamaystir Casharada iyo Quizzes si aad u furto biladahaan quruxda badan.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: predefinedBadges.length,
          itemBuilder: (context, index) {
            final badge = predefinedBadges[index];
            final bool isUnlocked = badge['condition'] == true;
            final Color badgeColor = badge['color'] as Color;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isUnlocked ? badgeColor.withValues(alpha: 0.3) : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge Icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: isUnlocked ? badgeColor.withValues(alpha: 0.12) : const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUnlocked ? badgeColor.withValues(alpha: 0.4) : const Color(0xFFD1D5DB),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      badge['icon'] as IconData,
                      size: 36,
                      color: isUnlocked ? badgeColor : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Badge Name
                  Text(
                    badge['name'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isUnlocked ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Badge Desc
                  Expanded(
                    child: Text(
                      badge['desc'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: isUnlocked ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Locked/Unlocked Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isUnlocked ? badgeColor.withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUnlocked ? Icons.verified_rounded : Icons.lock_rounded,
                          size: 11,
                          color: isUnlocked ? badgeColor : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isUnlocked ? 'Waa Furan yahay' : 'Waa Xiran yahay',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isUnlocked ? badgeColor : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // 2. CLASS-SPECIFIC AWARDS TAB
  Widget _buildClassAwardsTab(int classLevel) {
    // Filter active exams for this class level
    final classExams = _allExams.where((exam) => exam.classLevel == classLevel).toList();

    if (classExams.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: const [
                Icon(Icons.sentiment_dissatisfied, size: 64, color: Color(0xFF9CA3AF)),
                SizedBox(height: 16),
                Text(
                  'Imtixaanno looma helin fasalkaan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                ),
                SizedBox(height: 6),
                Text(
                  'Kuma jiraan wax imtixaan ah database-ka wali.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          )
        ],
      );
    }

    // Determine class completion: all exams in this class must be taken and passed
    int passedCount = 0;
    for (final exam in classExams) {
      final score = _examScores[exam.id];
      if (score != null && score.isPassed) {
        passedCount++;
      }
    }

    final bool isClassTrophyUnlocked = passedCount == classExams.length && classExams.isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // 2a. BIG TROPHY CONTAINER (Completion Cup)
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isClassTrophyUnlocked
                  ? [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)]
                  : [Colors.white, const Color(0xFFF9FAFB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isClassTrophyUnlocked ? const Color(0xFFFCD34D) : const Color(0xFFE5E7EB),
              width: 2,
            ),
            boxShadow: isClassTrophyUnlocked
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              // Trophy Icon
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, val, child) {
                  return Transform.scale(
                    scale: val,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isClassTrophyUnlocked
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                        boxShadow: isClassTrophyUnlocked
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: 60,
                        color: isClassTrophyUnlocked
                            ? const Color(0xFFD97706)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Trophy Title
              Text(
                'Koobka Dhamaystirka Fasalka $classLevel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isClassTrophyUnlocked ? const Color(0xFF78350F) : const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 8),
              // Progress Bar text
              Text(
                'Natiijada: $passedCount ka mid ah ${classExams.length} Imtixaan ayaa la gudbay',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isClassTrophyUnlocked ? const Color(0xFFB45309) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),
              // Simple progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: classExams.isEmpty ? 0 : passedCount / classExams.length,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isClassTrophyUnlocked ? const Color(0xFFD97706) : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isClassTrophyUnlocked
                    ? 'Hambalyo! Waad ku guulaysatay Koobka dhamaystirka ee Fasalka $classLevel! 🎉'
                    : 'Gudub dhamaan imtixaanada fasalkaan si aad u furto Koobkan dahabka ah!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isClassTrophyUnlocked ? const Color(0xFF78350F) : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'Maadooyinka & Biladahooda',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),

        // 2b. LIST OF SUBJECT MEDALS
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classExams.length,
          itemBuilder: (context, index) {
            final exam = classExams[index];
            final score = _examScores[exam.id];
            final bool isPassed = score != null && score.isPassed;

            final Color accentColor = _colorForSubject(exam.subjectName);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isPassed ? accentColor.withValues(alpha: 0.3) : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                boxShadow: isPassed
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Medal Icon Display
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isPassed ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPassed ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      size: 34,
                      color: isPassed ? const Color(0xFFD97706) : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Subject Score Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.subjectName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (score != null && score.hasTakenFinal) ...[
                          // Display 40/60 points breakdowns
                          Row(
                            children: [
                              _buildMiniBadge(
                                label: 'Cutubyo: ${score.chapterScoreOutOf40.round()}/40',
                                color: Colors.blue.shade700,
                                bgColor: Colors.blue.shade50,
                              ),
                              const SizedBox(width: 6),
                              _buildMiniBadge(
                                label: 'Final: ${score.finalScoreOutOf60.round()}/60',
                                color: Colors.purple.shade700,
                                bgColor: Colors.purple.shade50,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Wadajir: ${score.totalScore.round()}/100',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPassed ? 'Gudbay ✅' : 'Kuma dhacay (Min 50%) ❌',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const Text(
                            'Imtixaanka weli lama qaadin',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Lock/Unlock Icon indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPassed ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPassed ? Icons.lock_open_rounded : Icons.lock_rounded,
                      size: 18,
                      color: isPassed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniBadge({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Color _colorForSubject(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('soomaali')) return const Color(0xFF1D5AFF);
    if (s.contains('english')) return const Color(0xFF0EA5E9);
    if (s.contains('xisaab') || s.contains('math')) return const Color(0xFF10B981);
    if (s.contains('saynis') || s.contains('science')) return const Color(0xFFF59E0B);
    return const Color(0xFF8B5CF6);
  }
}
