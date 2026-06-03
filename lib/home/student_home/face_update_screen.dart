import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:classlens/api/api.dart';
import 'package:classlens/global/global.dart';
import 'student_colors.dart';

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
