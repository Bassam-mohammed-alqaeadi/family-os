import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:family_os/core/design/components/banner.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/domain/child_id.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n15_calendar/calendar_server_authority.dart';
import 'package:family_os/features/n02_day/family_chat_server_authority.dart';
import 'package:family_os/foundation_gate/family_chat_api_client.dart';
import 'package:family_os/foundation_gate/family_calendar_api_client.dart';
import 'package:family_os/foundation_gate/foundation_gate_configuration.dart';

/// One child this family can invite, as the roster the screen already read knows them.
///
/// The panel takes the roster as a parameter rather than reading one itself: two readers of
/// the same roster would eventually disagree, and the screen that draws the child's name is
/// the one that already knows it.
@immutable
class CalendarChild {
  const CalendarChild({required this.id, required this.label});

  final ChildId id;
  final String label;
}

/// W8 — the family's calendar, rendered for the guardian who keeps it.
///
/// Four cards, and each one says only what the server said:
///
///   * the events themselves, INCLUDING the ones that were called off with their reason -
///     a calendar that hid a cancellation would leave a child waiting at a door - and the
///     audience of each with the answer and the attendance that actually exist;
///   * the answer a child gave in words, recorded for ONE named child, because an answer
///     belongs to a person;
///   * what actually happened, recorded by a person after the event started - there is no
///     field here for a location, because presence read from a phone is the surveillance this
///     product refuses to be;
///   * a place to state a new event, with who it is for stated in the same breath.
///
/// What this panel deliberately does not do: it does not offer to answer for an event that has
/// already started, it does not offer to record attendance before there is anything to record,
/// it does not edit a cancelled event, and it never claims a reminder was delivered - a
/// reminder here is a preference the family recorded, and the footnote under the events says so
/// rather than implying otherwise.
class CalendarServerPanel extends StatefulWidget {
  const CalendarServerPanel({
    super.key,
    required this.children,
    this.authority,
    this.canEdit = true,
    this.idempotencyKey,
    this.windowDays = 60,
  });

  final List<CalendarChild> children;

  /// Bound at boot in the real app; passed explicitly by tests.
  final CalendarServerAuthority? authority;

  final bool canEdit;

  /// A key per write. In production it is derived from the action and the row so a retried
  /// tap is the same request; a screen that invented a new key per attempt would be asking
  /// the server to do the work twice.
  final String Function()? idempotencyKey;

  /// How far ahead the read looks. A window, not "everything": the server refuses a read
  /// without one, and a family that wants a year should say a year.
  final int windowDays;

  @override
  State<CalendarServerPanel> createState() => _CalendarServerPanelState();
}

class _CalendarServerPanelState extends State<CalendarServerPanel> {
  CalendarAuthorityStatus? _status;
  FoundationGateFamilyCalendar? _calendar;
  bool _busy = false;

  String? _answerEventId;
  String? _answerChildId;
  String? _attendanceEventId;
  String? _attendanceChildId;
  final Set<String> _createChildIds = <String>{};
  List<FamilyChatThread> _collaborationThreads = const <FamilyChatThread>[];
  String? _createAudienceThreadId;

  final TextEditingController _answerNoteCtrl = TextEditingController();
  final TextEditingController _attendanceNoteCtrl = TextEditingController();
  final TextEditingController _createTitleCtrl = TextEditingController();
  final TextEditingController _createLocationCtrl = TextEditingController();
  final TextEditingController _createNoteCtrl = TextEditingController();
  final TextEditingController _createReminderCtrl = TextEditingController(text: '60');

  DateTime? _createStart;
  DateTime? _createEnd;

  CalendarServerAuthority? get _authority =>
      widget.authority ?? activeCalendarServerAuthority;

  /// The children this build can name to the server. A stage-1 key like `k1` is a local
  /// identity, not a server row: offering it in a form would collect a plan this build cannot
  /// keep, so those children are not offered as choices at all. The week itself still reads -
  /// the family is what the window asks about, not the children.
  List<CalendarChild> get _addressableChildren => [
    for (final child in widget.children)
      if (isFoundationGateUuid(child.id.value)) child,
  ];

  bool get _canWrite =>
      widget.canEdit &&
      _addressableChildren.isNotEmpty &&
      _status == CalendarAuthorityStatus.ready;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCollaborationThreads();
  }

  @override
  void didUpdateWidget(covariant CalendarServerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The screen this panel lives in can stay open while the family changes which children
    // are on screen. Reading again is the only honest reaction: the previous family's plans
    // must not remain on screen under the new family's name, not even for the frame it takes
    // to ask.
    if (!listEquals(
          oldWidget.children.map((child) => child.id).toList(growable: false),
          widget.children.map((child) => child.id).toList(growable: false),
        ) ||
        oldWidget.authority != widget.authority ||
        oldWidget.windowDays != widget.windowDays) {
      _load();
    }
  }

  @override
  void dispose() {
    _answerNoteCtrl.dispose();
    _attendanceNoteCtrl.dispose();
    _createTitleCtrl.dispose();
    _createLocationCtrl.dispose();
    _createNoteCtrl.dispose();
    _createReminderCtrl.dispose();
    super.dispose();
  }

  String _key(String scope) =>
      widget.idempotencyKey?.call() ??
      'w8-$scope-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _load() async {
    final authority = _authority;
    if (authority == null) {
      setState(() => _status = CalendarAuthorityStatus.notConfigured);
      return;
    }
    setState(() => _busy = true);
    final now = DateTime.now();
    final answer = await authority.listEvents(
      from: now.subtract(const Duration(days: 1)),
      to: now.add(Duration(days: widget.windowDays)),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = answer.status;
      if (answer.isReady) _calendar = answer.value;
    });
  }

  Future<void> _loadCollaborationThreads() async {
    final chatAuthority = activeFamilyChatServerAuthority;
    if (chatAuthority == null) return;
    final answer = await chatAuthority.listGuardianThreads();
    if (!mounted || !answer.isReady) return;
    setState(() {
      _collaborationThreads = answer.value!.threads
          .where((thread) =>
              thread.kind == FamilyChatThreadKind.direct ||
              thread.kind == FamilyChatThreadKind.group)
          .toList(growable: false);
      if (!_collaborationThreads.any((thread) => thread.id == _createAudienceThreadId)) {
        _createAudienceThreadId = null;
      }
    });
  }

  Future<void> _recordAnswer(FoundationGateFamilyEvent event) async {
    final authority = _authority;
    if (authority == null || !widget.canEdit) return;
    final childId = _answerChildId;
    if (childId == null) return;
    setState(() => _busy = true);
    final answer = await authority.recordResponse(
      childId: childId,
      eventId: event.id,
      answer: _answerIsYes
          ? FoundationGateEventAnswer.accepted
          : FoundationGateEventAnswer.declined,
      note: _answerNoteCtrl.text.trim(),
      idempotencyKey: () => _key('answer-${event.id}-$childId'),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = answer.status;
    });
    if (answer.isReady) {
      _answerNoteCtrl.clear();
      await _load();
    }
  }

  bool _answerIsYes = true;

  Future<void> _recordAttendance() async {
    final authority = _authority;
    if (authority == null || !widget.canEdit) return;
    final eventId = _attendanceEventId;
    final childId = _attendanceChildId;
    if (eventId == null || childId == null) return;
    setState(() => _busy = true);
    final answer = await authority.recordAttendance(
      eventId: eventId,
      childId: childId,
      attended: _attendanceWasPresent,
      note: _attendanceNoteCtrl.text.trim(),
      idempotencyKey: () => _key('attendance-$eventId-$childId'),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = answer.status;
    });
    if (answer.isReady) {
      _attendanceNoteCtrl.clear();
      await _load();
    }
  }

  bool _attendanceWasPresent = true;

  Future<void> _cancel(FoundationGateFamilyEvent event) async {
    final authority = _authority;
    if (authority == null || !widget.canEdit) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _CancelDialog(),
    );
    if (reason == null || reason.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => _busy = true);
    final answer = await authority.cancelEvent(
      eventId: event.id,
      reason: reason.trim(),
      idempotencyKey: () => _key('cancel-${event.id}'),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = answer.status;
    });
    if (answer.isReady) await _load();
  }

  Future<void> _pickStart() async {
    final picked = await _pickDateTime(_createStart);
    if (picked == null) return;
    setState(() {
      _createStart = picked;
      // The end follows the start unless the family said otherwise: an event that ended
      // before it began would be refused by the server, and a form that offered that
      // refusal is a form that wasted a tap.
      if (_createEnd == null || !_createEnd!.isAfter(picked)) {
        _createEnd = picked.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final picked = await _pickDateTime(_createEnd);
    if (picked == null) return;
    setState(() => _createEnd = picked);
  }

  Future<DateTime?> _pickDateTime(DateTime? current) async {
    final base = current ?? DateTime.now().add(const Duration(hours: 2));
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _create() async {
    final authority = _authority;
    if (authority == null || !widget.canEdit) return;
    final title = _createTitleCtrl.text.trim();
    final start = _createStart;
    final end = _createEnd;
    if (title.isEmpty || start == null || end == null) return;
    if (_createChildIds.isEmpty && _createAudienceThreadId == null) return;
    if (_createChildIds.isNotEmpty &&
        !_addressableChildren.any(
          (child) => _createChildIds.contains(child.id.value),
        )) {
      return;
    }
    if (!end.isAfter(start)) return;
    setState(() => _busy = true);
    final answer = await authority.createEvent(
      title: title,
      note: _createNoteCtrl.text.trim(),
      location: _createLocationCtrl.text.trim(),
      startsAt: start,
      endsAt: end,
      reminderMinutes: int.tryParse(_createReminderCtrl.text.trim()),
      childIds: _createChildIds.toList(growable: false),
      audienceThreadId: _createAudienceThreadId,
      idempotencyKey: () => _key('create'),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = answer.status;
      if (answer.isReady) {
        _createTitleCtrl.clear();
        _createLocationCtrl.clear();
        _createNoteCtrl.clear();
        _createChildIds.clear();
        _createAudienceThreadId = null;
        _createStart = null;
        _createEnd = null;
      }
    });
    if (answer.isReady) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final status = _status;
    if (status == null) {
      return const SizedBox.shrink();
    }
    final banner = _statusBanner(l10n, status);
    final calendar = _calendar;
    final now = DateTime.now();
    return Column(
      key: const Key('calendar_server_panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (banner != null) ...[banner, const SizedBox(height: 12)],
        if (calendar != null) ...[
          _eventsCard(l10n, colors, calendar),
          const SizedBox(height: 12),
          if (_canWrite) ...[
            _answerCard(l10n, colors, calendar, now),
            const SizedBox(height: 12),
            _attendanceCard(l10n, colors, calendar, now),
            const SizedBox(height: 12),
            _createCard(l10n, colors),
          ] else if (status == CalendarAuthorityStatus.ready) ...[
            // Two different silences, and each says its own thing: a reader who may not write
            // reads what is there, and a build whose children have no server rows yet says
            // exactly that instead of collecting a plan it cannot record.
            Text(
              widget.canEdit
                  ? l10n.calendarServerNoAddressableChildren
                  : l10n.calendarServerPanelNote,
              key: const Key('calendar_server_read_only_note'),
              style: TextStyle(fontSize: 12, color: colors.ink2),
            ),
          ],
        ],
      ],
    );
  }

  Widget? _statusBanner(AppLocalizations l10n, CalendarAuthorityStatus status) {
    // The same honest four as the waves before it. There is deliberately no "we will keep a
    // local calendar for now": a family reading a plan needs to know whether a person stated
    // it, not how hard the app is trying.
    final (String? message, BannerVariant variant) = switch (status) {
      CalendarAuthorityStatus.ready => (null, BannerVariant.g),
      CalendarAuthorityStatus.notConfigured => (
        l10n.calendarServerNoSession,
        BannerVariant.t,
      ),
      CalendarAuthorityStatus.accessDenied => (
        l10n.calendarServerDenied,
        BannerVariant.a,
      ),
      // A refusal keeps the last true reading on screen and says that it is the last one: a
      // screen that emptied itself on a 409 would look like a family with nothing planned.
      CalendarAuthorityStatus.refused => (
        l10n.calendarServerRefused,
        BannerVariant.a,
      ),
      CalendarAuthorityStatus.unreachable => (
        l10n.calendarServerUnreachable,
        BannerVariant.a,
      ),
    };
    if (message == null) return null;
    return BannerNote(
      key: Key('calendar_server_${status.name}'),
      variant: variant,
      message: message,
    );
  }

  String _childLabel(String childId) {
    for (final child in widget.children) {
      if (child.id.value == childId) return child.label;
    }
    // A child the roster has not loaded yet is named by nothing rather than by a guess: the
    // row is drawn, the name is not invented.
    return '';
  }

  Widget _eventsCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateFamilyCalendar calendar,
  ) {
    final material = MaterialLocalizations.of(context);
    return Card(
      key: const Key('calendar_server_events_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.calendarServerEventsHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 6),
            if (calendar.events.isEmpty)
              Text(
                l10n.calendarServerEventsEmpty,
                key: const Key('calendar_server_events_empty'),
                style: TextStyle(fontSize: 12, color: colors.ink2),
              )
            else
              for (final event in calendar.events)
                _eventRow(l10n, material, colors, event),
            const SizedBox(height: 6),
            Text(
              l10n.calendarServerReminderNote,
              key: const Key('calendar_server_reminder_note'),
              style: TextStyle(fontSize: 12, color: colors.ink2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventRow(
    AppLocalizations l10n,
    MaterialLocalizations material,
    FamilyColors colors,
    FoundationGateFamilyEvent event,
  ) {
    return Padding(
      key: Key('calendar_server_event_${event.id}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${material.formatMediumDate(event.startsAt.toLocal())} '
            '${material.formatTimeOfDay(TimeOfDay.fromDateTime(event.startsAt.toLocal()))}',
            style: TextStyle(fontSize: 12, color: colors.ink2),
          ),
          if (event.location.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              event.location,
              style: TextStyle(fontSize: 12, color: colors.ink2),
            ),
          ],
          if (event.isCancelled) ...[
            const SizedBox(height: 4),
            Text(
              l10n.calendarServerEventCancelled,
              key: Key('calendar_server_event_cancelled_${event.id}'),
              style: TextStyle(fontSize: 12, color: colors.coral),
            ),
            if (event.cancelReason.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '${l10n.calendarServerEventCancelReason}: '
                '${event.cancelReason}',
                key: Key('calendar_server_event_reason_${event.id}'),
                style: TextStyle(fontSize: 12, color: colors.ink2),
              ),
            ],
          ],
          const SizedBox(height: 4),
          Text(
            l10n.calendarServerEventAudienceHeading,
            style: TextStyle(fontSize: 12, color: colors.ink2),
          ),
          for (final entry in event.audience)
            Text(
              // A child the roster has not loaded yet is drawn as a state without a name:
              // the row is real, and the name is the one thing this screen must not invent.
              _line(l10n, entry),
              key: Key(
                'calendar_server_audience_${event.id}_${entry.childId}',
              ),
              style: TextStyle(fontSize: 12, color: colors.ink),
            ),
          if (_canWrite && !event.isCancelled) ...[
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: Key('calendar_server_cancel_${event.id}'),
                onPressed: _busy ? null : () => _cancel(event),
                child: Text(l10n.calendarServerCancelButton),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// One audience line: the child's name when the roster knows it, then the state.
  String _line(AppLocalizations l10n, FoundationGateEventAudienceEntry entry) {
    final label = _childLabel(entry.childId);
    final state = _audienceState(l10n, entry);
    return label.isEmpty ? state : '$label: $state';
  }

  /// What is actually stored about one child, said in words.
  ///
  /// What happened outranks what was said would happen: a person recorded the attendance after
  /// the evening, and that is the fact. Until then the line carries the answer, and a child who
  /// has said nothing reads as having said nothing - never as a person who is not coming.
  String _audienceState(
    AppLocalizations l10n,
    FoundationGateEventAudienceEntry entry,
  ) {
    final attendance = entry.attendance;
    if (attendance != null) {
      return attendance.attended
          ? l10n.calendarServerAudienceAttended
          : l10n.calendarServerAudienceAbsent;
    }
    return switch (entry.response?.answer) {
      FoundationGateEventAnswer.accepted => l10n.calendarServerAudienceAccepted,
      FoundationGateEventAnswer.declined => l10n.calendarServerAudienceDeclined,
      null => l10n.calendarServerAudienceWaiting,
    };
  }

  Widget _answerCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateFamilyCalendar calendar,
    DateTime now,
  ) {
    // Only events that have not started: "will you come" is over once it has, and what
    // happened is asked with the attendance card instead.
    final open = calendar.scheduled
        .where((event) => event.startsAt.isAfter(now))
        .toList(growable: false);
    return Card(
      key: const Key('calendar_server_answer_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.calendarServerAnswerHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('calendar_server_answer_event'),
                value: open.any((event) => event.id == _answerEventId)
                    ? _answerEventId
                    : null,
                isExpanded: true,
                items: [
                  for (final event in open)
                    DropdownMenuItem<String>(
                      value: event.id,
                      child: Text(event.title),
                    ),
                ],
                onChanged: (value) => setState(() => _answerEventId = value),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('calendar_server_answer_child'),
                value: _addressableChildren.any(
                  (child) => child.id.value == _answerChildId,
                )
                    ? _answerChildId
                    : null,
                isExpanded: true,
                items: [
                  for (final child in _addressableChildren)
                    DropdownMenuItem<String>(
                      value: child.id.value,
                      child: Text(child.label),
                    ),
                ],
                onChanged: (value) => setState(() => _answerChildId = value),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('calendar_server_answer_note'),
              controller: _answerNoteCtrl,
              decoration: InputDecoration(
                hintText: l10n.calendarServerAnswerNoteHint,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  key: const Key('calendar_server_answer_yes'),
                  onPressed: _busy
                      ? null
                      : () {
                          _answerIsYes = true;
                          final event = _eventById(open);
                          if (event != null) _recordAnswer(event);
                        },
                  child: Text(l10n.calendarServerAudienceAccepted),
                ),
                TextButton(
                  key: const Key('calendar_server_answer_no'),
                  onPressed: _busy
                      ? null
                      : () {
                          _answerIsYes = false;
                          final event = _eventById(open);
                          if (event != null) _recordAnswer(event);
                        },
                  child: Text(l10n.calendarServerAudienceDeclined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  FoundationGateFamilyEvent? _eventById(List<FoundationGateFamilyEvent> events) {
    for (final event in events) {
      if (event.id == _answerEventId) return event;
    }
    return null;
  }

  Widget _attendanceCard(
    AppLocalizations l10n,
    FamilyColors colors,
    FoundationGateFamilyCalendar calendar,
    DateTime now,
  ) {
    // Only events that have started and still stand: before it starts there is nothing to
    // record, and a cancelled event has nothing to record about it.
    final began = calendar.scheduled
        .where((event) => !event.startsAt.isAfter(now))
        .toList(growable: false);
    return Card(
      key: const Key('calendar_server_attendance_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.calendarServerAttendanceHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('calendar_server_attendance_event'),
                value: began.any((event) => event.id == _attendanceEventId)
                    ? _attendanceEventId
                    : null,
                isExpanded: true,
                items: [
                  for (final event in began)
                    DropdownMenuItem<String>(
                      value: event.id,
                      child: Text(event.title),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _attendanceEventId = value),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('calendar_server_attendance_child'),
                value: _addressableChildren.any(
                  (child) => child.id.value == _attendanceChildId,
                )
                    ? _attendanceChildId
                    : null,
                isExpanded: true,
                items: [
                  for (final child in _addressableChildren)
                    DropdownMenuItem<String>(
                      value: child.id.value,
                      child: Text(child.label),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _attendanceChildId = value),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('calendar_server_attendance_note'),
              controller: _attendanceNoteCtrl,
              decoration: InputDecoration(
                hintText: l10n.calendarServerAttendanceNoteHint,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  key: const Key('calendar_server_attendance_present'),
                  onPressed: _busy
                      ? null
                      : () {
                          _attendanceWasPresent = true;
                          _recordAttendance();
                        },
                  child: Text(l10n.calendarServerAudienceAttended),
                ),
                TextButton(
                  key: const Key('calendar_server_attendance_absent'),
                  onPressed: _busy
                      ? null
                      : () {
                          _attendanceWasPresent = false;
                          _recordAttendance();
                        },
                  child: Text(l10n.calendarServerAudienceAbsent),
                ),
                Text(
                  l10n.calendarServerAttendanceRecordButton,
                  style: TextStyle(fontSize: 12, color: colors.ink2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _createCard(AppLocalizations l10n, FamilyColors colors) {
    final material = MaterialLocalizations.of(context);
    final start = _createStart;
    final end = _createEnd;
    return Card(
      key: const Key('calendar_server_create_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.calendarServerCreateHeading,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('calendar_server_create_title'),
              controller: _createTitleCtrl,
              decoration: InputDecoration(
                hintText: l10n.calendarServerCreateTitle,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('calendar_server_create_location'),
              controller: _createLocationCtrl,
              decoration: InputDecoration(
                hintText: l10n.calendarServerCreateLocation,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('calendar_server_create_note'),
              controller: _createNoteCtrl,
              decoration: InputDecoration(
                hintText: l10n.calendarServerCreateNoteHint,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  key: const Key('calendar_server_create_start'),
                  onPressed: _busy ? null : _pickStart,
                  child: Text(
                    start == null
                        ? l10n.calendarServerCreatePickStart
                        : '${material.formatMediumDate(start)} '
                              '${material.formatTimeOfDay(TimeOfDay.fromDateTime(start))}',
                  ),
                ),
                TextButton(
                  key: const Key('calendar_server_create_end'),
                  onPressed: _busy ? null : _pickEnd,
                  child: Text(
                    end == null
                        ? l10n.calendarServerCreatePickEnd
                        : '${material.formatMediumDate(end)} '
                              '${material.formatTimeOfDay(TimeOfDay.fromDateTime(end))}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              key: const Key('calendar_server_create_reminder'),
              controller: _createReminderCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: l10n.calendarServerCreateReminder,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const Key('calendar_server_create_audience_thread'),
              initialValue: _createAudienceThreadId ?? '',
              decoration: InputDecoration(
                labelText: l10n.calendarServerAudienceScopeLabel,
              ),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: '',
                  child: Text(l10n.calendarServerAudienceScopeChildrenOnly),
                ),
                for (final thread in _collaborationThreads)
                  DropdownMenuItem<String>(
                    value: thread.id,
                    child: Text(
                      thread.title.trim().isNotEmpty
                          ? thread.title
                          : thread.kind == FamilyChatThreadKind.direct
                              ? l10n.familyChatDirectThread
                              : l10n.familyChatGroupThread,
                    ),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _createAudienceThreadId = value == null || value.isEmpty
                          ? null
                          : value;
                      if (_createAudienceThreadId != null) {
                        _createChildIds.clear();
                      }
                    }),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.calendarServerCreateChildren,
              style: TextStyle(fontSize: 12, color: colors.ink2),
            ),
            for (final child in _addressableChildren)
              CheckboxListTile(
                key: Key('calendar_server_create_child_${child.id.value}'),
                value: _createChildIds.contains(child.id.value),
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        if (value == true) {
                          _createChildIds.add(child.id.value);
                        } else {
                          _createChildIds.remove(child.id.value);
                        }
                      }),
                title: Text(child.label),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(
                key: const Key('calendar_server_create_submit'),
                onPressed: _busy || start == null || end == null
                    ? null
                    : _create,
                child: Text(l10n.calendarServerCreateButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calling an event off: a reason is required, because a cancellation a child cannot
/// understand is worse than the cancellation itself.
class _CancelDialog extends StatefulWidget {
  const _CancelDialog();

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final TextEditingController _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.calendarServerCancelHeading),
      content: TextField(
        key: const Key('calendar_server_cancel_reason'),
        controller: _reasonCtrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.calendarServerCancelReasonHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('calendar_server_cancel_confirm'),
          onPressed: () => Navigator.of(context).pop(_reasonCtrl.text),
          child: Text(l10n.calendarServerCancelButton),
        ),
      ],
    );
  }
}
