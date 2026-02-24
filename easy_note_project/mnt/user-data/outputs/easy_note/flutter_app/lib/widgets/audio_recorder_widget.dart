// lib/widgets/audio_recorder_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import '../providers/providers.dart';
import '../models/note_model.dart';
import '../utils/app_theme.dart';
import 'package:uuid/uuid.dart';

class AudioRecorderWidget extends ConsumerStatefulWidget {
  final String noteId;

  const AudioRecorderWidget({super.key, required this.noteId});

  @override
  ConsumerState<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends ConsumerState<AudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isUploading = false;
  double _amplitude = 0;
  int _recordingSeconds = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isRecording) {
      return _buildRecordingBar(theme);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Record button
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            onTap: _toggleRecording,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isUploading
                    ? AppTheme.warmGray
                    : AppTheme.ink.withOpacity(0.85),
                shape: BoxShape.circle,
              ),
              child: _isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.warmWhite,
                      ),
                    )
                  : const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _isUploading ? 'Uploading...' : 'Hold to record, tap to toggle',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppTheme.warmGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.red.withOpacity(0.05),
      child: Row(
        children: [
          // Pulsing dot
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Duration
          Text(
            _formatDuration(_recordingSeconds),
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          // Amplitude bars
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(20, (i) {
                final height = 6 + (i % 5) * 3.0 * (_amplitude + 0.3);
                return Container(
                  width: 3,
                  height: height.clamp(4, 24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          // Cancel
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.warmGray),
          ),
          // Stop/send
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    final audioService = ref.read(audioServiceProvider);

    try {
      await audioService.startRecording();
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      // Tick timer
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        if (!_isRecording) return false;
        setState(() => _recordingSeconds++);
        return _isRecording;
      });

      // Amplitude stream
      audioService.amplitudeStream.listen((amp) {
        if (mounted && _isRecording) {
          setState(() {
            _amplitude = (amp.current + 60) / 60; // normalize -60dB to 0dB
            _amplitude = _amplitude.clamp(0, 1);
          });
        }
      });
    } catch (e) {
      _showError('Microphone access denied');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    HapticFeedback.lightImpact();

    final audioService = ref.read(audioServiceProvider);
    setState(() {
      _isRecording = false;
      _isUploading = true;
    });

    try {
      final (path, durationMs, id) = await audioService.stopRecording();

      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final storageService = ref.read(storageServiceProvider);
      final notesService = ref.read(notesServiceProvider);

      final url = await storageService.uploadAudio(
        user.uid,
        widget.noteId,
        File(path),
        id,
      );

      final attachment = AudioAttachment(
        id: id,
        storageUrl: url,
        durationMs: durationMs,
        createdAt: DateTime.now(),
      );

      await notesService.addAudioAttachment(widget.noteId, attachment);

      // Optional: auto-transcribe
      _tryTranscribe(File(path), id, user);
    } catch (e) {
      _showError('Recording failed: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _cancelRecording() async {
    final audioService = ref.read(audioServiceProvider);
    await audioService.cancelRecording();
    setState(() => _isRecording = false);
  }

  Future<void> _tryTranscribe(File file, String audioId, dynamic user) async {
    try {
      final idToken = await user.getIdToken();
      final aiService = ref.read(aiServiceProvider);
      final transcript = await aiService.transcribeAudio(file, idToken);

      if (transcript != null && transcript.isNotEmpty) {
        // Update the specific audio attachment with transcript
        final notesService = ref.read(notesServiceProvider);
        // We'd need a more granular update here in production
        print('Transcript: $transcript');
      }
    } catch (_) {}
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  String _formatDuration(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}
