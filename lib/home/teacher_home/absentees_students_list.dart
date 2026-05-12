import 'package:classlens/data_models/class_session_data.dart';
import 'package:classlens/global/global.dart';
import 'package:flutter/material.dart';
import 'package:classlens/api/api.dart';
import 'package:classlens/data_models/student_list.dart';
import 'package:classlens/data_models/teacher_subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

import 'package:lottie/lottie.dart';

import '../../data_models/present_absentees_student.dart';

const Color primaryTextColor = Color(0xFF1A2533);
const Color secondaryTextColor = Color(0xFF6C757D);
const Color cardBackgroundColor = Colors.white;
const Color primaryBackgroundColor = Color(0xFFF0F4F8);
const Color accentColor = Color(0xFF4A90E2);
const Color attentionColor = Color(0xFFE53935);
const Color dividerColor = Color(0xFFE8E8E8);
const Color successColor = Color(0xFF43A047);


const Color circleColor1 = Color.fromARGB(255, 178, 218, 255);
const Color circleColor2 = Color.fromARGB(255, 201, 247, 222);

const List<Color> _avatarColors = [
  Color(0xFF6E8CF3), // Blue/Purple
  Color(0xFF20C997), // Green
  Color(0xFFFE924B), // Orange
  Color(0xFFF7678B), // Pink
  Color(0xFF4AC2E2), // Cyan
  Color(0xFF8B77E8), // Violet
  Color(0xFFE55C7A), // Raspberry
  Color(0xFFF3BF43), // Golden Yellow
];

class AbsenteesStudentList extends StatefulWidget {
  final int sessionID;
  final String subjectName;

  const AbsenteesStudentList({
    super.key,
    required this.sessionID,
    required this.subjectName,
  });

  @override
  State<AbsenteesStudentList> createState() => _AbsenteesStudentListState();
}

class _AbsenteesStudentListState extends State<AbsenteesStudentList> with SingleTickerProviderStateMixin {
  List<StudentList> _allStudents = [];
  List<PresentAbsenteesStudents> _originalAbsentStudents = [];
  

  List<StudentList> _presentList = [];
  List<PresentAbsenteesStudents> _absentList = [];
  
  // For filtering
  List<StudentList> _filteredPresentList = [];
  List<PresentAbsenteesStudents> _filteredAbsentList = [];

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? teacherID = prefs.getInt("teacherID");
      
      if (teacherID == null) {
        throw Exception("Teacher ID not found");
      }

      // 1. Get Teacher Subjects to find Subject ID
      List<TeacherSubjects> subjects = await ApiServices.getTeacherSubjects(teacherID: teacherID);
      int? subjectID;
      try {
        final subject = subjects.firstWhere((s) => s.subjectName == widget.subjectName);
        subjectID = subject.id;
      } catch (e) {
        print("Subject not found in teacher's list: ${widget.subjectName}");
      }

      // 2. Get Absent Students (using sessionID)
      final absentStudents = await ApiServices.getPresentAbsentStudents(sessionID: widget.sessionID,isPresent: false);
      _originalAbsentStudents = List.from(absentStudents);
      _absentList = List.from(absentStudents);

      // 3. Get All Students (using subjectID)
      if (subjectID != null) {
        final allStudents = await ApiServices.getStudentList(subjectID: subjectID);
        _allStudents = allStudents;
        
        // 4. Derive Present Students
        // Present = All - Absent
        final absentIds = _absentList.map((s) => s.studentID).toSet();
        _presentList = _allStudents.where((s) => !absentIds.contains(s.studentID)).toList();
      } else {
        _presentList = []; // Cannot determine present students without subjectID
      }

      _filterStudents();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load data. Please try again.";
        });
      }
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAbsentList = _absentList.where((student) {
        return student.studentName.toLowerCase().contains(query) ||
            student.studentID.toString().contains(query) ||
            student.studentPRN.toString().contains(query);
      }).toList();

      _filteredPresentList = _presentList.where((student) {
        return student.studentName.toLowerCase().contains(query) ||
            student.studentID.toString().contains(query);
      }).toList();
    });
  }

  void _toggleStudentStatus(dynamic student) {
    int id;
    String name;
    int prn = 0;
    
    if (student is PresentAbsenteesStudents) {
      id = student.studentID;
      name = student.studentName;
      prn = student.studentPRN;
    } else if (student is StudentList) {
      id = student.studentID;
      name = student.studentName;
    } else {
      return;
    }

    setState(() {
      // Check if currently in absent list
      final absentIndex = _absentList.indexWhere((s) => s.studentID == id);
      if (absentIndex != -1) {
        // Move to Present
        _absentList.removeAt(absentIndex);
        // Add to Present List
        final originalInAll = _allStudents.firstWhere((s) => s.studentID == id, orElse: () => StudentList(studentID: id, studentName: name, totalClasses: 0, attendedClasses: 0));
        _presentList.add(originalInAll);
      } else {
        // Check if currently in present list
        final presentIndex = _presentList.indexWhere((s) => s.studentID == id);
        if (presentIndex != -1) {
          // Move to Absent
          _presentList.removeAt(presentIndex);
          // Add to Absent List
          final originalAbsent = _originalAbsentStudents.firstWhere((s) => s.studentID == id, orElse: () => PresentAbsenteesStudents(studentID: id, studentName: name, studentPRN: prn));
          _absentList.add(originalAbsent);
        }
      }
      _filterStudents();
    });
  }

  Future<void> _onSavePressed() async {
    // Calculate changes
    final originalAbsentIDs = _originalAbsentStudents.map((s) => s.studentID).toSet();
    final currentAbsentIDs = _absentList.map((s) => s.studentID).toSet();

    // Students who were absent but are now present (Removed from absent list)
    final toMarkPresent = originalAbsentIDs.difference(currentAbsentIDs).toList();
    
    // Students who were present but are now absent (Added to absent list)
    final toMarkAbsent = currentAbsentIDs.difference(originalAbsentIDs).toList();

    // Combine all changed students
    final allChanged = [...toMarkPresent, ...toMarkAbsent];

    if (allChanged.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No changes to save.")),
      );
      return;
    }

    print("Marking changed students: $allChanged");
    
    // We assume the API toggles status for the sent students
    bool result = await ApiServices.changeAttendance(sessionID: widget.sessionID, students: allChanged);

    if(result) {
      SessionStats? ss = classSessionBox.get(widget.sessionID);
      if(ss!=null) {
        int netChange = toMarkPresent.length - toMarkAbsent.length;
        ss.presentCount += netChange;
        ss.absentCount -= netChange;
        await ss.save();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Updated attendance successfully."),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update attendance."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const buttonBarHeight = 90.0;

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

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      color: accentColor,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: secondaryTextColor,
                    tabs: [
                      Tab(text: "Absent (${_filteredAbsentList.length})"),
                      Tab(text: "Present (${_filteredPresentList.length})"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: accentColor,
                    child: _isLoading
                        ? Center(child: Lottie.asset('assets/animations/loading2.json',width: screenSize.width*0.8,height: screenSize.height*0.8,fit: BoxFit.contain))
                        : _errorMessage != null
                          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: attentionColor)))
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildStudentList(_filteredAbsentList, true, buttonBarHeight + bottomPadding),
                                _buildStudentList(_filteredPresentList, false, buttonBarHeight + bottomPadding),
                              ],
                            ),
                  ),
                ),
              ],
            ),
          ),


          _buildBlurredAppBar(context),

          _buildBlurredBottomBar(context, buttonBarHeight, bottomPadding),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: primaryTextColor),
        cursorColor: accentColor,
        decoration: InputDecoration(
          hintText: 'Search by name or ID...',
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

  Widget _buildStudentList(List<dynamic> students, bool isAbsentList, double bottomPadding) {
    if (students.isEmpty) {
      return Center(
        child: Text(
          isAbsentList ? 'No absent students.' : 'No present students.',
          style: const TextStyle(fontSize: 18, color: secondaryTextColor),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 8.0, bottom: bottomPadding, left: 16.0, right: 16.0),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final color = _avatarColors[index % _avatarColors.length];
        
        String name = "";
        int id = 0;
        String subtitle = "";
        
        if (student is PresentAbsenteesStudents) {
          name = student.studentName;
          id = student.studentID;
          subtitle = 'ID: $id | PRN: ${student.studentPRN}';
        } else if (student is StudentList) {
          name = student.studentName;
          id = student.studentID;
          subtitle = 'ID: $id';
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
              onTap: () => _toggleStudentStatus(student),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : '',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Action Icon
                    Icon(
                      isAbsentList ? Icons.check_circle_outline : Icons.highlight_off,
                      color: isAbsentList ? successColor : attentionColor,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        _searchController.text.isEmpty
            ? 'No students found.'
            : 'No students found matching "${_searchController.text}".',
        style: const TextStyle(fontSize: 18, color: secondaryTextColor),
      ),
    );
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
            padding: EdgeInsets.only(top: topPadding, left: 4.0, right: 16.0),
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
                    widget.subjectName,
                    style: const TextStyle(
                      color: primaryTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlurredBottomBar(BuildContext context, double height, double padding) {
    final originalAbsentIDs = _originalAbsentStudents.map((s) => s.studentID).toSet();
    final currentAbsentIDs = _absentList.map((s) => s.studentID).toSet();
    bool hasChanges = originalAbsentIDs.length != currentAbsentIDs.length || !originalAbsentIDs.containsAll(currentAbsentIDs);
    
    bool isSaveDisabled = !hasChanges;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, padding + 16.0),

            color: cardBackgroundColor.withOpacity(0.75),
            child: Row(
              children: [

                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _absentList = List.from(_originalAbsentStudents);
                        if (_allStudents.isNotEmpty) {
                          final absentIds = _absentList.map((s) => s.studentID).toSet();
                          _presentList = _allStudents.where((s) => !absentIds.contains(s.studentID)).toList();
                        }
                        _filterStudents();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: attentionColor,
                      side: const BorderSide(color: attentionColor, width: 2),
                      shape: const StadiumBorder(),

                      backgroundColor: cardBackgroundColor.withOpacity(0.8),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaveDisabled ? null : _onSavePressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      disabledBackgroundColor: accentColor.withOpacity(0.4),
                      disabledForegroundColor: Colors.white.withOpacity(0.8),
                    ),
                    child: Text(
                      'Save Changes',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
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
