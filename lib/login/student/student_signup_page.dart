import 'package:classlens/api/api.dart';
import 'package:flutter/material.dart';
import 'package:classlens/page_animations/slide_animation.dart';
import 'package:classlens/login/student/student_otp.dart';


const Color primaryBackgroundColor = Color(0xFFF0F4F8);
const Color cardBackgroundColor = Colors.white;
const Color primaryTextColor = Color(0xFF1A2533);
const Color secondaryTextColor = Color(0xFF6C757D);
const Color buttonColor = Color(0xFF2C3E50);
const Color accentColor = Color(0xFFFFC107);
const Color textFieldFillColor = Color(0xFFF7F8F9);
const Color circleColor1 = Color.fromARGB(255, 178, 218, 255);
const Color circleColor2 = Color.fromARGB(255, 201, 247, 222);

class StudentSignUpPage extends StatefulWidget {
  const StudentSignUpPage({super.key});

  @override
  State<StudentSignUpPage> createState() => _StudentSignUpPageState();
}

class _StudentSignUpPageState extends State<StudentSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _studentPRNController = TextEditingController();

  @override
  void dispose() {
    _studentPRNController.dispose();
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school, color: primaryTextColor, size: 40),
                        const SizedBox(width: 12),
                        const Text(
                          'ClassLens',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _buildStudentSignUpPageCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSignUpPageCard() {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(30.0), // Consistent border radius
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
          children: [
            const Icon(Icons.person_add_alt_1_outlined, color: accentColor, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Register Here',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Enter your university PRN to receive a verification OTP.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _studentPRNController,
              decoration: _inputDecoration('PRN', Icons.badge_outlined),
              keyboardType: TextInputType.number,
              maxLength: 10,
              validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your PRN";
              }
              if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                return "Please enter a valid 10-digit PRN";
              }
              return null;
              },
            ),
            const SizedBox(height: 32),

            AnimatedButton(
              text: 'Get OTP',
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final prnString = _studentPRNController.text;
                  final prn = int.tryParse(prnString);
                  if (prn == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid PRN format')));
                    return;
                  }
                  Map<String, String> response = await ApiServices.verifyPRN(prn: prn);
                  if(response['status'] =='verified'){
                    // ignore: use_build_context_synchronously
                    navigatorWithAnimation(
                        context, StudentOtpPage(email: response['email']!, prn: prn)
                    );
                  }
                  else{
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message']!)));
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle( // Default style for the whole TextSpan
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                        color: secondaryTextColor, // Defined in your code
                      ),
                    ),
                    const TextSpan(
                      text: 'Login',
                      style: TextStyle(
                        color: Colors.blue,
                        // fontWeight is inherited from the parent TextSpan's style
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center, // Optional: if you want to ensure center alignment
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- Consistent InputDecoration ---
  InputDecoration _inputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: secondaryTextColor, fontSize: 15),
      prefixIcon: Icon(icon, color: secondaryTextColor, size: 22),
      fillColor: textFieldFillColor,
      filled: true,
      counterText: '',
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: buttonColor, width: 2.0),
      ),
    );
  }
}



class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const AnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    // A small delay to let the animation finish before navigating
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
        widget.onPressed();
      }
    });
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.96 : 1.0;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}