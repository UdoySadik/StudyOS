import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../roadmap/application/roadmap_provider.dart';
import '../../notes/application/notes_provider.dart';
import '../../documents/application/documents_provider.dart';
import '../domain/sync_models.dart';

final syncStatusProvider = FutureProvider<SyncStatusModel>((ref) async {
  final data = await ApiService().get('/sync/status') as Map<String, dynamic>;
  return SyncStatusModel.fromJson(data);
});

class SyncState {
  final bool isBusy;
  final String? message;
  final String? error;
  final SyncExportBundle? lastExport;
  final SyncImportResult? lastImport;

  const SyncState({
    this.isBusy = false,
    this.message,
    this.error,
    this.lastExport,
    this.lastImport,
  });

  SyncState copyWith({
    bool? isBusy,
    String? message,
    String? error,
    SyncExportBundle? lastExport,
    SyncImportResult? lastImport,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return SyncState(
      isBusy: isBusy ?? this.isBusy,
      message: clearMessage ? null : (message ?? this.message),
      error: clearError ? null : (error ?? this.error),
      lastExport: lastExport ?? this.lastExport,
      lastImport: lastImport ?? this.lastImport,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref ref;

  SyncNotifier(this.ref) : super(const SyncState());

  void _invalidateAllCaches() {
    ref.invalidate(syncStatusProvider);
    ref.invalidate(dashboardProvider);
    ref.invalidate(roadmapsProvider);
    ref.invalidate(allNotesProvider);
    ref.invalidate(documentsNotifierProvider);
  }

  Future<SyncExportBundle?> exportBundle({
    required String passphrase,
    bool includeDocuments = true,
    String? deviceName,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true, clearMessage: true);
    try {
      final payload = {
        'passphrase': passphrase.trim(),
        'include_documents': includeDocuments,
        if (deviceName != null && deviceName.trim().isNotEmpty) 'device_name': deviceName.trim(),
      };

      final data = await ApiService().post('/sync/export', payload) as Map<String, dynamic>;
      final bundle = SyncExportBundle.fromJson(data);

      state = state.copyWith(
        isBusy: false,
        lastExport: bundle,
        message: 'Sync bundle successfully encrypted with AES-256-GCM!',
      );
      ref.invalidate(syncStatusProvider);
      return bundle;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        error: 'Export failed: $e',
      );
      return null;
    }
  }

  Future<SyncImportResult?> importBundle({
    required String passphrase,
    required String saltHex,
    required String nonceHex,
    required String ciphertextBase64,
    String? checksumSha256,
    String mergeMode = 'merge',
  }) async {
    state = state.copyWith(isBusy: true, clearError: true, clearMessage: true);
    try {
      final payload = {
        'passphrase': passphrase.trim(),
        'salt_hex': saltHex.trim(),
        'nonce_hex': nonceHex.trim(),
        'ciphertext_base64': ciphertextBase64.trim(),
        if (checksumSha256 != null && checksumSha256.trim().isNotEmpty)
          'checksum_sha256': checksumSha256.trim(),
        'merge_mode': mergeMode,
      };

      final data = await ApiService().post('/sync/import', payload) as Map<String, dynamic>;
      final result = SyncImportResult.fromJson(data);

      state = state.copyWith(
        isBusy: false,
        lastImport: result,
        message: result.message,
      );
      _invalidateAllCaches();
      return result;
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        error: 'Import failed: $e',
      );
      return null;
    }
  }

  Future<SyncExportBundle?> exportBackup(String passphrase) async {
    return exportBundle(passphrase: passphrase, includeDocuments: true);
  }

  Future<SyncImportResult?> restoreBackup({
    required String passphrase,
    required String saltHex,
    required String nonceHex,
    required String ciphertextBase64,
    String? checksumSha256,
  }) async {
    return importBundle(
      passphrase: passphrase,
      saltHex: saltHex,
      nonceHex: nonceHex,
      ciphertextBase64: ciphertextBase64,
      checksumSha256: checksumSha256,
      mergeMode: 'overwrite',
    );
  }

  Future<void> registerDeviceName(String newName) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await ApiService().post('/sync/device/register', {'device_name': newName.trim()});
      ref.invalidate(syncStatusProvider);
      state = state.copyWith(isBusy: false, message: 'Device name updated.');
    } catch (e) {
      state = state.copyWith(isBusy: false, error: 'Failed to update device: $e');
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearMessage: true);
  }
}

final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});
