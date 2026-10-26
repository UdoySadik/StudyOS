import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyos/features/settings/presentation/settings_page.dart';
import 'package:studyos/features/sync/application/sync_provider.dart';
import 'package:studyos/features/sync/domain/sync_models.dart';
import 'package:studyos/features/sync/presentation/sync_center_dialog.dart';

void main() {
  group('Sync Domain Models Tests', () {
    test('SyncStatusModel serializes and deserializes correctly', () {
      final json = {
        'device_id': 'dev_test_123',
        'device_name': 'StudyOS Desktop',
        'created_at': '2026-10-26T12:00:00Z',
        'last_synced_at': '2026-10-26T14:30:00Z',
        'sync_count': 5,
        'total_roadmaps': 3,
        'total_phases': 9,
        'total_topics': 24,
        'total_notes': 15,
        'total_goals': 2,
        'total_flashcards': 40,
        'total_quizzes': 6,
        'total_documents': 4,
        'database_revision': 'rev_test_abc',
      };

      final status = SyncStatusModel.fromJson(json);
      expect(status.deviceId, 'dev_test_123');
      expect(status.deviceName, 'StudyOS Desktop');
      expect(status.syncCount, 5);
      expect(status.totalRoadmaps, 3);
      expect(status.totalTopics, 24);
      expect(status.totalFlashcards, 40);
      expect(status.databaseRevision, 'rev_test_abc');

      final exported = status.toJson();
      expect(exported['device_id'], 'dev_test_123');
      expect(exported['total_topics'], 24);
      expect(exported['database_revision'], 'rev_test_abc');
    });

    test('SyncStatusModel handles null values with robust defaults', () {
      final status = SyncStatusModel.fromJson({});
      expect(status.deviceId, 'unknown');
      expect(status.deviceName, 'StudyOS Client');
      expect(status.syncCount, 0);
      expect(status.totalRoadmaps, 0);
      expect(status.databaseRevision, 'rev_0');
    });

    test('SyncExportBundle serializes and deserializes correctly', () {
      final json = {
        'bundle_version': '1.0',
        'device_id': 'dev_999',
        'device_name': 'Laptop Client',
        'exported_at': '2026-10-26T15:00:00Z',
        'salt_hex': 'a1b2c3d4e5f6',
        'nonce_hex': '0102030405060708090a0b0c',
        'ciphertext_base64': 'ZW5jcnlwdGVkX2RhdGE=',
        'checksum_sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        'entity_counts': {
          'roadmaps': 2,
          'topics': 10,
          'notes': 8,
          'flashcards': 20,
        },
      };

      final bundle = SyncExportBundle.fromJson(json);
      expect(bundle.bundleVersion, '1.0');
      expect(bundle.deviceId, 'dev_999');
      expect(bundle.deviceName, 'Laptop Client');
      expect(bundle.saltHex, 'a1b2c3d4e5f6');
      expect(bundle.nonceHex, '0102030405060708090a0b0c');
      expect(bundle.ciphertextBase64, 'ZW5jcnlwdGVkX2RhdGE=');
      expect(bundle.checksumSha256, startsWith('e3b0c4'));
      expect(bundle.entityCounts['roadmaps'], 2);
      expect(bundle.entityCounts['topics'], 10);

      final exported = bundle.toJson();
      expect(exported['bundle_version'], '1.0');
      expect(exported['device_id'], 'dev_999');
      expect(exported['salt_hex'], 'a1b2c3d4e5f6');
    });

    test('SyncImportResult serializes and deserializes correctly', () {
      final json = {
        'success': true,
        'message': 'Decrypted and merged successfully.',
        'entities_imported': {
          'roadmaps': 2,
          'topics': 10,
          'notes': 5,
        },
        'conflicts_resolved': 3,
        'imported_at': '2026-10-26T16:00:00Z',
      };

      final result = SyncImportResult.fromJson(json);
      expect(result.success, isTrue);
      expect(result.message, contains('merged successfully'));
      expect(result.entitiesImported['roadmaps'], 2);
      expect(result.conflictsResolved, 3);
      expect(result.importedAt, '2026-10-26T16:00:00Z');

      final exported = result.toJson();
      expect(exported['success'], isTrue);
      expect(exported['conflicts_resolved'], 3);
    });

    test('SyncState copyWith operates correctly', () {
      const state = SyncState();
      expect(state.isBusy, isFalse);
      expect(state.message, isNull);
      expect(state.error, isNull);

      final updated = state.copyWith(
        isBusy: true,
        message: 'Sync in progress',
        error: 'Network timeout',
      );
      expect(updated.isBusy, isTrue);
      expect(updated.message, 'Sync in progress');
      expect(updated.error, 'Network timeout');

      final cleared = updated.copyWith(
        isBusy: false,
        clearMessage: true,
        clearError: true,
      );
      expect(cleared.isBusy, isFalse);
      expect(cleared.message, isNull);
      expect(cleared.error, isNull);
    });
  });

  group('SyncCenterDialog Widget Tests', () {
    testWidgets('renders all tabs and header info', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      const mockStatus = SyncStatusModel(
        deviceId: 'dev_mock_001',
        deviceName: 'Primary Workstation',
        lastSyncedAt: '2026-10-26T18:00:00Z',
        syncCount: 7,
        totalRoadmaps: 4,
        totalPhases: 12,
        totalTopics: 35,
        totalNotes: 20,
        totalGoals: 3,
        totalFlashcards: 50,
        totalQuizzes: 8,
        totalDocuments: 5,
        databaseRevision: 'rev_mock_xyz',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusProvider.overrideWith((ref) => Future.value(mockStatus)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncCenterDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('StudyOS Sync & Cloud Center'), findsOneWidget);
      expect(find.text('AES-GCM-256 Active'), findsOneWidget);
      expect(find.text('ID: dev_mock_001'), findsOneWidget);
      expect(find.text('Primary Workstation'), findsOneWidget);

      // Verify Tabs
      expect(find.text('Export Bundle'), findsOneWidget);
      expect(find.text('Import Sync'), findsOneWidget);
      expect(find.text('Snapshot Backups'), findsOneWidget);

      // Default Tab is Export
      expect(find.byKey(const Key('sync_export_passphrase_field')), findsOneWidget);
      expect(find.byKey(const Key('generate_sync_bundle_button')), findsOneWidget);
      expect(find.text('Generate Encrypted Bundle'), findsOneWidget);
    });

    testWidgets('validates passphrase length on export button tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      const mockStatus = SyncStatusModel(
        deviceId: 'dev_mock_001',
        deviceName: 'Primary Workstation',
        databaseRevision: 'rev_mock_xyz',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusProvider.overrideWith((ref) => Future.value(mockStatus)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncCenterDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter short password (< 6 chars)
      await tester.enterText(find.byKey(const Key('sync_export_passphrase_field')), '123');
      await tester.pump();

      // Tap generate button
      await tester.tap(find.byKey(const Key('generate_sync_bundle_button')));
      await tester.pumpAndSettle();

      // SnackBar with error should appear
      expect(find.text('Encryption passphrase must be at least 6 characters.'), findsOneWidget);
    });

    testWidgets('navigates to Import tab and renders import fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      const mockStatus = SyncStatusModel(
        deviceId: 'dev_mock_001',
        deviceName: 'Primary Workstation',
        databaseRevision: 'rev_mock_xyz',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusProvider.overrideWith((ref) => Future.value(mockStatus)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncCenterDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Import tab
      await tester.tap(find.text('Import Sync'));
      await tester.pumpAndSettle();

      // Verify Import elements
      expect(find.byKey(const Key('sync_import_payload_field')), findsOneWidget);
      expect(find.byKey(const Key('sync_import_passphrase_field')), findsOneWidget);
      expect(find.text('Merge (Safe Upsert)'), findsOneWidget);
      expect(find.text('Overwrite (Replace All)'), findsOneWidget);
      expect(find.byKey(const Key('apply_sync_bundle_button')), findsOneWidget);
      expect(find.text('Decrypt & Apply Sync Bundle'), findsOneWidget);
    });

    testWidgets('navigates to Snapshot Backups tab and renders backup options', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      const mockStatus = SyncStatusModel(
        deviceId: 'dev_mock_001',
        deviceName: 'Primary Workstation',
        databaseRevision: 'rev_mock_xyz',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusProvider.overrideWith((ref) => Future.value(mockStatus)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SyncCenterDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Snapshot Backups tab
      await tester.tap(find.text('Snapshot Backups'));
      await tester.pumpAndSettle();

      // Verify Snapshot elements
      expect(find.text('Create Encrypted Snapshot Backup'), findsOneWidget);
      expect(find.text('Export Now'), findsOneWidget);
      expect(find.text('Restore from Encrypted Snapshot'), findsOneWidget);
      expect(find.text('Restore Now'), findsOneWidget);
    });
  });

  group('SettingsPage Sync Integration Tests', () {
    testWidgets('renders Cloud & Multi-Device Sync setting and opens dialog on click', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      const mockStatus = SyncStatusModel(
        deviceId: 'dev_mock_001',
        deviceName: 'Primary Workstation',
        databaseRevision: 'rev_mock_xyz',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusProvider.overrideWith((ref) => Future.value(mockStatus)),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Settings Section
      expect(find.text('Cloud & Multi-Device Sync'), findsOneWidget);
      expect(find.text('End-to-End Encrypted Sync'), findsOneWidget);
      expect(find.byKey(const Key('open_sync_center_btn')), findsOneWidget);

      // Tap open sync center button
      await tester.tap(find.byKey(const Key('open_sync_center_btn')));
      await tester.pumpAndSettle();

      // Sync Center Dialog should be displayed
      expect(find.text('StudyOS Sync & Cloud Center'), findsOneWidget);
      expect(find.text('Export Bundle'), findsOneWidget);
    });
  });
}
