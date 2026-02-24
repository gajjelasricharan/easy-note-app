// lib/widgets/share_note_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note_model.dart';
import '../providers/providers.dart';
import '../utils/app_theme.dart';

class ShareNoteSheet extends ConsumerStatefulWidget {
  final NoteModel note;

  const ShareNoteSheet({super.key, required this.note});

  @override
  ConsumerState<ShareNoteSheet> createState() => _ShareNoteSheetState();
}

class _ShareNoteSheetState extends ConsumerState<ShareNoteSheet> {
  final _emailController = TextEditingController();
  NotePermission _selectedPermission = NotePermission.viewer;
  bool _isGeneratingLink = false;
  String? _inviteLink;

  @override
  void initState() {
    super.initState();
    if (widget.note.inviteToken != null) {
      _inviteLink = 'https://easynote.app/invite/${widget.note.inviteToken}';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHandle(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Share note', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Invite collaborators to "${widget.note.title}"',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),

                  // Invite by email
                  Text('INVITE BY EMAIL', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter email address',
                            prefixIcon: const Icon(Icons.email_outlined, size: 18),
                            hintStyle: GoogleFonts.dmSans(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PermissionDropdown(
                        value: _selectedPermission,
                        onChanged: (p) => setState(() => _selectedPermission = p!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _inviteByEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.ink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Send Invite', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                  ),

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Invite link
                  Text('INVITE LINK', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  if (_inviteLink != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.softTan.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _inviteLink!,
                              style: GoogleFonts.dmSans(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _inviteLink!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Link copied!')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Share.share(_inviteLink!),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share link'),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: _generateInviteLink,
                      icon: _isGeneratingLink
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Generate invite link'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],

                  // Current collaborators
                  if (widget.note.sharedWith.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text('COLLABORATORS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
                    const SizedBox(height: 10),
                    ...widget.note.sharedWith.map((user) => _CollaboratorTile(
                      user: user,
                      onRemove: () => _removeCollaborator(user),
                      onPermissionChange: (p) => _updatePermission(user, p),
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() => Container(
    width: 36,
    height: 4,
    margin: const EdgeInsets.only(top: 12, bottom: 8),
    decoration: BoxDecoration(
      color: AppTheme.softTan,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Future<void> _inviteByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    // In production, send an email notification via your backend
    // For now, we generate invite link and show it
    await _generateInviteLink();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invite link generated — share it with $email')),
      );
      _emailController.clear();
    }
  }

  Future<void> _generateInviteLink() async {
    setState(() => _isGeneratingLink = true);
    try {
      final token = await ref.read(notesServiceProvider).generateInviteToken(widget.note.id);
      setState(() => _inviteLink = 'https://easynote.app/invite/$token');
    } finally {
      if (mounted) setState(() => _isGeneratingLink = false);
    }
  }

  Future<void> _removeCollaborator(SharedUser user) async {
    final updated = widget.note.sharedWith.where((u) => u.uid != user.uid).toList();
    await ref.read(notesServiceProvider).updateSharing(widget.note.id, updated);
  }

  Future<void> _updatePermission(SharedUser user, NotePermission permission) async {
    final updated = widget.note.sharedWith.map((u) {
      if (u.uid == user.uid) {
        return SharedUser(uid: u.uid, email: u.email, displayName: u.displayName, permission: permission);
      }
      return u;
    }).toList();
    await ref.read(notesServiceProvider).updateSharing(widget.note.id, updated);
  }
}

class _PermissionDropdown extends StatelessWidget {
  final NotePermission value;
  final void Function(NotePermission?) onChanged;

  const _PermissionDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.softTan),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<NotePermission>(
          value: value,
          isDense: true,
          onChanged: onChanged,
          items: NotePermission.values
              .where((p) => p != NotePermission.owner)
              .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(
                      p.name.capitalize(),
                      style: GoogleFonts.dmSans(fontSize: 13),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _CollaboratorTile extends StatelessWidget {
  final SharedUser user;
  final VoidCallback onRemove;
  final void Function(NotePermission) onPermissionChange;

  const _CollaboratorTile({
    required this.user,
    required this.onRemove,
    required this.onPermissionChange,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppTheme.softTan,
        child: Text(
          (user.displayName ?? user.email).substring(0, 1).toUpperCase(),
          style: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(user.displayName ?? user.email, style: GoogleFonts.dmSans(fontSize: 14)),
      subtitle: Text(user.email, style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.warmGray)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PermissionDropdown(
            value: user.permission,
            onChanged: (p) => onPermissionChange(p!),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
