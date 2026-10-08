import 'package:flutter/material.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n02_day/family_chat_server_authority.dart';
import 'package:family_os/features/n02_day/family_chat_server_repository.dart';

/// Explicit connection/permission states for the chat screens. Access remains server-authoritative.
enum FamilyChatConnectionState {
  checking,
  connected,
  reconnecting,
  offline,
  unavailable,
  permissionDenied,
  requestRejected,
}

bool familyChatFailureRequiresDiscard(Object error) {
  if (error is! FamilyChatRepositoryFailure) return false;
  if (error.status == FamilyChatAuthorityStatus.notConfigured ||
      error.status == FamilyChatAuthorityStatus.accessDenied) {
    return true;
  }
  return error.status == FamilyChatAuthorityStatus.refused &&
      error.statusCode == 404 &&
      error.serverCode == 'chat_thread_not_found';
}

FamilyChatConnectionState familyChatConnectionStateFor(Object error) {
  if (error is! FamilyChatRepositoryFailure) {
    return FamilyChatConnectionState.offline;
  }
  return switch (error.status) {
    FamilyChatAuthorityStatus.ready => FamilyChatConnectionState.connected,
    FamilyChatAuthorityStatus.notConfigured =>
      FamilyChatConnectionState.unavailable,
    FamilyChatAuthorityStatus.accessDenied =>
      FamilyChatConnectionState.permissionDenied,
    FamilyChatAuthorityStatus.unreachable => FamilyChatConnectionState.offline,
    FamilyChatAuthorityStatus.refused =>
      FamilyChatConnectionState.requestRejected,
  };
}

String? familyChatConnectionMessage(
  AppLocalizations l10n,
  FamilyChatConnectionState state,
) => switch (state) {
  FamilyChatConnectionState.checking => l10n.familyChatConnecting,
  FamilyChatConnectionState.connected => null,
  FamilyChatConnectionState.reconnecting => l10n.familyChatReconnecting,
  FamilyChatConnectionState.offline => l10n.familyChatOffline,
  FamilyChatConnectionState.unavailable => l10n.familyChatUnavailable,
  FamilyChatConnectionState.permissionDenied => l10n.familyChatPermissionDenied,
  FamilyChatConnectionState.requestRejected => l10n.familyChatRequestRejected,
};

class FamilyChatConnectionBanner extends StatelessWidget {
  const FamilyChatConnectionBanner({
    required this.state,
    required this.onRetry,
    super.key,
  });

  final FamilyChatConnectionState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = familyChatConnectionMessage(
      AppLocalizations.of(context),
      state,
    );
    if (message == null) return const SizedBox.shrink();
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 8, 10),
          child: Row(
            children: [
              Icon(
                state == FamilyChatConnectionState.permissionDenied
                    ? Icons.lock_outline
                    : Icons.cloud_off_outlined,
                size: 18,
                color: colors.ink2,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                    height: 1.35,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  tapTargetSize: MaterialTapTargetSize.padded,
                  foregroundColor: colors.tealDeep,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(AppLocalizations.of(context).familyChatRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
