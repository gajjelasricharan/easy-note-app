// lib/widgets/note_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../utils/app_theme.dart';
import '../providers/providers.dart';
import '../screens/note_editor_screen.dart';

class NoteCard extends ConsumerWidget {
  final NoteModel note;
  final int index;

  const NoteCard({
    super.key,
    required this.note,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = ref.watch(darkModeProvider);
    final bgColor = isDark
        ? AppTheme.darkCard
        : AppTheme.noteColors[note.colorIndex % AppTheme.noteColors.length];

    return GestureDetector(
      onTap: () => _openNote(context),
      onLongPress: () => _showOptions(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: note.isPinned
              ? Border.all(
                  color: AppTheme.mediumGray.withOpacity(0.4),
                  width: 1.5,
                )
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pin indicator
            if (note.isPinned) ...[
              Row(
                children: [
                  const Spacer(),
                  Icon(
                    Icons.push_pin_rounded,
                    size: 14,
                    color: AppTheme.mediumGray.withOpacity(0.7),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            // Title
            Text(
              note.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.fraunces(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.softTan : AppTheme.ink,
                height: 1.3,
              ),
            ),
            // Content preview
            if (note.contentPlainText != null &&
                note.contentPlainText!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note.contentPlainText!,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.warmGray
                      : AppTheme.ink.withOpacity(0.65),
                  height: 1.5,
                ),
              ),
            ],
            // Attachments row
            if (note.audioAttachments.isNotEmpty ||
                note.mediaAttachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildAttachmentChips(),
            ],
            // Tags
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: note.tags
                    .take(3)
                    .map((tag) => _buildTag(tag, isDark))
                    .toList(),
              ),
            ],
            // AI Summary badge
            if (note.aiSummary != null) ...[
              const SizedBox(height: 8),
              _buildAIBadge(isDark),
            ],
            // Shared indicator + date
            const SizedBox(height: 10),
            _buildFooter(isDark, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentChips() {
    return Row(
      children: [
        if (note.audioAttachments.isNotEmpty) ...[
          _buildChip(
            Icons.mic_rounded,
            '${note.audioAttachments.length}',
          ),
          const SizedBox(width: 4),
        ],
        if (note.mediaAttachments.isNotEmpty) ...[
          _buildChip(
            Icons.attach_file_rounded,
            '${note.mediaAttachments.length}',
          ),
        ],
      ],
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.warmGray.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.mediumGray),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppTheme.mediumGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.warmGray.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#$tag',
        style: GoogleFonts.dmSans(
          fontSize: 10,
          color: AppTheme.mediumGray,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAIBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90A4).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 10, color: Color(0xFF4A90A4)),
          const SizedBox(width: 3),
          Text(
            'AI summary',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: const Color(0xFF4A90A4),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark, ThemeData theme) {
    return Row(
      children: [
        if (note.sharedWith.isNotEmpty) ...[
          Icon(
            Icons.people_outline_rounded,
            size: 12,
            color: AppTheme.warmGray,
          ),
          const SizedBox(width: 3),
        ],
        const Spacer(),
        Text(
          _formatDate(note.updatedAt),
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppTheme.warmGray,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  void _openNote(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => NoteEditorScreen(noteId: note.id),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    final notesService = ref.read(notesServiceProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.softTan,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(note.isPinned ? 'Unpin note' : 'Pin note'),
              onTap: () {
                Navigator.pop(ctx);
                notesService.togglePin(note.id, note.isPinned);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(ctx);
                notesService.setArchived(note.id, true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(notesServiceProvider).deleteNote(note.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
