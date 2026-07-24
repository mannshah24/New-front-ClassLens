import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:classlens/api/api.dart';
import 'package:classlens/global/global.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'student_colors.dart';

class ValidationResult {
  final bool isValid;
  final List<String> messages;
  final Rect? faceBoundingBox;

  ValidationResult({
    required this.isValid,
    this.messages = const [],
    this.faceBoundingBox,
  });
}

class StudentFaceUpdateScreen extends StatefulWidget {
  final String prn;

  const StudentFaceUpdateScreen({super.key, required this.prn});

  @override
  State<StudentFaceUpdateScreen> createState() => _StudentFaceUpdateScreenState();
}

class _StudentFaceUpdateScreenState extends State<StudentFaceUpdateScreen> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;

  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        );

      if (!mounted) return;

      if (pickedFile != null) {
        setState(() => _imageFile = pickedFile);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _removeImage() {
    setState(() => _imageFile = null);
  }

  bool _isSupportedImage(XFile imageFile) {
    final lowerName = imageFile.name.toLowerCase();
    return lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg') || lowerName.endsWith('.png');
  }

  Future<String?> _validateSelectedFile(XFile imageFile) async {
    if (!_isSupportedImage(imageFile)) {
      return 'Please select a JPG or PNG image.';
    }

    try {
      final fileSize = await File(imageFile.path).length();
      const maxSizeInBytes = 10 * 1024 * 1024;
      if (fileSize > maxSizeInBytes) {
        return 'Image is too large. Please choose a file under 10 MB.';
      }
    } catch (_) {
      // If size cannot be read, continue to the face validation step.
    }

    return null;
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

    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.accurate,
    );
    final faceDetector = FaceDetector(options: options);

    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final imageSize = await _getImageSize(imageFile);
      final List<Face> faces = await faceDetector.processImage(inputImage).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception("Face detection timed out");
        },
      );

      if (faces.isEmpty) {
        errorMessages.add('No face detected. Please ensure your face is clearly visible.');
        isGenerallyValid = false;
        return ValidationResult(isValid: false, messages: errorMessages);
      }

      if (faces.length > 1) {
        errorMessages.add('Multiple faces detected. Please upload a photo with only your face.');
        isGenerallyValid = false;
      }

      final Face face = faces.first;
      detectedFaceBoundingBox = face.boundingBox;

      final faceWidthPercentage = face.boundingBox.width / imageSize.width;
      final faceHeightPercentage = face.boundingBox.height / imageSize.height;

      if (faceWidthPercentage < 0.20 || faceHeightPercentage < 0.20) {
        errorMessages.add('The face in the image appears too small. Please try to be closer to the camera or use a higher resolution photo.');
        isGenerallyValid = false;
      }

      const double maxRotationY = 25.0;
      const double maxRotationZ = 20.0;
      const double maxRotationX = 20.0;

      if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > maxRotationY) {
        errorMessages.add('Please look more directly towards the camera (avoid turning your head too much to the side).');
        isGenerallyValid = false;
      }
      if (face.headEulerAngleZ != null && face.headEulerAngleZ!.abs() > maxRotationZ) {
        errorMessages.add('Please keep your head straight and avoid tilting it too much.');
        isGenerallyValid = false;
      }
      if (face.headEulerAngleX != null && face.headEulerAngleX!.abs() > maxRotationX) {
        errorMessages.add('Please ensure your head is not tilted too far up or down.');
        isGenerallyValid = false;
      }

      final FaceLandmark? leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final FaceLandmark? rightEye = face.landmarks[FaceLandmarkType.rightEye];
      final FaceLandmark? mouthBottom = face.landmarks[FaceLandmarkType.bottomMouth];
      final FaceLandmark? noseBase = face.landmarks[FaceLandmarkType.noseBase];

      if (leftEye == null || rightEye == null) {
        errorMessages.add('Eyes not clearly detected. Ensure they are not covered.');
        isGenerallyValid = false;
      }
      if (mouthBottom == null || noseBase == null) {
        errorMessages.add('Mouth or nose not clearly detected. Ensure your face is not partially covered.');
        isGenerallyValid = false;
      }

      const double minEyeOpenProbability = 0.5;
      if (face.leftEyeOpenProbability != null && face.leftEyeOpenProbability! < minEyeOpenProbability) {
        errorMessages.add('Left eye appears to be closed or squinting. Please ensure both eyes are open.');
        isGenerallyValid = false;
      }
      if (face.rightEyeOpenProbability != null && face.rightEyeOpenProbability! < minEyeOpenProbability) {
        errorMessages.add('Right eye appears to be closed or squinting. Please ensure both eyes are open.');
        isGenerallyValid = false;
      }
    } catch (e) {
      errorMessages.add('An error occurred while analyzing the image. Please try a different photo.');
      isGenerallyValid = false;
    } finally {
      await faceDetector.close();
    }

    return ValidationResult(
      isValid: isGenerallyValid && errorMessages.isEmpty,
      messages: errorMessages,
      faceBoundingBox: detectedFaceBoundingBox,
    );
  }

  void _proceedToUpdate() async {
    if (_imageFile == null) return;
    setState(() => _isAnalyzing = true);

    final fileValidationMessage = await _validateSelectedFile(_imageFile!);
    if (!mounted) return;
    if (fileValidationMessage != null) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fileValidationMessage)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analyzing image... Please wait.'),
        duration: Duration(seconds: 2),
      ),
    );

    ValidationResult? validation;
    try {
      validation = await _validateSelfie(_imageFile!);
    } catch (e) {
      validation = ValidationResult(isValid: false, messages: ["Error analyzing image: $e"]);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (validation == null || !validation.isValid) {
      setState(() => _isAnalyzing = false);
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

    setState(() => _isAnalyzing = true);
    final accessToken = await getStudentAccessToken();
    final updateResult = await ApiServices.updateStudentFace(
      photoBytes: await _imageFile!.readAsBytes(),
      photoFilename: _imageFile!.name,
      prn: widget.prn,
      accessToken: accessToken.isNotEmpty ? accessToken : null,
    );

    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    if (updateResult['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updateResult['message']?.toString() ?? 'Student face updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Failed'),
        content: Text(updateResult['message']?.toString() ?? 'Failed to update face.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        title: const Text("Update Face ID", style: TextStyle(color: primaryTextColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryTextColor),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Image Picker Area
              GestureDetector(
                onTap: _imageFile == null ? _pickImageFromCamera : null,
                child: DottedBorder(
                  color: secondaryTextColor.withOpacity(0.5),
                  strokeWidth: 2,
                  dashPattern: const [8, 6],
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(24),
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: _imageFile == null ? cardBackgroundColor : Colors.transparent,
                    ),
                    child: _imageFile == null
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.face, size: 60, color: accentColor.withOpacity(0.8)),
                          const SizedBox(height: 12),
                          const Text('Tap to Take New Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor)),
                        ],
                      ),
                    )
                        : Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 12, right: 12,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            onPressed: _removeImage,
                            style: IconButton.styleFrom(backgroundColor: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _imageFile != null ? buttonColor : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isAnalyzing ? null : _proceedToUpdate,
                  child: _isAnalyzing
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify & Update', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
