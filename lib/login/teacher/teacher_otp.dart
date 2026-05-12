import 'dart:async';
import 'package:classlens/page_animations/slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:classlens/api/api.dart';
import 'package:classlens/login/teacher/teacher_password_setter.dart';

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

class TeacherOtpPage extends StatefulWidget {
  final String email;
  const TeacherOtpPage({super.key, required this.email});

  @override
  State<TeacherOtpPage> createState() => _TeacherOtpPageState();
}

class _TeacherOtpPageState extends State<TeacherOtpPage> {
  final _otpController1 = TextEditingController();
  final _otpController2 = TextEditingController();
  final _otpController3 = TextEditingController();
  final _otpController4 = TextEditingController();

  static const int initialTimerSeconds = 30;
  late int secondsRemaining = initialTimerSeconds;
  Timer? timer;

  final _otpFocusNode1 = FocusNode();
  final _otpFocusNode2 = FocusNode();
  final _otpFocusNode3 = FocusNode();
  final _otpFocusNode4 = FocusNode();

  @override
  void initState() {
    super.initState();
    ApiServices.sendOpt(email: widget.email);
    print("api-otp hit");
    _resetAndStartTimer();
  }

  void _resetAndStartTimer() {
    timer?.cancel();
    setState(() {
      secondsRemaining = initialTimerSeconds;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining == 0) {
        timer.cancel();
      } else {
        if (mounted) {
          setState(() {
            secondsRemaining--;
          });
        }
      }
    });
  }

  String get _formattedTime {
    final minutes = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _otpController1.dispose();
    _otpController2.dispose();
    _otpController3.dispose();
    _otpController4.dispose();
    _otpFocusNode1.dispose();
    _otpFocusNode2.dispose();
    _otpFocusNode3.dispose();
    _otpFocusNode4.dispose();
    timer?.cancel();
    super.dispose();
  }

  Future<void> _confirmOtp() async {
    final otp = _otpController1.text +
        _otpController2.text +
        _otpController3.text +
        _otpController4.text;

    if (otp.length == 4) {
      bool response = await ApiServices.verifyOpt(email: widget.email, otp: int.parse(otp));
      if (response) {
        if (mounted) {
          // Navigator.of(context).popUntil((route) => route.isFirst);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> TeacherPasswordSetter(email: widget.email,)));
         // navigatorWithAnimation(context, TeacherPasswordSetter(email: widget.email));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.'), backgroundColor: Colors.red),
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
          // --- Consistent Decorative Background Shapes ---
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
                child: _buildOtpCard(),
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
          const Icon(Icons.shield_outlined, color: accentColor, size: 48),
          const SizedBox(height: 16),
          FittedBox(
            child: const Text(
              'Enter Verification Code',
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
              "An OTP has been sent to\n${widget.email}",
              style: const TextStyle(color: secondaryTextColor, fontSize: 15, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          _buildOtpBoxes(),
          const SizedBox(height: 24),
          _buildResendOtp(),
          const SizedBox(height: 32),
          AnimatedConfirmButton(
            text: 'Confirm',
            onPressed: _confirmOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _otpTextField(_otpController1, _otpFocusNode1, true),
        _otpTextField(_otpController2, _otpFocusNode2, false),
        _otpTextField(_otpController3, _otpFocusNode3, false),
        _otpTextField(_otpController4, _otpFocusNode4, false),
      ],
    );
  }

  Widget _buildResendOtp() {
    bool canResend = secondsRemaining == 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(child: const Text("Didn't receive code? ", style: TextStyle(color: secondaryTextColor))),
            TextButton(
              onPressed: canResend ? () async {
                _resetAndStartTimer();
                bool response = await ApiServices.sendOpt(email: widget.email);
                if(response){
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("OTP resent! Please check your email."),
                        backgroundColor: Colors.green,
                      )
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("An unexpected error occurred."),
                        backgroundColor: Colors.red,
                      )
                  );
                }
              } : null,
              child: FittedBox(
                child: Text(
                  'Resend',
                  style: TextStyle(
                    color: canResend ? buttonColor : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!canResend)
          FittedBox(
            child: Text(
              "Resend available in: $_formattedTime",
              style: const TextStyle(color: secondaryTextColor),
            ),
          )
      ],
    );
  }

  Widget _otpTextField(TextEditingController controller, FocusNode focusNode, bool autoFocus) {
    return SizedBox(
      height: 64,
      width: 58,
      child: TextFormField(
        autofocus: autoFocus,
        controller: controller,
        focusNode: focusNode,
        onChanged: (value) {
          if (value.length == 1 && focusNode != _otpFocusNode4) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && focusNode != _otpFocusNode1) {
            FocusScope.of(context).previousFocus();
          }
        },
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor),
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          fillColor: textFieldFillColor,
          filled: true,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: const BorderSide(color: buttonColor, width: 2.0),
          ),
        ),
      ),
    );
  }
}

// --- REUSABLE ANIMATED BUTTON WIDGET ---
class AnimatedConfirmButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const AnimatedConfirmButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<AnimatedConfirmButton> createState() => _AnimatedConfirmButtonState();
}

class _AnimatedConfirmButtonState extends State<AnimatedConfirmButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    widget.onPressed();
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
            child: FittedBox(
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
      ),
    );
  }
}