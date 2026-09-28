import 'package:flutter_test/flutter_test.dart';

import 'package:family_os/features/n02_day/day_board_projection.dart';

void main() {
  test('importanceLadder sorts by kind rank, stable within kind', () {
    const athkar = DayBoardPendingRequest(
      id: 'a1',
      titleKey: 'athkarBlessing',
      kind: DayBoardPendingKind.athkar,
    );
    const time = DayBoardPendingRequest(
      id: 't1',
      titleKey: 'timeRequest',
      kind: DayBoardPendingKind.time,
    );
    const friend = DayBoardPendingRequest(
      id: 'f1',
      titleKey: 'friendRequest',
      kind: DayBoardPendingKind.friend,
    );
    const sos = DayBoardPendingRequest(id: 's1', kind: DayBoardPendingKind.sos);
    const time2 = DayBoardPendingRequest(
      id: 't2',
      titleKey: 'timeRequest',
      kind: DayBoardPendingKind.time,
    );

    const p = DayBoardProjection(
      pendingRequests: [athkar, time, friend, sos, time2],
    );

    expect(p.importanceLadder.map((e) => e.id).toList(), [
      's1',
      'f1',
      't1',
      't2',
      'a1',
    ]);
    expect(p.primaryPending!.id, 's1');
  });

  test('empty ladder → null primary', () {
    expect(DayBoardProjection.empty.importanceLadder, isEmpty);
    expect(DayBoardProjection.empty.primaryPending, isNull);
  });
}
