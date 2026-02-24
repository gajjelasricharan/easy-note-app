// lib/screens/archive_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/providers.dart';
import '../widgets/note_card.dart';
import '../utils/app_theme.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final archivedAsync = ref.watch(archivedNotesProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive'),
        leading: const BackButton(),
      ),
      body: archivedAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.archive_outlined, size: 48, color: AppTheme.warmGray),
                  const SizedBox(height: 12),
                  Text('No archived notes', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: notes.length,
              itemBuilder: (_, i) => NoteCard(note: notes[i], index: i),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
