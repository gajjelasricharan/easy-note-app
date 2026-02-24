// lib/widgets/ai_actions_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/note_model.dart';
import '../providers/providers.dart';
import '../utils/app_theme.dart';

class AIActionsSheet extends ConsumerStatefulWidget {
  final NoteModel note;

  const AIActionsSheet({super.key, required this.note});

  @override
  ConsumerState<AIActionsSheet> createState() => _AIActionsSheetState();
}

class _AIActionsSheetState extends ConsumerState<AIActionsSheet> {
  bool _isSummarizing = false;
  bool _isTagging = false;
  bool _isConverting = false;
  bool _isDetecting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandle(),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90A4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 20, color: Color(0xFF4A90A4)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Actions', style: theme.textTheme.headlineSmall),
                    Text('Powered by OpenAI', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (widget.note.aiSummary != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90A4).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Summary', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4A90A4))),
                    const SizedBox(height: 6),
                    Text(widget.note.aiSummary!, style: GoogleFonts.dmSans(fontSize: 13, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildActionTile(
              icon: Icons.summarize_outlined,
              title: 'Summarize note',
              subtitle: 'Generate an AI summary',
              isLoading: _isSummarizing,
              onTap: _summarize,
            ),
            _buildActionTile(
              icon: Icons.label_outline_rounded,
              title: 'Smart tagging',
              subtitle: 'Auto-generate relevant tags',
              isLoading: _isTagging,
              onTap: _generateTags,
            ),
            _buildActionTile(
              icon: Icons.checklist_rounded,
              title: 'Convert to checklist',
              subtitle: 'Turn content into actionable items',
              isLoading: _isConverting,
              onTap: _convertToChecklist,
            ),
            _buildActionTile(
              icon: Icons.search_outlined,
              title: 'Detect content type',
              subtitle: 'Shopping list, medicine, reminder...',
              isLoading: _isDetecting,
              onTap: _detectType,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() => Center(
    child: Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.softTan,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.softTan.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 20, color: AppTheme.darkGray),
      ),
      title: Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.warmGray)),
      onTap: isLoading ? null : onTap,
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.warmGray),
    );
  }

  Future<void> _summarize() async {
    final content = widget.note.contentPlainText ?? '';
    if (content.trim().isEmpty) {
      _showSnack('Note has no content to summarize');
      return;
    }

    setState(() => _isSummarizing = true);
    try {
      final user = ref.read(currentUserProvider);
      final idToken = await user?.getIdToken();
      if (idToken == null) return;

      final aiService = ref.read(aiServiceProvider);
      final summary = await aiService.summarizeNote(content, idToken);

      if (summary != null) {
        await ref.read(notesServiceProvider).updateAISummary(widget.note.id, summary);
        _showSnack('Summary generated!');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Failed to summarize: $e');
    } finally {
      if (mounted) setState(() => _isSummarizing = false);
    }
  }

  Future<void> _generateTags() async {
    final content = widget.note.contentPlainText ?? '';
    if (content.trim().isEmpty) {
      _showSnack('Note has no content');
      return;
    }

    setState(() => _isTagging = true);
    try {
      final user = ref.read(currentUserProvider);
      final idToken = await user?.getIdToken();
      if (idToken == null) return;

      final aiService = ref.read(aiServiceProvider);
      final tags = await aiService.generateTags(content, idToken);

      if (tags.isNotEmpty) {
        await ref.read(notesServiceProvider).updateTags(widget.note.id, tags);
        _showSnack('Tags added: ${tags.join(', ')}');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Failed to generate tags');
    } finally {
      if (mounted) setState(() => _isTagging = false);
    }
  }

  Future<void> _convertToChecklist() async {
    _showSnack('Checklist conversion — coming soon!');
  }

  Future<void> _detectType() async {
    final content = widget.note.contentPlainText ?? '';
    if (content.trim().isEmpty) {
      _showSnack('Note has no content');
      return;
    }

    setState(() => _isDetecting = true);
    try {
      final user = ref.read(currentUserProvider);
      final idToken = await user?.getIdToken();
      if (idToken == null) return;

      final aiService = ref.read(aiServiceProvider);
      final type = await aiService.detectContentType(content, idToken);

      if (type != null) {
        _showSnack('Detected: ${type.toUpperCase()}');
      }
    } catch (e) {
      _showSnack('Detection failed');
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
