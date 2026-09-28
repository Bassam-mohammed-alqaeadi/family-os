import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/family_chat_local_store.dart';

/// Localizes known OD-09 seeded thread labels (title stored as wire key).
String localizedConversationThreadTitle(
  AppLocalizations l10n,
  String chatWith,
  String storedTitle,
) {
  if (chatWith == FamilyChatLocalStore.familyChatWith ||
      storedTitle == FamilyChatLocalStore.familyChatWith) {
    return l10n.conversationsListFamilyThreadTitle;
  }
  return storedTitle;
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
