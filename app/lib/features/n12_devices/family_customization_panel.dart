import 'package:flutter/material.dart';
import 'package:family_os/core/design/components/primary_btn.dart';
import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/i18n/numeral_format.dart';
import 'package:family_os/core/i18n/app_localizations.dart';
import 'package:family_os/features/n12_devices/family_customization_server_authority.dart';
import 'package:family_os/foundation_gate/family_customization_api_client.dart';

/// Keys the journey test taps and the screen-reader audit finds.
@visibleForTesting
class FamilyCustomizationKeys {
  const FamilyCustomizationKeys._();

  static const card = Key('family_customization_card');
  static const note = Key('family_customization_note');
  static const status = Key('family_customization_status');
  static const weekStartGroup = Key('family_customization_week_start');
  static const restDaysGroup = Key('family_customization_rest_days');
  static const numeralsGroup = Key('family_customization_numerals');
  static const numeralsPreview = Key('family_customization_numerals_preview');
  static const wordsGroup = Key('family_customization_words');
  static const saveCta = Key('family_customization_save');
  static const refreshCta = Key('family_customization_refresh');
  static const busy = Key('family_customization_busy');

  static Key weekStartDay(FamilyCustomizationDay day) =>
      Key('family_customization_week_start_${day.wire}');

  static Key restDay(FamilyCustomizationDay day) =>
      Key('family_customization_rest_day_${day.wire}');

  static Key numeral(FamilyNumeralSystem system) =>
      Key('family_customization_numeral_${system.wire}');

  static Key label(FamilyGuardianLabelKey key) =>
      Key('family_customization_label_${key.wire}');
}

/// The family's own character, on the screen its father already opens.
///
/// Four things used to be written into this build: the day a week grid opened with, which days
/// were rest days, what children were told to call their guardians, and how their numbers were
/// drawn. All four are here now, read from one row the spine holds for this family, and written
/// back through the one route allowed to change them. Nothing on this card computes a policy: the
/// week a child is measured against, the schedule that treats a day as rest, and the digits every
/// screen prints are the server's answers, and this card is where a family sets them.
///
/// It is mounted inside the settings hub rather than behind a route of its own, because a family
/// should not have to discover a second place where "our family" lives. And it renders its honest
/// state when there is no answer to show — no server, a server that did not reply, a write the
/// spine refused — instead of drawing a profile this build made up.
class FamilyCustomizationSection extends StatefulWidget {
  const FamilyCustomizationSection({super.key, this.authority});

  /// Test seam. Unbound at runtime resolves to the application's authority, and a section with no
  /// authority says so rather than showing a family a week nobody chose.
  final FamilyCustomizationAuthority? authority;

  @override
  State<FamilyCustomizationSection> createState() =>
      _FamilyCustomizationSectionState();
}

class _FamilyCustomizationSectionState extends State<FamilyCustomizationSection> {
  FamilyCustomizationProfile? _profile;
  FamilyCustomizationStatus _status =
      FamilyCustomizationStatus.notConfigured;
  FamilyCustomizationRefusal _refusal = FamilyCustomizationRefusal.none;

  /// The drafts a guardian is editing. Held apart from [_profile] on purpose: the spine's answer
  /// stays untouched until a write comes back, so a refused change never leaves the screen
  /// displaying something that was never stored.
  FamilyCustomizationDay? _weekStartDraft;
  Set<FamilyCustomizationDay> _restDraft = const <FamilyCustomizationDay>{};
  FamilyNumeralSystem? _numeralsDraft;
  final Map<FamilyGuardianLabelKey, TextEditingController> _wordControllers =
      <FamilyGuardianLabelKey, TextEditingController>{};

  bool _busy = false;

  /// Counts this screen's own writes, so two taps in the same microsecond are two
  /// different requests to the spine rather than one retried.
  int _writeSequence = 0;

  String? _note;
  bool _noteIsGood = false;

  FamilyCustomizationAuthority? get _authority =>
      widget.authority ?? FamilyCustomizationAuthority.bound;

  /// A write is only ever worth sending: a live request, no profile to version against, or a
  /// screen that has changed nothing, and the button stays shut.
  bool get _canSave =>
      !_busy &&
      _profile != null &&
      _status == FamilyCustomizationStatus.ready &&
      _refusal != FamilyCustomizationRefusal.notPrimaryGuardian &&
      _isDirty;

  bool get _isDirty {
    final profile = _profile;
    if (profile == null) return false;
    if (_weekStartDraft != null &&
        _weekStartDraft != profile.weekStartDay) {
      return true;
    }
    if (_restDraft.length != profile.restDays.length ||
        !_restDraft.containsAll(profile.restDays)) {
      return true;
    }
    if (_numeralsDraft != null && _numeralsDraft != profile.numerals) {
      return true;
    }
    for (final entry in _wordControllers.entries) {
      final typed = entry.value.text.trim();
      final stored = profile.labels[entry.key] ?? '';
      if (typed != stored) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    for (final key in FamilyGuardianLabelKey.values) {
      _wordControllers[key] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    for (final controller in _wordControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final authority = _authority;
    if (authority == null) {
      if (mounted) {
        setState(() {
          _status = FamilyCustomizationStatus.notConfigured;
          _profile = null;
        });
      }
      return;
    }
    if (_busy) return;
    if (mounted) setState(() => _busy = true);
    final answer = await authority.read();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = answer.status;
      _refusal = FamilyCustomizationRefusal.none;
      // A read that failed leaves the last read on screen with the sentence that says what it is.
      // Wiping it would be worse than the failure: the guardian would lose the family's profile
      // because of a network, and a screen with nothing on it cannot be reasoned about.
      if (answer.profile != null) {
        _profile = answer.profile;
        _adoptDrafts(answer.profile!);
      }
    });
  }

  /// The moment a profile lands — first read, a save, or a re-read after a stale write — its
  /// values become the drafts. Whatever the guardian was mid-typing belongs to a version the
  /// spine did not accept, and keeping it would be showing them a change that does not exist.
  void _adoptDrafts(FamilyCustomizationProfile profile) {
    _weekStartDraft = profile.weekStartDay;
    _restDraft = Set<FamilyCustomizationDay>.of(profile.restDays);
    _numeralsDraft = profile.numerals;
    for (final entry in _wordControllers.entries) {
      entry.value.value = TextEditingValue(
        text: profile.labels[entry.key] ?? '',
        selection: TextSelection.collapsed(
          offset: (profile.labels[entry.key] ?? '').length,
        ),
      );
    }
  }

  void _toggleRestDay(FamilyCustomizationDay day) {
    final next = Set<FamilyCustomizationDay>.of(_restDraft);
    if (next.contains(day)) {
      // The floor is the database's, and it is stated here so a guardian learns it from a tap
      // rather than from a refusal after saving. An empty week is what every weekday rule in this
      // app is measured against, so it is not a choice this build will send at all.
      if (next.length == 1) {
        setState(() {
          _note = AppLocalizations.of(context).familyCustomizationNoRestDayNote;
          _noteIsGood = false;
        });
        return;
      }
      next.remove(day);
    } else {
      next.add(day);
    }
    setState(() {
      _restDraft = next;
      _note = null;
    });
  }

  Future<void> _save() async {
    final authority = _authority;
    final profile = _profile;
    if (authority == null || profile == null || _busy || !_canSave) return;
    // The sentences are taken before the await, not after it: a screen that asks the world a
    // question and then reads the widget tree to answer it is a screen that can be asked to speak
    // to a state that no longer exists.
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _note = null;
    });

    final changedWords = <FamilyGuardianLabelKey, String?>{};
    for (final entry in _wordControllers.entries) {
      final typed = entry.value.text.trim();
      final stored = profile.labels[entry.key] ?? '';
      if (typed == stored) continue;
      // An emptied field is a request to drop the family's word and go back to what the app
      // says, which is a real change and is sent as null rather than as silence.
      changedWords[entry.key] = typed.isEmpty ? null : typed;
    }

    final answer = await authority.write(
      expectedVersion: profile.version,
      weekStartDay: _weekStartDraft != profile.weekStartDay
          ? _weekStartDraft
          : null,
      restDays:
          _restDraft.length != profile.restDays.length ||
              !_restDraft.containsAll(profile.restDays)
          ? FamilyCustomizationDay.values
              .where(_restDraft.contains)
              .toList(growable: false)
          : null,
      numerals: _numeralsDraft != profile.numerals ? _numeralsDraft : null,
      labels: changedWords.isEmpty ? null : changedWords,
      idempotencyKey: 'family-customization:'
          '${DateTime.now().microsecondsSinceEpoch}:${_writeSequence++}',
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = answer.status;
      _refusal = answer.refusal;
      if (answer.profile != null) {
        _profile = answer.profile;
        _adoptDrafts(answer.profile!);
        _noteIsGood = true;
        _note = l10n.familyCustomizationSavedNote;
      } else {
        _noteIsGood = false;
        _note = _refusalNote(l10n, answer.refusal);
      }
    });
    // A stale version means somebody else in this family wrote first. Their answer is the one
    // that stands, so it is read back rather than argued with — and the guardian sees the
    // family's real profile, not their own unsent draft.
    if (answer.refusal == FamilyCustomizationRefusal.staleVersion) {
      await _load();
      if (mounted) {
        setState(() {
          _note = _refusalNote(l10n, FamilyCustomizationRefusal.staleVersion);
          _noteIsGood = false;
        });
      }
    }
  }

  String _refusalNote(
    AppLocalizations l10n,
    FamilyCustomizationRefusal refusal,
  ) {
    return switch (refusal) {
      FamilyCustomizationRefusal.staleVersion =>
        l10n.familyCustomizationStaleNote,
      FamilyCustomizationRefusal.notPrimaryGuardian =>
        l10n.familyCustomizationNotPrimaryNote,
      FamilyCustomizationRefusal.noRestDay =>
        l10n.familyCustomizationNoRestDayNote,
      FamilyCustomizationRefusal.wordRefused =>
        l10n.familyCustomizationWordRefusedNote,
      FamilyCustomizationRefusal.unexplained ||
      FamilyCustomizationRefusal.none =>
        l10n.familyCustomizationRefusedNote,
    };
  }

  String _statusNote(AppLocalizations l10n) {
    return switch (_status) {
      FamilyCustomizationStatus.notConfigured =>
        l10n.familyCustomizationNoServerNote,
      FamilyCustomizationStatus.unreachable =>
        l10n.familyCustomizationUnreachableNote,
      FamilyCustomizationStatus.accessDenied =>
        l10n.familyCustomizationAccessDeniedNote,
      FamilyCustomizationStatus.unreadable =>
        l10n.familyCustomizationUnreadableNote,
      FamilyCustomizationStatus.ready ||
      FamilyCustomizationStatus.refused =>
        '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final profile = _profile;
    final dayNames = <FamilyCustomizationDay, String>{
      FamilyCustomizationDay.sunday: l10n.screenTimeServerDaySun,
      FamilyCustomizationDay.monday: l10n.screenTimeServerDayMon,
      FamilyCustomizationDay.tuesday: l10n.screenTimeServerDayTue,
      FamilyCustomizationDay.wednesday: l10n.screenTimeServerDayWed,
      FamilyCustomizationDay.thursday: l10n.screenTimeServerDayThu,
      FamilyCustomizationDay.friday: l10n.screenTimeServerDayFri,
      FamilyCustomizationDay.saturday: l10n.screenTimeServerDaySat,
    };
    final statusNote = _statusNote(l10n);

    return DecoratedBox(
      key: FamilyCustomizationKeys.card,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.familyCustomizationTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.familyCustomizationIntro,
              style: TextStyle(fontSize: 12, height: 1.5, color: colors.ink2),
            ),
            if (profile == null || statusNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              if (statusNote.isNotEmpty)
                Text(
                  key: FamilyCustomizationKeys.status,
                  statusNote,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: colors.coral,
                  ),
                ),
              const SizedBox(height: 6),
              PrimaryBtn(
                key: FamilyCustomizationKeys.refreshCta,
                label: l10n.familyCustomizationRefreshCta,
                variant: PrimaryBtnVariant.sec,
                fullWidth: false,
                onPressed: _busy ? null : _load,
              ),
            ],
            if (profile != null) ...[
              const SizedBox(height: 10),
              _Group(
                key: FamilyCustomizationKeys.weekStartGroup,
                label: l10n.familyCustomizationWeekStartLabel,
                children: [
                  for (final day in FamilyCustomizationDay.values)
                    ChoiceChip(
                      key: FamilyCustomizationKeys.weekStartDay(day),
                      label: Text(dayNames[day]!),
                      selected: _weekStartDraft == day,
                      onSelected: _busy
                          ? null
                          : (_) => setState(() => _weekStartDraft = day),
                    ),
                ],
              ),
              _Group(
                key: FamilyCustomizationKeys.restDaysGroup,
                label: l10n.familyCustomizationRestDaysLabel,
                hint: l10n.familyCustomizationRestDaysHint,
                children: [
                  for (final day in FamilyCustomizationDay.values)
                    FilterChip(
                      key: FamilyCustomizationKeys.restDay(day),
                      label: Text(dayNames[day]!),
                      selected: _restDraft.contains(day),
                      onSelected: _busy ? null : (_) => _toggleRestDay(day),
                    ),
                ],
              ),
              _Group(
                key: FamilyCustomizationKeys.numeralsGroup,
                label: l10n.familyCustomizationNumeralsLabel,
                footer: Text(
                  key: FamilyCustomizationKeys.numeralsPreview,
                  l10n.familyCustomizationNumeralsPreview(
                    _previewFor(_numeralsDraft ?? profile.numerals),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.ink2,
                  ),
                ),
                children: [
                  ChoiceChip(
                    key: FamilyCustomizationKeys.numeral(
                      FamilyNumeralSystem.western,
                    ),
                    label: Text(l10n.familyCustomizationNumeralsWestern),
                    selected: _numeralsDraft == FamilyNumeralSystem.western,
                    onSelected: _busy
                        ? null
                        : (_) => setState(
                            () =>
                                _numeralsDraft = FamilyNumeralSystem.western,
                          ),
                  ),
                  ChoiceChip(
                    key: FamilyCustomizationKeys.numeral(
                      FamilyNumeralSystem.eastern,
                    ),
                    label: Text(l10n.familyCustomizationNumeralsEastern),
                    selected: _numeralsDraft == FamilyNumeralSystem.eastern,
                    onSelected: _busy
                        ? null
                        : (_) => setState(
                            () => _numeralsDraft = FamilyNumeralSystem.eastern,
                          ),
                  ),
                ],
              ),
              _Group(
                key: FamilyCustomizationKeys.wordsGroup,
                label: l10n.familyCustomizationWordsLabel,
                hint: l10n.familyCustomizationWordsHint,
                children: [
                  for (final entry in _wordControllers.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: TextField(
                        key: FamilyCustomizationKeys.label(entry.key),
                        controller: entry.value,
                        maxLength: 24,
                        maxLines: 1,
                        enabled: !_busy,
                        // Typing must rebuild THIS widget: the save button's state is decided
                        // here, not inside the field, so without this the card would sit on a
                        // stale answer and a parent would tap a dead button wondering why nothing
                        // was kept.
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: _wordLabel(l10n, entry.key),
                          counterText: '',
                          hintText: profile.labels[entry.key],
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                ],
              ),
              if (!profile.isFamilyChosen)
                Text(
                  l10n.familyCustomizationDefaultNote,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: colors.ink2,
                  ),
                ),
              const SizedBox(height: 8),
              // A Column, not a Row: at a doubled text size a spinner beside the button squeezes
              // its label, and a clipped CTA is the one thing this card must stay readable through.
              if (_busy)
                const Padding(
                  padding: EdgeInsetsDirectional.only(bottom: 6),
                  child: SizedBox(
                    key: FamilyCustomizationKeys.busy,
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              PrimaryBtn(
                key: FamilyCustomizationKeys.saveCta,
                label: l10n.familyCustomizationSave,
                fullWidth: true,
                onPressed: _canSave ? _save : null,
              ),
              if (_note != null) ...[
                const SizedBox(height: 6),
                Text(
                  key: FamilyCustomizationKeys.note,
                  _note!,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: _noteIsGood ? colors.teal : colors.coral,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _wordLabel(AppLocalizations l10n, FamilyGuardianLabelKey key) {
    return switch (key) {
      FamilyGuardianLabelKey.father => l10n.familyCustomizationWordFather,
      FamilyGuardianLabelKey.mother => l10n.familyCustomizationWordMother,
      FamilyGuardianLabelKey.guardian => l10n.familyCustomizationWordGuardian,
      FamilyGuardianLabelKey.child => l10n.familyCustomizationWordChild,
    };
  }

  /// Both renderings are shown before a family chooses, because "Eastern digits" means nothing
  /// to most people and «١٢٣٤» means everything. This is the one place the app writes digits in a
  /// shape the family has NOT chosen — and it is a preview of a choice, not a screen's answer.
  String _previewFor(FamilyNumeralSystem system) {
    return switch (system) {
      FamilyNumeralSystem.western => '1234',
      FamilyNumeralSystem.eastern => toEasternDigits(1234),
    };
  }
}

/// A labelled group of controls. `Wrap` rather than `Row` so a doubled text size and a long day
/// name reflow instead of overflowing.
class _Group extends StatelessWidget {
  const _Group({
    super.key,
    required this.label,
    required this.children,
    this.hint,
    this.footer,
  });

  final String label;
  final String? hint;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FamilyColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: TextStyle(fontSize: 11, height: 1.45, color: colors.ink2),
            ),
          ],
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: children),
          if (footer != null) ...[const SizedBox(height: 6), footer!],
        ],
      ),
    );
  }
}
