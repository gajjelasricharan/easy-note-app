// lib/widgets/media_attachment_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/note_model.dart';
import '../providers/providers.dart';
import '../utils/app_theme.dart';

class MediaAttachmentWidget extends ConsumerWidget {
  final List<MediaAttachment> attachments;
  final String noteId;

  const MediaAttachmentWidget({
    super.key,
    required this.attachments,
    required this.noteId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = attachments.where((a) => a.type == 'image').toList();
    final others = attachments.where((a) => a.type != 'image').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) _buildImageGrid(context, ref, images),
        if (others.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...others.map((a) => _buildFileItem(context, ref, a)),
        ],
      ],
    );
  }

  Widget _buildImageGrid(BuildContext context, WidgetRef ref, List<MediaAttachment> images) {
    if (images.length == 1) {
      return _buildSingleImage(context, ref, images.first);
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: images.length,
      itemBuilder: (_, i) => _buildThumbnail(context, ref, images[i]),
    );
  }

  Widget _buildSingleImage(BuildContext context, WidgetRef ref, MediaAttachment attachment) {
    return GestureDetector(
      onTap: () => _openImage(context, attachment.storageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: attachment.storageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          placeholder: (_, __) => Container(
            height: 200,
            color: AppTheme.softTan,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 200,
            color: AppTheme.softTan,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, WidgetRef ref, MediaAttachment attachment) {
    return GestureDetector(
      onTap: () => _openImage(context, attachment.storageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: attachment.storageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: AppTheme.softTan),
          errorWidget: (_, __, ___) => Container(
            color: AppTheme.softTan,
            child: const Icon(Icons.broken_image_outlined, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, WidgetRef ref, MediaAttachment attachment) {
    IconData icon;
    Color iconColor;

    switch (attachment.type) {
      case 'pdf':
        icon = Icons.picture_as_pdf_outlined;
        iconColor = Colors.red;
        break;
      case 'video':
        icon = Icons.videocam_outlined;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.attach_file_rounded;
        iconColor = AppTheme.mediumGray;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.softTan.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment.fileSize != null)
                  Text(
                    _formatFileSize(attachment.fileSize!),
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.warmGray),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => launchUrl(Uri.parse(attachment.storageUrl)),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            color: AppTheme.mediumGray,
          ),
          IconButton(
            onPressed: () => _deleteMedia(context, ref, attachment),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppTheme.warmGray,
          ),
        ],
      ),
    );
  }

  void _openImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMedia(BuildContext context, WidgetRef ref, MediaAttachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete attachment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(_, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(notesServiceProvider).removeMediaAttachment(noteId, attachment.id);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
