// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Upload audio recording
  Future<String> uploadAudio(
    String uid,
    String noteId,
    File file,
    String audioId, {
    void Function(double)? onProgress,
  }) async {
    final ext = p.extension(file.path);
    final ref = _storage.ref('users/$uid/notes/$noteId/audio/$audioId$ext');

    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'audio/m4a'),
    );

    task.snapshotEvents.listen((snap) {
      if (snap.totalBytes > 0) {
        onProgress?.call(snap.bytesTransferred / snap.totalBytes);
      }
    });

    await task;
    return await ref.getDownloadURL();
  }

  /// Upload image with compression
  Future<String> uploadImage(
    String uid,
    String noteId,
    File file,
    String mediaId, {
    void Function(double)? onProgress,
  }) async {
    // Compress image
    final compressed = await FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: 1200,
      minHeight: 1200,
      quality: 80,
    );

    final compressedFile = File('${file.parent.path}/${mediaId}_compressed.jpg');
    if (compressed != null) {
      await compressedFile.writeAsBytes(compressed);
    }

    final fileToUpload = compressed != null ? compressedFile : file;
    final ref = _storage.ref('users/$uid/notes/$noteId/images/$mediaId.jpg');

    final task = ref.putFile(
      fileToUpload,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    task.snapshotEvents.listen((snap) {
      if (snap.totalBytes > 0) {
        onProgress?.call(snap.bytesTransferred / snap.totalBytes);
      }
    });

    await task;

    // Clean up temp file
    if (compressed != null && compressedFile.existsSync()) {
      await compressedFile.delete();
    }

    return await ref.getDownloadURL();
  }

  /// Upload video
  Future<String> uploadVideo(
    String uid,
    String noteId,
    File file,
    String mediaId, {
    void Function(double)? onProgress,
  }) async {
    final ext = p.extension(file.path);
    final ref = _storage.ref('users/$uid/notes/$noteId/videos/$mediaId$ext');

    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'video/mp4'),
    );

    task.snapshotEvents.listen((snap) {
      if (snap.totalBytes > 0) {
        onProgress?.call(snap.bytesTransferred / snap.totalBytes);
      }
    });

    await task;
    return await ref.getDownloadURL();
  }

  /// Upload PDF
  Future<String> uploadPdf(
    String uid,
    String noteId,
    File file,
    String mediaId, {
    void Function(double)? onProgress,
  }) async {
    final ref = _storage.ref('users/$uid/notes/$noteId/pdfs/$mediaId.pdf');

    final task = ref.putFile(
      file,
      SettableMetadata(contentType: 'application/pdf'),
    );

    task.snapshotEvents.listen((snap) {
      if (snap.totalBytes > 0) {
        onProgress?.call(snap.bytesTransferred / snap.totalBytes);
      }
    });

    await task;
    return await ref.getDownloadURL();
  }

  /// Delete file by storage URL
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // File may not exist, ignore
    }
  }
}
