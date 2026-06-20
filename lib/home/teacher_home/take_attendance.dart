import 'dart:io';
import 'package:classlens/api/api.dart';
import 'package:classlens/data_models/teacher_subjects.dart';
import 'package:classlens/global/global.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:classlens/home/teacher_home/processing_screen.dart';

// Using a consistent color palette
const Color primaryBackgroundColor = Color(0xFFF0F4F8);
const Color cardBackgroundColor = Colors.white;
const Color primaryTextColor = Color(0xFF1A2533);
const Color secondaryTextColor = Color(0xFF6C757D);
const Color accentColor = Color(0xFF1A2533);
const Color buttonColor = Color(0xFF2C3E50);
const Color attentionColor = Color(0xFFE53935);
const Color borderColor = Color(0xFFE8EBF0);

class AttendanceUploadScreen extends StatefulWidget {
  const AttendanceUploadScreen({super.key});

  @override
  State<AttendanceUploadScreen> createState() => _AttendanceUploadScreenState();
}

class _AttendanceUploadScreenState extends State<AttendanceUploadScreen> {
  List<XFile> _imageFiles = [];
  bool _isLoading = false;

  late Future<List<TeacherSubjects>> _teacherSubjectsFuture;
  TeacherSubjects? _selectedTeacherSubject;

  @override
  void initState() {
    super.initState();
    _teacherSubjectsFuture = ApiServices.getTeacherSubjects(teacherID: userID);
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final picker = ImagePicker();

    if (source == ImageSource.gallery) {
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        imageQuality: 85,
      );

      if (!mounted) return;

      if (pickedFiles.isNotEmpty) {
        final totalLength = _imageFiles.length + pickedFiles.length;
        setState(() {
          _imageFiles.addAll(pickedFiles);
          if (_imageFiles.length > 10) {
            _imageFiles = _imageFiles.sublist(0, 10);
          }
        });
        if (totalLength > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 10 images allowed')),
          );
        }
      }
    } else {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (pickedFile != null) {
        if (_imageFiles.length < 10) {
          setState(() => _imageFiles.add(pickedFile));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 10 images allowed')),
          );
        }
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
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
              const FittedBox(
                child: Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: accentColor,
                ),

                title: const Text('Choose from Gallery'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: accentColor,
                ),
                title: const Text('Take a Photo'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAttendance() async {
    if (_imageFiles.isEmpty || _selectedTeacherSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields to proceed.'),
          backgroundColor: attentionColor,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProcessingScreen(
            imageFiles: _imageFiles.map((x) => File(x.path)).toList(),
            departmentName: _selectedTeacherSubject!.departmentName ?? '',
            semester: _selectedTeacherSubject!.semester ?? 1,
            year: _selectedTeacherSubject!.year ?? 1,
            subject: _selectedTeacherSubject!.subjectName,
            subjectID: _selectedTeacherSubject!.id,
            divisionID: _selectedTeacherSubject!.divisionId,
          ),
        ),
      );
      if (result != null && result is String && mounted) {
        Navigator.of(context).pop(result);
      }
    }
    catch(e){
      print(e.toString());
    }
    finally{
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: AppBar(
        title: const FittedBox(
          child: Text(
            'Mark Attendance',
            style: TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryTextColor),
      ),
      body: Stack(
        children:[
          SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePickerBox(),
              const SizedBox(height: 32),
              const FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  'Class Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<TeacherSubjects>>(
                future: _teacherSubjectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text(
                      'Unable to fetch assigned classes: ${snapshot.error}',
                      style: const TextStyle(color: attentionColor),
                    );
                  }
                  
                  if (snapshot.hasData) {
                    final subjectsList = snapshot.data!;
                    if (subjectsList.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.info_outline_rounded, color: attentionColor, size: 40),
                            SizedBox(height: 12),
                            Text(
                              'No assigned classes found. Please contact your administrator.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: secondaryTextColor, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Select Class / Subject',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...subjectsList.map((subject) {
                          final isSelected = _selectedTeacherSubject?.id == subject.id &&
                              _selectedTeacherSubject?.divisionId == subject.divisionId;
                          return _buildSelectableSubjectCard(subject, isSelected);
                        }).toList(),
                        const SizedBox(height: 24),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              _buildSubmitButton(),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildImagePickerBox() {
    return Column(
      children: [
        if (_imageFiles.isNotEmpty)
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageFiles.length + (_imageFiles.length < 10 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _imageFiles.length) {
                  // Add button
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: _showImageSourceActionSheet,
                      child: DottedBorder(
                        color: secondaryTextColor.withOpacity(0.5),
                        strokeWidth: 2,
                        dashPattern: const [8, 6],
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(24),
                        child: Container(
                          width: 160,
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: cardBackgroundColor,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 40,
                                  color: accentColor.withOpacity(0.8),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Add More',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Stack(
                    children: [
                      Container(
                        width: 160,
                        height: 220,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          image: DecorationImage(
                            image: FileImage(File(_imageFiles[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          GestureDetector(
            onTap: _showImageSourceActionSheet,
            child: DottedBorder(
              color: secondaryTextColor.withOpacity(0.5),
              strokeWidth: 2,
              dashPattern: const [8, 6],
              borderType: BorderType.RRect,
              radius: const Radius.circular(24),
              child: Container(
                height: 220,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: cardBackgroundColor,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 60,
                          color: accentColor.withOpacity(0.8),
                        ),
                        const SizedBox(height: 12),
                        const FittedBox(
                          child: Text(
                            'Select Attendance Images',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          child: Text(
                            'Tap here to upload (Max 10)',
                            style: TextStyle(
                              color: secondaryTextColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectableSubjectCard(TeacherSubjects subject, bool isSelected) {
    final displayName = (subject.divisionName != null && subject.divisionName!.trim().isNotEmpty)
        ? '${subject.subjectName} (${subject.divisionName})'
        : subject.subjectName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: isSelected ? accentColor.withOpacity(0.05) : cardBackgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isSelected ? accentColor : borderColor,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
            setState(() {
              _selectedTeacherSubject = subject;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : borderColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: isSelected ? Colors.white : secondaryTextColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!subject.isMapped)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Proxy Subject',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subject.subjectCode} • ${subject.departmentName ?? "N/A"}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people_outline_rounded,
                              color: secondaryTextColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${subject.strength} Students',
                              style: const TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: secondaryTextColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_ordinalYear(subject.year)} Year • Sem ${subject.semester ?? "N/A"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: accentColor,
                    size: 26,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _ordinalYear(int? year) {
    if (year == 1) return '1st';
    if (year == 2) return '2nd';
    if (year == 3) return '3rd';
    if (year == 4) return '4th';
    return year?.toString() ?? 'N/A';
  }


  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: buttonColor,
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _submitAttendance,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            // Padding for safety
            child: _isLoading
                ? Lottie.asset('assets/animations/loading.json',width: 50,height: 50)
                : const FittedBox(
                    child: Text(
                      'Submit Attendance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
