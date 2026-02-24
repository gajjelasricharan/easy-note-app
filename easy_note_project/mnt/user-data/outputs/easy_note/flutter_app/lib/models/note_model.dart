// lib/models/note_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotePermission { owner, editor, viewer }

class SharedUser {
  final String uid;
  final String email;
  final String? displayName;
  final NotePermission permission;

  SharedUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.permission,
  });

  factory SharedUser.fromMap(Map<String, dynamic> map) {
    return SharedUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      permission: NotePermission.values.firstWhere(
        (e) => e.name == (map['permission'] ?? 'viewer'),
        orElse: () => NotePermission.viewer,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'permission': permission.name,
  };
}

class AudioAttachment {
  final String id;
  final String storageUrl;
  final String? localPath;
  final int durationMs;
  final String? transcript;
  final DateTime createdAt;

  AudioAttachment({
    required this.id,
    required this.storageUrl,
    this.localPath,
    required this.durationMs,
    this.transcript,
    required this.createdAt,
  });

  factory AudioAttachment.fromMap(Map<String, dynamic> map) {
    return AudioAttachment(
      id: map['id'] ?? '',
      storageUrl: map['storageUrl'] ?? '',
      localPath: map['localPath'],
      durationMs: map['durationMs'] ?? 0,
      transcript: map['transcript'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'storageUrl': storageUrl,
    'durationMs': durationMs,
    'transcript': transcript,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class MediaAttachment {
  final String id;
  final String storageUrl;
  final String? localPath;
  final String type; // image, video, pdf
  final String fileName;
  final int? fileSize;
  final DateTime createdAt;

  MediaAttachment({
    required this.id,
    required this.storageUrl,
    this.localPath,
    required this.type,
    required this.fileName,
    this.fileSize,
    required this.createdAt,
  });

  factory MediaAttachment.fromMap(Map<String, dynamic> map) {
    return MediaAttachment(
      id: map['id'] ?? '',
      storageUrl: map['storageUrl'] ?? '',
      localPath: map['localPath'],
      type: map['type'] ?? 'image',
      fileName: map['fileName'] ?? '',
      fileSize: map['fileSize'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'storageUrl': storageUrl,
    'type': type,
    'fileName': fileName,
    'fileSize': fileSize,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class NoteModel {
  final String id;
  final String ownerId;
  final String title;
  final String? contentPlainText; // for preview
  final Map<String, dynamic>? contentDelta; // Quill delta
  final int colorIndex;
  final bool isPinned;
  final bool isArchived;
  final List<String> tags;
  final List<AudioAttachment> audioAttachments;
  final List<MediaAttachment> mediaAttachments;
  final List<SharedUser> sharedWith;
  final String? aiSummary;
  final String? inviteToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.ownerId,
    required this.title,
    this.contentPlainText,
    this.contentDelta,
    this.colorIndex = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.tags = const [],
    this.audioAttachments = const [],
    this.mediaAttachments = const [],
    this.sharedWith = const [],
    this.aiSummary,
    this.inviteToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? 'Untitled',
      contentPlainText: data['contentPlainText'],
      contentDelta: data['contentDelta'],
      colorIndex: data['colorIndex'] ?? 0,
      isPinned: data['isPinned'] ?? false,
      isArchived: data['isArchived'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      audioAttachments: (data['audioAttachments'] as List? ?? [])
          .map((a) => AudioAttachment.fromMap(a))
          .toList(),
      mediaAttachments: (data['mediaAttachments'] as List? ?? [])
          .map((m) => MediaAttachment.fromMap(m))
          .toList(),
      sharedWith: (data['sharedWith'] as List? ?? [])
          .map((s) => SharedUser.fromMap(s))
          .toList(),
      aiSummary: data['aiSummary'],
      inviteToken: data['inviteToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'ownerId': ownerId,
    'title': title,
    'contentPlainText': contentPlainText,
    'contentDelta': contentDelta,
    'colorIndex': colorIndex,
    'isPinned': isPinned,
    'isArchived': isArchived,
    'tags': tags,
    'audioAttachments': audioAttachments.map((a) => a.toMap()).toList(),
    'mediaAttachments': mediaAttachments.map((m) => m.toMap()).toList(),
    'sharedWith': sharedWith.map((s) => s.toMap()).toList(),
    'sharedWithUids': sharedWith.map((s) => s.uid).toList(),
    'aiSummary': aiSummary,
    'inviteToken': inviteToken,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  NoteModel copyWith({
    String? title,
    String? contentPlainText,
    Map<String, dynamic>? contentDelta,
    int? colorIndex,
    bool? isPinned,
    bool? isArchived,
    List<String>? tags,
    List<AudioAttachment>? audioAttachments,
    List<MediaAttachment>? mediaAttachments,
    List<SharedUser>? sharedWith,
    String? aiSummary,
    String? inviteToken,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      contentPlainText: contentPlainText ?? this.contentPlainText,
      contentDelta: contentDelta ?? this.contentDelta,
      colorIndex: colorIndex ?? this.colorIndex,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      audioAttachments: audioAttachments ?? this.audioAttachments,
      mediaAttachments: mediaAttachments ?? this.mediaAttachments,
      sharedWith: sharedWith ?? this.sharedWith,
      aiSummary: aiSummary ?? this.aiSummary,
      inviteToken: inviteToken ?? this.inviteToken,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
