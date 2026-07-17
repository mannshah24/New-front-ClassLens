import 'dart:ui';
import 'package:classlens/data_models/student_list.dart';
import 'package:flutter/material.dart';
import 'package:classlens/data_models/teacher_subjects.dart';
import 'package:lottie/lottie.dart';
import '../../api/api.dart';
import 'package:classlens/global/global.dart';
import 'package:classlens/api/attendance_export_service.dart';


const Color primaryTextColor = Color(0xFF1A2533);
const Color secondaryTextColor = Color(0xFF6C757D);
const Color cardBackgroundColor = Colors.white;
const Color primaryBackgroundColor = Color(0xFFF0F4F8);
const Color accentColor = Color(0xFF4A90E2);
const Color successColor = Color(0xFF43A047);
const Color attentionColor = Color(0xFFE53935);
const Color warningColor = Color(0xFFFDD835);

const Color circleColor1 = Color.fromARGB(255, 178, 218, 255);
const Color circleColor2 = Color.fromARGB(255, 201, 247, 222);

class StudentListPage extends StatefulWidget {
  final TeacherSubjects subject;
  const StudentListPage({super.key, required this.subject});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {

  Future<List<StudentList>>? _studentsFuture;
  List<StudentList> _allStudents = [];
  List<StudentList> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _studentsFuture = loadStudents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<StudentList>> loadStudents() async {
    final students =
    await ApiServices.getStudentList(
      subjectID: widget.subject.id,
      divisionID: widget.subject.divisionId,
    );

    setState(() {
      _allStudents = students;
      _filteredStudents = students;
    });
    return students;
  }


  Future<void> _refreshStudents() async {

    _searchController.clear();

    setState(() {
      _studentsFuture = loadStudents();
    });

    await _studentsFuture;
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents
          .where((student) =>
      student.studentName.toLowerCase().contains(query) ||
          student.studentName.toLowerCase().contains(query))
          .toList();
    });
  }

  Widget _buildSearchBar() {

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: primaryTextColor),
        cursorColor: accentColor,
        decoration: InputDecoration(
          hintText: 'Search by name or roll no...',
          hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.7)),
          prefixIcon: Icon(
            Icons.search,
            color: secondaryTextColor.withOpacity(0.7),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: secondaryTextColor),
            onPressed: () {
              _searchController.clear();
            },
          )
              : null,
          filled: true,
          fillColor: cardBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  _handleExport() async {
    setState(() => _isExporting = true);
    try {
      await AttendanceExportService().downloadReport(widget.subject.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Widget _buildBlurredAppBar(BuildContext context) {

    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: EdgeInsets.only(
              top: topPadding,
              left: 4.0,
              right: 16.0,
            ),
            height: kToolbarHeight + topPadding,
            color: Colors.transparent,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: primaryTextColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.subject.subjectName,
                    style: const TextStyle(
                      color: primaryTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _isExporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryTextColor),
                    )
                  : IconButton(
                      icon: const Icon(Icons.download, color: primaryTextColor),
                      onPressed: _handleExport,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshableError(Widget child) {
    return RefreshIndicator(
      onRefresh: _refreshStudents,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

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


          Padding(
            padding: EdgeInsets.only(top: kToolbarHeight + topPadding),
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: FutureBuilder<List<StudentList>>(

                    future: _studentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          _allStudents.isEmpty) {
                        return Center(
                          child: Lottie.asset(
                              'assets/animations/loading2.json',
                              width: 350,
                              height: 350
                          ),
                        );
                      }


                      if (snapshot.hasError) {
                        return _buildRefreshableError(
                          Text(
                            'Error: ${snapshot.error}\nPull down to try again.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: attentionColor),
                          ),
                        );
                      }
                      if (_allStudents.isEmpty) {
                        return _buildRefreshableError(
                          const Text(
                            'No students found.\nPull down to refresh.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18, color: secondaryTextColor),
                          ),
                        );
                      }
                      if (_filteredStudents.isEmpty) {

                        return Center(
                          child: Text(
                            'No students found for "${_searchController.text}".',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18, color: secondaryTextColor),
                          ),
                        );
                      }


                      return RefreshIndicator(
                        onRefresh: _refreshStudents,
                        child: ListView.builder(
                          // Ensure it's always scrollable
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return StudentProgressTile(
                              student: student,
                              onTap: () {
                                print("Tapped on ${student.studentName}");
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          _buildBlurredAppBar(context),
        ],
      ),
    );
  }
}


class StudentProgressTile extends StatelessWidget {
  final StudentList student;
  final VoidCallback onTap;

  const StudentProgressTile({
    super.key,
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final Color progressColor;
    if (student.attendancePercentage >= 75.0) {
      progressColor = successColor;
    } else if (student.attendancePercentage >= 50.0) {
      progressColor = warningColor;
    } else {
      progressColor = attentionColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: progressColor.withOpacity(0.1),
                  child: Text(
                    student.studentName.isNotEmpty
                        ? student.studentName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        student.studentName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // const SizedBox(height: 4),
                      // Text(
                      //   "Student ID: ${student.studentID}",
                      //   style: const TextStyle(
                      //     fontSize: 13,
                      //     color: secondaryTextColor,
                      //   ),
                      // ),
                      const SizedBox(height: 4),
                      Text(
                        "Classes: ${student.attendedClasses} / ${student.totalClasses}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 45,
                  height: 45,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: student.attendancePercentage / 100,
                        backgroundColor: progressColor.withOpacity(0.2),
                        valueColor:
                        AlwaysStoppedAnimation<Color>(progressColor),
                        strokeWidth: 5,
                      ),
                      Center(
                        child: Text(
                          '${student.attendancePercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}