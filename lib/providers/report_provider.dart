// providers/report_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/report_model.dart';

class ReportNotifier extends StateNotifier<AsyncValue<List<ReportModel>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ReportNotifier() : super(const AsyncValue.loading()) {
    _loadReports();
  }

  // Load reports dari Firestore (Real-time)
  void _loadReports() {
    _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final reports = snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
      state = AsyncValue.data(reports);
    }, onError: (error) {
      state = AsyncValue.error(error, StackTrace.current);
    });
  }

  // ========================================
  // FUNGSI BARU: Simpan foto ke storage lokal HP
  // ========================================
  Future<String> _savePhotoLocally(File imageFile, String folder) async {
    try {
      // Dapatkan direktori penyimpanan aplikasi
      final appDir = await getApplicationDocumentsDirectory();

      // Buat folder khusus untuk foto (misal: 'reports' atau 'completions')
      final photoDir = Directory('${appDir.path}/$folder');

      // Buat folder jika belum ada
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }

      // Buat nama file unik (timestamp + ekstensi asli)
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // Path lengkap file baru
      final newPath = '${photoDir.path}/$fileName';

      // Copy file ke lokasi baru
      final savedFile = await imageFile.copy(newPath);

      // Return path file yang sudah disimpan
      return savedFile.path;

    } catch (e) {
      throw Exception('Gagal menyimpan foto: $e');
    }
  }

  // ========================================
  // Tambah laporan baru
  // ========================================
  Future<void> addReport(ReportModel report, File imageFile) async {
    try {
      // Simpan foto ke storage lokal (folder 'reports')
      final localPhotoPath = await _savePhotoLocally(imageFile, 'reports');

      // Update report dengan path lokal foto
      final newReport = report.copyWith(photoUrl: localPhotoPath);

      // Simpan data ke Firestore (hanya path lokal, bukan file foto)
      await _firestore.collection('reports').add(newReport.toMap());

    } catch (e) {
      throw Exception('Gagal menambah laporan: $e');
    }
  }

  // ========================================
  // Update status menjadi selesai
  // ========================================
  Future<void> markAsCompleted(
      String reportId,
      String completionDescription,
      File? completionImage,
      ) async {
    try {
      String? completionPhotoPath;

      // Simpan foto hasil jika ada
      if (completionImage != null) {
        completionPhotoPath = await _savePhotoLocally(completionImage, 'completions');
      }

      // Update dokumen di Firestore
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'selesai',
        'completionDescription': completionDescription,
        'completionPhotoUrl': completionPhotoPath,
      });

    } catch (e) {
      throw Exception('Gagal menandai selesai: $e');
    }
  }

  // ========================================
  // Hapus laporan
  // ========================================
  Future<void> deleteReport(String reportId) async {
    try {
      // Ambil dokumen untuk mendapatkan path foto lokal
      final doc = await _firestore.collection('reports').doc(reportId).get();

      if (doc.exists) {
        final data = doc.data();

        // Hapus foto utama dari storage lokal jika ada
        if (data != null && data['photoUrl'] != null) {
          try {
            final photoFile = File(data['photoUrl']);
            if (await photoFile.exists()) {
              await photoFile.delete();
            }
          } catch (e) {
            // Abaikan error jika file tidak ditemukan
            print('Info: Foto utama tidak ditemukan atau sudah terhapus');
          }
        }

        // Hapus foto completion dari storage lokal jika ada
        if (data != null && data['completionPhotoUrl'] != null) {
          try {
            final completionFile = File(data['completionPhotoUrl']);
            if (await completionFile.exists()) {
              await completionFile.delete();
            }
          } catch (e) {
            // Abaikan error
            print('Info: Foto completion tidak ditemukan atau sudah terhapus');
          }
        }
      }

      // Hapus dokumen dari Firestore
      await _firestore.collection('reports').doc(reportId).delete();

    } catch (e) {
      throw Exception('Gagal menghapus laporan: $e');
    }
  }
}

// Provider untuk Report
final reportProvider = StateNotifierProvider<ReportNotifier, AsyncValue<List<ReportModel>>>((ref) {
  return ReportNotifier();
});