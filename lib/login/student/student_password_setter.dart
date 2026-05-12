// import 'package:classlens/login/student/student_login.dart';
import 'package:classlens/login/student/student_photo_uploader.dart';
import 'package:classlens/page_animations/slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:classlens/api/api.dart';

// --- SHARED COLOR & STYLE CONSTANTS ---
const Color primaryBackgroundColor = Color(0xFFF0F4F8);
const Color cardBackgroundColor = Colors.white;
const Color primaryTextColor = Color(0xFF1A2533);
const Color secondaryTextColor = Color(0xFF6C757D);
const Color buttonColor = Color(0xFF2C3E50);
const Color accentColor = Color(0xFFFFC107);
const Color textFieldFillColor = Color(0xFFF7F8F9);
const Color circleColor1 = Color.fromARGB(255, 178, 218, 255);
const Color circleColor2 = Color.fromARGB(255, 201, 247, 222);

class StudentPasswordSetter extends StatefulWidget {
  final String email;
  final int prn;
  const StudentPasswordSetter({
    super.key,
    required this.email,
    required this.prn,
  });

  @override
  State<StudentPasswordSetter> createState() => _StudentPasswordSetterState();
}

class _StudentPasswordSetterState extends State<StudentPasswordSetter> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _studentPasswordController = TextEditingController();
  final _studentConfirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _studentPasswordController.dispose();
    _studentConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _confirmPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_studentPasswordController.text !=
          _studentConfirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Passwords do not match"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });
      // ignore: unused_local_variable
      bool response = await ApiServices.setPassword(email: widget.email, password: _studentPasswordController.text);

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        navigatorWithAnimation(
          context,
          StudentPhotoUploader(
            prn: widget.prn,
            password: _studentPasswordController.text,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password set successfully!"),
              backgroundColor: Colors.green),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
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
                child: _buildPasswordCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(28.0),
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
          children: [
            const Icon(Icons.lock_reset, color: accentColor, size: 48),
            const SizedBox(height: 16),
            FittedBox(
              child: const Text(
                'Set New Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FittedBox(
              child: Text(
                "Create a new, secure password for\n${widget.email}",
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            _buildPasswordFields(),
            const SizedBox(height: 32),
            AnimatedButton(
              text: 'Confirm',
              onPressed: _confirmPassword,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        TextFormField(
          controller: _studentPasswordController,
          decoration: _inputDecoration("New Password", Icons.lock_outline)
              .copyWith(
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: secondaryTextColor,
                  ),
                ),
              ),
          validator: (value) {
            if (value == null || value.isEmpty) return "Enter a password";
            if (value.length < 8)
              return "Password must be at least 8 characters";
            return null;
          },
          obscureText: _obscurePassword,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _studentConfirmPasswordController,
          decoration:
              _inputDecoration(
                "Confirm New Password",
                Icons.lock_outline,
              ).copyWith(
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: secondaryTextColor,
                  ),
                ),
              ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return "Please confirm your password";
            if (value != _studentPasswordController.text)
              return "Passwords do not match";
            return null;
          },
          obscureText: _obscureConfirmPassword,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: secondaryTextColor),
      prefixIcon: Icon(icon, color: secondaryTextColor, size: 22),
      fillColor: textFieldFillColor,
      filled: true,
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

// --- REUSABLE ANIMATED BUTTON WIDGET ---
class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const AnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) => setState(() => _isPressed = true);

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onPressed();
  }

  void _onTapCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.96 : 1.0;

    return GestureDetector(
      onTapDown: widget.isLoading ? null : _onTapDown,
      onTapUp: widget.isLoading ? null : _onTapUp,
      onTapCancel: widget.isLoading ? null : _onTapCancel,
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
            child: widget.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
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
