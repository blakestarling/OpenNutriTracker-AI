import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';

class ExportDataUsecase {
  final UserActivityRepository _userActivityRepository;
  final IntakeRepository _intakeRepository;
  final TrackedDayRepository _trackedDayRepository;

  ExportDataUsecase(this._userActivityRepository, this._intakeRepository,
      this._trackedDayRepository);

  /// Exports user activity, intake, and tracked day data to a zip of json
  /// files at a user specified location.
  Future<bool> exportData(
      String exportZipFileName,
      String userActivityJsonFileName,
      String userIntakeJsonFileName,
      String trackedDayJsonFileName) async {
    final archive = Archive();

    // Export user activity data to Json File Bytes
    final fullUserActivity =
        await _userActivityRepository.getAllUserActivityDBO();
    final fullUserActivityJson = jsonEncode(
        fullUserActivity.map((activity) => activity.toJson()).toList());
    final userActivityJsonBytes = utf8.encode(fullUserActivityJson);
    archive.addFile(
      ArchiveFile(userActivityJsonFileName, userActivityJsonBytes.length,
          userActivityJsonBytes),
    );

    // Export intake data to Json File Bytes and handle images
    final fullIntake = await _intakeRepository.getAllIntakesDBO();
    final List<Map<String, dynamic>> processedIntakes = [];

    for (var intake in fullIntake) {
      var intakeJson = intake.toJson();
      var mealJson = intakeJson['meal'] as Map<String, dynamic>;

      Future<void> processImage(String key) async {
        if (mealJson[key] != null) {
          String path = mealJson[key];
          if (!path.startsWith('http') && !path.startsWith('https')) {
            try {
              final file = File(path);
              if (await file.exists()) {
                final filename = path.split(Platform.pathSeparator).last;
                // Ensure unique filename if needed, or assume timestamps make them unique enough
                final archivePath = 'images/$filename';
                final bytes = await file.readAsBytes();

                // Only add if not already present to save space/time
                if (archive.findFile(archivePath) == null) {
                  archive
                      .addFile(ArchiveFile(archivePath, bytes.length, bytes));
                }

                mealJson[key] = archivePath;
              }
            } catch (e) {
              // Ignore error, keep original path
            }
          }
        }
      }

      await processImage('mainImageUrl');
      await processImage('thumbnailImageUrl');

      intakeJson['meal'] = mealJson;
      processedIntakes.add(intakeJson);
    }

    final fullIntakeJson = jsonEncode(processedIntakes);
    final intakeJsonBytes = utf8.encode(fullIntakeJson);
    archive.addFile(
      ArchiveFile(
          userIntakeJsonFileName, intakeJsonBytes.length, intakeJsonBytes),
    );

    // Export tracked day data to Json File Bytes
    final fullTrackedDay = await _trackedDayRepository.getAllTrackedDaysDBO();
    final fullTrackedDayJson = jsonEncode(
        fullTrackedDay.map((trackedDay) => trackedDay.toJson()).toList());
    final trackedDayJsonBytes = utf8.encode(fullTrackedDayJson);
    archive.addFile(
      ArchiveFile(trackedDayJsonFileName, trackedDayJsonBytes.length,
          trackedDayJsonBytes),
    );

    // Save the zip file to the user specified location
    final zipBytes = ZipEncoder().encode(archive);
    final result = await FilePicker.platform.saveFile(
      fileName: exportZipFileName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: Uint8List.fromList(zipBytes),
    );

    return result != null && result.isNotEmpty;
  }
}
