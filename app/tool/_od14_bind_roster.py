from pathlib import Path

root = Path(r"D:/special projects/family/app/lib")

# --- attribution_reward_repository.dart ---
path = root / "features/n14_studio/attribution_reward_repository.dart"
text = path.read_text(encoding="utf-8")
if "roster_children" not in text:
    text = text.replace(
        "import 'package:family_os/core/domain/child_id.dart';",
        "import 'package:family_os/core/domain/child_id.dart';\n"
        "import 'package:family_os/core/identity/roster_children.dart';",
    )

old = """AttributionRewardSnapshot attributionRewardPrototypeFixture() {
  return const AttributionRewardSnapshot(
    children: [
      AttributionChild(
        id: 'child_a',
        nameKey: 'one',
        emoji: '🦁',
        swatch: AttributionChildSwatch.purple,
      ),
      AttributionChild(
        id: 'child_b',
        nameKey: 'two',
        emoji: '🐱',
        swatch: AttributionChildSwatch.sky,
      ),
      AttributionChild(
        id: 'child_c',
        nameKey: 'three',
        emoji: '🐼',
        swatch: AttributionChildSwatch.amber,
      ),
    ],
    selectedChildId: 'child_a',"""
new = """AttributionRewardSnapshot attributionRewardPrototypeFixture() {
  return AttributionRewardSnapshot(
    children: _rosterAttributionChildren(),
    selectedChildId: activeRosterChild()?.id.value,"""
if old not in text:
    raise SystemExit("ATTR prototype block not found")
text = text.replace(old, new)

text = text.replace(
    """  @override
  Future<AttributionRewardSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _copy();
  }""",
    """  @override
  Future<AttributionRewardSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    _snap = bindAttributionToRoster(_snap);
    return _copy();
  }""",
)
text = text.replace(
    """  @override
  Future<AttributionRewardSnapshot> assign() async {
    if (!_snap.canAssign) return _copy();
    final child = _snap.selectedChild!;""",
    """  @override
  Future<AttributionRewardSnapshot> assign() async {
    _snap = bindAttributionToRoster(_snap);
    if (!_snap.canAssign) return _copy();
    final child = _snap.selectedChild!;""",
)

if "bindAttributionToRoster" not in text:
    text = text.rstrip() + """

List<AttributionChild> _rosterAttributionChildren() {
  const swatches = [
    AttributionChildSwatch.purple,
    AttributionChildSwatch.sky,
    AttributionChildSwatch.amber,
  ];
  const emojis = ['🦁', '🐱', '🐼', '🦊', '🐰'];
  final roster = activeFamilyRosterChildren();
  return [
    for (var i = 0; i < roster.length; i++)
      AttributionChild(
        id: roster[i].id.value,
        nameKey: roster[i].nameKey,
        emoji: emojis[i % emojis.length],
        swatch: swatches[i % swatches.length],
      ),
  ];
}

/// OD-14 — picker children = active family roster.
AttributionRewardSnapshot bindAttributionToRoster(
  AttributionRewardSnapshot snap,
) {
  final children = _rosterAttributionChildren();
  if (children.isEmpty) {
    return const AttributionRewardSnapshot();
  }
  if (snap.children.isEmpty &&
      snap.selectedChildId == null &&
      !snap.assigned &&
      snap.rewards.isEmpty) {
    return snap;
  }
  final activeId = activeRosterChild()!.id.value;
  final selected = snap.selectedChildId;
  final keep = selected != null && children.any((c) => c.id == selected)
      ? selected
      : activeId;
  return AttributionRewardSnapshot(
    children: children,
    selectedChildId: keep,
    schedule: snap.schedule,
    rewards: List<AttributionRewardToggle>.from(snap.rewards),
    masteryPercent: snap.masteryPercent,
    assigned: snap.assigned,
  );
}
"""
path.write_text(text, encoding="utf-8")
print("attribution ok")

# --- create_task_repository ---
path = root / "features/n16_tasks/create_task_repository.dart"
text = path.read_text(encoding="utf-8")
if "roster_children" not in text:
    text = text.replace(
        "import 'package:family_os/core/domain/minutes.dart';",
        "import 'package:family_os/core/domain/minutes.dart';\n"
        "import 'package:family_os/core/identity/roster_children.dart';",
    )
text = text.replace(
    """  @override
  Future<CreateTaskSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _copy(_snap);
  }""",
    """  @override
  Future<CreateTaskSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    _snap = bindCreateTaskToRoster(_snap);
    return _copy(_snap);
  }""",
)
text = text.replace(
    """  @override
  Future<CreateTaskSnapshot> submitTask(CreateTaskDraft draft) async {
    if (_snap.isEmpty) return _copy(_snap);""",
    """  @override
  Future<CreateTaskSnapshot> submitTask(CreateTaskDraft draft) async {
    _snap = bindCreateTaskToRoster(_snap);
    if (_snap.isEmpty) return _copy(_snap);""",
)

# Replace fixtures
text = text.replace(
    """CreateTaskSnapshot createTaskOneFixture() {
  return const CreateTaskSnapshot(
    children: [
      CreateTaskChild(id: 'child_a', nameKey: 'one'),
    ],""",
    """CreateTaskSnapshot createTaskOneFixture() {
  final roster = activeFamilyRosterChildren();
  if (roster.isEmpty) return const CreateTaskSnapshot();
  return CreateTaskSnapshot(
    children: [
      CreateTaskChild(id: roster.first.id.value, nameKey: roster.first.nameKey),
    ],""",
)
text = text.replace(
    """CreateTaskSnapshot createTaskPrototypeFixture() {
  return const CreateTaskSnapshot(
    children: [
      CreateTaskChild(id: 'child_a', nameKey: 'one'),
      CreateTaskChild(id: 'child_b', nameKey: 'two'),
      CreateTaskChild(id: 'child_c', nameKey: 'three'),
    ],""",
    """CreateTaskSnapshot createTaskPrototypeFixture() {
  final roster = activeFamilyRosterChildren();
  return CreateTaskSnapshot(
    children: [
      for (final c in roster) CreateTaskChild(id: c.id.value, nameKey: c.nameKey),
    ],""",
)

if "bindCreateTaskToRoster" not in text:
    text = text.rstrip() + """

CreateTaskSnapshot bindCreateTaskToRoster(CreateTaskSnapshot snap) {
  final roster = activeFamilyRosterChildren();
  if (snap.children.isEmpty && snap.submittedCount == 0) {
    return snap;
  }
  if (roster.isEmpty) {
    return const CreateTaskSnapshot();
  }
  return snap.copyWith(
    children: [
      for (final c in roster) CreateTaskChild(id: c.id.value, nameKey: c.nameKey),
    ],
  );
}
"""
path.write_text(text, encoding="utf-8")
print("create_task ok")

# --- add_event_repository ---
path = root / "features/n15_calendar/add_event_repository.dart"
text = path.read_text(encoding="utf-8")
if "roster_children" not in text:
    # find first import
    lines = text.splitlines(True)
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1
    lines.insert(
        insert_at,
        "import 'package:family_os/core/identity/roster_children.dart';\n",
    )
    text = "".join(lines)

text = text.replace(
    """AddEventSnapshot addEventOneFixture() {
  return const AddEventSnapshot(
    children: [
      AddEventChild(id: 'child_a', nameKey: 'one'),
    ],""",
    """AddEventSnapshot addEventOneFixture() {
  final roster = activeFamilyRosterChildren();
  if (roster.isEmpty) return const AddEventSnapshot();
  return AddEventSnapshot(
    children: [
      AddEventChild(id: roster.first.id.value, nameKey: roster.first.nameKey),
    ],""",
)
text = text.replace(
    """AddEventSnapshot addEventPrototypeFixture() {
  return const AddEventSnapshot(
    children: [
      AddEventChild(id: 'child_a', nameKey: 'one'),
      AddEventChild(id: 'child_b', nameKey: 'two'),
      AddEventChild(id: 'child_c', nameKey: 'three'),
    ],""",
    """AddEventSnapshot addEventPrototypeFixture() {
  final roster = activeFamilyRosterChildren();
  return AddEventSnapshot(
    children: [
      for (final c in roster) AddEventChild(id: c.id.value, nameKey: c.nameKey),
    ],""",
)

# bind on load if present
if "Future<AddEventSnapshot> load()" in text and "bindAddEventToRoster" not in text:
    text = text.replace(
        """  @override
  Future<AddEventSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    return _copy(_snap);
  }""",
        """  @override
  Future<AddEventSnapshot> load() async {
    final gate = loadGate;
    if (gate != null) await gate();
    _snap = bindAddEventToRoster(_snap);
    return _copy(_snap);
  }""",
    )
    text = text.rstrip() + """

AddEventSnapshot bindAddEventToRoster(AddEventSnapshot snap) {
  final roster = activeFamilyRosterChildren();
  if (snap.children.isEmpty && snap.savedEventCount == 0) {
    return snap;
  }
  if (roster.isEmpty) {
    return const AddEventSnapshot();
  }
  return snap.copyWith(
    children: [
      for (final c in roster) AddEventChild(id: c.id.value, nameKey: c.nameKey),
    ],
  );
}
"""
path.write_text(text, encoding="utf-8")
print("add_event ok")

# --- focus_report + results_followup child_a -> roster ---
for rel, one_id, proto_id, binder_name, child_ctor, empty_check in [
    (
        "features/n14_studio/focus_report_repository.dart",
        "FocusReportChild(id: 'child_a', nameKey: 'one')",
        "FocusReportChild(id: 'child_a', nameKey: 'one')",
        "bindFocusReportToRoster",
        "FocusReportChild",
        "snap.child == null",
    ),
    (
        "features/n14_studio/results_followup_repository.dart",
        "ResultsFollowupChild(id: 'child_a', nameKey: 'one')",
        "ResultsFollowupChild(id: 'child_a', nameKey: 'one')",
        "bindResultsFollowupToRoster",
        "ResultsFollowupChild",
        "snap.child == null",
    ),
]:
    path = root / rel
    text = path.read_text(encoding="utf-8")
    if "roster_children" not in text:
        lines = text.splitlines(True)
        insert_at = 0
        for i, line in enumerate(lines):
            if line.startswith("import "):
                insert_at = i + 1
        lines.insert(
            insert_at,
            "import 'package:family_os/core/identity/roster_children.dart';\n",
        )
        text = "".join(lines)
    text = text.replace(
        "child: FocusReportChild(id: 'child_a', nameKey: 'one')",
        "child: _rosterFocusChild()",
    )
    text = text.replace(
        "child: ResultsFollowupChild(id: 'child_a', nameKey: 'one')",
        "child: _rosterResultsChild()",
    )
    # remove const where needed - rough
    text = text.replace(
        "return const FocusReportSnapshot(\n    child: _rosterFocusChild()",
        "return FocusReportSnapshot(\n    child: _rosterFocusChild()",
    )
    text = text.replace(
        "return const ResultsFollowupSnapshot(\n    child: _rosterResultsChild()",
        "return ResultsFollowupSnapshot(\n    child: _rosterResultsChild()",
    )
    if "FocusReport" in rel and "_rosterFocusChild" not in text:
        text = text.rstrip() + """

FocusReportChild? _rosterFocusChild() {
  final c = activeRosterChild();
  if (c == null) return null;
  return FocusReportChild(id: c.id.value, nameKey: c.nameKey);
}
"""
    if "results_followup" in rel and "_rosterResultsChild" not in text:
        text = text.rstrip() + """

ResultsFollowupChild? _rosterResultsChild() {
  final c = activeRosterChild();
  if (c == null) return null;
  return ResultsFollowupChild(id: c.id.value, nameKey: c.nameKey);
}
"""
    path.write_text(text, encoding="utf-8")
    print(rel, "ok")

print("ALL DONE")
