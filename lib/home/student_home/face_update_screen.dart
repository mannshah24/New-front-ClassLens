import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:dotted_border/dotted_border.dart';
import 'student_colors.dart';

class ValidationResult {
  final bool isValid;
  final List<String> messages;
  final Rect? faceBoundingBox;
  ValidationResult({required this.isValid, this.messages = const [], this.faceBoundingBox});
}

class StudentFaceUpdateScreen extends StatefulWidget {
  const StudentFaceUpdateScreen({super.key});

  @override
  State<StudentFaceUpdateScreen> createState() => _StudentFaceUpdateScreenState();
}

class _StudentFaceUpdateScreenState extends State<StudentFaceUpdateScreen> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);

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

  Future<Size> _getImageSize(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = await decodeImageFromList(bytes);
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  Future<ValidationResult> _validateSelfie(XFile imageFile) async {
    final List<String> errorMessages = [];
    bool isGenerallyValid = true;
    final options = FaceDetectorOptions(enableClassification: true, enableLandmarks: true, minFaceSize: 0.1, performanceMode: FaceDetectorMode.accurate);
    final faceDetector = FaceDetector(options: options);

    try {
      final bytes = await imageFile.readAsBytes();
      final imageSize = await _getImageSize(imageFile);
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: imageSize.width.toInt() * 4,
        ),
      );
      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        errorMessages.add('No face detected.');
        return ValidationResult(isValid: false, messages: errorMessages);
      }
      if (faces.length > 1) {
        errorMessages.add('Multiple faces detected. Use a solo photo.');
        isGenerallyValid = false;
      }

      final Face face = faces.first;
      final faceWidthPercentage = face.boundingBox.width / imageSize.width;
      if (faceWidthPercentage < 0.20) {
        errorMessages.add('Face is too small. Move closer.');
        isGenerallyValid = false;
      }

      if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 25.0) {
        errorMessages.add('Look directly at the camera.');
        isGenerallyValid = false;
      }

      if (face.leftEyeOpenProbability != null && face.leftEyeOpenProbability! < 0.5) {
        errorMessages.add('Keep both eyes open.');
        isGenerallyValid = false;
      }

    } catch (e) {
      errorMessages.add('Error analyzing image.');
      isGenerallyValid = false;
    } finally {
      await faceDetector.close();
    }

    return ValidationResult(isValid: isGenerallyValid && errorMessages.isEmpty, messages: errorMessages);
  }

  void _proceedToUpdate() async {
    if (_imageFile == null) return;
    setState(() => _isAnalyzing = true);

    final ValidationResult validation = await _validateSelfie(_imageFile!);
    setState(() => _isAnalyzing = false);

    if (!validation.isValid) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invalid Photo'),
          content: Text(validation.messages.join('\n')),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }

    // SUCCESS MOCK
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Face ID Updated Successfully!'), backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.0))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Select Image Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: accentColor),
                title: const Text('Gallery'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: accentColor),
                title: const Text('Camera'),
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
                onTap: _imageFile == null ? _showImageSourceActionSheet : null,
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
                          const Text('Tap to Upload New Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor)),
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
