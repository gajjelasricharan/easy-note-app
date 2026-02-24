// lib/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/notes_service.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/ai_service.dart';
import '../models/note_model.dart';

// Services
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final notesServiceProvider = Provider<NotesService>((ref) => NotesService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
final aiServiceProvider = Provider<AIService>((ref) => AIService());

// Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

// Current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// Notes stream
final notesStreamProvider = StreamProvider.family<List<NoteModel>, String>((ref, uid) {
  return ref.read(notesServiceProvider).watchUserNotes(uid);
});

// Single note stream
final noteStreamProvider = StreamProvider.family<NoteModel?, String>((ref, noteId) {
  return ref.read(notesServiceProvider).watchNote(noteId);
});

// Archived notes
final archivedNotesProvider = StreamProvider.family<List<NoteModel>, String>((ref, uid) {
  return ref.read(notesServiceProvider).watchArchivedNotes(uid);
});

// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search results
final searchResultsProvider = FutureProvider.family<List<NoteModel>, String>((ref, uid) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  return ref.read(notesServiceProvider).searchNotes(uid, query);
});

// Dark mode
final darkModeProvider = StateProvider<bool>((ref) => false);

// Current note for editing
final currentNoteIdProvider = StateProvider<String?>((ref) => null);

// Recording state for a note
final recordingStateProvider = StateProvider<bool>((ref) => false);

// Note color filter
final colorFilterProvider = StateProvider<int?>((ref) => null);

// Tag filter
final tagFilterProvider = StateProvider<String?>((ref) => null);

// Filtered notes
final filteredNotesProvider = Provider.family<AsyncValue<List<NoteModel>>, String>((ref, uid) {
  final notesAsync = ref.watch(notesStreamProvider(uid));
  final colorFilter = ref.watch(colorFilterProvider);
  final tagFilter = ref.watch(tagFilterProvider);

  return notesAsync.when(
    data: (notes) {
      var filtered = notes;
      if (colorFilter != null) {
        filtered = filtered.where((n) => n.colorIndex == colorFilter).toList();
      }
      if (tagFilter != null) {
        filtered = filtered.where((n) => n.tags.contains(tagFilter)).toList();
      }
      return AsyncData(filtered);
    },
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});
