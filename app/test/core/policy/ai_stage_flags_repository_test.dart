import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/policy/ai_stage_flags.dart';
import 'package:family_os/core/policy/ai_stage_flags_repository.dart';
import 'package:family_os/core/policy/ai_stage_id.dart';
import 'package:family_os/core/policy/advisor_repository.dart';

void main() {
  group('AiStageFlagsRepository', () {
    test('fetchFlags caches server snapshot', () async {
      final repo = MockRemoteAiStageFlags(
        initialServer: AiStageFlags.fromMap({
          AiStageId.suggest: true,
          AiStageId.analyze: false,
          AiStageId.coach: false,
        }),
        cache: MemoryAiStageFlagsCacheStore(),
      );

      final flags = await repo.fetchFlags();
      expect(flags.isEnabled(AiStageId.suggest), isTrue);
      expect(flags.isEnabled(AiStageId.analyze), isFalse);
      expect(repo.cachedFlags, flags);

      final offline = await repo.loadCachedOrOff();
      expect(offline.isEnabled(AiStageId.suggest), isTrue);
    });

    test('setLocalEnableInference always throws', () {
      final repo = MockRemoteAiStageFlags();
      expect(
        () => repo.setLocalEnableInference(AiStageId.suggest, enable: true),
        throwsA(isA<UnsupportedError>()),
      );
      expect(repo.cachedFlags, isNull);
    });

    test('simulateServerPush is the only unlock path', () async {
      final repo = MockRemoteAiStageFlags(
        initialServer: AiStageFlags.allOff(),
      );
      expect((await repo.fetchFlags()).isEnabled(AiStageId.suggest), isFalse);

      repo.simulateServerPush(
        AiStageFlags.fromMap({AiStageId.suggest: true}),
      );
      expect((await repo.fetchFlags()).isEnabled(AiStageId.suggest), isTrue);
    });
  });

  group('MockAdvisorRepository', () {
    test('suggestions are prototype-only (Rule 26)', () async {
      const advisor = MockAdvisorRepository();
      final list = await advisor.suggestions();
      expect(list, isNotEmpty);
      expect(list.first.id, 'sug-bedtime');
      expect(list.length, MockAdvisorRepository.prototypeSuggestions.length);
    });
  });

  group('architecture — no on-device inference', () {
    test('lib has no OnDeviceInference / runLocalModel symbols', () {
      final lib = Directory('lib');
      expect(lib.existsSync(), isTrue);

      final offenders = <String>[];
      for (final entity in lib.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final text = entity.readAsStringSync();
        if (text.contains('OnDeviceInference') ||
            text.contains('runLocalModel') ||
            text.contains('LocalInferenceService') ||
            text.contains('enableOnDeviceBrain')) {
          offenders.add(entity.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Forbidden on-device inference symbols in: $offenders',
      );
    });
  });
}
