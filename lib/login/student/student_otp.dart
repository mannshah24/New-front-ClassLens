import 'dart:async';
import 'package:classlens/api/api.dart';
import 'package:classlens/login/student/student_password_setter.dart';
import 'package:flutter/material.dart';
import 'package:classlens/page_animations/slide_animation.dart';

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

class StudentOtpPage extends StatefulWidget {
  final String email;
  final int prn;

  const StudentOtpPage({super.key, required this.email, required this.prn});

  @override
  State<StudentOtpPage> createState() => _StudentOtpPageState();
}

class _StudentOtpPageState extends State<StudentOtpPage> {
  final _otpController1 = TextEditingController();
  final _otpController2 = TextEditingController();
  final _otpController3 = TextEditingController();
  final _otpController4 = TextEditingController();

  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();
  final FocusNode _focusNode4 = FocusNode();

  Timer? _timer;
  int _start = 60;
  bool _isResendAvailable = false;

  @override
  void initState() {
    super.initState();
    _sendOtpAndStartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController1.dispose();
    _otpController2.dispose();
    _otpController3.dispose();
    _otpController4.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    _focusNode3.dispose();
    _focusNode4.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_start ~/ 60).toString().padLeft(2, '0');
    final seconds = (_start % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _isResendAvailable = false;
      _start = seconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer?.cancel();
          _isResendAvailable = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  Future<void> _sendOtpAndStartTimer() async {
    setState(() {
      _isResendAvailable = false;
      _start = 60;
    });
    _startTimer(60);

    final result = await ApiServices.sendOpt(email: widget.email);
    if (mounted) {
      int cooldown = result['cooldown_seconds'] ?? 60;
      _startTimer(cooldown);
      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send OTP.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_isResendAvailable) {
      setState(() {
        _isResendAvailable = false;
        _start = 60;
      });
      _timer?.cancel();

      final result = await ApiServices.sendOpt(email: widget.email);
      if (mounted) {
        int cooldown = result['cooldown_seconds'] ?? 60;
        _startTimer(cooldown);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP Resent Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to resend OTP. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmOtp() async {
    final otp =
        _otpController1.text +
        _otpController2.text +
        _otpController3.text +
        _otpController4.text;

    if (otp.length == 4) {
      bool response = await ApiServices.verifyOpt(
        email: widget.email,
        otp: int.parse(otp),
      );
      if (response) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          navigatorWithAnimation(
            context,
            StudentPasswordSetter(email: widget.email, prn: widget.prn),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 4 digits of the OTP.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      body: Stack(
        children: [
          // --- Background Circles ---
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
                        const Icon(
                          Icons.school,
                          color: primaryTextColor,
                          size: 40,
                        ),
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
                    _buildOtpCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard() {
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
      child: Column(
        children: [
          const Icon(Icons.lock_outline, color: accentColor, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Verification',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Enter the 4-digit code sent to\n${widget.email}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // --- OTP Fields ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _otpField(_otpController1, _focusNode1, _focusNode2),
              _otpField(_otpController2, _focusNode2, _focusNode3),
              _otpField(_otpController3, _focusNode3, _focusNode4),
              _otpField(_otpController4, _focusNode4, null),
            ],
          ),
          const SizedBox(height: 32),

          AnimatedButton(text: 'Verify', onPressed: _confirmOtp),

          const SizedBox(height: 24),

          // --- Resend Timer ---
          TextButton(
            onPressed: _isResendAvailable ? _resendOtp : null,
            child: Text(
              _isResendAvailable
                  ? "Resend OTP"
                  : "Resend OTP in $_formattedTime",
              style: TextStyle(
                color: _isResendAvailable ? buttonColor : secondaryTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpField(
    TextEditingController controller,
    FocusNode currentFocus,
    FocusNode? nextFocus,
  ) {
    return SizedBox(
      width: 50,
      height: 60,
      child: TextFormField(
        controller: controller,
        focusNode: currentFocus,
        autofocus: true,
        onChanged: (value) {
          if (value.length == 1 && nextFocus != null) {
            nextFocus.requestFocus();
          }
          if (value.isEmpty && currentFocus != _focusNode1) {
            // Handle backspace to move focus back?
            // Flutter's default behavior might not do this automatically for empty fields easily without RawKeyboardListener
            // For simplicity, we keep it forward moving or manual tap.
            FocusScope.of(context).previousFocus();
          }
        },
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        decoration: InputDecoration(
          counterText: "",
          fillColor: textFieldFillColor,
          filled: true,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: buttonColor, width: 2.0),
          ),
        ),
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
