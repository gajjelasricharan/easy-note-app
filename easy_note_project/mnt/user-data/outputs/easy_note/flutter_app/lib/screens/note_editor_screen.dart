// lib/screens/note_editor_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/providers.dart';
import '../models/note_model.dart';
import '../utils/app_theme.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/media_attachment_widget.dart';
import '../widgets/share_note_sheet.dart';
import '../widgets/ai_actions_sheet.dart';
import '../services/storage_service.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String noteId;

  const NoteEditorScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late QuillController _quillController;
  late TextEditingController _titleController;
  final _uuid = const Uuid();
  bool _isInitialized = false;
  bool _isSaving = false;
  NoteModel? _currentNote;
  int _selectedColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    // Auto-save on dispose
    _saveNote();
    _quillController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _initFromNote(NoteModel note) {
    if (_isInitialized) return;
    _isInitialized = true;
    _currentNote = note;
    _titleController.text = note.title;
    _selectedColorIndex = note.colorIndex;

    if (note.contentDelta != null) {
      try {
        final doc = Document.fromJson(
          List<dynamic>.from(note.contentDelta!['ops'] ?? []),
        );
        _quillController = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {}
    }
  }

  Future<void> _saveNote() async {
    if (_currentNote == null) return;
    final notesService = ref.read(notesServiceProvider);

    final delta = _quillController.document.toDelta().toJson();
    final plainText = _quillController.document.toPlainText().trim();

    await notesService.updateNote(widget.noteId, {
      'title': _titleController.text.trim().isEmpty
          ? 'Untitled'
          : _titleController.text.trim(),
      'contentDelta': {'ops': delta},
      'contentPlainText': plainText.length > 300
          ? '${plainText.substring(0, 300)}...'
          : plainText,
      'colorIndex': _selectedColorIndex,
    });
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteStreamProvider(widget.noteId));
    final theme = Theme.of(context);
    final isDark = ref.watch(darkModeProvider);

    return noteAsync.when(
      data: (note) {
        if (note == null) return const Scaffold(body: Center(child: Text('Note not found')));
        _initFromNote(note);
        _currentNote = note;
        final bgColor = isDark
            ? AppTheme.darkCard
            : AppTheme.noteColors[note.colorIndex % AppTheme.noteColors.length];

        return Scaffold(
          backgroundColor: bgColor,
          appBar: _buildAppBar(context, note, isDark),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextField(
                        controller: _titleController,
                        onChanged: (_) => _autoSave(),
                        style: GoogleFonts.fraunces(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.softTan : AppTheme.ink,
                          letterSpacing: -0.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Title',
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.next,
                      ),
                      // Date
                      Text(
                        _formatDate(note.updatedAt),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      // Quill editor
                      QuillEditor.basic(
                        controller: _quillController,
                        readOnly: false,
                        configurations: QuillEditorConfigurations(
                          placeholder: 'Start writing...',
                          customStyles: _buildQuillStyles(isDark),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Audio recordings
                      if (note.audioAttachments.isNotEmpty) ...[
                        Text(
                          'VOICE NOTES',
                          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 8),
                        ...note.audioAttachments.map((audio) => AudioPlayerWidget(
                          audio: audio,
                          noteId: widget.noteId,
                        )),
                        const SizedBox(height: 16),
                      ],
                      // Media attachments
                      if (note.mediaAttachments.isNotEmpty) ...[
                        Text(
                          'ATTACHMENTS',
                          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 8),
                        MediaAttachmentWidget(
                          attachments: note.mediaAttachments,
                          noteId: widget.noteId,
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Tags
                      if (note.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 6,
                          children: note.tags.map((tag) => Chip(
                            label: Text('#$tag', style: GoogleFonts.dmSans(fontSize: 12)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // AI Summary
                      if (note.aiSummary != null) ...[
                        _buildAISummaryCard(note.aiSummary!, isDark),
                      ],
                    ],
                  ),
                ),
              ),
              // Bottom toolbar
              _buildBottomBar(note, isDark),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, NoteModel note, bool isDark) {
    final bgColor = isDark
        ? AppTheme.darkCard
        : AppTheme.noteColors[note.colorIndex % AppTheme.noteColors.length];

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () async {
          await _saveNote();
          if (mounted) Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      ),
      actions: [
        // Color picker
        IconButton(
          onPressed: () => _showColorPicker(context),
          icon: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.noteColors[_selectedColorIndex],
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.warmGray, width: 1.5),
            ),
          ),
        ),
        // Pin
        IconButton(
          onPressed: () => ref.read(notesServiceProvider).togglePin(note.id, note.isPinned),
          icon: Icon(
            note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            size: 20,
          ),
        ),
        // Share
        IconButton(
          onPressed: () => _showShareSheet(context, note),
          icon: const Icon(Icons.person_add_alt_outlined, size: 20),
        ),
        // AI Actions
        IconButton(
          onPressed: () => _showAIActions(context, note),
          icon: const Icon(Icons.auto_awesome_rounded, size: 20),
        ),
        // More options
        PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'archive', child: Text('Archive')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
          onSelected: (value) async {
            if (value == 'archive') {
              await ref.read(notesServiceProvider).setArchived(note.id, true);
              if (mounted) Navigator.pop(context);
            } else if (value == 'delete') {
              _confirmDelete(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(NoteModel note, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface
            : Colors.white.withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.softTan,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Audio recorder
            AudioRecorderWidget(noteId: widget.noteId),
            // Formatting and attach toolbar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // Quill formatting buttons
                  QuillToolbarToggleStyleButton(
                    attribute: Attribute.bold,
                    controller: _quillController,
                    options: const QuillToolbarToggleStyleButtonOptions(
                      childBuilder: _boldButtonBuilder,
                    ),
                  ),
                  QuillToolbarToggleStyleButton(
                    attribute: Attribute.italic,
                    controller: _quillController,
                    options: const QuillToolbarToggleStyleButtonOptions(
                      childBuilder: _italicButtonBuilder,
                    ),
                  ),
                  QuillToolbarToggleStyleButton(
                    attribute: Attribute.underline,
                    controller: _quillController,
                    options: const QuillToolbarToggleStyleButtonOptions(
                      childBuilder: _underlineButtonBuilder,
                    ),
                  ),
                  _toolbarDivider(),
                  _toolbarButton(Icons.format_list_bulleted_rounded, () {
                    _quillController.formatSelection(Attribute.ul);
                  }),
                  _toolbarButton(Icons.format_list_numbered_rounded, () {
                    _quillController.formatSelection(Attribute.ol);
                  }),
                  _toolbarButton(Icons.check_box_outlined, () {
                    _quillController.formatSelection(Attribute.unchecked);
                  }),
                  _toolbarDivider(),
                  // Attachments
                  _toolbarButton(Icons.image_outlined, _pickImage),
                  _toolbarButton(Icons.videocam_outlined, _pickVideo),
                  _toolbarButton(Icons.picture_as_pdf_outlined, _pickPdf),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: AppTheme.mediumGray),
      ),
    );
  }

  Widget _toolbarDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppTheme.softTan,
    );
  }

  DefaultStyles _buildQuillStyles(bool isDark) {
    final textColor = isDark ? AppTheme.softTan : AppTheme.ink;
    final textStyle = GoogleFonts.dmSans(
      fontSize: 16,
      color: textColor,
      height: 1.7,
    );

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(textStyle, const VerticalSpacing(0, 0), const VerticalSpacing(0, 0), null),
      h1: DefaultTextBlockStyle(
        GoogleFonts.fraunces(fontSize: 26, fontWeight: FontWeight.w700, color: textColor),
        const VerticalSpacing(8, 0), const VerticalSpacing(0, 0), null,
      ),
      h2: DefaultTextBlockStyle(
        GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600, color: textColor),
        const VerticalSpacing(6, 0), const VerticalSpacing(0, 0), null,
      ),
    );
  }

  Widget _buildAISummaryCard(String summary, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90A4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A90A4).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF4A90A4)),
              const SizedBox(width: 6),
              Text(
                'AI Summary',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A90A4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: isDark ? AppTheme.warmGray : AppTheme.darkGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Auto-save debounce
  void _autoSave() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _saveNote();
    });
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Note color', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: List.generate(
                AppTheme.noteColors.length,
                (i) => GestureDetector(
                  onTap: () {
                    setState(() => _selectedColorIndex = i);
                    Navigator.pop(context);
                    _saveNote();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.noteColors[i],
                      shape: BoxShape.circle,
                      border: i == _selectedColorIndex
                          ? Border.all(color: AppTheme.darkGray, width: 2)
                          : null,
                    ),
                    child: i == _selectedColorIndex
                        ? const Icon(Icons.check_rounded, size: 18, color: AppTheme.darkGray)
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context, NoteModel note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShareNoteSheet(note: note),
    );
  }

  void _showAIActions(BuildContext context, NoteModel note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AIActionsSheet(note: note),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    await _uploadMedia(File(xfile.path), 'image', xfile.name);
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final xfile = await picker.pickVideo(source: ImageSource.gallery);
    if (xfile == null) return;

    await _uploadMedia(File(xfile.path), 'video', xfile.name);
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null || result.files.single.path == null) return;

    await _uploadMedia(File(result.files.single.path!), 'pdf', result.files.single.name);
  }

  Future<void> _uploadMedia(File file, String type, String fileName) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final storageService = ref.read(storageServiceProvider);
    final notesService = ref.read(notesServiceProvider);
    final mediaId = _uuid.v4();

    try {
      String url;
      if (type == 'image') {
        url = await storageService.uploadImage(user.uid, widget.noteId, file, mediaId);
      } else if (type == 'video') {
        url = await storageService.uploadVideo(user.uid, widget.noteId, file, mediaId);
      } else {
        url = await storageService.uploadPdf(user.uid, widget.noteId, file, mediaId);
      }

      final attachment = MediaAttachment(
        id: mediaId,
        storageUrl: url,
        type: type,
        fileName: fileName,
        fileSize: await file.length(),
        createdAt: DateTime.now(),
      );

      await notesService.addMediaAttachment(widget.noteId, attachment);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(notesServiceProvider).deleteNote(widget.noteId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Static builder helpers for QuillToolbar
Widget _boldButtonBuilder(QuillToolbarToggleStyleButtonExtraOptions options, QuillToolbarToggleStyleButtonOptions baseOptions) {
  return InkWell(
    onTap: options.onPressed,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(Icons.format_bold_rounded, size: 20,
        color: options.isToggled ? AppTheme.ink : AppTheme.mediumGray),
    ),
  );
}

Widget _italicButtonBuilder(QuillToolbarToggleStyleButtonExtraOptions options, QuillToolbarToggleStyleButtonOptions baseOptions) {
  return InkWell(
    onTap: options.onPressed,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(Icons.format_italic_rounded, size: 20,
        color: options.isToggled ? AppTheme.ink : AppTheme.mediumGray),
    ),
  );
}

Widget _underlineButtonBuilder(QuillToolbarToggleStyleButtonExtraOptions options, QuillToolbarToggleStyleButtonOptions baseOptions) {
  return InkWell(
    onTap: options.onPressed,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(Icons.format_underline_rounded, size: 20,
        color: options.isToggled ? AppTheme.ink : AppTheme.mediumGray),
    ),
  );
}
