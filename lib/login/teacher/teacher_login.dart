
import 'package:flutter/material.dart';
import 'package:classlens/login/teacher/teacher_signup_page.dart';
import 'package:classlens/api/api.dart';
import 'package:classlens/home/teacher_home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: unused_import
import 'package:classlens/global/global.dart';
import 'package:classlens/login/forgot_password.dart';

class Login extends StatefulWidget {
  final String? initialEmail;
  final String? initialPassword;
  const Login({super.key, this.initialEmail, this.initialPassword});

  @override
  State<Login> createState() => _LoginPageState();
}

class _LoginPageState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool isChecked = true;
  bool _obscurePassword = true;

  final _teacherEmailController = TextEditingController();
  final _teacherPasswordController = TextEditingController();

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
    _teacherEmailController.text = widget.initialEmail ?? "";
    _teacherPasswordController.text = widget.initialPassword ?? "";
  }

  @override
  void dispose() {
    _teacherEmailController.dispose();
    _teacherPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

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
                child: _buildLoginCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
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
              'Welcome, Teacher',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 28),

            // --- Email Text Field ---
            TextFormField(
              controller: _teacherEmailController,
              decoration: _inputDecoration('Email', Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter an email";
                }
                if (!RegExp(r"^[a-zA-Z0-9._%+-]+@msubaroda\.ac\.in$").hasMatch(value)) {
                  return "Please enter a valid University email";
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            // --- Password Text Field ---
            TextFormField(
              controller: _teacherPasswordController,
              decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
            const SizedBox(height: 12),

            // --- Forgot Password Link ---
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(isStudent: false),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
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
              onPressed: _isLoading ? null : _handleLogin,
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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TeacherSignUpPage()),
                );
              },
              child: const Text.rich(
                TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(color: secondaryTextColor, fontSize: 15),
                  children: [
                    TextSpan(
                      text: 'Register',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await ApiServices.validateTeacher(
          email: _teacherEmailController.text,
          password: _teacherPasswordController.text);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['status']) {
          _teacherEmailController.clear();
          _teacherPasswordController.clear();
          final SharedPreferences pref = await SharedPreferences.getInstance();
          pref.setBool("rememberMe", isChecked);
          pref.setString("teacherName", result['teacherName']);
          pref.setInt("teacherID", result['teacherID']);
         // navigatorWithAnimation(context, Home(teacherName: result['teacherName'] as String?,teacherID: result['teacherID'] as int),);

          saveTeacherSession(
              rememberMe: isChecked,
              teacherName: result['teacherName'],
              teacherID: result['teacherID']
          );

          await registerTeacherFCMToken(result['teacherID']);

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => Home(
                teacherName: result['teacherName'] as String?,
                teacherID: result['teacherID'] as int,
              ),
            ),
                (route) => false,
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

