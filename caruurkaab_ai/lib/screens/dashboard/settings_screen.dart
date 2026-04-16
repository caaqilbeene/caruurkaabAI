import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'progress_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isEnglish = true;
  bool appSounds = true;
  bool learningReminders = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D5AFF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Section
            Row(
              children: [
                const Icon(Icons.translate, color: Color(0xFF1D5AFF), size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Language / Luqadda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E9F2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isEnglish = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isEnglish ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: isEnglish
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'English',
                          style: TextStyle(
                            color: isEnglish
                                ? const Color(0xFF1D5AFF)
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isEnglish = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !isEnglish ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: !isEnglish
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Somali',
                          style: TextStyle(
                            color: !isEnglish
                                ? const Color(0xFF1D5AFF)
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sound Effects Section
            Row(
              children: [
                const Icon(Icons.volume_up, color: Color(0xFF1D5AFF), size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Sound Effects',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'App Sounds',
              subtitle: 'Hear sounds when you play.',
              value: appSounds,
              onChanged: (val) => setState(() => appSounds = val),
            ),
            const SizedBox(height: 32),

            // Notifications Section
            Row(
              children: [
                const Icon(
                  Icons.notifications,
                  color: Color(0xFF1D5AFF),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Learning Reminders',
              subtitle: 'Get reminders to learn.',
              value: learningReminders,
              onChanged: (val) => setState(() => learningReminders = val),
            ),
            const SizedBox(height: 32),

            // Links Section
            _buildLinkTile(title: 'Terms of Service', onTap: () {}),
            const SizedBox(height: 12),
            _buildLinkTile(title: 'Privacy Policy', onTap: () {}),
            const SizedBox(height: 48),

            // Save Changes Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Firebase integration can go here
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProgressScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D5AFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF1D5AFF).withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: const Color(0xFF1D5AFF),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E9F2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
