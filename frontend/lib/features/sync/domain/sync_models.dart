class SyncStatusModel {
  final String deviceId;
  final String deviceName;
  final String? createdAt;
  final String? lastSyncedAt;
  final int syncCount;
  final int totalRoadmaps;
  final int totalPhases;
  final int totalTopics;
  final int totalNotes;
  final int totalGoals;
  final int totalFlashcards;
  final int totalQuizzes;
  final int totalDocuments;
  final String databaseRevision;

  const SyncStatusModel({
    required this.deviceId,
    required this.deviceName,
    this.createdAt,
    this.lastSyncedAt,
    this.syncCount = 0,
    this.totalRoadmaps = 0,
    this.totalPhases = 0,
    this.totalTopics = 0,
    this.totalNotes = 0,
    this.totalGoals = 0,
    this.totalFlashcards = 0,
    this.totalQuizzes = 0,
    this.totalDocuments = 0,
    required this.databaseRevision,
  });

  factory SyncStatusModel.fromJson(Map<String, dynamic> json) {
    return SyncStatusModel(
      deviceId: json['device_id'] as String? ?? 'unknown',
      deviceName: json['device_name'] as String? ?? 'StudyOS Client',
      createdAt: json['created_at'] as String?,
      lastSyncedAt: json['last_synced_at'] as String?,
      syncCount: json['sync_count'] as int? ?? 0,
      totalRoadmaps: json['total_roadmaps'] as int? ?? 0,
      totalPhases: json['total_phases'] as int? ?? 0,
      totalTopics: json['total_topics'] as int? ?? 0,
      totalNotes: json['total_notes'] as int? ?? 0,
      totalGoals: json['total_goals'] as int? ?? 0,
      totalFlashcards: json['total_flashcards'] as int? ?? 0,
      totalQuizzes: json['total_quizzes'] as int? ?? 0,
      totalDocuments: json['total_documents'] as int? ?? 0,
      databaseRevision: json['database_revision'] as String? ?? 'rev_0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'created_at': createdAt,
      'last_synced_at': lastSyncedAt,
      'sync_count': syncCount,
      'total_roadmaps': totalRoadmaps,
      'total_phases': totalPhases,
      'total_topics': totalTopics,
      'total_notes': totalNotes,
      'total_goals': totalGoals,
      'total_flashcards': totalFlashcards,
      'total_quizzes': totalQuizzes,
      'total_documents': totalDocuments,
      'database_revision': databaseRevision,
    };
  }
}

class SyncExportBundle {
  final String bundleVersion;
  final String deviceId;
  final String deviceName;
  final String exportedAt;
  final String saltHex;
  final String nonceHex;
  final String ciphertextBase64;
  final String checksumSha256;
  final Map<String, int> entityCounts;

  const SyncExportBundle({
    this.bundleVersion = '1.0',
    required this.deviceId,
    required this.deviceName,
    required this.exportedAt,
    required this.saltHex,
    required this.nonceHex,
    required this.ciphertextBase64,
    required this.checksumSha256,
    this.entityCounts = const {},
  });

  factory SyncExportBundle.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['entity_counts'] as Map<String, dynamic>? ?? {};
    final counts = rawCounts.map((k, v) => MapEntry(k, (v as num).toInt()));

    return SyncExportBundle(
      bundleVersion: json['bundle_version'] as String? ?? '1.0',
      deviceId: json['device_id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      exportedAt: json['exported_at'] as String? ?? '',
      saltHex: json['salt_hex'] as String? ?? '',
      nonceHex: json['nonce_hex'] as String? ?? '',
      ciphertextBase64: json['ciphertext_base64'] as String? ?? '',
      checksumSha256: json['checksum_sha256'] as String? ?? '',
      entityCounts: counts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bundle_version': bundleVersion,
      'device_id': deviceId,
      'device_name': deviceName,
      'exported_at': exportedAt,
      'salt_hex': saltHex,
      'nonce_hex': nonceHex,
      'ciphertext_base64': ciphertextBase64,
      'checksum_sha256': checksumSha256,
      'entity_counts': entityCounts,
    };
  }
}

class SyncImportResult {
  final bool success;
  final String message;
  final Map<String, int> entitiesImported;
  final int conflictsResolved;
  final String importedAt;

  const SyncImportResult({
    required this.success,
    required this.message,
    this.entitiesImported = const {},
    this.conflictsResolved = 0,
    required this.importedAt,
  });

  factory SyncImportResult.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['entities_imported'] as Map<String, dynamic>? ?? {};
    final counts = rawCounts.map((k, v) => MapEntry(k, (v as num).toInt()));

    return SyncImportResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      entitiesImported: counts,
      conflictsResolved: json['conflicts_resolved'] as int? ?? 0,
      importedAt: json['imported_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'entities_imported': entitiesImported,
      'conflicts_resolved': conflictsResolved,
      'imported_at': importedAt,
    };
  }
}
