import 'package:flutter/material.dart';

import 'package:family_os/core/data/communication_rules.dart';
import 'package:family_os/core/design/components/bottom_sheet_host.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/conversation_repository.dart';

/// Whose brand a thread wears — parents purple, child turquoise. ADR-053 is
/// explicit that the WhatsApp line never restyles this.
enum ChatTone { parent, child }

/// The per-chat wallpaper, from [kWallpapers]. Null → the screen default.
Color? chatWallpaperColor(FamilyColors colors, String? wallpaper) =>
    switch (wallpaper) {
      'rose' => colors.coral100,
      'mint' => colors.mint100,
      'violet' => colors.p100,
      _ => null,
    };

/// Bubble fill for this reader's own message, honouring the per-chat theme
/// ([kBubbleThemes]) while staying inside our palette.
Color chatBubbleColor({
  required FamilyColors colors,
  required bool mine,
  required ChatTone tone,
  String? theme,
}) {
  if (!mine) return colors.surface;
  return switch (theme) {
    'rose' => colors.coral,
    'teal' => colors.teal600,
    'p' => colors.p500,
    _ => tone == ChatTone.child ? colors.teal : colors.p500,
  };
}

/// ✓ = sent, ✓✓ = read. There is deliberately no third glyph (ADR-053).
String chatTickGlyph(MessageTick tick) =>
    tick == MessageTick.read ? '✓✓' : '✓';

/// The message pinned at the top of the thread (S-COM-008).
class ChatPinnedBar extends StatelessWidget {
  const ChatPinnedBar({
    super.key,
    required this.preview,
    required this.label,
    required this.unpinLabel,
    required this.onUnpin,
    this.unpinKey,
    this.mediaLabel,
  });

  final String preview;
  final String label;
  final String unpinLabel;
  final VoidCallback onUnpin;

  /// Key for the unpin button (screen-specific acceptance key).
  final Key? unpinKey;

  /// ARB-sourced media label when the message is not plain text.
  final String? mediaLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final text = mediaLabel ?? preview;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.p50,
          borderRadius: BorderRadius.circular(radii.card),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: colors.p700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: unpinKey,
                tooltip: unpinLabel,
                onPressed: onUnpin,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: Icon(Icons.push_pin_outlined, size: 18, color: colors.ink2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One bubble, RTL: my messages on the LEFT (`centerEnd` under RTL), time
/// inside the bubble, reply quoted inside, tombstone in place.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.bubbleKey,
    required this.message,
    required this.tone,
    required this.theme,
    required this.replyPrefix,
    required this.deletedLabel,
    required this.editedTag,
    required this.mediaLabel,
    this.onLongPress,
  });

  final Key bubbleKey;
  final ConversationMessage message;
  final ChatTone tone;
  final String? theme;
  final String replyPrefix;
  final String deletedLabel;
  final String editedTag;
  final String? mediaLabel;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final mine = message.isMine;
    final bg = chatBubbleColor(
      colors: colors,
      mine: mine,
      tone: tone,
      theme: theme,
    );
    final fg = mine ? Colors.white : colors.ink;
    final subtle = mine ? Colors.white70 : colors.ink2;

    // RTL: centerEnd is the left edge — WhatsApp's own mirroring.
    final align =
        mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart;

    final body = message.deleted
        ? deletedLabel
        : (mediaLabel ?? message.body);

    return Align(
      alignment: align,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: DecoratedBox(
            key: bubbleKey,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(mine ? 18 : 6),
                topEnd: Radius.circular(mine ? 6 : 18),
                bottomStart: const Radius.circular(18),
                bottomEnd: const Radius.circular(18),
              ),
              border: mine
                  ? null
                  : Border.all(color: colors.border.withValues(alpha: 0.85)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.senderLabel != null) ...[
                    Text(
                      message.senderLabel!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: mine ? Colors.white70 : colors.p600,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  if (message.replyTo != null) ...[
                    _ReplyQuote(
                      reply: message.replyTo!,
                      prefix: replyPrefix,
                      mine: mine,
                      colors: colors,
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (message.deleted)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block, size: 14, color: subtle),
                        const SizedBox(width: 6),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: subtle,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: fg,
                        height: 1.35,
                      ),
                    ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.edited && !message.deleted) ...[
                        Text(
                          editedTag,
                          style: TextStyle(fontSize: 10, color: subtle),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        message.timeLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: subtle,
                        ),
                      ),
                      if (mine && !message.deleted) ...[
                        const SizedBox(width: 4),
                        Text(
                          chatTickGlyph(message.tick),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: message.tick == MessageTick.read
                                ? colors.toastAction
                                : subtle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({
    required this.reply,
    required this.prefix,
    required this.mine,
    required this.colors,
  });

  final ConversationReply reply;
  final String prefix;
  final bool mine;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: mine
            ? Colors.white.withValues(alpha: 0.18)
            : colors.bg,
        borderRadius: BorderRadius.circular(8),
        border: BorderDirectional(
          start: BorderSide(
            width: 3,
            color: mine ? Colors.white70 : colors.p500,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prefix,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: mine ? Colors.white70 : colors.p700,
            ),
          ),
          Text(
            reply.preview.isEmpty
                ? AppLocalizations.of(context).conversationDeletedMessage
                : reply.preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: mine ? Colors.white : colors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

/// What a long-press on a bubble can ask for (ADR-053 «نأخذ»).
enum ChatMessageAction { reply, pin, unpin, edit, delete }

/// Bubble action sheet. The choices shown are the rules' — edit appears only
/// while the author's 15-minute window is open, pin never on a tombstone.
Future<ChatMessageAction?> showChatMessageSheet(
  BuildContext context, {
  required ConversationMessage message,
  required bool editable,
  required AppLocalizations l10n,
}) {
  final options = <(ChatMessageAction, String, IconData)>[
    if (message.visible)
      (ChatMessageAction.reply, l10n.conversationMenuReply, Icons.reply),
    if (message.visible && !message.pinned)
      (ChatMessageAction.pin, l10n.conversationMenuPin, Icons.push_pin_outlined),
    if (message.pinned)
      (ChatMessageAction.unpin, l10n.conversationMenuUnpin, Icons.push_pin),
    if (message.isMine && message.visible && editable)
      (ChatMessageAction.edit, l10n.conversationMenuEdit, Icons.edit_outlined),
    if (message.isMine && message.visible)
      (ChatMessageAction.delete, l10n.conversationMenuDelete, Icons.delete_outline),
  ];
  if (options.isEmpty) return Future.value(null);

  return BottomSheetHost.show<ChatMessageAction>(
    context,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (action, label, icon) in options)
          ListTile(
            key: Key('chat_action_${action.name}'),
            leading: Icon(icon),
            title: Text(label),
            onTap: () => Navigator.of(sheetContext).pop(action),
          ),
      ],
    ),
  );
}

/// The writes the settings sheet may ask for, all reader-scoped (ADR-053).
class ChatSettingsHandlers {
  const ChatSettingsHandlers({
    required this.onMute,
    required this.onUnmute,
    required this.onArchive,
    required this.onPin,
    required this.onLook,
  });

  final Future<void> Function(Duration? preset) onMute;
  final Future<void> Function() onUnmute;
  final Future<void> Function(bool archived) onArchive;
  final Future<void> Function(bool pinned) onPin;
  final Future<void> Function(String wallpaper, String bubbleTheme) onLook;
}

/// "⚙️ إعدادات هذه المحادثة … تُطبَّق على هذه المحادثة فقط" — mute presets,
/// archive, pin, wallpaper and bubble theme, plus the receipts rule.
Future<void> showChatSettingsSheet(
  BuildContext context, {
  required ConversationDetail detail,
  required ChatSettingsHandlers handlers,
  required AppLocalizations l10n,
}) {
  return BottomSheetHost.show<void>(
    context,
    semanticLabel: l10n.chatSettingsTitle,
    builder: (_) => _ChatSettingsSheet(
      detail: detail,
      handlers: handlers,
      l10n: l10n,
    ),
  );
}

class _ChatSettingsSheet extends StatefulWidget {
  const _ChatSettingsSheet({
    required this.detail,
    required this.handlers,
    required this.l10n,
  });

  final ConversationDetail detail;
  final ChatSettingsHandlers handlers;
  final AppLocalizations l10n;

  @override
  State<_ChatSettingsSheet> createState() => _ChatSettingsSheetState();
}

class _ChatSettingsSheetState extends State<_ChatSettingsSheet> {
  late bool _muted = widget.detail.muted;
  late bool _archived = widget.detail.archived;
  late bool _pinned = widget.detail.pinned;
  late String _wallpaper = widget.detail.wallpaper ?? 'light';
  late String _theme = widget.detail.bubbleTheme ?? 'p';
  var _receiptsOn = true;

  AppLocalizations get _l10n => widget.l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final isFamily = widget.detail.familyPinnedNote;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _l10n.chatSettingsTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _l10n.chatSettingsScopeNote,
            style: TextStyle(fontSize: 11.5, color: colors.ink2),
          ),
          const SizedBox(height: 12),
          _section(_l10n.chatSettingsMute),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _choice(
                key: 'chat_mute_8h',
                label: _l10n.conversationMuteEightHours,
                selected: _muted,
                onTap: () => _mute(kMuteEightHours),
              ),
              _choice(
                key: 'chat_mute_week',
                label: _l10n.conversationMuteOneWeek,
                selected: _muted,
                onTap: () => _mute(kMuteOneWeek),
              ),
              _choice(
                key: 'chat_mute_forever',
                label: _l10n.conversationMuteForever,
                selected: _muted,
                onTap: () => _mute(null),
              ),
              _choice(
                key: 'chat_unmute',
                label: _l10n.conversationUnmute,
                selected: !_muted,
                onTap: () async {
                  await widget.handlers.onUnmute();
                  if (mounted) setState(() => _muted = false);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('chat_archive_switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              _l10n.chatSettingsArchive,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            value: _archived,
            onChanged: (v) async {
              await widget.handlers.onArchive(v);
              if (mounted) setState(() => _archived = v);
            },
          ),
          SwitchListTile(
            key: const Key('chat_pin_switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              _l10n.chatSettingsPin,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            subtitle: isFamily
                ? Text(
                    _l10n.conversationFamilyAlwaysPinned,
                    style: TextStyle(fontSize: 11, color: colors.ink2),
                  )
                : null,
            value: isFamily ? true : _pinned,
            onChanged: isFamily
                ? null
                : (v) async {
                    await widget.handlers.onPin(v);
                    if (mounted) setState(() => _pinned = v);
                  },
          ),
          const SizedBox(height: 4),
          _section(_l10n.chatSettingsWallpaper),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final w in kWallpapers)
                _choice(
                  key: 'chat_wallpaper_$w',
                  label: _wallpaperLabel(w),
                  selected: _wallpaper == w,
                  swatch: chatWallpaperColor(colors, w) ?? colors.bg,
                  onTap: () => _look(wallpaper: w),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _section(_l10n.chatSettingsBubbleTheme),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final t in kBubbleThemes)
                _choice(
                  key: 'chat_theme_$t',
                  label: _themeLabel(t),
                  selected: _theme == t,
                  swatch: chatBubbleColor(
                    colors: colors,
                    mine: true,
                    tone: ChatTone.parent,
                    theme: t,
                  ),
                  onTap: () => _look(theme: t),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _section(_l10n.chatSettingsReceipts),
          if (widget.detail.receiptsMandatory)
            Row(
              children: [
                Icon(Icons.verified_outlined, size: 16, color: colors.p600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _l10n.chatSettingsReceiptsMandatory,
                    key: const Key('chat_receipts_mandatory'),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: colors.ink2,
                    ),
                  ),
                ),
              ],
            )
          else
            SwitchListTile(
              key: const Key('chat_receipts_switch'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                _l10n.chatSettingsReceiptsOptional,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.ink2,
                ),
              ),
              value: _receiptsOn,
              onChanged: (v) => setState(() => _receiptsOn = v),
            ),
          const SizedBox(height: 8),
          _section(_l10n.chatSettingsLock),
          Text(
            _l10n.chatSettingsLockParentNote,
            key: const Key('chat_lock_parent_note'),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: colors.ink2,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            key: const Key('chat_settings_done'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_l10n.chatSettingsDone),
          ),
        ],
      ),
    );
  }

  Future<void> _mute(Duration? preset) async {
    await widget.handlers.onMute(preset);
    if (mounted) setState(() => _muted = true);
  }

  Future<void> _look({String? wallpaper, String? theme}) async {
    final nextWallpaper = wallpaper ?? _wallpaper;
    final nextTheme = theme ?? _theme;
    await widget.handlers.onLook(nextWallpaper, nextTheme);
    if (!mounted) return;
    setState(() {
      _wallpaper = nextWallpaper;
      _theme = nextTheme;
    });
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).extension<FamilyColors>()!.ink,
          ),
        ),
      );

  Widget _choice({
    required String key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? swatch,
  }) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return ChoiceChip(
      key: Key(key),
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: swatch == null
          ? null
          : CircleAvatar(backgroundColor: swatch, radius: 8),
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      selectedColor: colors.p100,
      backgroundColor: colors.surface,
    );
  }

  String _wallpaperLabel(String w) => switch (w) {
        'rose' => _l10n.chatWallpaperRose,
        'mint' => _l10n.chatWallpaperMint,
        'violet' => _l10n.chatWallpaperViolet,
        _ => _l10n.chatWallpaperLight,
      };

  String _themeLabel(String t) => switch (t) {
        'rose' => _l10n.chatThemeRose,
        'teal' => _l10n.chatThemeTeal,
        _ => _l10n.chatThemeP,
      };
}

/// ARB label for a media bubble, or null for plain text.
String? chatMediaLabel(AppLocalizations l10n, ConversationMediaKind kind) =>
    switch (kind) {
      ConversationMediaKind.text => null,
      ConversationMediaKind.image => l10n.conversationMediaImage,
      ConversationMediaKind.video => l10n.conversationMediaVideo,
      ConversationMediaKind.file => l10n.conversationMediaFile,
      ConversationMediaKind.voice => l10n.conversationMediaVoice,
    };

/// The one-line list preview: a voice note is described in words, never blank.
String chatPreviewText(
  AppLocalizations l10n,
  String preview, {
  required bool isVoice,
}) =>
    isVoice ? l10n.conversationMediaVoice : preview;

/// The edit dialog (S-COM-006). A StatefulWidget so the controller lives and
/// dies with the dialog, never disposed out from under the close animation.
class EditMessageDialog extends StatefulWidget {
  const EditMessageDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.initialText,
    required this.saveLabel,
    required this.cancelLabel,
    this.fieldKey,
  });

  final String title;
  final String hint;
  final String initialText;
  final String saveLabel;
  final String cancelLabel;
  final Key? fieldKey;

  @override
  State<EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<EditMessageDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: widget.fieldKey,
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}
