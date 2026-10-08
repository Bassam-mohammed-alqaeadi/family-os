import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/family_chat_local_store.dart';

/// Localizes known OD-09 seeded thread labels (title stored as wire key).
String localizedConversationThreadTitle(
  AppLocalizations l10n,
  String chatWith,
  String storedTitle, {
  String? threadKind,
  bool? isFamilyThread,
}) {
  if (chatWith == FamilyChatLocalStore.familyChatWith ||
      storedTitle == FamilyChatLocalStore.familyChatWith) {
    return l10n.conversationsListFamilyThreadTitle;
  }
  if (storedTitle.trim().isNotEmpty) return storedTitle;
  if (isFamilyThread == true || threadKind == 'family') {
    return l10n.familyChatFamilyThread;
  }
  if (isFamilyThread == false || threadKind == 'child') {
    return l10n.familyChatChildThread;
  }
  return storedTitle;
}

/// A membership's stable role id is not a person's name. Show a localized generic role rather
/// than leaking wire identifiers such as `primary_guardian` into a message bubble.
String? localizedFamilyChatSenderLabel(
  AppLocalizations l10n,
  String? senderLabel,
) {
  if (senderLabel == null) return null;
  return switch (senderLabel) {
    'primary_guardian' || 'co_guardian' => l10n.dayBoardGuardianFallback,
    'child' => l10n.familyChatChildFallback,
    _ => senderLabel,
  };
}

String localizedConversationThreadPreview(
  AppLocalizations l10n,
  String chatWith,
  String storedPreview,
) {
  if (storedPreview.trim().isEmpty &&
      chatWith == FamilyChatLocalStore.familyChatWith) {
    return l10n.conversationsListFamilyThreadPreview;
  }
  return storedPreview;
}
