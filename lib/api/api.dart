import 'dart:convert';
import 'dart:io';
import 'package:classlens/data_models/subjects.dart';
import 'package:classlens/data_models/teacher_profile.dart';
import 'package:classlens/data_models/teacher_subjects.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:classlens/data_models/departments.dart';
import 'package:classlens/data_models/task_status.dart';
import 'package:classlens/data_models/student_list.dart';
import 'package:classlens/global/config.dart';
import '../data_models/present_absentees_student.dart';
import '../global/global.dart';

class ApiServices {
  static final String _baseUrl = AppConfig.baseUrl;

  static String _extractMessageFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final dynamic message = decoded['detail'] ?? decoded['error'] ?? decoded['message'];
        if (message != null) {
          return message.toString();
        }
      }
      if (decoded is String) {
        return decoded;
      }
    } catch (_) {
      // Fall through to raw body.
    }
    return body.trim().isEmpty ? 'Unknown error' : body;
  }

  static MediaType _mediaTypeForImage(String filename) {
    final lowerName = filename.toLowerCase();
    if (lowerName.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    return MediaType('image', 'jpeg');
  }

  static List<Map<String, dynamic>> _decodeMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  static Future<List<Departments>> getDepartments() async {
    print("base url is $_baseUrl");

    String apiUrl = '$_baseUrl/getDepartments/';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        List<Departments> departmentList = jsonData
            .map((json) => Departments.fromJson(json as Map<String, dynamic>))
            .toList();
        return departmentList;
      } else {
        throw Exception('Failed to load Departments${response.statusCode}');
      }
    } catch (e) {
      print(e.toString());
      throw Exception("Failed to load : $e");
    }
  }

  static Future<String?> signUpTeacher({
    required final String name,
    required String email,
    required String password,
    required String? departmentID,
  }) async {
    String endpoint = "$_baseUrl/registerNewTeacher/";
    final url = Uri.parse(endpoint);

    try {
      final headers = {'Content-Type': 'application/json; charset=UTF-8'};

      final body = jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "departmentID": departmentID,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        print('Sign up successful!');
        return "success";
      } else {
        return "failed";
      }
    } catch (e) {
      print(e.toString());
      return 'Could not connect to the server.';
    }
  }

  static Future<bool> sendOpt({required final String email}) async {
    String endpoint = "$_baseUrl/sendOtp/";
    final url = Uri.parse(endpoint);

    try {
      const headers = {'Content-Type': 'application/json; charset=UTF-8'};

      final body = jsonEncode({"email": email});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("mail sent");
        return Future.value(true);
      } else {
        print("mail not sent");
        return Future.value(false);
      }
    } catch (e) {
      print(e.toString());
      return Future.value(false);
    }
  }

  static Future<bool> verifyOpt({
    required final String email,
    required final int otp,
  }) async {
    String endpoint = "$_baseUrl/verifyOtp/";
    final url = Uri.parse(endpoint);

    try {
      const headers = {'Content-Type': 'application/json; charset=UTF-8'};

      final body = jsonEncode({"email": email, "otp": otp});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("otp verified");
        return Future.value(true);
      } else {
        return Future.value(false);
      }
    } catch (e) {
      print(e.toString());
      return Future.value(false);
    }
  }

  static Future<String> verifyEmail({required final String email}) async {
    String endpoint = "$_baseUrl/verifyEmail/";
    final url = Uri.parse(endpoint);

    const headers = {'Content-Type': 'application/json; charset=UTF-8'};

    final body = jsonEncode({'email': email});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("email verified");
        return Future.value("verified");
      } else {
        print("email not verified");
        final jsonBody = jsonDecode(response.body);
        return Future.value(jsonBody['detail'] ?? "No message");
      }
    } catch (e) {
      print(e.toString());
      return Future.value(e.toString());
    }
  }

  static Future<bool> setPassword({
    required final String email,
    required final String password,
  }) async {
    String endpoint = "$_baseUrl/setPassword/";
    final url = Uri.parse(endpoint);

    const headers = {'Content-Type': 'application/json; charset=UTF-8'};

    final body = jsonEncode({'email': email, 'password': password});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("otp verified");
        return Future.value(true);
      } else {
        return Future.value(false);
      }
    } catch (e) {
      print(e.toString());
      return Future.value(false);
    }
  }

  static Future<Map<String, dynamic>> validateTeacher({
    required final String email,
    required final String password,
  }) async {
    String endpoint = "$_baseUrl/validateTeacher/";
    final url = Uri.parse(endpoint);

    const headers = {'Content-Type': 'application/json; charset=UTF-8'};

    final body = jsonEncode({'email': email, 'password': password});

    try {
      final response = await http.post(url, headers: headers, body: body);
      String jsonBody = response.body;
      String teacherName = jsonDecode(jsonBody)['teacher_name'];
      int teacherID = jsonDecode(jsonBody)['teacher_id'];
      String message = jsonDecode(jsonBody)['message'];
      if (response.statusCode == 200) {
        print("teacher validated successfully");

        return {
          'status': true,
          'teacherID': teacherID,
          'teacherName': teacherName,
          'message': message,
        };
      } else {
        print("teacher validation failed");
        return {'status': false, 'teacherName': 'teacher', 'message': message};
      }
    } catch (e) {
      print(e.toString());
      return {
        'status': false,
        'teacherName': 'teacher',
        'message': 'exception',
      };
    }
  }

  static Future<List<Subjects>> getSubjects({
    required final String departmentName,
    required final int year,
    required final int semester,
  }) async {
    String endpoint = '$_baseUrl/getSubjectDetails/';
    final url = Uri.parse(endpoint);

    const headers = {'Content-Type': 'application/json; charset=UTF-8'};

    final body = jsonEncode({
      'department': departmentName,
      'year': year,
      'semester': semester,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body)['subjects'];
        return jsonData.map((json) => Subjects.fromJson(json)).toList();
      } else {
        String message = jsonDecode(response.body)['detail'];
        print(message);
        return Future.value([]);
      }
    } catch (e) {
      print(e.toString());
      throw Exception('Failed to connect to the server: $e');
    }
  }

  static Future<Map<String, dynamic>> markAttendance({
    required final List<File> imageFiles,
    required final String departmentName,
    required final int semester,
    required final int year,
    required final String subject,
    required final int subjectID,
    final int? divisionID,
  }) async {
    String endpoint = '$_baseUrl/markAttendance/';
    final url = Uri.parse(endpoint);
    try {
      final request = http.MultipartRequest('POST', url);


      request.fields['departmentName'] = departmentName;
      request.fields['year'] = year.toString();
      request.fields["teacherID"] = userID.toString();
      request.fields["subjectID"] = subjectID.toString();
      if (divisionID != null) {
        request.fields['divisionID'] = divisionID.toString();
      }
      print(subjectID);
      print(subject);

      for (final image in imageFiles) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', image.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode==202) {
        final responseData = json.decode(response.body);
        return {
          "message": responseData['message'] ?? "Task initiated",
          "task_id": responseData["task_id"]
        };
      } else {
        String errorMessage = 'Failed to mark attendance: ${response.statusCode}';
        try {
          final responseData = json.decode(response.body);
          if (responseData != null && responseData['error'] != null) {
            errorMessage = responseData['error'];
          } 
        } catch (_) {
          
        }
        return {"message": errorMessage, "task_id": null};
      }
    } catch (e) {
      print("Exception in markAttendance: ${e.toString()}");
      return {"message": e.toString(), "task_id": null};
    }
  }

  static Future<Map<String, dynamic>> resubmitAttendance({
    required final int sessionID,
    required final List<File> imageFiles,
  }) async {
    String endpoint = '$_baseUrl/resubmitAttendance/';
    final url = Uri.parse(endpoint);
    try {
      final request = http.MultipartRequest('POST', url);
      request.fields['class_session_id'] = sessionID.toString();

      for (final image in imageFiles) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', image.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 202) {
        final responseData = json.decode(response.body);
        return {
          "message": responseData['message'] ?? "Task initiated",
          "task_id": responseData["task_id"]
        };
      } else {
        String errorMessage = 'Failed to resubmit attendance: ${response.statusCode}';
        try {
          final responseData = json.decode(response.body);
          if (responseData != null && responseData['error'] != null) {
            errorMessage = responseData['error'];
          }
        } catch (_) {}
        return {"message": errorMessage, "task_id": null};
      }
    } catch (e) {
      print("Exception in resubmitAttendance: ${e.toString()}");
      return {"message": e.toString(), "task_id": null};
    }
  }

  static Future<TaskStatus> checkTaskStatus({required taskID}) async {
    String endpoint = '$_baseUrl/attendanceStatus/$taskID/';

    final url = Uri.parse(endpoint);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 || response.statusCode == 202) {
        final jsonBody = jsonDecode(response.body);
        return TaskStatus.fromJson(jsonBody);
      } else {
        throw Exception('Failed to check task status');
      }
    } catch (e) {
      print(e.toString());
      return TaskStatus(status: "error", result: e.toString());
    }
  }

  static Future<List<TeacherSubjects>> getTeacherSubjects({
    required teacherID,
  }) async {
    try {
      final newEndpoint = Uri.parse('$_baseUrl/teacher/subjects/').replace(
        queryParameters: {'teacher_id': teacherID.toString()},
      );
      final newResponse = await http.get(newEndpoint);

      if (newResponse.statusCode == 200) {
        final decoded = jsonDecode(newResponse.body);
        final subjects = decoded is Map<String, dynamic>
            ? _decodeMapList(decoded['subjects'] ?? decoded['results'] ?? decoded)
            : _decodeMapList(decoded);
        if (subjects.isNotEmpty) {
          return subjects.map((json) => TeacherSubjects.fromJson(json)).toList();
        }
      }

      String endpoint = '$_baseUrl/getSubjects/';
      final url = Uri.parse(endpoint);

      const header = {'Content-Type': 'application/json; charset=UTF-8'};
      final body = jsonEncode({'teacher_id': teacherID});
      final response = await http.post(url, headers: header, body: body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final subjects = _decodeMapList(jsonData['subjects']);
        return subjects.map((json) => TeacherSubjects.fromJson(json)).toList();
      }
      return Future.value(List<TeacherSubjects>.empty());
    } catch (e) {
      print(e.toString());
      return Future.value(List<TeacherSubjects>.empty());
    }
  }

  static Future<List<Map<String, dynamic>>> getDivisions({
    required String departmentName,
    int? year,
    int? semester,
  }) async {
    try {
      final endpoint = Uri.parse('$_baseUrl/getSubjectDetails/');
      final response = await http.post(
        endpoint,
        headers: const {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'department': departmentName,
          'year': year,
          'semester': semester,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return _decodeMapList(decoded['divisions'] ?? decoded['results'] ?? decoded['data'] ?? decoded);
        }
        return _decodeMapList(decoded);
      }

      return [];
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  static Future<List<StudentList>> getStudentList({
    required subjectID,
    int? divisionID,
  }) async {
    String endpoint = '$_baseUrl/students/attendance/';
    final url = Uri.parse(endpoint);

    const header = {'Content-Type': 'application/json; charset=UTF-8'};

    final body = jsonEncode({
      'subject_id': subjectID,
      if (divisionID != null) 'division_id': divisionID,
    });

    try {
      final response = await http.post(url, headers: header, body: body);

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);

        final students = jsonBody['attendance'];

        if (students != null) {
          final List<dynamic> students = jsonBody['attendance'];
          return students.map((json) => StudentList.fromJson(json)).toList();
        } else {
          return Future.value(List<StudentList>.empty());
        }
      } else {
        return Future.value(List<StudentList>.empty());
      }
    } catch (e) {
      print(e);
      return Future.value(List<StudentList>.empty());
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentSubjectAttendance({
    required int subjectId,
    int? divisionId,
    int? year,
    int? semester,
  }) async {
    try {
      final queryParameters = <String, String>{};
      if (divisionId != null) {
        queryParameters['division_id'] = divisionId.toString();
      }
      if (year != null) {
        queryParameters['year'] = year.toString();
      }
      if (semester != null) {
        queryParameters['semester'] = semester.toString();
      }

      final endpoint = Uri.parse('$_baseUrl/student/attendance/subject/$subjectId/')
          .replace(queryParameters: queryParameters.isEmpty ? null : queryParameters);
      final response = await http.get(endpoint);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return _decodeMapList(decoded['attendance_records'] ?? decoded['records'] ?? decoded['results'] ?? decoded);
        }
        return _decodeMapList(decoded);
      }

      return [];
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTeacherClassSessions({
    required int teacherID,
    int? limit,
  }) async {
    try {
      final queryParameters = <String, String>{
        'teacher_id': teacherID.toString(),
      };
      if (limit != null) {
        queryParameters['limit'] = limit.toString();
      }

      final endpoint = Uri.parse('$_baseUrl/teacher/class-sessions/')
          .replace(queryParameters: queryParameters);
      final response = await http.get(endpoint);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return _decodeMapList(
            decoded['class_sessions'] ??
                decoded['sessions'] ??
                decoded['results'] ??
                decoded['data'] ??
                decoded,
          );
        }
        return _decodeMapList(decoded);
      }
    } catch (e) {
      print('getTeacherClassSessions GET failed: ${e.toString()}');
    }

    // Backward-compatible fallback for older backend contracts.
    try {
      final endpoint = Uri.parse('$_baseUrl/getTeacherClassSessions/');
      final response = await http.post(
        endpoint,
        headers: const {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'teacher_id': teacherID,
          'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return _decodeMapList(
            decoded['class_sessions'] ??
                decoded['sessions'] ??
                decoded['results'] ??
                decoded['data'] ??
                decoded,
          );
        }
        return _decodeMapList(decoded);
      }
    } catch (e) {
      print('getTeacherClassSessions POST failed: ${e.toString()}');
    }

    return [];
  }

  static Future<List<String>> getSessionPhotos({required int sessionID}) async {
    final endpoint = Uri.parse('$_baseUrl/getSessionPhotos/$sessionID/');
    try {
      final response = await http.get(endpoint);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final List<dynamic> photos = decoded['photos'] ?? [];
          return photos.map<String>((p) => p['detected_url'] as String).toList();
        }
      }
    } catch (e) {
      print('getSessionPhotos failed: ${e.toString()}');
    }
    return [];
  }

  static Future<List<PresentAbsenteesStudents>> getPresentAbsentStudents({
    required sessionID,
    required bool isPresent,
  }) async {
    String endpoint = "$_baseUrl/getPresentAbsentList/";
    final url = Uri.parse(endpoint);

    const header = {'Content-Type': 'application/json; charset=UTF-8'};

    final body = jsonEncode({
      'class_session_id': sessionID,
      'isPresent': isPresent,
    });
    try {
      final response = await http.post(url, headers: header, body: body);

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);

        final students = jsonBody["students"];
        if (students != null) {
          final List<dynamic> students = jsonBody["students"];
          print(response.body);
          return students.map((json)=>PresentAbsenteesStudents.fromJson(json)).toList();
        } else {
          return Future.value(List<PresentAbsenteesStudents>.empty());
        }
      } else {
        print(response.body);
        return Future.value(List<PresentAbsenteesStudents>.empty());
      }
    } catch (e) {
      print(e.toString());
      return Future.value(List<PresentAbsenteesStudents>.empty());
    }
  }

  static Future<List<PresentAbsenteesStudents>> getAbsentStudents({
    required sessionID,
  }) {
    return getPresentAbsentStudents(sessionID: sessionID, isPresent: false);
  }

  static Future<bool> changeAttendance({
    required sessionID,
    required List<int> students,
  }) async {
    String endpoint = "$_baseUrl/changeAttendance/";
    final url = Uri.parse(endpoint);

    const header = {'Content-Type': 'application/json; charset=UTF-8'};

    final body = jsonEncode({
      'class_session_id': sessionID,
      'student_list': students,
    });
    try {
      final response = await http.post(url, headers: header, body: body);

      if (response.statusCode == 200) {
        return Future.value(true);
      } else {
        return Future.value(false);
      }
    } catch (e) {
      print(e.toString());
      return Future.value(false);
    }
  }

  static Future<TeacherProfile> getTeacherProfile({required teacherID}) async {
    String endpoint = '$_baseUrl/teacherProfile/$teacherID/';
    final url = Uri.parse(endpoint);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);

        final profile = jsonBody["teacher_profile"];
        if (profile != null) {
          print(profile);
          return TeacherProfile.fromJson(profile);
        } else {
          return Future.value(
            TeacherProfile(
              name: "teacher",
              email: "null",
              totalSubjects: 0,
              totalStudents: 0,
              department: "null",
              dateJoined: DateTime.now(),
            ),
          );
        }
      } else {
        return Future.value(
          TeacherProfile(
            name: "teacher",
            email: "null",
            totalSubjects: 0,
            totalStudents: 0,
            department: "null",
            dateJoined: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      print(e.toString());
      return Future.value(
        TeacherProfile(
          name: "teacher",
          email: "null",
          totalSubjects: 0,
          totalStudents: 0,
          department: "null",
          dateJoined: DateTime.now(),
        ),
      );
    }
  }

  static Future<Map<String, dynamic>> validateStudent({
    required final int prn,
    required final String password,
  }) async {
    String endpoint = "$_baseUrl/validateStudent/";
    final url = Uri.parse(endpoint);

    const headers = {'Content-Type': 'application/json; charset=UTF-8'};

    final body = jsonEncode({'prn': prn, 'password': password});

    try {
      final response = await http.post(url, headers: headers, body: body);
      String jsonBody = response.body;

      if (response.statusCode == 200) {
        var decoded = jsonDecode(jsonBody);
        String studentName = decoded['student_name'];
        int studentId = decoded['student_id'];
        int studentPrn = decoded['prn'];
        String message = decoded['message'];
        String? accessToken;

        for (final key in const ['access_token', 'accessToken', 'token', 'authToken']) {
          final value = decoded[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            accessToken = value.toString().trim();
            break;
          }
        }

        print("student validated successfully");
        print(message);
        final result = {
          'status': true,
          'studentName': studentName,
          'student_id': studentId,
          'prn': studentPrn,
          'message': message
        };

        if (accessToken != null) {
          result['accessToken'] = accessToken;
        }

        return result;
      } else {
        print("student validation failed");
        // Handle potential missing 'detail' key safely
        var decoded = jsonDecode(jsonBody);
        String detail = decoded is Map && decoded.containsKey('detail') 
            ? decoded['detail'] 
            : 'Validation failed';
        return {'status': false, 'studentName': 'student', 'student_id': 0, 'prn': 0, 'message': detail};
      }
    } catch (e) {
      print(e.toString());
      return {'status': false, 'studentName': 'student', 'student_id': 0, 'prn': 0, 'message': 'exception'};
    }
  }

  static Future<Map<String, dynamic>> updateStudentFace({
    required List<int> photoBytes,
    required String photoFilename,
    String? prn,
    String? accessToken,
  }) async {
    final normalizedToken = accessToken?.trim() ?? '';
    final normalizedPrn = prn?.trim() ?? '';

    if (normalizedToken.isEmpty && normalizedPrn.isEmpty) {
      return {
        'status': false,
        'message': 'prn is required',
      };
    }

    Future<Map<String, dynamic>> sendMultipart(String endpoint) async {
      final url = Uri.parse(endpoint);
      final request = http.MultipartRequest('POST', url);

      if (normalizedToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $normalizedToken';
      } else {
        request.fields['prn'] = normalizedPrn;
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          photoBytes,
          filename: photoFilename,
          contentType: _mediaTypeForImage(photoFilename),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final message = _extractMessageFromBody(response.body);

      if (response.statusCode == 202) {
        try {
          final responseData = json.decode(response.body);
          final taskId = responseData['task_id'];
          if (taskId != null) {
            print("Async face update task initiated: $taskId. Polling...");
            final isSuccess = await _pollTaskStatus(taskId);
            return {
              'statusCode': isSuccess ? 200 : 500,
              'message': isSuccess ? 'Student face updated successfully' : 'Failed to update face',
              'body': response.body,
            };
          }
        } catch (_) {}
      }

      return {
        'statusCode': response.statusCode,
        'message': message,
        'body': response.body,
      };
    }

    try {
      final primary = await sendMultipart("$_baseUrl/updateFace/");
      if (primary['statusCode'] == 200) {
        return {
          'status': true,
          'message': primary['message'] ?? 'Student face updated successfully',
        };
      }

      if (primary['statusCode'] == 404 || primary['statusCode'] == 405) {
        final fallback = await sendMultipart("$_baseUrl/registerStudent/");
        if (fallback['statusCode'] == 200) {
          return {
            'status': true,
            'message': fallback['message'] ?? 'Student face updated successfully',
          };
        }

        return {
          'status': false,
          'message': fallback['message'] ?? 'Failed to update face',
        };
      }

      return {
        'status': false,
        'message': primary['message'] ?? 'Failed to update face',
      };
    } catch (e) {
      print('Error updating student face: $e');
      return {
        'status': false,
        'message': e.toString(),
      };
    }
  }

  /// Fetches the student dashboard data including subjects and attendance
  static Future<Map<String, dynamic>> getStudentDashboard({
    required int studentId,
  }) async {
    String endpoint = "$_baseUrl/student/dashboard/";
    final url = Uri.parse(endpoint);

    const headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final body = jsonEncode({'student_id': studentId});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': true,
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'status': false,
          'message': errorData['detail'] ?? 'Failed to load dashboard',
        };
      }
    } catch (e) {
      print("Error fetching student dashboard: $e");
      return {
        'status': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  static Future<Map<String, String>> verifyPRN({required int prn}) async {
    String endpoint = "$_baseUrl/verifyPRN/";
    final url = Uri.parse(endpoint);

    const headers = {'Content-Type': 'application/json; charset=UTF-8'};

    final body = jsonEncode({'prn': prn});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("PRN verified");
        var decoded = jsonDecode(response.body);
        print(decoded['email']);
        return {
          "status": "verified",
          "email": decoded['email'].toString(),
        };
      } else {
        final jsonBody = jsonDecode(response.body);
        print("PRN not verified");
        return {
          "status": "error",
          "message": jsonBody['detail'] ?? "Unknown error",
        };
      }
    } catch (e) {
      print(e.toString());
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<bool> registerStudent({
    required int prn,
    required String password,
    required List<int> photoBytes,
    required String photoFilename,
  }) async {
    try {
      String endpoint = "$_baseUrl/registerStudent/";
      final url = Uri.parse(endpoint);

      // Send as multipart/form-data
      final request = http.MultipartRequest('POST', url);
      request.fields['prn'] = prn.toString();
      request.fields['password'] = password;

      final multipartFile = http.MultipartFile.fromBytes(
        'photo',
        photoBytes,
        filename: photoFilename,
        contentType: MediaType('image', 'jpeg'), // Adjust if needed
      );
      request.files.add(multipartFile);

      print('Sending image to backend...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print("Password set and student registered successfully");
        return true;
      } else if (response.statusCode == 202) {
        final responseData = json.decode(response.body);
        final taskId = responseData['task_id'];
        if (taskId != null) {
          print("Async registration task initiated: $taskId. Polling...");
          return await _pollTaskStatus(taskId);
        }
        return false;
      } else {
        print("Failed to register student: ${response.statusCode}");
        print(response.body);
        return false;
      }
    } catch (e) {
      print("Error in registerStudent API call: $e");
      return false;
    }
  }

  /// Updates the FCM notification token for a student
  static Future<bool> updateNotificationToken({
    required int studentId,
    required String notificationToken,
  }) async {
    String endpoint = "$_baseUrl/student/notification-token/";
    final url = Uri.parse(endpoint);

    const headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final body = jsonEncode({
      'student_id': studentId,
      'notification_token': notificationToken,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("Notification token updated successfully");
        return true;
      } else {
        print("Failed to update notification token: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error updating notification token: $e");
      return false;
    }
  }

  /// Removes the FCM notification token for a student (on logout)
  static Future<bool> removeNotificationToken({
    required int studentId,
  }) async {
    String endpoint = "$_baseUrl/student/notification-token/remove/";
    final url = Uri.parse(endpoint);

    const headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final body = jsonEncode({'student_id': studentId});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("Notification token removed successfully");
        return true;
      } else {
        print("Failed to remove notification token: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error removing notification token: $e");
      return false;
    }
  }

  /// Fetches the daily schedule from the backend, containing holiday information.
  static Future<Map<String, dynamic>> getDailySchedule({int? studentId, String? date}) async {
    final queryParameters = <String, String>{};
    if (studentId != null) {
      queryParameters['student_id'] = studentId.toString();
    }
    if (date != null) {
      queryParameters['date'] = date;
    }
    final url = Uri.parse("$_baseUrl/schedule/daily/").replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return {
        'is_holiday': false,
        'holiday_name': null,
        'sessions': [],
      };
    } catch (e) {
      print("Error fetching daily schedule: $e");
      return {
        'is_holiday': false,
        'holiday_name': null,
        'sessions': [],
      };
    }
  }

  /// Updates the ui_order of a DailySession.
  static Future<bool> updateSessionOrder({required int sessionId, required int uiOrder}) async {
    final url = Uri.parse("$_baseUrl/schedule/daily/reorder/");
    const headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final body = jsonEncode({
      'session_id': sessionId,
      'ui_order': uiOrder,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("Error updating session order: $e");
      return false;
    }
  }

  /// Fetches the weekly timetable for a student's division.
  static Future<Map<String, dynamic>> getWeeklyTimetable({required int studentId}) async {
    final url = Uri.parse("$_baseUrl/student/timetable/").replace(
      queryParameters: {'student_id': studentId.toString()},
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return {
        'division_name': null,
        'timetable': {},
      };
    } catch (e) {
      print("Error fetching weekly timetable: $e");
      return {
        'division_name': null,
        'timetable': {},
      };
    }
  }

  /// Polls task status until completion or timeout
  static Future<bool> _pollTaskStatus(String taskId) async {
    int attempts = 0;
    const maxAttempts = 15;
    final url = Uri.parse("$_baseUrl/taskStatus/$taskId/");
    
    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 2));
      attempts++;
      
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final status = data['status'];
          if (status == 'SUCCESS') {
            print("Task completed successfully.");
            return true;
          } else if (status == 'FAILURE' || status == 'error') {
            print("Task failed: ${data['error']}");
            return false;
          }
        } else if (response.statusCode == 500) {
          final data = jsonDecode(response.body);
          print("Task failed with 500: ${data['error']}");
          return false;
        }
      } catch (e) {
        print("Error polling task status: $e");
      }
    }
    print("Task status polling timed out.");
    return false;
  }

  /// Updates the FCM notification token for a teacher
  static Future<bool> updateTeacherNotificationToken({
    required int teacherId,
    required String notificationToken,
  }) async {
    String endpoint = "$_baseUrl/teacher/notification-token/";
    final url = Uri.parse(endpoint);

    const headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final body = jsonEncode({
      'teacher_id': teacherId,
      'notification_token': notificationToken,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("Teacher notification token updated successfully");
        return true;
      } else {
        print("Failed to update teacher notification token: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error updating teacher notification token: $e");
      return false;
    }
  }

  /// Removes the FCM notification token for a teacher (on logout)
  static Future<bool> removeTeacherNotificationToken({
    required int teacherId,
  }) async {
    String endpoint = "$_baseUrl/teacher/notification-token/remove/";
    final url = Uri.parse(endpoint);

    const headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final body = jsonEncode({'teacher_id': teacherId});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        print("Teacher notification token removed successfully");
        return true;
      } else {
        print("Failed to remove teacher notification token: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error removing teacher notification token: $e");
      return false;
    }
  }
}
