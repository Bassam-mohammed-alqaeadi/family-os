import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/core/data/communication_rules.dart';

/// PERS-2d — the contract's own rules for chat, suggestions and the AI layer.
///
/// Each of these is a promise: an edit window, a ten-minute undo, an alias
/// instead of a name, an excerpt instead of an archive. They are tested because
/// a promise nobody checks is a promise nobody keeps.
void main() {
  group('the message edit window (S-COM-006)', () {
    final sent = DateTime(2026, 9, 24, 12);

    test('a message is editable for fifteen minutes, not sixteen', () {
      expect(
        messageIsEditable(
          sentAt: sent,
          now: sent.add(const Duration(minutes: 14)),
        ),
        isTrue,
      );
      expect(
        messageIsEditable(
          sentAt: sent,
          now: sent.add(const Duration(minutes: 15)),
        ),
        isFalse,
      );
    });

    test('a deleted message is not editable', () {
      expect(
        messageIsEditable(sentAt: sent, now: sent, deleted: true),
        isFalse,
      );
    });

    test('only the author edits, and only inside the window', () {
      expect(
        senderMayEdit(
          senderKey: 'child-1',
          actorKey: 'child-1',
          sentAt: sent,
          now: sent.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
      expect(
        senderMayEdit(
          senderKey: 'child-1',
          actorKey: 'acc-parent',
          sentAt: sent,
          now: sent.add(const Duration(minutes: 5)),
        ),
        isFalse,
        reason: 'a parent does not edit a child\'s words',
      );
      expect(
        senderMayEdit(
          senderKey: 'child-1',
          actorKey: 'child-1',
          sentAt: sent,
          now: sent.add(const Duration(minutes: 30)),
        ),
        isFalse,
      );
    });

    test('a tombstone is hidden from the reader but kept as a row', () {
      expect(messageIsVisible(deleted: true), isFalse);
      expect(messageIsVisible(deleted: false), isTrue);
    });
  });

  group('the suggestion undo window', () {
    final applied = DateTime(2026, 9, 24, 12);

    test('undo is possible for ten minutes and not beyond', () {
      expect(
        suggestionIsUndoable(
          appliedAt: applied,
          now: applied.add(const Duration(minutes: 9)),
        ),
        isTrue,
      );
      expect(
        suggestionIsUndoable(
          appliedAt: applied,
          now: applied.add(const Duration(minutes: 10)),
        ),
        isFalse,
      );
    });

    test('an undone or dismissed suggestion cannot be undone again', () {
      expect(
        suggestionIsUndoable(
          appliedAt: applied,
          now: applied.add(const Duration(minutes: 1)),
          undone: true,
        ),
        isFalse,
      );
      expect(
        suggestionIsUndoable(
          appliedAt: applied,
          now: applied.add(const Duration(minutes: 1)),
          dismissed: true,
        ),
        isFalse,
      );
    });
  });

  group('value sets are enforced where the row is written', () {
    test('one action must be filled in — a menu has no column to live in', () {
      expect(
        () => requireAction(label: '  ', kind: 'RULE'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => requireAction(label: 'اسأل', kind: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(() => requireAction(label: 'اسأل', kind: 'RULE'), returnsNormally);
    });

    test('the AI layer needs an alias, never a name', () {
      expect(() => requireAlias(''), throwsA(isA<ArgumentError>()));
      expect(() => requireAlias('lion-01'), returnsNormally);
    });

    test('domain and severity stay inside their sets', () {
      for (final domain in kAiDomains) {
        expect(() => requireDomain(domain), returnsNormally);
      }
      expect(() => requireDomain('FIN'), throwsA(isA<ArgumentError>()));

      expect(() => requireSeverity(0), throwsA(isA<ArgumentError>()));
      expect(() => requireSeverity(6), throwsA(isA<ArgumentError>()));
      expect(() => requireSeverity(5), returnsNormally);
    });

    test('the payload is an excerpt, not an archive (S-AIC-006)', () {
      expect(
        () => requireExcerpt('x' * (kMaxPayloadChars + 1)),
        throwsA(isA<ArgumentError>()),
      );
      expect(() => requireExcerpt('x' * kMaxPayloadChars), returnsNormally);
    });

    test('a jsonb column only accepts JSON', () {
      expect(() => requireJson('{"a":1}'), returnsNormally);
      expect(() => requireJson('not json'), throwsA(isA<ArgumentError>()));
    });

    test('call kind and outcome stay inside their sets', () {
      for (final kind in kCallKinds) {
        expect(() => requireCallKind(kind), returnsNormally);
      }
      expect(() => requireCallKind('HOLOGRAM'), throwsA(isA<ArgumentError>()));

      for (final outcome in kCallOutcomes) {
        expect(() => requireCallOutcome(outcome), returnsNormally);
      }
      expect(
        () => requireCallOutcome('IGNORED'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
