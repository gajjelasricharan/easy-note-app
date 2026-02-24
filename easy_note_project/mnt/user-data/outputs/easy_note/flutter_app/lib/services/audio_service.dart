// lib/services/audio_service.dart
import 'dart:io';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum AudioRecordingState { idle, recording, paused }
enum AudioPlaybackState { idle, loading, playing, paused }

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final _uuid = const Uuid();

  AudioRecordingState _recordingState = AudioRecordingState.idle;
  AudioPlaybackState _playbackState = AudioPlaybackState.idle;

  AudioRecordingState get recordingState => _recordingState;
  AudioPlaybackState get playbackState => _playbackState;
  bool get isRecording => _recordingState == AudioRecordingState.recording;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  String? _currentRecordingPath;
  String? _currentRecordingId;
  DateTime? _recordingStartTime;

  /// Start recording — returns recording ID
  Future<String> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) throw Exception('Microphone permission denied');

    final dir = await getTemporaryDirectory();
    final id = _uuid.v4();
    final path = '${dir.path}/$id.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _currentRecordingPath = path;
    _currentRecordingId = id;
    _recordingStartTime = DateTime.now();
    _recordingState = AudioRecordingState.recording;

    return id;
  }

  /// Stop recording — returns (path, durationMs)
  Future<(String path, int durationMs, String id)> stopRecording() async {
    if (!isRecording) throw Exception('Not recording');

    final path = await _recorder.stop();
    final durationMs = DateTime.now()
        .difference(_recordingStartTime!)
        .inMilliseconds;

    final id = _currentRecordingId!;
    _recordingState = AudioRecordingState.idle;
    _currentRecordingPath = null;
    _currentRecordingId = null;
    _recordingStartTime = null;

    return (path ?? '', durationMs, id);
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    await _recorder.cancel();
    _recordingState = AudioRecordingState.idle;
    _currentRecordingPath = null;
    _currentRecordingId = null;
  }

  /// Get amplitude stream for waveform visualization
  Stream<Amplitude> get amplitudeStream => _recorder.onAmplitudeChanged(
    const Duration(milliseconds: 50),
  );

  /// Play audio from URL or local path
  Future<void> playAudio(String source, {bool isLocal = false}) async {
    _playbackState = AudioPlaybackState.loading;
    try {
      if (isLocal) {
        await _player.setFilePath(source);
      } else {
        await _player.setUrl(source);
      }
      _playbackState = AudioPlaybackState.playing;
      await _player.play();
    } catch (e) {
      _playbackState = AudioPlaybackState.idle;
      rethrow;
    }
  }

  Future<void> pauseAudio() async {
    await _player.pause();
    _playbackState = AudioPlaybackState.paused;
  }

  Future<void> resumeAudio() async {
    await _player.play();
    _playbackState = AudioPlaybackState.playing;
  }

  Future<void> stopAudio() async {
    await _player.stop();
    _playbackState = AudioPlaybackState.idle;
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}
