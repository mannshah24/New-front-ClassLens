import 'package:classlens/home/student_home/home_screen.dart';
import 'package:classlens/page_animations/slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:classlens/login/student/student_signup_page.dart';
import 'package:classlens/api/api.dart';
import 'package:classlens/global/global.dart';

class StudentLogin extends StatefulWidget {
  const StudentLogin({super.key});

  @override
  State<StudentLogin> createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLogin> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool isChecked = true;
  bool _obscurePassword = true;

  final _studentPRNController = TextEditingController();
  final _studentPasswordController = TextEditingController();

  static const Color primaryBackgroundColor = Color(0xFFF0F4F8);
  static const Color cardBackgroundColor = Colors.white;
  static const Color primaryTextColor = Color(0xFF1A2533);
  static const Color secondaryTextColor = Color(0xFF6C757D);
  static const Color buttonColor = Color(0xFF2C3E50);
  static const Color accentColor = Color(0xFF4A90E2);
  static const Color textFieldFillColor = Color(0xFFF7F8F9);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color circleColor1 = Color.fromARGB(255, 178, 218, 255);
  static const Color circleColor2 = Color.fromARGB(255, 201, 247, 222);


  @override
  void initState() {
    super.initState();
    _studentPasswordController.clear();
    _studentPRNController.clear();
  }

  @override
  void dispose() {
    _studentPRNController.dispose();
    _studentPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final screenSize = MediaQuery
        .of(context)
        .size;
=======
    final screenSize = MediaQuery.of(context).size;
>>>>>>> 05feae35b47784663b5cb3855d02b9651cea23ed

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -screenSize.width * 0.3,
            left: -screenSize.width * 0.3,
            child: CircleAvatar(
              radius: screenSize.width * 0.45,
              backgroundColor: circleColor1.withOpacity(0.5),
            ),
          ),
          Positioned(
            bottom: -screenSize.width * 0.4,
            right: -screenSize.width * 0.4,
            child: CircleAvatar(
              radius: screenSize.width * 0.5,
              backgroundColor: circleColor2.withOpacity(0.5),
            ),
          ),

          // --- Main Content ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildStudentLoginCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentLoginCard() {
    return Container(
      // --- EDITED: Optimized padding for a sleeker look ---
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Header Text ---
            const Text(
              'ClassLens',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome, Student',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 28),

            // --- PRN Text Field ---
            TextFormField(
              controller: _studentPRNController,
              decoration: _inputDecoration('PRN', Icons.badge_outlined),
              keyboardType: TextInputType.number,
              maxLength: 10,
              validator: (value) {
<<<<<<< HEAD
                if (value == null || value.isEmpty) {
                  return "Please enter your PRN";
                }
                if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                  return "Please enter a valid 10-digit PRN";
                }
                return null;
=======
              if (value == null || value.isEmpty) {
                return "Please enter your PRN";
              }
              if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                return "Please enter a valid 10-digit PRN";
              }
              return null;
>>>>>>> 05feae35b47784663b5cb3855d02b9651cea23ed
              },
            ),

            const SizedBox(height: 18),

            // --- Password Text Field ---
            TextFormField(
              controller: _studentPasswordController,
<<<<<<< HEAD
              decoration: _inputDecoration('Password', Icons.lock_outline)
                  .copyWith(
=======
              decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
>>>>>>> 05feae35b47784663b5cb3855d02b9651cea23ed
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
<<<<<<< HEAD
                    _obscurePassword ? Icons.visibility_off_outlined : Icons
                        .visibility_outlined,
=======
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
>>>>>>> 05feae35b47784663b5cb3855d02b9651cea23ed
                    color: secondaryTextColor,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Enter a password";
                }
                if (value.length > 20) {
                  return "Password is too long";
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // --- Remember Me Row ---
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isChecked = value ?? false;
                      });
                    },
                    activeColor: accentColor,
                    checkColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Remember Me",
                  style: TextStyle(color: secondaryTextColor, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Login Button ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _handleStudentLogin,
              child: _isLoading
                  ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              )
                  : const Text(
                'Login',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),

            // --- Registration Link ---
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const StudentSignUpPage()),
                );
              },
              child: const Text.rich(
                TextSpan(
                  style: const TextStyle( // Default style for the whole TextSpan
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  children: <TextSpan>[
                    const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: secondaryTextColor, // Defined in your code
                      ),
                    ),
                    const TextSpan(
                      text: 'Register',
                      style: TextStyle(
                        color: Colors.blue,
                        // fontWeight is inherited from the parent TextSpan's style
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable Input Decoration ---
  InputDecoration _inputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: secondaryTextColor, fontSize: 15),
      prefixIcon: Icon(icon, color: secondaryTextColor, size: 22),
      fillColor: textFieldFillColor,
      filled: true,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: accentColor, width: 2.0),
      ),
    );
  }

  // --- Login Logic Handler ---
  void _handleStudentLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await ApiServices.validateStudent(
          prn: int.parse(_studentPRNController.text),
          password: _studentPasswordController.text);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['status']) {
          _studentPRNController.clear();
          _studentPasswordController.clear();
<<<<<<< HEAD

=======
          
>>>>>>> 05feae35b47784663b5cb3855d02b9651cea23ed
          // Save student session to SharedPreferences
          await saveStudentSession(
            rememberMe: isChecked,
            studentName: result['studentName'],
            studentID: result['student_id'],
            prn: result['prn'].toString(),
          );
<<<<<<< HEAD

          // Register FCM token for push notifications
          await registerFCMToken(result['student_id']);

          Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(
                builder: (context) => StudentHomeScreen()
            ),
            (route) => false
=======
          
          // Register FCM token for push notifications
          await registerFCMToken(result['student_id']);
          
          navigatorWithAnimation(
            context,
            const StudentHomeScreen(),
>>>>>>> 05feae35b47784663b5cb3855d02b9651cea23ed
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid Credentials'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

<<<<<<< HEAD

=======
>>>>>>> 05feae35b47784663b5cb3855d02b9651cea23ed
