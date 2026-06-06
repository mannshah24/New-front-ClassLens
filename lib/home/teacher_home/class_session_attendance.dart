import 'package:classlens/data_models/class_session_data.dart';
import 'package:classlens/global/global.dart';
import 'package:flutter/material.dart';
import 'package:classlens/api/api.dart';
import 'dart:ui';

import 'package:lottie/lottie.dart';

import '../../data_models/present_absentees_student.dart';


const Color appThemeColor = Color(0xFF465BD8);
const Color primaryTextColor = Color(0xFF1A2533);
const Color secondaryTextColor = Color(0xFF6C757D);
const Color cardBackgroundColor = Colors.white;
const Color primaryBackgroundColor = Color(0xFFF0F4F8);
const Color successColor = Color(0xFF4CAF50);
const Color attentionColor = Color(0xFFE53935);
const Color dividerColor = Color(0xFFE8E8E8);


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

class ClassSessionAttendance extends StatefulWidget {
  final int sessionID;
  final String subjectName;

  const ClassSessionAttendance({
    super.key,
    required this.sessionID,
    required this.subjectName,
  });

  @override
  State<ClassSessionAttendance> createState() => _ClassSessionAttendanceState();
}

class _ClassSessionAttendanceState extends State<ClassSessionAttendance> {
  List<String> _sessionPhotos = [];
  bool _loadingPhotos = true;

  @override
  void initState() {
    super.initState();
    _loadSessionPhotos();
  }

  Future<void> _loadSessionPhotos() async {
    try {
      final photos = await ApiServices.getSessionPhotos(sessionID: widget.sessionID);
      if (mounted) {
        setState(() {
          _sessionPhotos = photos;
          _loadingPhotos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingPhotos = false;
        });
      }
    }
  }

  void _viewImageFullScreen(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              maxScale: 4.0,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: primaryBackgroundColor,
        appBar: AppBar(
          backgroundColor: appThemeColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.subjectName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        body: Column(
          children: [
            if (!_loadingPhotos && _sessionPhotos.isNotEmpty) ...[
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: const Text(
                  "Face Detection Results",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: primaryTextColor,
                  ),
                ),
              ),
              Container(
                height: 150,
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _sessionPhotos.length,
                  itemBuilder: (context, index) {
                    final photoUrl = _sessionPhotos[index];
                    return GestureDetector(
                      onTap: () => _viewImageFullScreen(context, photoUrl),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12.0),
                        width: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) =>
                            progress == null ? child : const Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const Material(
              color: appThemeColor,
              child: TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3.0,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: [
                  Tab(text: "Present Students"),
                  Tab(text: "Absent Students"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  StudentListContent(
                    sessionID: widget.sessionID,
                    isAbsentView: false,
                  ),
                  StudentListContent(
                    sessionID: widget.sessionID,
                    isAbsentView: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentListContent extends StatefulWidget {
  final int sessionID;
  final bool isAbsentView;

  const StudentListContent({
    super.key,
    required this.sessionID,
    required this.isAbsentView,
  });

  @override
  State<StudentListContent> createState() => _StudentListContentState();
}

class _StudentListContentState extends State<StudentListContent> with AutomaticKeepAliveClientMixin {
  List<PresentAbsenteesStudents> _masterList = [];
  List<PresentAbsenteesStudents> _filteredList = [];
  final Set<int> _selectedStudents = {};

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    if (mounted) setState(() { _isLoading = true; });
    _searchController.clear();
    _selectedStudents.clear();

    List<PresentAbsenteesStudents> students = [];

    if (widget.isAbsentView) {
      students = await ApiServices.getPresentAbsentStudents(sessionID: widget.sessionID,isPresent: false);
    } else {

      students = await ApiServices.getPresentAbsentStudents(sessionID: widget.sessionID, isPresent: true);

      debugPrint("Fetching Present Students... (API Not connected in code)");
    }

    if (mounted) {
      setState(() {
        _masterList = students;
        _filteredList = students;
        _isLoading = false;
      });
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredList = _masterList.where((student) {
        return student.studentName.toLowerCase().contains(query) ||
            student.studentID.toString().contains(query) ||
            student.studentPRN.toString().contains(query);
      }).toList();
    });
  }

  void _onStudentTapped(int studentID) {
    setState(() {
      if (_selectedStudents.contains(studentID)) {
        _selectedStudents.remove(studentID);
      } else {
        _selectedStudents.add(studentID);
      }
    });
  }

  void _onClearPressed() {
    setState(() {
      _selectedStudents.clear();
    });
  }

  Future<void> _onSavePressed() async {

    bool markingAsPresent = widget.isAbsentView;

    print("Marking selected students. As Present? $markingAsPresent : $_selectedStudents");

    bool result = await ApiServices.changeAttendance(
        sessionID: widget.sessionID,
        students: _selectedStudents.toList()
    );

    if(result) {
      SessionStats? ss = classSessionBox.get(widget.sessionID);
      if(ss != null) {
        if (markingAsPresent) {
          ss.presentCount += _selectedStudents.length;
          ss.absentCount -= _selectedStudents.length;
        } else {
          ss.presentCount -= _selectedStudents.length;
          ss.absentCount += _selectedStudents.length;
        }
        await ss.save();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              markingAsPresent
                  ? "Marked ${_selectedStudents.length} students as Present."
                  : "Marked ${_selectedStudents.length} students as Absent."
          ),
          backgroundColor: successColor,
        ),
      );

      _loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final screenSize = MediaQuery.of(context).size;
    const buttonBarHeight = 90.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if(_isLoading){

    }

    return Stack(
      children: [
        Column(
          children: [

            Container(
              color: primaryBackgroundColor,
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: primaryTextColor),
                cursorColor: appThemeColor,
                decoration: InputDecoration(
                  hintText: 'Search student...',
                  hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.7)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: secondaryTextColor.withOpacity(0.7),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadStudents,
                color: appThemeColor,
                child: _isLoading
                    ? Center(child: Lottie.asset('assets/animations/loading2.json', width: screenSize.width*0.8))
                    : _filteredList.isEmpty
                    ? _buildEmptyState()
                    : _buildStudentList(buttonBarHeight + bottomPadding),
              ),
            ),
          ],
        ),


        if (_selectedStudents.isNotEmpty)
          _buildBottomBar(context, buttonBarHeight, bottomPadding),
      ],
    );
  }

  Widget _buildStudentList(double bottomPadding) {
    return ListView.separated(
      padding: EdgeInsets.only(top: 8.0, bottom: bottomPadding),
      itemCount: _filteredList.length,
      separatorBuilder: (ctx, index) => const Divider(color: dividerColor, height: 1),
      itemBuilder: (context, index) {
        final student = _filteredList[index];
        final isSelected = _selectedStudents.contains(student.studentID);
        final color = _avatarColors[index % _avatarColors.length];

        return Material(
          color: cardBackgroundColor,
          child: InkWell(
            onTap: () => _onStudentTapped(student.studentID),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [

                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        student.studentName.isNotEmpty
                            ? student.studentName[0].toUpperCase()
                            : '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
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
                          student.studentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [

                            Text(
                              'PRN: ${student.studentPRN}',
                              style: const TextStyle(fontSize: 13, color: secondaryTextColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.isAbsentView
                                ? attentionColor.withOpacity(0.1)
                                : successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.isAbsentView ? "Absent" : "Present",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: widget.isAbsentView ? attentionColor : successColor,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  if(isSelected)
                    const Icon(Icons.check_circle, color: appThemeColor, size: 28)
                  else
                    const Icon(Icons.radio_button_unchecked, color: Color(0xFFB0B0B0), size: 28),
                ],
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
            ? (widget.isAbsentView ? 'No absent students.' : 'No present students.')
            : 'No matches found.',
        style: const TextStyle(fontSize: 16, color: secondaryTextColor),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, double height, double padding) {
    String actionText = widget.isAbsentView
        ? 'Mark ${_selectedStudents.length} as Present'
        : 'Mark ${_selectedStudents.length} as Absent';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, padding + 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Row(
          children: [

            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _onClearPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.black54,
                  side: const BorderSide(color: Colors.black12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Clear'),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _onSavePressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: successColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}