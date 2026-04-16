// import 'package:caruurkaab_ai/screens/assessment/assessment_flow.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'signup_screen.dart';

// class LoginPage extends StatefulWidget {
//   final VoidCallback onNext;
//   final VoidCallback? onBack;
//   final String locale;

//   const LoginPage({
//     super.key,
//     required this.onNext,
//     this.onBack,
//     required this.locale,
//   });

//   @override
//   State<LoginPage> createState() => _LoginSignupState();
// }

// class _LoginSignupState extends State<LoginPage> {
//   final loginFormKey = GlobalKey<FormState>();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   bool passwordvisible = false;
//   bool isLoading = false;

//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> loginUser() async {
//     if (!mounted) return;
//     setState(() => isLoading = true);

//     try {
//       UserCredential userCredential = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(
//             email: emailController.text.trim(),
//             password: passwordController.text.trim(),
//           );
//       User? user = userCredential.user;
//       if (user != null) {
//         await user.reload();
//         if (!user.emailVerified) {
//           await FirebaseAuth.instance.signOut();

//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text("Fadlan xaqiiji email-kaaga")),
//             );
//           }
//           return;
//         }
//       }

//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const AssessmentFlow()),
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       String message = "Login error";
//       if (e.code == "user-not-found" ||
//           e.code == "wrong-password" ||
//           e.code == "invalid-credential") {
//         message = "Invalid email or password";
//       } else if (e.code == "invalid-email") {
//         message = "Invalid email address";
//       }
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(message)));
//       }
//     } finally {
//       if (mounted) setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     bool isSomali = widget.locale == 'so';

//     String welcomeTitle = isSomali ? "Ku soo dhawaaw" : "Welcome Back";
//     String welcomeSubtitle = isSomali
//         ? "Soo gal si aad u bilowdo barashada\nCaruurkab AI"
//         : "Log in to start learning with\nCaruurkab AI";
//     String emailLabel = isSomali ? "Email" : "Email";
//     String emailHint = isSomali ? "Gali email-kaaga" : "Enter your email";
//     String passwordLabel = isSomali ? "Ereyga sirta ah" : "Password";
//     String passwordHint = isSomali
//         ? "Gali ereygaaga sirta ah"
//         : "Enter your password";
//     String forgotPassword = isSomali
//         ? "Ma ilaawday ereyga sirta ah?"
//         : "Forgot password?";
//     String loginBtn = isSomali ? "Soo gal" : "Login";
//     String orText = isSomali ? "ama" : "or";
//     String createAccountBtn = isSomali ? "Akoon Samayso" : "Create Account";
//     String terms1 = isSomali
//         ? "Markaad soo gasho, waxaad ogolaatay "
//         : "By logging in, you agree to our ";
//     String terms2 = isSomali ? "Shuruudaha Adeegga" : "Terms of Service";
//     String termsAnd = isSomali ? " iyo " : " and ";
//     String terms3 = isSomali ? "Xeerka Qarsoodiga" : "Privacy Policy";

//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F8FA),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (widget.onBack != null)
//                 IconButton(
//                   icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
//                   onPressed: widget.onBack,
//                   padding: EdgeInsets.zero,
//                   alignment: Alignment.centerLeft,
//                 )
//               else
//                 const SizedBox(height: 48),

//               const SizedBox(height: 10),

//               Center(
//                 child: Container(
//                   width: 60, // Reduced from 80
//                   height: 60, // Reduced from 80
//                   decoration: const BoxDecoration(
//                     color: Color(0xFFE5EDFF),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.menu_book,
//                     size: 30,
//                     color: Color(0xFF1D5AFF),
//                   ), // Reduced icon size
//                 ),
//               ),

//               const SizedBox(height: 15), // Reduced

//               Text(
//                 welcomeTitle,
//                 style: const TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.w900,
//                   color: Color(0xFF0D1333),
//                 ), // Reduced text size slightly
//               ),
//               const SizedBox(height: 5), // Reduced
//               Text(
//                 welcomeSubtitle,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Color(0xFF4B5563),
//                   height: 1.5,
//                 ), // Reduced text size slightly
//               ),

//               const SizedBox(height: 25), // Reduced

//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Form(
//                     key: loginFormKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Email
//                         Text(
//                           emailLabel,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13,
//                             color: Color(0xFF111827),
//                           ),
//                         ),
//                         const SizedBox(height: 6), // Reduced
//                         TextFormField(
//                           controller: emailController,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return isSomali
//                                   ? "Fadlan gali email-kaaga"
//                                   : "Please enter your email";
//                             }
//                             return null;
//                           },
//                           decoration: InputDecoration(
//                             hintText: emailHint,
//                             hintStyle: const TextStyle(
//                               color: Colors.grey,
//                               fontSize: 14,
//                             ),
//                             filled: true,
//                             fillColor: Colors.white,
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 15,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15),
//                               borderSide: BorderSide.none,
//                             ), // Less circular
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15),
//                               borderSide: const BorderSide(
//                                 color: Color(0xFFE5E7EB),
//                               ),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15),
//                               borderSide: const BorderSide(
//                                 color: Color(0xFF1D5AFF),
//                               ),
//                             ),
//                             errorBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15),
//                               borderSide: const BorderSide(color: Colors.red),
//                             ),
//                             focusedErrorBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15),
//                               borderSide: const BorderSide(color: Colors.red),
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 15), // Reduced
//                         // Password
//                         Text(
//                           passwordLabel,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13,
//                             color: Color(0xFF111827),
//                           ),
//                         ),
//                         const SizedBox(height: 6), // Reduced
//                         TextFormField(
//                           controller: passwordController,
//                           obscureText: !passwordvisible,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return isSomali
//                                   ? "Fadlan gali ereyga sirta ah"
//                                   : "Please enter your password";
//                             }
//                             return null;
//                           },
//                           decoration: InputDecoration(
//                             hintText: passwordHint,
//                             hintStyle: const TextStyle(
//                               color: Colors.grey,
//                               fontSize: 14,
//                             ),
//                             filled: true,
//                             fillColor: Colors.white,
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 15,
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15),
//                               borderSide: BorderSide.none,
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15),
//                               borderSide: const BorderSide(
//                                 color: Color(0xFFE5E7EB),
//                               ),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15),
//                               borderSide: const BorderSide(
//                                 color: Color(0xFF1D5AFF),
//                               ),
//                             ),
//                             errorBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15),
//                               borderSide: const BorderSide(color: Colors.red),
//                             ),
//                             focusedErrorBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15),
//                               borderSide: const BorderSide(color: Colors.red),
//                             ),
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                 passwordvisible
//                                     ? Icons.visibility
//                                     : Icons.visibility_off,
//                                 color: Colors.grey,
//                                 size: 20,
//                               ),
//                               onPressed: () {
//                                 setState(() {
//                                   passwordvisible = !passwordvisible;
//                                 });
//                               },
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 5), // Reduced

//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: TextButton(
//                             onPressed: () {},
//                             child: Text(
//                               forgotPassword,
//                               style: const TextStyle(
//                                 color: Color(0xFF1D5AFF),
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 13,
//                               ),
//                             ), // Reduced text size
//                           ),
//                         ),

//                         const SizedBox(height: 10),

//                         isLoading
//                             ? const Center(
//                                 child: CircularProgressIndicator(
//                                   color: Color(0xFF1D5AFF),
//                                 ),
//                               )
//                             : ElevatedButton(
//                                 onPressed: () {
//                                   if (loginFormKey.currentState!.validate()) {
//                                     loginUser();
//                                   }
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF1D5AFF),
//                                   minimumSize: const Size(
//                                     double.infinity,
//                                     55,
//                                   ), // Slightly reduced height
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(20),
//                                   ), // Less circular
//                                   elevation: 5,
//                                   shadowColor: const Color(
//                                     0xFF1D5AFF,
//                                   ).withValues(alpha: 0.5),
//                                 ),
//                                 child: Text(
//                                   loginBtn,
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ),

//                         const SizedBox(height: 15), // Reduced

//                         Row(
//                           children: [
//                             Expanded(
//                               child: Divider(color: Colors.grey.shade300),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 10,
//                               ),
//                               child: Text(
//                                 orText,
//                                 style: const TextStyle(
//                                   color: Colors.grey,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ),
//                             Expanded(
//                               child: Divider(color: Colors.grey.shade300),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 15), // Reduced

//                         OutlinedButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => SignupScreen(
//                                   onBack: () => Navigator.pop(context),
//                                   locale: widget.locale,
//                                 ),
//                               ),
//                             );
//                           },
//                           style: OutlinedButton.styleFrom(
//                             minimumSize: const Size(
//                               double.infinity,
//                               55,
//                             ), // Slightly reduced height
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             side: const BorderSide(color: Color(0xFFE5E7EB)),
//                             backgroundColor: Colors.transparent,
//                           ),
//                           child: Text(
//                             createAccountBtn,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 20), // Reduced

//                         Center(
//                           child: RichText(
//                             textAlign: TextAlign.center,
//                             text: TextSpan(
//                               style: const TextStyle(
//                                 color: Colors.grey,
//                                 fontSize: 12,
//                               ), // Reduced size and removed lines
//                               children: [
//                                 TextSpan(text: terms1),
//                                 TextSpan(
//                                   text: terms2,
//                                   style: const TextStyle(
//                                     decoration: TextDecoration.underline,
//                                     color: Color(0xFF4B5563),
//                                   ),
//                                 ),
//                                 TextSpan(text: termsAnd),
//                                 TextSpan(
//                                   text: terms3,
//                                   style: const TextStyle(
//                                     decoration: TextDecoration.underline,
//                                     color: Color(0xFF4B5563),
//                                   ),
//                                 ),
//                                 const TextSpan(text: "."),
//                               ],
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 10),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:caruurkaab_ai/screens/learning/student_dashboard.dart';
import 'package:caruurkaab_ai/screens/admin/admin_dashboard_screen.dart';
import 'package:caruurkaab_ai/screens/auth/resetpassword.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ADMIN LOGIN RULES: kaliya emails-kan + password-kan ayaa gala Admin Dashboard.
  static const Set<String> _adminEmails = {
    'admin@caruurkaab.ai',
    'admin@caruurkaab.so',
  };
  static const String _adminPassword = 'Admin@2026';

  final loginFormKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool passwordvisible = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final inputEmail = emailController.text.trim().toLowerCase();
      final inputPassword = passwordController.text.trim();
      // ADMIN CHECK: email-ku haddii uu admin list-ka ku jiro, user-kan admin ayuu noqdaa.
      final isAdminEmail = _adminEmails.contains(inputEmail);

      if (isAdminEmail) {
        if (inputPassword != _adminPassword) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Admin password waa qalad")),
            );
          }
          return;
        }

        if (!mounted) return;
        // ADMIN ROUTE: halkan admin-ka waxaa loo diraa admin dashboard.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: inputEmail,
            password: inputPassword,
          );
      User? user = userCredential.user;
      if (user != null) {
        await user.reload();
        if (!user.emailVerified) {
          await FirebaseAuth.instance.signOut();
          emailController.clear();
          passwordController.clear();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Fadlan xaqiiji email-kaaga")),
            );
          }
          return;
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login error";
      if (e.code == "user-not-found" ||
          e.code == "wrong-password" ||
          e.code == "invalid-credential") {
        message = "Invalid email or password";
      } else if (e.code == "invalid-email") {
        message = "Invalid email address";
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              const SizedBox(height: 10),

              Center(
                child: Container(
                  width: 60, // Reduced from 80
                  height: 60, // Reduced from 80
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5EDFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 30,
                    color: Color(0xFF1D5AFF),
                  ), // Reduced icon size
                ),
              ),

              const SizedBox(height: 15), // Reduced

              const Text(
                "Soo gal",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D1333),
                ), // Reduced text size slightly
              ),
              const SizedBox(height: 5), // Reduced
              const Text(
                "Soo gal si aad u bilowdo barashada\nCaruurkab AI",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                ), // Reduced text size slightly
              ),

              const SizedBox(height: 25), // Reduced

              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: loginFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email
                        const Text(
                          "Email",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6), // Reduced
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: "Gali email-kaaga",
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
                            ), // Less circular
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Color(0xFF1D5AFF),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15), // Reduced
                        // Password
                        const Text(
                          "Ereyga sirta ah",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6), // Reduced
                        TextFormField(
                          controller: passwordController,
                          obscureText: !passwordvisible,
                          decoration: InputDecoration(
                            hintText: "Gali ereygaaga sirta ah",
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
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Color(0xFF1D5AFF),
                              ),
                            ),
                            // errorBorder: OutlineInputBorder(
                            //   borderRadius: BorderRadius.circular(15),
                            //   borderSide: const BorderSide(color: Colors.red),
                            // ),
                            // focusedErrorBorder: OutlineInputBorder(
                            //   borderRadius: BorderRadius.circular(15),
                            //   borderSide: const BorderSide(color: Colors.red),
                            // ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                passwordvisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  passwordvisible = !passwordvisible;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 5), // Reduced

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              ).then((_) {
                                emailController.clear();
                                passwordController.clear();
                              });
                            },
                            child: const Text(
                              "Ma ilaawday ereyga sirta ah?",
                              style: TextStyle(
                                color: Color(0xFF1D5AFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          // child: TextButton(
                          //   onPressed: () {},
                          //   child: GestureDetector(
                          //     onTap: () {
                          //       Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (_) => ForgotPasswordScreen(),
                          //         ),
                          //       );
                          //     },
                          //     child: const Text(
                          //       "Ma ilaawday ereyga sirta ah?",
                          //       style: TextStyle(
                          //         color: Color(0xFF1D5AFF),
                          //         fontWeight: FontWeight.bold,
                          //         fontSize: 13,
                          //       ),
                          //     ),
                          //   ), // Reduced text size
                          // ),
                        ),

                        const SizedBox(height: 10),

                        isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1D5AFF),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  final email = emailController.text.trim();
                                  final pass = passwordController.text.trim();
                                  if (email.isEmpty || pass.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Fadlan buuxi email-ka iyo ereyga sirta ah.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  loginUser();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1D5AFF),
                                  minimumSize: const Size(
                                    double.infinity,
                                    55,
                                  ), // Slightly reduced height
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ), // Less circular

                                  shadowColor: const Color(
                                    0xFF1D5AFF,
                                  ).withValues(alpha: 0.5),
                                ),
                                child: const Text(
                                  "Soo gal",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                        const SizedBox(height: 15), // Reduced

                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: const Text(
                                "ama",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15), // Reduced

                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(
                              double.infinity,
                              55,
                            ), // Slightly reduced height
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            backgroundColor: Colors.transparent,
                          ),
                          child: const Text(
                            "Akoon Samayso",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20), // Reduced

                        Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ), // Reduced size and removed lines
                              children: [
                                const TextSpan(
                                  text: "Markaad soo gasho, waxaad ogolaatay ",
                                ),
                                const TextSpan(
                                  text: "Shuruudaha Adeegga",
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                                const TextSpan(text: " iyo "),
                                const TextSpan(
                                  text: "Xeerka Qarsoodiga",
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                                const TextSpan(text: "."),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
