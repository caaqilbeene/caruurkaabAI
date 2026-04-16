import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
// Ku dar Form key halkaan
  final _forgotformKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    // 1. Hubi in Form-ku saxan yahay
    if (!_forgotformKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset email sent. Please check your inbox."),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = "An error occurred";
      if (e.code == "user-not-found") {
        message = "Email not found in records";
      } else if (e.code == "invalid-email") {
        message = "Invalid email address";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Forgot Password"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Bubbles
          // Positioned(
          //   top: -50,
          //   left: -50,
          //   child: CircleAvatar(
          //     radius: 100,
          //     backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          //   ),
          // ),
          // Positioned(
          //   bottom: -50,
          //   right: -50,
          //   child: CircleAvatar(
          //     radius: 100,
          //     backgroundColor: Theme.of(
          //       context,
          //     ).colorScheme.secondary.withOpacity(0.1),
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _forgotformKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Forgot Your Password?",
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Please enter your email to reset your password.",
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: "Email",
                      prefixIcon: Icon(Icons.mail_outline),
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1D5AFF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D5AFF),
                              minimumSize: const Size(
                                double.infinity,
                                55,
                              ), // Slightly reduced height
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              "Send Reset Email",
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
        ],
      ),
    );
  }
}
