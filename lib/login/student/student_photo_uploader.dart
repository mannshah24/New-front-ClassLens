import 'dart:io';
import 'package:classlens/login/student/student_login.dart';
// import 'package:classlens/login/student/student_password_setter.dart';
import 'package:classlens/page_animations/slide_animation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:dotted_border/dotted_border.dart';

import '../../api/api.dart';

// --- SHARED COLOR & STYLE CONSTANTS (from your other files) ---
const Color primaryBackgroundColor = Color(0xFFF0F4F8);
const Color cardBackgroundColor = Colors.white;
const Color primaryTextColor = Color(0xFF1A2533);
const Color secondaryTextColor = Color(0xFF6C757D);
const Color buttonColor = Color(0xFF2C3E50);
const Color accentColor = Color(0xFFFFC107);
const Color circleColor1 = Color.fromARGB(255, 178, 218, 255);
const Color circleColor2 = Color.fromARGB(255, 201, 247, 222);

class StudentPhotoUploader extends StatefulWidget {
  final int prn;
  final String password;
  const StudentPhotoUploader({
    super.key,
    required this.prn,
    required this.password,
  });

  @override
  State<StudentPhotoUploader> createState() => _StudentPhotoUploaderState();
}

class ValidationResult {
  final bool isValid;
  final List<String> messages;
  final Rect? faceBoundingBox; // Optional: To return the detected face bounds

  ValidationResult({
    required this.isValid,
    this.messages = const [],
    this.faceBoundingBox,
  });
}

class _StudentPhotoUploaderState extends State<StudentPhotoUploader> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  bool _isRegistering = false;

  Future<void> _pickImage(ImageSource source) async {
<<<<<<< HEAD
    // Close the bottom sheet first, then wait for the dismiss animation to complete before launching the camera.
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

=======
    Navigator.of(context).pop(); // Close the bottom sheet
>>>>>>> 05feae35b47784663b5cb3855d02b9651cea23ed
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Compress image to reduce file size
      );
<<<<<<< HEAD

      if (!mounted) return;

=======
>>>>>>> 05feae35b47784663b5cb3855d02b9651cea23ed
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
<<<<<<< HEAD
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
=======
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
>>>>>>> 05feae35b47784663b5cb3855d02b9651cea23ed
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
  }

  Future<Size> _getImageSize(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = await decodeImageFromList(bytes);
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  Future<ValidationResult> _validateSelfie(XFile imageFile) async {
    final List<String> errorMessages = [];
    bool isGenerallyValid = true;
    Rect? detectedFaceBoundingBox;

    // --- ML Kit Face Detector Options ---
    final options = FaceDetectorOptions(
      enableClassification: true, // For smiling/eye open probability
      enableLandmarks: true, // For detecting eyes, mouth, etc.
      minFaceSize: 0.1, // Smallest face size relative to image width/height
      performanceMode: FaceDetectorMode.accurate, // Prioritize accuracy
    );
    final faceDetector = FaceDetector(options: options);

    try {
<<<<<<< HEAD
      final inputImage = InputImage.fromFilePath(imageFile.path);
      print("Starting image validation...");

      final imageSize = await _getImageSize(imageFile);

      // imageSize already fetched above alongside bytes reading
=======
      print("Starting image validation...");
      final inputImage = InputImage.fromFilePath(imageFile.path);
      
      print("Getting image size...");
      final imageSize = await _getImageSize(imageFile); 
>>>>>>> 05feae35b47784663b5cb3855d02b9651cea23ed

      print("Processing image with FaceDetector...");
      // Add a timeout to prevent infinite hanging
      final List<Face> faces = await faceDetector.processImage(inputImage).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception("Face detection timed out");
        },
      );
      print("Face detection complete. Found ${faces.length} faces.");

      // 1. Face Presence Check
      if (faces.isEmpty) {
        errorMessages.add(
          'No face detected. Please ensure your face is clearly visible.',
        );
        isGenerallyValid = false;
        return ValidationResult(
          isValid: false,
          messages: errorMessages,
        ); // Early exit
      }

      // 2. Single Face Check
      if (faces.length > 1) {
        errorMessages.add(
          'Multiple faces detected. Please upload a photo with only your face.',
        );
        isGenerallyValid = false;
        // You might still want to check the largest face if you decide to proceed
      }

      // Process the first (or largest) detected face
      // You could add logic here to find the largest face if multiple are detected
      // but for simplicity, we'll use the first one.
      final Face face = faces.first;
      detectedFaceBoundingBox = face.boundingBox;

      // 3. Face Size Check (relative to image size)
      final faceWidthPercentage = face.boundingBox.width / imageSize.width;
      final faceHeightPercentage = face.boundingBox.height / imageSize.height;

      // Adjust these thresholds as needed
      if (faceWidthPercentage < 0.20 || faceHeightPercentage < 0.20) {
        errorMessages.add(
          'The face in the image appears too small. Please try to be closer to the camera or use a higher resolution photo.',
        );
        isGenerallyValid = false;
      }

      // 4. Head Pose (Euler Angles) - Adjust thresholds as needed
      const double maxRotationY = 25.0; // Max degrees looking left/right
      const double maxRotationZ = 20.0; // Max degrees head tilt
      const double maxRotationX = 20.0; // Max degrees looking up/down

      if (face.headEulerAngleY != null &&
          face.headEulerAngleY!.abs() > maxRotationY) {
        errorMessages.add(
          'Please look more directly towards the camera (avoid turning your head too much to the side).',
        );
        isGenerallyValid = false;
      }
      if (face.headEulerAngleZ != null &&
          face.headEulerAngleZ!.abs() > maxRotationZ) {
        errorMessages.add(
          'Please keep your head straight and avoid tilting it too much.',
        );
        isGenerallyValid = false;
      }
      if (face.headEulerAngleX != null &&
          face.headEulerAngleX!.abs() > maxRotationX) {
        errorMessages.add(
          'Please ensure your head is not tilted too far up or down.',
        );
        isGenerallyValid = false;
      }

      // 5. Key Landmark Visibility & Eye Open Probability
      final FaceLandmark? leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final FaceLandmark? rightEye = face.landmarks[FaceLandmarkType.rightEye];
      final FaceLandmark? mouthBottom = face
          .landmarks[FaceLandmarkType.bottomMouth]; // Or mouthLeft/mouthRight
      final FaceLandmark? noseBase = face.landmarks[FaceLandmarkType.noseBase];

      if (leftEye == null || rightEye == null) {
        errorMessages.add(
          'Eyes not clearly detected. Ensure they are not covered (e.g., by hair or glasses if they obstruct).',
        );
        isGenerallyValid = false;
      }
      if (mouthBottom == null || noseBase == null) {
        // Check for mouth and nose
        errorMessages.add(
          'Mouth or nose not clearly detected. Ensure your face is not partially covered.',
        );
        isGenerallyValid = false;
      }

      // Eye Open Probability - Threshold can be adjusted (0.0 to 1.0)
      const double minEyeOpenProbability = 0.5;
      if (face.leftEyeOpenProbability != null &&
          face.leftEyeOpenProbability! < minEyeOpenProbability) {
        errorMessages.add(
          'Left eye appears to be closed or squinting. Please ensure both eyes are open.',
        );
        isGenerallyValid = false;
      }
      if (face.rightEyeOpenProbability != null &&
          face.rightEyeOpenProbability! < minEyeOpenProbability) {
        errorMessages.add(
          'Right eye appears to be closed or squinting. Please ensure both eyes are open.',
        );
        isGenerallyValid = false;
      }

      // Optional: Smiling Probability (if you need a neutral expression)
      // const double maxSmilingProbability = 0.3;
      // if (face.smilingProbability != null && face.smilingProbability! > maxSmilingProbability) {
      //   errorMessages.add('Please maintain a neutral facial expression (avoid excessive smiling).');
      //   isGenerallyValid = false;
      // }
    } catch (e) {
      print('Error during selfie validation: $e');
      errorMessages.add(
        'An error occurred while analyzing the image. Please try a different photo.',
      );
      isGenerallyValid = false;
    } finally {
      await faceDetector.close();
    }

    return ValidationResult(
      isValid:
          isGenerallyValid &&
          errorMessages.isEmpty, // isValid is true only if no errors
      messages: errorMessages,
      faceBoundingBox: detectedFaceBoundingBox,
    );
  }

  // Future<bool> _detectFace(XFile imageFile) async {
  //   final options = FaceDetectorOptions();
  //   final faceDetector = FaceDetector(options: options);
  //   try {
  //     final inputImage = InputImage.fromFilePath(imageFile.path);
  //     final List<Face> faces = await faceDetector.processImage(inputImage);
  //     return faces.isNotEmpty;
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to detect face: $e')),
  //     );
  //     return false;
  //   } finally {
  //     faceDetector.close();
  //   }
  // }

  void _proceedToNextStep() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a photo to continue.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    // Show a loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analyzing image... Please wait.'),
        duration: Duration(seconds: 2), // Short duration so it doesn't stick
      ),
    );

    ValidationResult? validation;
    try {
      validation = await _validateSelfie(_imageFile!);
    } catch (e) {
      print("Validation error: $e");
      validation = ValidationResult(isValid: false, messages: ["Error analyzing image: $e"]);
    }

    if (!mounted) return;

    setState(() {
      _isAnalyzing = false;
    });

    // Hide loading indicator
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (validation == null || !validation.isValid) {
      // Show all validation messages
      String allMessages = validation?.messages.join('\n') ?? "Unknown error";
      if (validation?.messages.isEmpty ?? true) {
        allMessages = "The image is not suitable. Please try another one.";
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Image Validation Failed'),
          content: Text(allMessages),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // If all checks pass
    print('Selfie validation successful. Proceeding to registration...');
    
    setState(() {
      _isRegistering = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image valid! Registering...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      bool response = await ApiServices.registerStudent(
        prn: widget.prn,
        password: widget.password,
        photoBytes: await _imageFile!.readAsBytes(),
        photoFilename: _imageFile!.name,
      );

      if (!mounted) return;

      if (response) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        navigatorWithAnimation(context, const StudentLogin());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful! Please login."),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to register. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: accentColor,
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: primaryTextColor),
                ),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: accentColor,
                ),
                title: const Text(
                  'Take a Photo',
                  style: TextStyle(color: primaryTextColor),
                ),
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildPhotoCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard() {
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
          const Icon(Icons.camera_alt_outlined, color: accentColor, size: 48),
          const SizedBox(height: 16),
          const FittedBox(
            child: Text(
              'Upload Your Photo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const FittedBox(
            child: Text(
              "This photo will be used for attendance.",
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          _buildImagePickerBox(), // New image picker box
          const SizedBox(height: 32),
          AnimatedConfirmButton(
            text: _isAnalyzing 
                ? 'Analyzing...' 
                : _isRegistering 
                    ? 'Registering...' 
                    : 'Continue',
            onPressed: _proceedToNextStep,
            isEnabled: _imageFile != null && !_isAnalyzing && !_isRegistering,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerBox() {
    return GestureDetector(
      onTap: _imageFile == null ? _showImageSourceActionSheet : null,
      child: DottedBorder(
        color: secondaryTextColor.withOpacity(0.5),
        strokeWidth: 2,
        dashPattern: const [8, 6],
        borderType: BorderType.RRect,
        radius: const Radius.circular(24),
        child: Container(
          height: 280,
          width: double.infinity,
          clipBehavior: Clip
              .antiAlias, // Ensures the child (Image) respects the border radius
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              22,
            ), // Slightly less than DottedBorder radius for better clipping
            color: _imageFile == null
                ? cardBackgroundColor.withOpacity(0.5)
                : Colors.transparent,
          ),
          child: _imageFile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 60,
                        color: accentColor.withOpacity(0.8),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Select Attendance Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap here to upload or take a photo',
                        style: TextStyle(
                          color: secondaryTextColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // Handle web and mobile image display
                    kIsWeb
                        ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                        : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _removeImage,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          padding: const EdgeInsets.all(4), // Reduced padding
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

// --- REUSABLE ANIMATED BUTTON WIDGET (Adapted for enable/disable state) ---
class AnimatedConfirmButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isEnabled;

  const AnimatedConfirmButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  State<AnimatedConfirmButton> createState() => _AnimatedConfirmButtonState();
}

class _AnimatedConfirmButtonState extends State<AnimatedConfirmButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled) setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isEnabled) {
      setState(() => _isPressed = false);
      widget.onPressed();
    }
  }

  void _onTapCancel() {
    if (widget.isEnabled) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.96 : 1.0;
    final color = widget.isEnabled ? buttonColor : Colors.grey;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: widget.isEnabled
                ? [
                    BoxShadow(
                      color: buttonColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
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
