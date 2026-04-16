// import 'package:caruurkaab_ai/screens/login_signup.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class SignupScreen extends StatefulWidget {
//   final VoidCallback onBack;
//   final String locale;

//   const SignupScreen({super.key, required this.onBack, required this.locale});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final SignUpFormKey = GlobalKey<FormState>();
//   final TextEditingController FullNameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmpasswordController =
//       TextEditingController();
//   bool passwordvisible = false;
//   bool confirmpasswordvisible = false;
//   bool isLoading = false;

//   @override
//   void dispose() {
//     FullNameController.dispose();
//     emailController.dispose();
//     passwordController.dispose();
//     confirmpasswordController.dispose();
//     super.dispose();
//   }

//   Future<void> SignUp() async {
//     if (!SignUpFormKey.currentState!.validate()) return;
//     setState(() => isLoading = true);
//     try {
//       UserCredential userCredential = await FirebaseAuth.instance
//           .createUserWithEmailAndPassword(
//             email: emailController.text.trim(),
//             password: passwordController.text.trim(),
//           );

//       await userCredential.user!.sendEmailVerification();
//       await FirebaseAuth.instance.signOut();
//       FullNameController.clear();
//       emailController.clear();
//       passwordController.clear();
//       confirmpasswordController.clear();
//       if (mounted) {
//         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage(onNext: onNext, locale: locale))); // Go back to Login Screen
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               "Verification email sent. Please check your inbox or junk folder.",
//             ),
//           ),
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       String message = "Sign up error";
//       if (e.code == "weak-password") {
//         message = "Password is too weak";
//       } else if (e.code == "email-already-in-use") {
//         message = "Email is already in use";
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

//     String signupTitle = isSomali ? "Samayso Akoon" : "Create Account";
//     String signupSubtitle = isSomali
//         ? "Gali xogtaada si aad u bilowdo"
//         : "Enter your details to get started";

//     String nameLabel = isSomali ? "Magaca oo buuxa" : "Full Name";
//     String nameHint = isSomali ? "Gali magacaaga" : "Enter your name";
//     String emailLabel = isSomali ? "Email" : "Email";
//     String emailHint = isSomali ? "Gali email-kaaga" : "Enter your email";
//     String passwordLabel = isSomali ? "Ereyga sirta ah" : "Password";
//     String passwordHint = isSomali
//         ? "Gali ereygaaga sirta ah"
//         : "Enter your password";
//     String createBtn = isSomali ? "Samayso Akoon" : "Sign Up";
//     String terms1 = isSomali
//         ? "Markaad is-diiwaangaliso, waxaad ogolaatay "
//         : "By signing up, you agree to our ";
//     String terms2 = isSomali ? "Shuruudaha Adeegga" : "Terms of Service";

//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F8FA),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
//                 onPressed: widget.onBack,
//                 padding: EdgeInsets.zero,
//                 alignment: Alignment.centerLeft,
//               ),

//               const SizedBox(height: 10),

//               Center(
//                 child: Container(
//                   width: 60,
//                   height: 60,
//                   decoration: const BoxDecoration(
//                     color: Color(0xFFE5EDFF),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.person_add,
//                     size: 30,
//                     color: Color(0xFF1D5AFF),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 15),

//               Text(
//                 signupTitle,
//                 style: const TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.w900,
//                   color: Color(0xFF0D1333),
//                 ),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 signupSubtitle,
//                 style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
//               ),

//               const SizedBox(height: 25),

//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Form(
//                     key: SignUpFormKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Name
//                         Text(
//                           nameLabel,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13,
//                             color: Color(0xFF111827),
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         TextFormField(
//                           controller: FullNameController,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return isSomali
//                                   ? "Magaca waa qasab"
//                                   : "Full name is required";
//                             }
//                             return null;
//                           },
//                           decoration: InputDecoration(
//                             hintText: nameHint,
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
//                           ),
//                         ),

//                         const SizedBox(height: 15),

//                         // Email
//                         Text(
//                           emailLabel,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13,
//                             color: Color(0xFF111827),
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         TextFormField(
//                           controller: emailController,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return isSomali
//                                   ? "Email-ka waa qasab"
//                                   : "Email is required";
//                             }
//                             if (!value.contains("@") || !value.contains(".")) {
//                               return isSomali
//                                   ? "Fadlan gali email sax ah"
//                                   : "Please enter a valid email";
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
//                           ),
//                         ),

//                         const SizedBox(height: 15),

//                         // Password
//                         Text(
//                           passwordLabel,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13,
//                             color: Color(0xFF111827),
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         TextFormField(
//                           controller: passwordController,
//                           obscureText: !passwordvisible,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return isSomali
//                                   ? "Fadlan gali ereyga sirta ah"
//                                   : "Please enter your password";
//                             }
//                             if (value.length < 8) {
//                               return isSomali
//                                   ? "Password orkiisu uguyaraan 8 xaraf ah inuu ahaadaa"
//                                   : "Password must be at least 8 characters long.";
//                             }
//                             if (!RegExp(r'[A-Z]').hasMatch(value)) {
//                               return isSomali
//                                   ? "Waa inaad xaraf weyn kudartaa (A-Z)"
//                                   : "Password must contain at least one uppercase letter (A-Z)";
//                             }
//                             if (!RegExp(r'[a-z]').hasMatch(value)) {
//                               return isSomali
//                                   ? "Waa inaad xaraf yar kudartaa (a-z)"
//                                   : "Password must contain at least one lowercase letter (a-z)";
//                             }
//                             if (!RegExp(r'[0-9]').hasMatch(value)) {
//                               return isSomali
//                                   ? "Waa inuu ku jiraa nambar (0-9)"
//                                   : "Password must contain at least one digit (0-9)";
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

//                         const SizedBox(height: 15),

//                         // Confirm Password (New Field)
//                         Text(
//                           isSomali
//                               ? "Hubi Ereyga Sirta ah"
//                               : "Confirm Password",
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13,
//                             color: Color(0xFF111827),
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         TextFormField(
//                           controller: confirmpasswordController,
//                           obscureText: !confirmpasswordvisible,
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return isSomali
//                                   ? "Fadlan hubi ereyga sirta ah"
//                                   : "Please confirm your password";
//                             }
//                             if (value != passwordController.text) {
//                               return isSomali
//                                   ? "Password-ku isma laha"
//                                   : "Passwords do not match";
//                             }
//                             return null;
//                           },
//                           decoration: InputDecoration(
//                             hintText: isSomali
//                                 ? "Hubi ereygaaga sirta ah"
//                                 : "Confirm your password",
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
//                                 confirmpasswordvisible
//                                     ? Icons.visibility
//                                     : Icons.visibility_off,
//                                 color: Colors.grey,
//                                 size: 20,
//                               ),
//                               onPressed: () {
//                                 setState(() {
//                                   confirmpasswordvisible =
//                                       !confirmpasswordvisible;
//                                 });
//                               },
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 25),

//                         isLoading
//                             ? const Center(
//                                 child: CircularProgressIndicator(
//                                   color: Color(0xFF1D5AFF),
//                                 ),
//                               )
//                             : ElevatedButton(
//                                 onPressed: () {
//                                   SignUp();
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF1D5AFF),
//                                   minimumSize: const Size(double.infinity, 55),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(20),
//                                   ),
//                                   elevation: 5,
//                                   shadowColor: const Color(
//                                     0xFF1D5AFF,
//                                   ).withValues(alpha: 0.5),
//                                 ),
//                                 child: Text(
//                                   createBtn,
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ),

//                         const SizedBox(height: 15),

//                         Center(
//                           child: RichText(
//                             textAlign: TextAlign.center,
//                             text: TextSpan(
//                               style: const TextStyle(
//                                 color: Colors.grey,
//                                 fontSize: 12,
//                               ),
//                               children: [
//                                 TextSpan(text: terms1),
//                                 TextSpan(
//                                   text: terms2,
//                                   style: const TextStyle(
//                                     decoration: TextDecoration.underline,
//                                     color: Color(0xFF4B5563),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 20),
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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:caruurkaab_ai/screens/placement/placement_flow.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final signUpFormKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmpasswordController =
      TextEditingController();
  bool passwordvisible = false;
  bool confirmpasswordvisible = false;
  bool isLoading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmpasswordController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (!signUpFormKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      await userCredential.user!.updateDisplayName(
        fullNameController.text.trim(),
      );
      await userCredential.user!.reload();

      await userCredential.user!.sendEmailVerification();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const VerifyEmailAndPlacementScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Sign up error";
      if (e.code == "weak-password") {
        message = "Password is too weak";
      } else if (e.code == "email-already-in-use") {
        message = "Email is already in use";
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
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                onPressed: () {
                  Navigator.pop(context);
                },
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),

              const SizedBox(height: 10),

              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5EDFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add,
                    size: 30,
                    color: Color(0xFF1D5AFF),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Samayso Akoon",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D1333),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Gali xogtaada si aad u bilowdo",
                style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
              ),

              const SizedBox(height: 25),

              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: signUpFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        const Text(
                          "Magaca oo buuxa",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: fullNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Magaca waa qasab";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Gali magacaaga",
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

                        const SizedBox(height: 15),

                        // Email
                        const Text(
                          "Email",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Email-ka waa qasab";
                            }
                            if (!value.contains("@") || !value.contains(".")) {
                              return "Fadlan gali email sax ah";
                            }
                            return null;
                          },
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

                        const SizedBox(height: 15),

                        // Password
                        const Text(
                          "Ereyga sirta ah",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: passwordController,
                          obscureText: !passwordvisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Fadlan gali ereyga sirta ah";
                            }
                            if (value.length < 8) {
                              return "Password orkiisu uguyaraan 8 xaraf ah inuu ahaadaa";
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return "Waa inaad xaraf weyn kudartaa (A-Z)";
                            }
                            if (!RegExp(r'[a-z]').hasMatch(value)) {
                              return "Waa inaad xaraf yar kudartaa (a-z)";
                            }
                            if (!RegExp(r'[0-9]').hasMatch(value)) {
                              return "Waa inuu ku jiraa nambar (0-9)";
                            }
                            return null;
                          },
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
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
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

                        const SizedBox(height: 15),

                        // Confirm Password (New Field)
                        Text(
                          "Hubi Ereyga Sirta ah",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: confirmpasswordController,
                          obscureText: !confirmpasswordvisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Fadlan hubi ereyga sirta ah";
                            }
                            if (value != passwordController.text) {
                              return "Password-ku isma laha";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Hubi ereygaaga sirta ah",
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
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                confirmpasswordvisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  confirmpasswordvisible =
                                      !confirmpasswordvisible;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1D5AFF),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  signUp();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1D5AFF),
                                  minimumSize: const Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 5,
                                  shadowColor: const Color(
                                    0xFF1D5AFF,
                                  ).withValues(alpha: 0.5),
                                ),
                                child: const Text(
                                  "Samayso Akoon",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                        const SizedBox(height: 15),

                        Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      "Markaad is-diiwaangaliso, waxaad ogolaatay ",
                                ),
                                const TextSpan(
                                  text: "Shuruudaha Adeegga",
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
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

class VerifyEmailAndPlacementScreen extends StatefulWidget {
  const VerifyEmailAndPlacementScreen({super.key});

  @override
  State<VerifyEmailAndPlacementScreen> createState() =>
      _VerifyEmailAndPlacementScreenState();
}

class _VerifyEmailAndPlacementScreenState
    extends State<VerifyEmailAndPlacementScreen> {
  bool _isChecking = false;

  Future<void> _checkVerificationAndContinue() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isChecking = true);
    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (refreshedUser != null && refreshedUser.emailVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PlacementFlowScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fadlan marka hore verify garee email-ka."),
        ),
      );
    }
  }

  Future<void> _resendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.sendEmailVerification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Verification link cusub ayaa laguu diray."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD6E0FF)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Verify Email-kaaga",
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Link verification ah ayaa laguu diray. "
                      "Markaad furto oo verify sameyso, guji badhanka hoose.",
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _checkVerificationAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D5AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Waan Verify Gareeyay",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _resendVerificationEmail,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    side: const BorderSide(color: Color(0xFF1D5AFF)),
                  ),
                  child: const Text(
                    "Resend Link",
                    style: TextStyle(
                      color: Color(0xFF1D5AFF),
                      fontWeight: FontWeight.w700,
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
