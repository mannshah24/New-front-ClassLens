import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:classlens/global/config.dart';

class AttendanceExportService {
  final Dio _dio = Dio();

  Future<void> downloadReport(int subjectId) async {
    Directory? dir = await getExternalStorageDirectory();
    dir ??= await getApplicationDocumentsDirectory(); // Fail-safe
    String path = "${dir.path}/Attendance_Subject_$subjectId.xlsx";

    String url = "${AppConfig.baseUrl}/subjects/$subjectId/export/";

    Response res = await _dio.download(
      url,
      path,
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );

    if (res.statusCode == 200) {
      await OpenFilex.open(path); // Auto-open file sheet using native Android Intent
    } else {
      throw Exception("Download failed");
    }
  }
}
