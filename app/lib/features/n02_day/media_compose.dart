import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';
import 'package:family_os/features/n02_day/live_conversation_repository.dart';
import 'package:family_os/foundation_gate/family_chat_media_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Why a photo or recording could not be prepared for sending.
enum MediaComposeProblem { unsupportedType, tooLarge, noPermission, empty }

final class MediaComposeException implements Exception {
  const MediaComposeException(this.problem);

  final MediaComposeProblem problem;
}

/// A new draft with fresh idempotency ids. The ids stay with the draft for its whole life, so a
/// retry after a lost answer reaches the server with the same ids.
ConversationMediaDraft newConversationMediaDraft({
  required ConversationMediaKind kind,
  required Uint8List bytes,
  required String mimeType,
  int? durationMs,
}) {
  return ConversationMediaDraft(
    kind: kind,
    bytes: bytes,
    mimeType: mimeType,
    durationMs: durationMs,
    clientMediaId: newFoundationGateIdempotencyKey(),
    clientMessageId: newFoundationGateIdempotencyKey(),
    idempotencyKey: newFoundationGateIdempotencyKey(),
  );
}

/// Picks one photo from the gallery or camera and makes it an unsent draft. Null means the person
/// cancelled. The photo is downscaled and re-encoded by the picker, and must be JPEG, PNG or WebP.
Future<ConversationMediaDraft?> pickConversationPhoto(
  ImageSource source, {
  ImagePicker? picker,
}) async {
  final file = await (picker ?? ImagePicker()).pickImage(
    source: source,
    maxWidth: 2048,
    maxHeight: 2048,
    imageQuality: 85,
  );
  if (file == null) return null;
  final mimeType = _photoMimeType(file.mimeType, file.name);
  if (mimeType == null) {
    throw const MediaComposeException(MediaComposeProblem.unsupportedType);
  }
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) throw const MediaComposeException(MediaComposeProblem.empty);
  if (bytes.length > FamilyChatMediaClient.maxUploadBytes) {
    throw const MediaComposeException(MediaComposeProblem.tooLarge);
  }
  return newConversationMediaDraft(
    kind: ConversationMediaKind.image,
    bytes: bytes,
    mimeType: mimeType,
  );
}

String? _photoMimeType(String? declared, String name) {
  final type = declared?.toLowerCase();
  if (type == 'image/jpeg' || type == 'image/png' || type == 'image/webp') return type;
  final lower = name.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return null;
}

/// One finished recording: the encoded bytes and the length measured on this device.
final class VoiceNoteRecording {
  const VoiceNoteRecording({required this.bytes, required this.durationMs});

  final Uint8List bytes;
  final int durationMs;
}

/// Records one voice note as AAC in an MP4 container (`audio/mp4`), which every supported
/// platform can play back. Recording stops by itself at the server's five-minute limit.
final class VoiceNoteRecorder {
  VoiceNoteRecorder({AudioRecorder? recorder}) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final Stopwatch _clock = Stopwatch();

  /// Starts the microphone. False means the person did not grant access.
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) return false;
    final directory = await getTemporaryDirectory();
    final path = p.join(directory.path, 'voice-${newFoundationGateIdempotencyKey()}.m4a');
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    _clock
      ..reset()
      ..start();
    return true;
  }

  int get elapsedMs => _clock.elapsedMilliseconds;

  /// Stops and returns the recording, or null if nothing was captured.
  Future<VoiceNoteRecording?> stop() async {
    final path = await _recorder.stop();
    _clock.stop();
    final elapsed = _clock.elapsedMilliseconds;
    if (path == null) return null;
    final file = File(path);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw const MediaComposeException(MediaComposeProblem.empty);
      if (bytes.length > FamilyChatMediaClient.maxUploadBytes) {
        throw const MediaComposeException(MediaComposeProblem.tooLarge);
      }
      final durationMs = elapsed < 1
          ? 1
          : (elapsed > FamilyChatMediaClient.maxVoiceNoteMs
                ? FamilyChatMediaClient.maxVoiceNoteMs
                : elapsed);
      return VoiceNoteRecording(bytes: bytes, durationMs: durationMs);
    } finally {
      try {
        await file.delete();
      } on FileSystemException {
        // The temporary file is ours; a failed delete leaves nothing that is shared.
      }
    }
  }

  Future<void> cancel() async {
    _clock.stop();
    await _recorder.cancel();
  }

  void dispose() => _recorder.dispose();
}

/// Shows the recording controls. Resolves to the recording when the person sends it, and to null
/// when they cancel, deny the microphone, or the recording fails.
Future<VoiceNoteRecording?> showVoiceNoteRecorder(BuildContext context) {
  return showDialog<VoiceNoteRecording>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _VoiceNoteRecorderDialog(recorder: VoiceNoteRecorder()),
  );
}

class _VoiceNoteRecorderDialog extends StatefulWidget {
  const _VoiceNoteRecorderDialog({required this.recorder});

  final VoiceNoteRecorder recorder;

  @override
  State<_VoiceNoteRecorderDialog> createState() => _VoiceNoteRecorderDialogState();
}

class _VoiceNoteRecorderDialogState extends State<_VoiceNoteRecorderDialog> {
  Timer? _ticker;
  bool _recording = false;
  bool _busy = false;
  MediaComposeProblem? _problem;

  @override
  void initState() {
    super.initState();
    unawaited(_begin());
  }

  Future<void> _begin() async {
    try {
      final started = await widget.recorder.start();
      if (!mounted) return;
      if (!started) {
        setState(() => _problem = MediaComposeProblem.noPermission);
        return;
      }
      setState(() => _recording = true);
      _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!mounted) return;
        if (widget.recorder.elapsedMs >= FamilyChatMediaClient.maxVoiceNoteMs) {
          unawaited(_send());
        } else {
          setState(() {});
        }
      });
    } on Object {
      if (mounted) setState(() => _problem = MediaComposeProblem.empty);
    }
  }

  Future<void> _send() async {
    if (_busy || !_recording) return;
    setState(() => _busy = true);
    _ticker?.cancel();
    try {
      final recording = await widget.recorder.stop();
      if (!mounted) return;
      if (recording == null) {
        setState(() {
          _busy = false;
          _problem = MediaComposeProblem.empty;
        });
        return;
      }
      Navigator.of(context).pop(recording);
    } on MediaComposeException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _problem = error.problem;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _problem = MediaComposeProblem.empty;
        });
      }
    }
  }

  Future<void> _cancel() async {
    _ticker?.cancel();
    if (_recording) {
      try {
        await widget.recorder.cancel();
      } on Object {
        // Nothing was sent; the recorder is released below regardless.
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    widget.recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seconds = widget.recorder.elapsedMs ~/ 1000;
    final clock = '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return AlertDialog(
      key: const Key('voice_note_recorder'),
      title: Text(l10n.voiceRecordingTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _recording ? Icons.fiber_manual_record : Icons.mic_none,
            color: _recording ? Colors.red : null,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(_recording ? clock : '', style: const TextStyle(fontSize: 22)),
          if (_problem != null) ...[
            const SizedBox(height: 8),
            Text(mediaComposeMessage(l10n, _problem!), textAlign: TextAlign.center),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: _cancel, child: Text(l10n.voiceRecordingCancel)),
        FilledButton(
          onPressed: _recording && !_busy ? _send : null,
          child: Text(l10n.voiceRecordingSend),
        ),
      ],
    );
  }
}

/// The honest sentence for each way composing can fail.
String mediaComposeMessage(AppLocalizations l10n, MediaComposeProblem problem) {
  return switch (problem) {
    MediaComposeProblem.unsupportedType => l10n.mediaComposeUnsupportedType,
    MediaComposeProblem.tooLarge => l10n.mediaComposeTooLarge,
    MediaComposeProblem.noPermission => l10n.mediaComposeMicrophoneDenied,
    MediaComposeProblem.empty => l10n.mediaComposeFailed,
  };
}
