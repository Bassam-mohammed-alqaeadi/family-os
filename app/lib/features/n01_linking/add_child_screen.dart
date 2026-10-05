import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_os/core/design/tokens.dart';
import 'package:family_os/core/runtime/app_scope.dart';
import 'package:family_os/core/runtime/family_child_profile_source.dart';
import 'package:family_os/foundation_gate/onboarding_copy.dart';
import 'package:family_os/features/shared_onboarding/onboarding_form.dart';
import 'package:family_os/foundation_gate/foundation_gate_models.dart';

/// Character emoji options (server stores the chosen emoji as-is).
const List<String> kAddChildCharacters = ['🦁', '🐱', '🐼', '🦊', '🐰', '🐢'];

/// Ages offered on SCR-FAT-003 (inclusive).
const List<int> kAddChildAges = [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];

/// Theme colour names sent to the server, in picker order.
const List<String> kAddChildThemeColors = [
  'purple',
  'sky',
  'amber',
  'coral',
  'mint',
  'teal',
];

/// Widget keys for SCR-FAT-003.
abstract final class AddChildKeys {
  static const name = Key('add_child_name');
  static const age = Key('add_child_age');
  static const characters = Key('add_child_characters');
  static const colors = Key('add_child_colors');
  static const submit = Key('add_child_continue');
  static const notice = Key('add_child_notice');
  static const noticeAction = Key('add_child_notice_action');
  static Key character(int i) => Key('add_child_char_$i');
  static Key color(int i) => Key('add_child_color_$i');
}

/// SCR-FAT-003 — create the child profile on the server.
///
/// The form sends exactly what the server stores: display name, age, avatar
/// emoji and theme colour. Submission is idempotent: the same draft reuses the
/// same idempotency key across retries, and the button is locked while a
/// request is in flight, so a double tap or a flaky network can never produce
/// two children. There is no local/mock creation path.
class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  static const _maxNameLength = 120;

  final _name = TextEditingController();
  final _scroll = ScrollController();
  var _touched = false;
  var _submitting = false;
  int _age = 10;
  int _characterIndex = 0;
  int _colorIndex = 0;

  // Idempotency: one key per distinct draft, reused on retry.
  String? _idempotencyKey;
  FamilyChildProfileDraft? _submittedDraft;

  FamilyChildProfileCreateFailurePresentation? _failure;
  var _showNoFamily = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _trimmedName => _name.text.trim();

  String? _nameProblem(OnboardingCopy copy) {
    if (_trimmedName.isEmpty) return copy.childNameRequired;
    if (_trimmedName.runes.length > _maxNameLength) {
      return copy.childNameTooLong;
    }
    return null;
  }

  FamilyChildProfileDraft _draft() => FamilyChildProfileDraft(
    displayName: _trimmedName,
    ageYears: _age,
    avatarEmoji: kAddChildCharacters[_characterIndex],
    themeColor: kAddChildThemeColors[_colorIndex],
  );

  bool _sameDraft(FamilyChildProfileDraft a, FamilyChildProfileDraft b) =>
      a.displayName == b.displayName &&
      a.ageYears == b.ageYears &&
      a.avatarEmoji == b.avatarEmoji &&
      a.themeColor == b.themeColor;

  Future<void> _submit() async {
    if (_submitting) return;
    final copy = OnboardingCopy.of(context);
    setState(() => _touched = true);
    if (_nameProblem(copy) != null) return;

    final runtime = AppScope.maybeOf(context);
    final identity = runtime?.identity.value;
    final familyId = identity?.familyId;
    if (runtime == null ||
        identity == null ||
        familyId == null ||
        !identity.isRemoteAuthoritative) {
      // No active server family: the only honest outcome is to send the user
      // back to family creation. Nothing is created locally.
      setState(() {
        _failure = null;
        _showNoFamily = true;
      });
      revealOnboardingNotice(_scroll);
      return;
    }

    FocusScope.of(context).unfocus();
    final draft = _draft();
    if (_idempotencyKey == null ||
        _submittedDraft == null ||
        !_sameDraft(_submittedDraft!, draft)) {
      _idempotencyKey = newFoundationGateIdempotencyKey();
      _submittedDraft = draft;
    }
    setState(() {
      _submitting = true;
      _failure = null;
      _showNoFamily = false;
    });
    FamilyChildProfileCreateResult result;
    try {
      result = await runtime.childProfiles.create(
        familyId: familyId,
        idempotencyKey: _idempotencyKey!,
        draft: draft,
      );
    } catch (_) {
      result = const FamilyChildProfileCreateResult.failed(
        FamilyChildProfileCreateFailure.networkUnavailable,
      );
    }
    if (!mounted) return;
    final childId = result.childId;
    if (childId == null) {
      setState(() {
        _submitting = false;
        _failure = _present(result.failure);
      });
      revealOnboardingNotice(_scroll);
      return;
    }
    // Keep the button locked while the route transition happens.
    context.go(
      '/scr-fat-004?childId=${Uri.encodeComponent(childId)}&source=server',
    );
  }

  static FamilyChildProfileCreateFailurePresentation _present(
    FamilyChildProfileCreateFailure? failure,
  ) => switch (failure) {
    FamilyChildProfileCreateFailure.invalidInput =>
      FamilyChildProfileCreateFailurePresentation.invalidInput,
    FamilyChildProfileCreateFailure.conflict =>
      FamilyChildProfileCreateFailurePresentation.conflict,
    FamilyChildProfileCreateFailure.accessDenied =>
      FamilyChildProfileCreateFailurePresentation.accessDenied,
    FamilyChildProfileCreateFailure.sessionInvalid =>
      FamilyChildProfileCreateFailurePresentation.sessionInvalid,
    FamilyChildProfileCreateFailure.networkUnavailable ||
    FamilyChildProfileCreateFailure.rosterRefreshUnavailable =>
      FamilyChildProfileCreateFailurePresentation.network,
    FamilyChildProfileCreateFailure.serviceUnavailable ||
    FamilyChildProfileCreateFailure.unavailable ||
    null => FamilyChildProfileCreateFailurePresentation.unavailable,
  };

  List<Color> _kidColors(FamilyColors colors) => [
    colors.p500,
    colors.sky,
    colors.amber,
    colors.coral,
    colors.mint,
    colors.teal600,
  ];

  @override
  Widget build(BuildContext context) {
    final copy = OnboardingCopy.of(context);
    final colors = Theme.of(context).extension<FamilyColors>()!;
    final radii = Theme.of(context).extension<FamilyRadii>()!;
    final kidColors = _kidColors(colors);
    final busy = _submitting;
    final failure = _failure;
    final selectedColor = kidColors[_colorIndex];

    return OnboardingScaffold(
      controller: _scroll,
      appBarTitle: '2 / 3',
      children: [
        OnboardingHeader(
          icon: Icons.child_care_rounded,
          title: copy.childTitle,
          subtitle: copy.childSubtitle,
        ),
        if (_showNoFamily)
          OnboardingNotice(
            key: AddChildKeys.notice,
            tone: OnboardingNoticeTone.warning,
            title: copy.childNoFamilyTitle,
            message: copy.childNoFamilyMessage,
            actionLabel: copy.childGoCreateFamily,
            actionKey: AddChildKeys.noticeAction,
            onAction: () => context.go('/scr-fat-001'),
          )
        else if (failure != null)
          OnboardingNotice(
            key: AddChildKeys.notice,
            tone: OnboardingNoticeTone.error,
            title: copy.childCreateFailureTitle(failure),
            message: copy.childCreateFailureMessage(failure),
            actionLabel:
                failure ==
                        FamilyChildProfileCreateFailurePresentation.network ||
                    failure ==
                        FamilyChildProfileCreateFailurePresentation.unavailable
                ? copy.tryAgain
                : null,
            actionKey: AddChildKeys.noticeAction,
            onAction: busy ? null : _submit,
          ),
        // Live preview card: how the child will appear in the parent app.
        _ChildPreview(
          name: _trimmedName.isEmpty ? copy.childNameHint : _trimmedName,
          emoji: kAddChildCharacters[_characterIndex],
          ageLabel: copy.ageYears(_age),
          color: selectedColor,
          colors: colors,
          radii: radii,
          placeholder: _trimmedName.isEmpty,
        ),
        OnboardingTextField(
          fieldKey: AddChildKeys.name,
          label: copy.childNameLabel,
          controller: _name,
          hint: copy.childNameHint,
          enabled: !busy,
          autofocus: true,
          maxLength: _maxNameLength,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.givenName],
          errorText: _touched ? _nameProblem(copy) : null,
          onChanged: (_) {
            if (!_touched && _trimmedName.isNotEmpty) _touched = true;
          },
          onSubmitted: (_) => _submit(),
        ),
        _FieldLabel(copy.childAgeLabel, colors),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Semantics(
            label: copy.childAgeLabel,
            child: Wrap(
              key: AddChildKeys.age,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final age in kAddChildAges)
                  ChoiceChip(
                    key: Key('add_child_age_$age'),
                    label: Text(
                      '$age',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _age == age ? Colors.white : colors.ink,
                      ),
                    ),
                    selected: _age == age,
                    showCheckmark: false,
                    selectedColor: colors.p500,
                    backgroundColor: colors.surface,
                    side: BorderSide(
                      color: _age == age ? colors.p500 : colors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radii.pill),
                    ),
                    onSelected: busy ? null : (_) => setState(() => _age = age),
                  ),
              ],
            ),
          ),
        ),
        _FieldLabel(copy.childCharacterLabel, colors),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Semantics(
            label: copy.childCharacterLabel,
            child: Wrap(
              key: AddChildKeys.characters,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < kAddChildCharacters.length; i++)
                  Semantics(
                    button: true,
                    selected: _characterIndex == i,
                    label: kAddChildCharacters[i],
                    child: InkWell(
                      key: AddChildKeys.character(i),
                      onTap: busy
                          ? null
                          : () => setState(() => _characterIndex = i),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _characterIndex == i
                              ? selectedColor.withValues(alpha: 0.16)
                              : colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _characterIndex == i
                                ? selectedColor
                                : colors.border,
                            width: _characterIndex == i ? 2 : 1.2,
                          ),
                        ),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 160),
                          scale: _characterIndex == i ? 1.15 : 1,
                          child: Text(
                            kAddChildCharacters[i],
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _FieldLabel(copy.childColorLabel, colors),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Semantics(
            label: copy.childColorLabel,
            child: Wrap(
              key: AddChildKeys.colors,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < kidColors.length; i++)
                  Semantics(
                    button: true,
                    selected: _colorIndex == i,
                    label: copy.colorSwatch(i + 1),
                    child: InkWell(
                      key: AddChildKeys.color(i),
                      onTap: busy
                          ? null
                          : () => setState(() => _colorIndex = i),
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: _colorIndex == i ? 36 : 30,
                            height: _colorIndex == i ? 36 : 30,
                            decoration: BoxDecoration(
                              color: kidColors[i],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _colorIndex == i
                                    ? colors.ink
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: _colorIndex == i
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        OnboardingSubmitButton(
          label: copy.childSubmit,
          busyLabel: copy.savingChild,
          busy: busy,
          onPressed: _nameProblem(copy) == null ? _submit : null,
          buttonKey: AddChildKeys.submit,
        ),
        const SizedBox(height: 10),
        Text(
          copy.childSavedToServer,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, this.colors);

  final String text;
  final FamilyColors colors;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: colors.ink,
      ),
    ),
  );
}

class _ChildPreview extends StatelessWidget {
  const _ChildPreview({
    required this.name,
    required this.emoji,
    required this.ageLabel,
    required this.color,
    required this.colors,
    required this.radii,
    required this.placeholder,
  });

  final String name;
  final String emoji;
  final String ageLabel;
  final Color color;
  final FamilyColors colors;
  final FamilyRadii radii;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radii.card),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: placeholder
                        ? colors.ink2.withValues(alpha: 0.6)
                        : colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ageLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
