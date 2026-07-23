import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class BackupService {
  static const _backupFileName = 'budget_buddy_backup.json';

  static Future<bool> performBackup(http.Client authClient) async {
    try {
      final driveApi = drive.DriveApi(authClient);
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final Map<String, dynamic> allData = {};
      
      for (String key in keys) {
        allData[key] = prefs.get(key);
      }
      
      final jsonString = jsonEncode(allData);
      final List<int> content = utf8.encode(jsonString);
      final media = drive.Media(Stream.value(content), content.length);

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: "files(id, name)",
      );

      final files = fileList.files;
      if (files != null && files.isNotEmpty) {
        final existingFileId = files.first.id!;
        await driveApi.files.update(
          drive.File(),
          existingFileId,
          uploadMedia: media,
        );
        debugPrint('Backup updated successfully.');
      } else {
        final file = drive.File()
          ..name = _backupFileName
          ..parents = ['appDataFolder'];
        
        await driveApi.files.create(
          file,
          uploadMedia: media,
        );
        debugPrint('Backup created successfully.');
      }
      
      await prefs.setString('last_backup_time', DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      debugPrint('Backup failed: $e');
      return false;
    }
  }

  static Future<String?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_backup_time');
  }

  static Future<bool> restoreBackup(http.Client authClient, Function onRestoreSuccess) async {
    try {
      final driveApi = drive.DriveApi(authClient);
      
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: "files(id, name)",
      );

      final files = fileList.files;
      if (files == null || files.isEmpty) {
        debugPrint('No backup found.');
        return false;
      }

      final backupFileId = files.first.id!;
      
      final drive.Media media = await driveApi.files.get(backupFileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      
      final List<int> dataStore = [];
      await for (var data in media.stream) {
        dataStore.addAll(data);
      }
      
      final jsonString = utf8.decode(dataStore);
      final Map<String, dynamic> allData = jsonDecode(jsonString);
      
      final prefs = await SharedPreferences.getInstance();
      for (var entry in allData.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value is String) await prefs.setString(key, value);
        else if (value is int) await prefs.setInt(key, value);
        else if (value is double) await prefs.setDouble(key, value);
        else if (value is bool) await prefs.setBool(key, value);
        else if (value is List) await prefs.setStringList(key, List<String>.from(value));
      }
      
      onRestoreSuccess();
      return true;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }
}
