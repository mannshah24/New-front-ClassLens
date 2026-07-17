import 'dart:async';
import 'package:flutter/material.dart';
import 'package:classlens/api/api.dart';
import 'package:classlens/page_animations/slide_animation.dart';
import 'package:classlens/login/student/student_password_setter.dart';
import 'package:classlens/login/teacher/teacher_password_setter.dart';
import 'package:classlens/login/student/student_signup_page.dart';
import 'package:classlens/login/teacher/teacher_signup_page.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final bool isStudent;
  const ForgotPasswordScreen({super.key, required this.isStudent});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prnController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String _sentToEmail = '';

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
  void dispose() {
    _prnController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer(int seconds) {
    setState(() {
      _cooldownSeconds = seconds;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        _cooldownTimer?.cancel();
      }
    });
  }

  Future<void> _handleSendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final prn = widget.isStudent ? int.tryParse(_prnController.text) : null;
      final email = widget.isStudent ? null : _emailController.text;

      final result = await ApiServices.forgotPasswordSendOtp(
        email: email,
        prn: prn,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        setState(() {
          _isOtpSent = true;
          _sentToEmail = result['email'] ?? '';
        });
        _startCooldownTimer(result['cooldown_seconds']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'OTP sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final message = result['message'] ?? 'Failed to send OTP.';
        final isNotRegistered = message.toLowerCase().contains('not registered') || 
                               message.toLowerCase().contains('sign up');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isNotRegistered ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        if (isNotRegistered && mounted) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => widget.isStudent
                      ? const StudentSignUpPage()
                      : const TeacherSignUpPage(),
                ),
              );
            }
          });
        }
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otpText = _otpController.text;
    if (otpText.isEmpty || otpText.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 4-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final otp = int.tryParse(otpText);
    if (otp == null) return;

    setState(() {
      _isLoading = true;
    });

    final prn = widget.isStudent ? int.tryParse(_prnController.text) : null;
    final email = widget.isStudent ? null : _emailController.text;

    final result = await ApiServices.forgotPasswordVerifyOtp(
      email: email,
      prn: prn,
      otp: otp,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      final verifiedEmail = result['email'] ?? _sentToEmail;
      final String? token = result['token'];
      if (widget.isStudent) {
        final verifiedPrn = result['prn'] ?? prn;
        Navigator.of(context).pop(); // Go back from forgot password screen
        navigatorWithAnimation(
          context,
          StudentPasswordSetter(
            email: verifiedEmail,
            prn: verifiedPrn!,
            isForgotPassword: true,
            token: token,
          ),
        );
      } else {
        Navigator.of(context).pop(); // Go back from forgot password screen
        navigatorWithAnimation(
          context,
          TeacherPasswordSetter(
            email: verifiedEmail,
            token: token,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Invalid OTP.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isStudent ? 'Student Password Reset' : 'Teacher Password Reset',
          style: const TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
        ),
      ),
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isOtpSent) ...[
              Icon(
                widget.isStudent ? Icons.school_outlined : Icons.person_outline,
                color: buttonColor,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                widget.isStudent ? 'Verify PRN' : 'Verify Email',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isStudent
                    ? 'Enter your university PRN to get a password reset OTP on your registered email.'
                    : 'Enter your university email to get a password reset OTP.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: secondaryTextColor, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),
              widget.isStudent
                  ? TextFormField(
                      key: const ValueKey('student_prn'),
                      controller: _prnController,
                      decoration: _inputDecoration('University PRN', Icons.badge_outlined),
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
                    )
                  : TextFormField(
                      key: const ValueKey('teacher_email'),
                      controller: _emailController,
                      decoration: _inputDecoration('University Email', Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your email";
                        }
                        if (!RegExp(r"^[a-zA-Z0-9._%+-]+@msubaroda\.ac\.in$").hasMatch(value)) {
                          return "Please enter a valid University email";
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 20),
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
                onPressed: _isLoading ? null : _handleSendOtp,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                    : const Text('Send Reset OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ] else ...[
              const Icon(Icons.mark_email_read_outlined, color: accentColor, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Verify OTP',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor),
              ),
              const SizedBox(height: 12),
              Text(
                'We have sent a verification code to:\n$_sentToEmail',
                textAlign: TextAlign.center,
                style: const TextStyle(color: secondaryTextColor, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _otpController,
                decoration: _inputDecoration('4-Digit OTP', Icons.security_outlined),
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
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
                onPressed: _isLoading ? null : _handleVerifyOtp,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                    : const Text('Verify & Reset', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text("Didn't receive code? ", style: TextStyle(color: secondaryTextColor, fontSize: 14)),
                  GestureDetector(
                    onTap: _cooldownSeconds > 0 ? null : _handleSendOtp,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: Text(
                        _cooldownSeconds > 0 ? 'Resend in ${_cooldownSeconds}s' : 'Resend OTP',
                        style: TextStyle(
                          color: _cooldownSeconds > 0 ? secondaryTextColor : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

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
}
