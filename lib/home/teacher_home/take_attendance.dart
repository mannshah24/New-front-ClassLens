import 'dart:io';
import 'package:classlens/api/api.dart';
import 'package:classlens/data_models/departments.dart';
import 'package:classlens/data_models/subjects.dart';
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
  String? _selectedDepartment;
  String? _selectedSubject;
  int? _selectedSubjectID;
  String? _selectedDivision;
  int? _selectedDivisionID;
  String? _selectedYear;
  String? _selectedSemester;
  bool _isLoading = false;
  late Future<List<Departments>> _departments;
  List<Departments> _departmentLookup = [];
  List<Subjects> _subjects = [];
  List<Map<String, dynamic>> _divisions = [];
  final List<String> _years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
  final List<String> _semesters = ['Semester 1', 'Semester 2'];
  bool _isSubjectsLoading = false;
  bool _isDivisionsLoading = false;

  @override
  void initState() {
    super.initState();
    _departments = ApiServices.getDepartments().then((departments) {
      _departmentLookup = departments;
      return departments;
    });
  }

  Future<void> _fetchSubjects() async{
    if(_selectedDepartment!=null && _selectedSemester!=null && _selectedYear!=null){
      setState(() {
        _isSubjectsLoading=true;
        _selectedSubject=null;
        _selectedDivision=null;
        _selectedDivisionID=null;
        _subjects=[];
        _divisions=[];
      });
      final int updatedYear = int.parse(_selectedYear!.replaceAll(RegExp(r'[^0-9]'), ''));
      final int updatedSemester = int.parse(_selectedSemester!.replaceAll(RegExp(r'[^0-9]'), ''));
      print(updatedSemester);
      print(_selectedDepartment!+_selectedSemester!+_selectedYear!);
      try{
        final List<Subjects> fetchedSubject = await ApiServices.getSubjects(
            departmentName: _selectedDepartment!,
            year: updatedYear,
            semester: updatedSemester
        );

        setState(() {
          _isSubjectsLoading=false;
          _subjects= fetchedSubject;
        });
      }
      catch(e){
        setState(() { _isSubjectsLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching subjects'))
        );
      }


    }
  }

  Future<void> _fetchDivisions() async {
    if (_selectedDepartment == null || _selectedYear == null || _selectedSemester == null) {
      return;
    }

    setState(() {
      _isDivisionsLoading = true;
      _selectedDivision = null;
      _selectedDivisionID = null;
      _divisions = [];
    });

    try {
      final departmentId = _departmentLookup
          .where((department) => department.departmentName == _selectedDepartment)
          .map((department) => department.id)
          .cast<int?>()
          .firstWhere((id) => id != null, orElse: () => null);

      final fetchedDivisions = await ApiServices.getDivisions(
        departmentId: departmentId,
        year: int.tryParse(_selectedYear!.replaceAll(RegExp(r'[^0-9]'), '')),
        semester: int.tryParse(_selectedSemester!.replaceAll(RegExp(r'[^0-9]'), '')),
      );

      setState(() {
        _divisions = fetchedDivisions.where((division) {
          final divisionDepartment = division['department'];
          final divisionYear = int.tryParse(division['year'].toString());
          final divisionSemester = int.tryParse(division['semester'].toString());
          return (departmentId == null || divisionDepartment == departmentId) &&
              (divisionYear == null || divisionYear == int.tryParse(_selectedYear!.replaceAll(RegExp(r'[^0-9]'), ''))) &&
              (divisionSemester == null || divisionSemester == int.tryParse(_selectedSemester!.replaceAll(RegExp(r'[^0-9]'), '')));
        }).toList();
        _isDivisionsLoading = false;
      });
    } catch (e) {
      setState(() {
        _isDivisionsLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching divisions')),
      );
    }
  }

  String _divisionLabel(Map<String, dynamic> division) {
    final name = division['name']?.toString() ?? 'Division';
    final year = division['year']?.toString();
    final semester = division['semester']?.toString();
    final program = division['program_name']?.toString();

    final details = <String>[];
    if (program != null && program.isNotEmpty) {
      details.add(program);
    }
    if (year != null && year.isNotEmpty) {
      details.add('Year $year');
    }
    if (semester != null && semester.isNotEmpty) {
      details.add('Sem $semester');
    }

    return details.isEmpty ? name : '$name · ${details.join(' · ')}';
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
        setState(() {
          _imageFiles.addAll(pickedFiles);
          if (_imageFiles.length > 3) {
            _imageFiles = _imageFiles.sublist(0, 3);
          }
        });
        if (_imageFiles.length > 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 3 images allowed')),
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
        if (_imageFiles.length < 3) {
          setState(() => _imageFiles.add(pickedFile));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 3 images allowed')),
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
    if (_imageFiles.isEmpty ||
        _selectedDepartment == null ||
        _selectedYear == null ||
        _selectedSemester == null||
        _selectedSubjectID==null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields to proceed.'),
          backgroundColor: attentionColor,
        ),
      );
      return;
    }

    else {
      try {
        final int updatedYear = int.parse(_selectedYear!.replaceAll(RegExp(r'[^0-9]'), ''));
        final int updatedSemester = int.parse(_selectedSemester!.replaceAll(RegExp(r'[^0-9]'), ''));

        // 2. Navigate to the new processing screen and wait for a result
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProcessingScreen(
              imageFiles: _imageFiles.map((x) => File(x.path)).toList(),
              departmentName: _selectedDepartment!,
              semester: updatedSemester,
              year: updatedYear,
              subject: _selectedSubject!,
              subjectID:_selectedSubjectID!,
              divisionID: _selectedDivisionID,
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
              FutureBuilder<List<Departments>>(
                future: _departments,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Unable to fetch departments: ${snapshot.error}');
                  }
                  if (snapshot.hasData) {
                    final List<Departments> departmentsList = snapshot.data!;
                    final List<String> departmentNames = departmentsList
                        .map((department) => department.departmentName)
                        .toList();
                    return Column(
                      children: [
                        _buildDropdown(
                          icon: Icons.school_outlined,
                          hint: 'Department',
                          value: _selectedDepartment,
                          items: departmentNames,

                          onChanged: (value) {
                            setState(() => _selectedDepartment = value);
                            _fetchSubjects();
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          icon: Icons.format_list_numbered,
                          hint: 'Year',
                          value: _selectedYear,
                          items: _years,
                          onChanged: (value) {
                            setState(() => _selectedYear = value);
                            _fetchSubjects();
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          icon: Icons.calendar_today_outlined,
                          hint: 'Semester',
                          value: _selectedSemester,
                          items: _semesters,
                          onChanged: (value) {
                            setState(() => _selectedSemester = value);
                            _fetchSubjects();
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_isSubjectsLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: CircularProgressIndicator(),
                          )
                        else
                          _buildDropdown(
                            icon: Icons.subject,
                            hint: 'Subject',
                            value: _selectedSubject,
                            items: _subjects.map((s) => s.name).toList(),
                            onChanged: _subjects.isEmpty
                                ? null
                                : (value) {
                                if(value==null){
                                  setState(() {
                                    _selectedSubjectID=null;
                                    _selectedSubject=null;
                                    _selectedDivisionID=null;
                                    _selectedDivision=null;
                                    _divisions=[];
                                  });
                                }else{
                                  final selectedSubject = _subjects.firstWhere((s)=>s.name==value);
                                  setState(() {
                                    _selectedSubject=selectedSubject.name;
                                    _selectedSubjectID=selectedSubject.id;
                                  });
                                  _fetchDivisions();
                                }
                                setState(() => _selectedSubject = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_selectedDepartment == null || _selectedYear == null || _selectedSemester == null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: const Text(
                                'Select department, year, and semester to load available divisions.',
                                style: TextStyle(color: secondaryTextColor),
                              ),
                            )
                          else if (_isDivisionsLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: CircularProgressIndicator(),
                            )
                          else
                            DropdownButtonFormField<int>(
                              value: _selectedDivisionID,
                              hint: const Text('Division (optional)'),
                              isExpanded: true,
                              items: _divisions
                                  .map((division) {
                                    final idValue = division['id'] is int
                                        ? division['id'] as int
                                        : int.tryParse(division['id'].toString());
                                    if (idValue == null) {
                                      return null;
                                    }
                                    return DropdownMenuItem<int>(
                                      value: idValue,
                                      child: Text(
                                        _divisionLabel(division),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    );
                                  })
                                  .whereType<DropdownMenuItem<int>>()
                                  .toList(),
                              onChanged: _divisions.isEmpty
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedDivisionID = value;
                                        _selectedDivision = value == null
                                            ? null
                                            : _divisions
                                                .firstWhere(
                                                  (division) => (division['id'] is int
                                                      ? division['id'] as int
                                                      : int.tryParse(division['id'].toString())) == value,
                                                  orElse: () => <String, dynamic>{},
                                                )['name']
                                                ?.toString();
                                      });
                                    },
                              dropdownColor: cardBackgroundColor,
                              borderRadius: BorderRadius.circular(16.0),
                              icon: const Icon(
                                Icons.arrow_drop_down_rounded,
                                color: secondaryTextColor,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Division (optional)',
                                labelStyle: const TextStyle(color: secondaryTextColor),
                                floatingLabelStyle: const TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                prefixIcon: const Icon(Icons.groups_outlined, color: accentColor),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(color: accentColor, width: 2.0),
                                ),
                              ),
                            ),
                          if (_divisions.isEmpty && !_isDivisionsLoading && _selectedDepartment != null && _selectedYear != null && _selectedSemester != null)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                'No divisions found for the selected class details. You can still submit attendance without a division.',
                                style: TextStyle(color: secondaryTextColor, fontSize: 12),
                              ),
                            ),
                        const SizedBox(height: 32),
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
              itemCount: _imageFiles.length + (_imageFiles.length < 3 ? 1 : 0),
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
                            'Tap here to upload (Max 3)',
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

  Widget _buildDropdown({
    required IconData icon,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      selectedItemBuilder: (BuildContext context) {
        return items.map<Widget>((String item) {
          return Text(
            item,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          );
        }).toList();
      },
      onChanged: onChanged,

      dropdownColor: cardBackgroundColor,
      borderRadius: BorderRadius.circular(16.0),

      icon: const Icon(
        Icons.arrow_drop_down_rounded,
        color: secondaryTextColor,
      ),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: secondaryTextColor),
        floatingLabelStyle: const TextStyle(
          color: accentColor,
          fontWeight: FontWeight.bold,
        ),

        prefixIcon: Icon(icon, color: accentColor),

        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: accentColor, width: 2.0),
        ),
      ),
    );
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
