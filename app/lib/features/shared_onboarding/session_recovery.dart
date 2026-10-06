import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Guardian onboarding steps that may be resumed after the provider asks for
/// credentials again. Keeping this list narrow prevents the login route from
/// becoming an open redirect to arbitrary app or web locations.
const Set<String> _resumableGuardianPaths = {
  '/scr-fat-001',
  '/scr-fat-002',
  '/scr-fat-003',
  '/scr-fat-004',
};

final RegExp _serverChildId = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Returns a canonical local resume location, or `null` when [raw] is not a
/// supported onboarding step.
///
/// Only the server child identifier needed by the pairing step survives. Any
/// unrelated query values, fragments, authorities, or external schemes are
/// discarded instead of being reflected into navigation.
String? safeGuardianResumeLocation(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final uri = Uri.tryParse(raw.trim());
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.userInfo.isNotEmpty ||
      uri.fragment.isNotEmpty ||
      !_resumableGuardianPaths.contains(uri.path)) {
    return null;
  }

  if (uri.path != '/scr-fat-004') return Uri(path: uri.path).toString();

  final childId = uri.queryParameters['childId']?.trim();
  if (childId == null || !_serverChildId.hasMatch(childId)) return null;
  return Uri(
    path: uri.path,
    queryParameters: {
      'childId': childId,
      if (uri.queryParameters['source'] == 'server') 'source': 'server',
    },
  ).toString();
}

/// Builds the only login deep link allowed to carry a resume destination.
String guardianSessionRecoveryLoginLocation(String currentLocation) {
  final resume = safeGuardianResumeLocation(currentLocation);
  return Uri(
    path: '/scr-shr-003',
    queryParameters: {if (resume != null) 'resume': resume},
  ).toString();
}

/// Opens re-authentication above the current step so its widget state (typed
/// names, selected age, and idempotency key) remains in memory. A successful
/// login pops with `true`; backing out returns `null`.
Future<bool?> pushGuardianSessionRecovery(BuildContext context) {
  final current = GoRouterState.of(context).uri.toString();
  return context.push<bool>(guardianSessionRecoveryLoginLocation(current));
}
