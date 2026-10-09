import 'package:flutter_test/flutter_test.dart';
import 'package:family_os/app/audit_population.dart';
import 'package:family_os/core/domain/role.dart';
import 'package:family_os/features/n14_studio/studio_board_models.dart';
import 'package:family_os/features/n14_studio/studio_board_repository.dart';

void main() {
  test('gallery role follows the SCR prefix', () {
    expect(galleryRoleForScreen('SCR-CHD-030'), AppRole.child);
    expect(galleryRoleForScreen('SCR-FAT-076'), AppRole.mother);
    expect(galleryRoleForScreen('SCR-FAT-054'), AppRole.father);
    expect(galleryRoleForScreen('SCR-SHR-005'), AppRole.father);
  });

  test('gallery push carries the active child and alert id', () {
    expect(
      galleryLocationForScreen('SCR-CHD-012'),
      '/scr-chd-012?childId=demo-child',
    );
    expect(
      galleryLocationForScreen('SCR-FAT-020'),
      '/scr-fat-020?childId=demo-child&alertId=a_stranger',
    );
  });

  test('release-style route query is stripped from the GoRouter path', () {
    expect(auditRoutePath('/dev-screens?audit=populated'), '/dev-screens');
    expect(auditRoutePath('/dev-screens'), '/dev-screens');
  });

  test('vision host is opt-in — populate alone does not hide tabs', () {
    expect(resolveAuditVisionHost(platformRoute: '/scr-fat-010'), isFalse);
    expect(
      resolveAuditVisionHost(platformRoute: '/scr-fat-010?audit=vision'),
      isTrue,
    );
    expect(resolveAuditVisionHost(platformRoute: '/dev-screens'), isTrue);
  });

  test('population flag off leaves the studio singleton empty', () async {
    stage1StudioBoardRepository.seed(const StudioBoardSnapshot());
    final seeded = await applyAuditPopulation(enabled: false);
    expect(seeded, 0);
    final snap = await stage1StudioBoardRepository.load();
    expect(snap.suggestions, isEmpty);
    expect(snap.recent, isEmpty);
  });

  test('population flag on seeds an existing studio fixture', () async {
    stage1StudioBoardRepository.seed(const StudioBoardSnapshot());
    final seeded = await applyAuditPopulation(enabled: true);
    expect(seeded, greaterThan(10));
    final snap = await stage1StudioBoardRepository.load();
    expect(snap.suggestions, isNotEmpty);
    stage1StudioBoardRepository.seed(const StudioBoardSnapshot());
  });
}
