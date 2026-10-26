import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/sync_provider.dart';
import '../domain/sync_models.dart';

class SyncCenterDialog extends ConsumerStatefulWidget {
  const SyncCenterDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const SyncCenterDialog(),
    );
  }

  @override
  ConsumerState<SyncCenterDialog> createState() => _SyncCenterDialogState();
}

class _SyncCenterDialogState extends ConsumerState<SyncCenterDialog> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Export fields
  final _exportPassController = TextEditingController();
  bool _exportIncludeDocs = true;
  bool _exportPassObscured = true;

  // Import fields
  final _importJsonController = TextEditingController();
  final _importPassController = TextEditingController();
  bool _importPassObscured = true;
  String _selectedMergeMode = 'merge';

  // Device edit
  final _deviceNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _exportPassController.dispose();
    _importJsonController.dispose();
    _importPassController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    final pass = _exportPassController.text.trim();
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Encryption passphrase must be at least 6 characters.'),
        ),
      );
      return;
    }

    final bundle = await ref.read(syncNotifierProvider.notifier).exportBundle(
          passphrase: pass,
          includeDocuments: _exportIncludeDocs,
        );

    if (bundle != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Encrypted sync bundle created! Ready to transfer or copy.'),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleImport() async {
    final pass = _importPassController.text.trim();
    if (pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Please enter the encryption passphrase.'),
        ),
      );
      return;
    }

    final rawJson = _importJsonController.text.trim();
    if (rawJson.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Please paste the encrypted bundle JSON payload.'),
        ),
      );
      return;
    }

    try {
      final decoded = json.decode(rawJson) as Map<String, dynamic>;
      final saltHex = decoded['salt_hex'] as String? ?? '';
      final nonceHex = decoded['nonce_hex'] as String? ?? '';
      final ciphertextB64 = decoded['ciphertext_base64'] as String? ?? '';
      final checksum = decoded['checksum_sha256'] as String?;

      if (saltHex.isEmpty || nonceHex.isEmpty || ciphertextB64.isEmpty) {
        throw const FormatException('Missing salt_hex, nonce_hex, or ciphertext_base64 in bundle.');
      }

      final result = await ref.read(syncNotifierProvider.notifier).importBundle(
            passphrase: pass,
            saltHex: saltHex,
            nonceHex: nonceHex,
            ciphertextBase64: ciphertextB64,
            checksumSha256: checksum,
            mergeMode: _selectedMergeMode,
          );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(result.message)),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to parse or apply sync bundle: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(syncStatusProvider);
    final syncState = ref.watch(syncNotifierProvider);

    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 16),

              // Device Status Ribbon
              _buildDeviceStatusRibbon(statusAsync),
              const SizedBox(height: 16),

              // TabBar Navigation
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primaryLight,
                  unselectedLabelColor: AppColors.textDarkSecondary,
                  tabs: const [
                    Tab(text: 'Export Bundle'),
                    Tab(text: 'Import Sync'),
                    Tab(text: 'Snapshot Backups'),
                  ],
                ),
              ),

              // TabBarView Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExportTab(syncState),
                    _buildImportTab(syncState),
                    _buildBackupsTab(syncState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.enhanced_encryption_rounded, color: AppColors.primaryLight, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 4,
                children: const [
                  Text(
                    'StudyOS Sync & Cloud Center',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDarkPrimary,
                    ),
                  ),
                  _CryptoStatusChip(),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Zero-knowledge AES-256-GCM encrypted transfer across laptops, phones, and backup vaults.',
                style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textDarkSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildDeviceStatusRibbon(AsyncValue<SyncStatusModel> statusAsync) {
    return statusAsync.when(
      loading: () => Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Text('Unable to read sync device status: $e', style: const TextStyle(color: AppColors.error, fontSize: 12)),
      ),
      data: (status) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.laptop_chromebook_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Text(
                          status.deviceName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDarkPrimary),
                        ),
                        Text(
                          'ID: ${status.deviceId}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textDarkMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      children: [
                        Text('${status.totalRoadmaps} roadmaps', style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                        Text('• ${status.totalNotes} notes', style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                        Text('• ${status.totalFlashcards} flashcards', style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                        Text('• ${status.totalDocuments} docs', style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                        Text('• Rev: ${status.databaseRevision}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.accent)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textDarkSecondary),
                tooltip: 'Rename device',
                onPressed: () => _showRenameDialog(context, status.deviceName),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportTab(SyncState syncState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GENERATE ENCRYPTED SYNC BUNDLE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: AppColors.textDarkSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Derives an AES-256-GCM symmetric key with PBKDF2 (100,000 iterations). Your passphrase never leaves this machine.',
            style: TextStyle(fontSize: 12, color: AppColors.textDarkMuted),
          ),
          const SizedBox(height: 14),

          // Passphrase Input
          TextField(
            key: const Key('sync_export_passphrase_field'),
            controller: _exportPassController,
            obscureText: _exportPassObscured,
            style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Master Encryption Passphrase',
              labelStyle: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
              hintText: 'Enter a strong secret passphrase (min 6 characters)',
              hintStyle: const TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
              prefixIcon: const Icon(Icons.key_rounded, size: 18, color: AppColors.primaryLight),
              suffixIcon: IconButton(
                icon: Icon(_exportPassObscured ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18, color: AppColors.textDarkSecondary),
                onPressed: () => setState(() => _exportPassObscured = !_exportPassObscured),
              ),
              filled: true,
              fillColor: AppColors.darkCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.darkBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.darkBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),

          // Include documents checkbox
          CheckboxListTile(
            value: _exportIncludeDocs,
            onChanged: (val) => setState(() => _exportIncludeDocs = val ?? true),
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: const Text('Include indexed study documents and RAG chunks', style: TextStyle(fontSize: 13, color: AppColors.textDarkPrimary)),
            subtitle: const Text('Uncheck to produce a smaller, ultra-compact sync payload', style: TextStyle(fontSize: 11, color: AppColors.textDarkMuted)),
          ),
          const SizedBox(height: 14),

          // Export Button
          ElevatedButton.icon(
            key: const Key('generate_sync_bundle_button'),
            onPressed: syncState.isBusy ? null : _handleExport,
            icon: syncState.isBusy
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock_rounded, size: 16),
            label: Text(syncState.isBusy ? 'Encrypting with AES-256-GCM...' : 'Generate Encrypted Bundle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          // Result Viewer
          if (syncState.lastExport != null) ...[
            const SizedBox(height: 20),
            const Divider(color: AppColors.darkBorder),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ENCRYPTED SYNC BUNDLE (JSON)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: AppColors.textDarkSecondary),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final jsonStr = json.encode(syncState.lastExport!.toJson());
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Encrypted bundle copied to clipboard!')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copy Bundle JSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkCard,
                    foregroundColor: AppColors.primaryLight,
                    side: const BorderSide(color: AppColors.darkBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: SelectableText(
                json.encode(syncState.lastExport!.toJson()),
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textDarkSecondary),
                maxLines: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImportTab(SyncState syncState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IMPORT ENCRYPTED SYNC BUNDLE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: AppColors.textDarkSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Paste the encrypted JSON bundle from your other device and provide the master passphrase to decrypt and merge.',
            style: TextStyle(fontSize: 12, color: AppColors.textDarkMuted),
          ),
          const SizedBox(height: 14),

          // Bundle JSON Input
          TextField(
            key: const Key('sync_import_payload_field'),
            controller: _importJsonController,
            maxLines: 6,
            minLines: 4,
            style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'Paste encrypted bundle JSON here (containing salt_hex, nonce_hex, ciphertext_base64)...',
              hintStyle: const TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
              filled: true,
              fillColor: AppColors.darkCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.darkBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.darkBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 14),

          // Passphrase Input
          TextField(
            key: const Key('sync_import_passphrase_field'),
            controller: _importPassController,
            obscureText: _importPassObscured,
            style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Master Encryption Passphrase',
              labelStyle: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
              hintText: 'Enter the passphrase used to encrypt this bundle',
              hintStyle: const TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
              prefixIcon: const Icon(Icons.lock_open_rounded, size: 18, color: AppColors.accent),
              suffixIcon: IconButton(
                icon: Icon(_importPassObscured ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18, color: AppColors.textDarkSecondary),
                onPressed: () => setState(() => _importPassObscured = !_importPassObscured),
              ),
              filled: true,
              fillColor: AppColors.darkCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.darkBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.darkBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          // Merge Mode Option
          Row(
            children: [
              const Text('Merge Mode:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary)),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Merge (Safe Upsert)'),
                selected: _selectedMergeMode == 'merge',
                onSelected: (val) => setState(() => _selectedMergeMode = 'merge'),
                selectedColor: AppColors.primary.withValues(alpha: 0.3),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _selectedMergeMode == 'merge' ? AppColors.primaryLight : AppColors.textDarkSecondary,
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Overwrite (Replace All)'),
                selected: _selectedMergeMode == 'overwrite',
                onSelected: (val) => setState(() => _selectedMergeMode = 'overwrite'),
                selectedColor: AppColors.error.withValues(alpha: 0.3),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: _selectedMergeMode == 'overwrite' ? AppColors.error : AppColors.textDarkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Import Button
          ElevatedButton.icon(
            key: const Key('apply_sync_bundle_button'),
            onPressed: syncState.isBusy ? null : _handleImport,
            icon: syncState.isBusy
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync_rounded, size: 16),
            label: Text(syncState.isBusy ? 'Decrypting & Merging...' : 'Decrypt & Apply Sync Bundle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.darkBg,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          // Success Result Card
          if (syncState.lastImport != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                      SizedBox(width: 8),
                      Text('Sync Completed Successfully', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Conflicts safely resolved: ${syncState.lastImport!.conflictsResolved}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: syncState.lastImport!.entitiesImported.entries
                        .map((e) => Chip(
                              label: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 10)),
                              backgroundColor: AppColors.darkSurface,
                              side: const BorderSide(color: AppColors.darkBorder),
                              padding: EdgeInsets.zero,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackupsTab(SyncState syncState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENCRYPTED DATABASE SNAPSHOT BACKUPS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: AppColors.textDarkSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a self-contained AES-256-GCM encrypted snapshot backup of your StudyOS database that can be stored securely in cloud storage (Google Drive, iCloud, OneDrive) without exposing your study notes or roadmap data.',
            style: TextStyle(fontSize: 12, color: AppColors.textDarkMuted, height: 1.4),
          ),
          const SizedBox(height: 20),

          // Backup Export Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primaryLight, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create Encrypted Snapshot Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDarkPrimary)),
                      SizedBox(height: 2),
                      Text('Exports complete study repository into encrypted JSON vault with SHA-256 checksum', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Export Now', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Backup Restore Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_download_rounded, color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Restore from Encrypted Snapshot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDarkPrimary)),
                      SizedBox(height: 2),
                      Text('Decrypts and recovers your entire study repository onto this workstation', style: TextStyle(fontSize: 11, color: AppColors.textDarkSecondary)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _tabController.animateTo(1);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  child: const Text('Restore Now', style: TextStyle(color: AppColors.darkBg, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String currentName) {
    _deviceNameController.text = currentName;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Rename Device', style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 16)),
        content: TextField(
          controller: _deviceNameController,
          style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
          decoration: const InputDecoration(
            labelText: 'Device Name',
            labelStyle: TextStyle(color: AppColors.textDarkSecondary),
            filled: true,
            fillColor: AppColors.darkCard,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final newName = _deviceNameController.text.trim();
              if (newName.isNotEmpty) {
                await ref.read(syncNotifierProvider.notifier).registerDeviceName(newName);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CryptoStatusChip extends StatelessWidget {
  const _CryptoStatusChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 12, color: AppColors.success),
          SizedBox(width: 4),
          Text(
            'AES-GCM-256 Active',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
