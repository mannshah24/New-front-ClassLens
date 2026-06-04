import 'package:classlens/home/teacher_home/student_list_page.dart';
import 'package:classlens/page_animations/slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:classlens/api/api.dart';
import 'package:classlens/data_models/teacher_subjects.dart';
import 'package:lottie/lottie.dart';


const Color primaryTextColor = Color(0xFF1A2533);
const Color secondaryTextColor = Color(0xFF6C757D);
const Color cardBackgroundColor = Colors.white;
const Color primaryBackgroundColor = Color(0xFFF0F4F8);

class StudentsPercentageStatus extends StatefulWidget {
  final String? teacherName;
  final int teacherID;

  const StudentsPercentageStatus({
    super.key,
    this.teacherName,
    required this.teacherID,
  });

  @override
  State<StudentsPercentageStatus> createState() =>
      _StudentsPercentageStatusState();
}

class _StudentsPercentageStatusState extends State<StudentsPercentageStatus> with TickerProviderStateMixin{
  
  Future<List<TeacherSubjects>>? _subjectsFuture;

  final List<Color> _iconColors = [
    const Color(0xFF6E8CF3), // Blue/Purple
    const Color(0xFF20C997), // Green
    const Color(0xFFFE924B), // Orange
    const Color(0xFFF7678B), // Pink
    const Color(0xFF4AC2E2), // Cyan
    const Color(0xFF8B77E8), // Violet
    const Color(0xFFE55C7A), // Raspberry
    const Color(0xFF5A9CF5), // Bright Blue
    const Color(0xFFF3BF43), // Golden Yellow
    const Color(0xFF7D7AFF), // Lavender
  ];

  @override
  void initState() {
    super.initState();

    _subjectsFuture = loadSubjects();
  }

  Future<List<TeacherSubjects>> loadSubjects() async {
    print("Loading subjects for teacher ID: ${widget.teacherID}");
    List<TeacherSubjects> subjects =
    await ApiServices.getTeacherSubjects(teacherID: widget.teacherID);
    return subjects;
  }


  Future<void> _refreshSubjects() async {

    setState(() {
      _subjectsFuture = loadSubjects();
    });

    await _subjectsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TeacherSubjects>>(
      future: _subjectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
         return Center(
           child: Lottie.asset(
             'assets/animations/loading2.json',
               fit: BoxFit.contain
           ),
         );
        }


        if (snapshot.hasError) {
          return RefreshIndicator(
            onRefresh: _refreshSubjects,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                alignment: Alignment.center,
                child: Text(
                    'Error: ${snapshot.error}\nPull down to try again.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshSubjects,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                alignment: Alignment.center,
                child: const Text(
                  'No subjects assigned.\nPull down to refresh.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: secondaryTextColor),
                ),
              ),
            ),
          );
        }

        final subjects = snapshot.data!;


        return RefreshIndicator(
          onRefresh: _refreshSubjects,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final iconColor = _iconColors[index % _iconColors.length];

              return ProfessionalSubjectTile(
                subject: subject,
                iconBgColor: iconColor,
                onTap: () {
                  print(
                      "Tapped on ${subject.subjectName} (ID: ${subject.id}) (strength: ${subject.strength})");
                      navigatorWithAnimation(context, StudentListPage(subject: subject));
                },
              );
            },
          ),
        );
      },
    );
  }
}


class ProfessionalSubjectTile extends StatelessWidget {
  final TeacherSubjects subject;
  final Color iconBgColor;
  final VoidCallback onTap;

  const ProfessionalSubjectTile({
    super.key,
    required this.subject,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (subject.divisionName != null && subject.divisionName!.trim().isNotEmpty)
                            ? '${subject.subjectName} (${subject.divisionName})'
                            : subject.subjectName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject.subjectCode,
                        style: const TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            color: secondaryTextColor.withOpacity(0.8),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${subject.strength} Students',
                            style: const TextStyle(
                              fontSize: 13,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: secondaryTextColor.withOpacity(0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}