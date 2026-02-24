// lib/services/notes_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';

class NotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference get _notes => _firestore.collection('notes');

  /// Stream all notes for a user (owned + shared)
  Stream<List<NoteModel>> watchUserNotes(String uid) {
    return _firestore
        .collection('notes')
        .where(Filter.or(
          Filter('ownerId', isEqualTo: uid),
          Filter('sharedWithUids', arrayContains: uid),
        ))
        .where('isArchived', isEqualTo: false)
        .orderBy('isPinned', descending: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => NoteModel.fromFirestore(d)).toList());
  }

  /// Stream archived notes
  Stream<List<NoteModel>> watchArchivedNotes(String uid) {
    return _firestore
        .collection('notes')
        .where('ownerId', isEqualTo: uid)
        .where('isArchived', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => NoteModel.fromFirestore(d)).toList());
  }

  /// Watch single note
  Stream<NoteModel?> watchNote(String noteId) {
    return _notes.doc(noteId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return NoteModel.fromFirestore(doc);
    });
  }

  /// Create a new note
  Future<NoteModel> createNote(String ownerId, {String title = 'New Note', int colorIndex = 0}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final note = NoteModel(
      id: id,
      ownerId: ownerId,
      title: title,
      colorIndex: colorIndex,
      createdAt: now,
      updatedAt: now,
    );
    await _notes.doc(id).set(note.toFirestore());
    return note;
  }

  /// Update note fields
  Future<void> updateNote(String noteId, Map<String, dynamic> fields) async {
    await _notes.doc(noteId).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete note
  Future<void> deleteNote(String noteId) async {
    await _notes.doc(noteId).delete();
  }

  /// Toggle pin
  Future<void> togglePin(String noteId, bool isPinned) async {
    await updateNote(noteId, {'isPinned': !isPinned});
  }

  /// Archive / unarchive
  Future<void> setArchived(String noteId, bool archived) async {
    await updateNote(noteId, {'isArchived': archived});
  }

  /// Add audio attachment
  Future<void> addAudioAttachment(String noteId, AudioAttachment audio) async {
    await _notes.doc(noteId).update({
      'audioAttachments': FieldValue.arrayUnion([audio.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove audio attachment
  Future<void> removeAudioAttachment(String noteId, String audioId) async {
    final doc = await _notes.doc(noteId).get();
    final note = NoteModel.fromFirestore(doc);
    final updated = note.audioAttachments.where((a) => a.id != audioId).toList();
    await updateNote(noteId, {
      'audioAttachments': updated.map((a) => a.toMap()).toList(),
    });
  }

  /// Add media attachment
  Future<void> addMediaAttachment(String noteId, MediaAttachment media) async {
    await _notes.doc(noteId).update({
      'mediaAttachments': FieldValue.arrayUnion([media.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove media attachment
  Future<void> removeMediaAttachment(String noteId, String mediaId) async {
    final doc = await _notes.doc(noteId).get();
    final note = NoteModel.fromFirestore(doc);
    final updated = note.mediaAttachments.where((m) => m.id != mediaId).toList();
    await updateNote(noteId, {
      'mediaAttachments': updated.map((m) => m.toMap()).toList(),
    });
  }

  /// Update sharing
  Future<void> updateSharing(String noteId, List<SharedUser> sharedWith) async {
    await _notes.doc(noteId).update({
      'sharedWith': sharedWith.map((s) => s.toMap()).toList(),
      'sharedWithUids': sharedWith.map((s) => s.uid).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Generate invite token
  Future<String> generateInviteToken(String noteId) async {
    final token = _uuid.v4();
    await _notes.doc(noteId).update({'inviteToken': token});
    return token;
  }

  /// Find note by invite token
  Future<NoteModel?> getNoteByInviteToken(String token) async {
    final snap = await _firestore
        .collection('notes')
        .where('inviteToken', isEqualTo: token)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return NoteModel.fromFirestore(snap.docs.first);
  }

  /// Accept invite — add user to sharedWith
  Future<void> acceptInvite(
    String noteId,
    SharedUser user,
  ) async {
    final doc = await _notes.doc(noteId).get();
    final note = NoteModel.fromFirestore(doc);

    // Check if already shared
    final exists = note.sharedWith.any((s) => s.uid == user.uid);
    if (exists) return;

    final updated = [...note.sharedWith, user];
    await updateSharing(noteId, updated);
  }

  /// Update AI summary
  Future<void> updateAISummary(String noteId, String summary) async {
    await updateNote(noteId, {'aiSummary': summary});
  }

  /// Update tags
  Future<void> updateTags(String noteId, List<String> tags) async {
    await updateNote(noteId, {'tags': tags});
  }

  /// Search notes (client-side for now — can be upgraded to Algolia)
  Future<List<NoteModel>> searchNotes(String uid, String query) async {
    final snap = await _firestore
        .collection('notes')
        .where(Filter.or(
          Filter('ownerId', isEqualTo: uid),
          Filter('sharedWithUids', arrayContains: uid),
        ))
        .where('isArchived', isEqualTo: false)
        .get();

    final lowerQuery = query.toLowerCase();
    return snap.docs
        .map((d) => NoteModel.fromFirestore(d))
        .where((note) =>
            note.title.toLowerCase().contains(lowerQuery) ||
            (note.contentPlainText?.toLowerCase().contains(lowerQuery) ?? false) ||
            note.tags.any((t) => t.toLowerCase().contains(lowerQuery)))
        .toList();
  }
}
