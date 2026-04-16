// ADMIN CONTENT SCREEN: System Settings.
import 'package:flutter/material.dart';
import 'package:caruurkaab_ai/screens/auth/login_signup.dart';

class AdminSystemSettingsScreen extends StatefulWidget {
  const AdminSystemSettingsScreen({super.key});

  @override
  State<AdminSystemSettingsScreen> createState() =>
      _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState extends State<AdminSystemSettingsScreen> {
bool appNotifications = true;
  bool maintenanceMode = false;
  String selectedLanguage = 'English (Default)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text(
          'System Settings',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text(
            'GENERAL SETTINGS',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('App Notifications')),
                    Switch(
                      value: appNotifications,
                      onChanged: (value) {
                        setState(() => appNotifications = value);
                      },
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Expanded(child: Text('Maintenance Mode')),
                    Switch(
                      value: maintenanceMode,
                      onChanged: (value) {
                        setState(() => maintenanceMode = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'LANGUAGE SELECTION',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedLanguage,
                items: const [
                  DropdownMenuItem(
                    value: 'English (Default)',
                    child: Text('English (Default)'),
                  ),
                  DropdownMenuItem(
                    value: 'Somali (Af-Soomaali)',
                    child: Text('Somali (Af-Soomaali)'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedLanguage = value);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ABOUT CARUURKAAB AI',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: const [
                ListTile(
                  title: Text('Terms of Service'),
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Privacy Policy'),
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('App Version'),
                  subtitle: Text('1.0.42 (Beta)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFFECACA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
