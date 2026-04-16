// ADMIN SCREEN: Add/Edit user form-ka maamulka.
import 'package:flutter/material.dart';

class AdminAddEditUserScreen extends StatefulWidget {
  const AdminAddEditUserScreen({super.key});

  @override
  State<AdminAddEditUserScreen> createState() => _AdminAddEditUserScreenState();
}

class _AdminAddEditUserScreenState extends State<AdminAddEditUserScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text(
          'Add New User',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 38,
                    backgroundColor: Color(0xFFE8EEFF),
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF1D5AFF),
                      size: 28,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Upload Profile Photo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Full Name',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter full name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Role', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: 'Child',
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Child', child: Text('Child')),
                DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            const Text(
              'Email Address',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              decoration: InputDecoration(
                hintText: 'example@caruurkab.ai',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Status',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Allow user to access the platform',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(value: true, onChanged: (_) {}),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDDF5EA),
                  foregroundColor: const Color(0xFF0F766E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save User Profile',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
