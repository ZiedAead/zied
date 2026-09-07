import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/database/database_helper.dart';
import '../models/backup_data_model.dart';

class BackupService {
  /// تصدير النسخة الاحتياطية كملف JSON ومشاركتها عبر نظام iOS / Android
  static Future<bool> exportAndShareBackup(double exchangeRate) async {
    try {
      final backupData = await DatabaseHelper.instance.exportBackupData(exchangeRate);
      final jsonString = backupData.toJson();

      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'zied_debts_backup_$dateStr.json';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsString(jsonString);

      // مشاركة الملف عبر نافذة المشاركة الرسمية (AirDrop, WhatsApp, Files, Drive)
      final xFile = XFile(file.path, mimeType: 'application/json', name: fileName);
      final shareResult = await Share.shareXFiles(
        [xFile],
        subject: 'نسخة احتياطية لتطبيق زيد اياد للديون',
        text: 'ملف النسخة الاحتياطية لتطبيق زيد اياد للديون بتاريخ $dateStr',
      );

      return shareResult.status == ShareResultStatus.success ||
          shareResult.status == ShareResultStatus.dismissed;
    } catch (e) {
      return false;
    }
  }

  /// اختيار ملف نسخة احتياطية من الجهاز واسترجاعه
  static Future<BackupData?> pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final jsonContent = await file.readAsString();

        // تحويل JSON إلى كائن BackupData والتحقق من صحته
        final backupData = BackupData.fromJson(jsonContent);
        return backupData;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
