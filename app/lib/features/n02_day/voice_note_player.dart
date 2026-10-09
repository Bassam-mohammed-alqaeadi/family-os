import 'dart:async';
import 'dart:io';

import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Plays one voice note the caller may see.
///
/// The bytes are fetched on the first tap, and the client has already checked them against the
/// server's SHA-256 before they arrive here. They are written to the app's temporary folder and
/// played from there. The file is removed when the bubble leaves the screen.
class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({
    super.key,
    required this.media,
    required this.foreground,
    required this.surface,
    this.buttonKey,
  });

  final ConversationMedia media;
  final Color foreground;
  final Color surface;
  final Key? buttonKey;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _stateSub;
  File? _file;
  bool _loading = false;
  bool _failed = false;

  Future<void> _toggle() async {
    if (_loading) return;
    final player = _player;
    if (player != null) {
      if (player.playing) {
        await player.pause();
      } else {
        unawaited(player.play());
      }
      if (mounted) setState(() {});
      return;
    }
    setState(() => _loading = true);
    try {
      final load = widget.media.loadBytes;
      final bytes = load == null ? null : await load();
      if (bytes == null) throw StateError('voice note unavailable');
      final directory = await getTemporaryDirectory();
      final file = File(
        p.join(directory.path, 'voice-${widget.media.id}.${_extensionFor(widget.media.mimeType)}'),
      );
      await file.writeAsBytes(bytes, flush: true);
      _file = file;
      final created = AudioPlayer();
      await created.setFilePath(file.path);
      _stateSub = created.playerStateStream.listen((_) {
        if (mounted) setState(() {});
      });
      _player = created;
      unawaited(created.play());
      if (mounted) setState(() => _loading = false);
    } on Object {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  static String _extensionFor(String mimeType) => switch (mimeType) {
    'audio/ogg' => 'ogg',
    'audio/mpeg' => 'mp3',
    _ => 'm4a',
  };

  @override
  void dispose() {
    unawaited(_stateSub?.cancel());
    unawaited(_player?.dispose());
    final file = _file;
    if (file != null) {
      try {
        file.deleteSync();
      } on FileSystemException {
        // Already gone; nothing else refers to it.
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final playing = _player?.playing ?? false;
    final ms = widget.media.durationMs;
    final length = ms == null ? '' : ' · ${_clock(ms)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: widget.surface.withValues(alpha: 0.18),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: widget.buttonKey,
            tooltip: playing ? l10n.voicePauseSemantics : l10n.voicePlaySemantics,
            onPressed: _failed ? null : _toggle,
            icon: _loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.foreground,
                    ),
                  )
                : Icon(
                    playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: widget.foreground,
                    size: 34,
                  ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _failed
                  ? l10n.familyChatMediaItemUnavailable
                  : '${l10n.familyChatMediaVoiceNote}$length',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.foreground,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _clock(int ms) {
    final seconds = ms ~/ 1000;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
