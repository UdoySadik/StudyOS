import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                color: AppColors.textDarkPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your local workspace preferences and application parameters.',
              style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: ListView(
                children: [
                  _buildSectionHeader('Appearance'),
                  _buildThemeSetting(),
                  const Divider(color: AppColors.darkBorder, height: 32),
                  _buildSectionHeader('About StudyOS'),
                  _buildInfoRow('Version', '1.0.0 (MVP)'),
                  _buildInfoRow('Database Engine', 'SQLite 3.x'),
                  _buildInfoRow('Local Port', '127.0.0.1:8000'),
                  _buildInfoRow('Platform Support', 'Windows / Linux'),
                  const Divider(color: AppColors.darkBorder, height: 32),
                  _buildSectionHeader('Troubleshooting'),
                  _buildResetDataSetting(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildThemeSetting() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.dark_mode, color: AppColors.textDarkSecondary),
              SizedBox(width: 12),
              Text(
                'Dark Theme',
                style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 14),
              ),
            ],
          ),
          Switch(
            value: true, // V1.0 Dark Mode default
            onChanged: (val) {
              // Switch functionality
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildResetDataSetting(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Database Clean Reset',
                style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Deletes all roadmaps, tasks, notes, and milestones.',
                style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              // Confirm reset dialog
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.darkCard,
                  title: const Text('Reset Application Database?'),
                  content: const Text(
                    'Are you sure you want to proceed? This will erase all your local roadmap and task progress files.',
                    style: TextStyle(color: AppColors.textDarkSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // DB clear triggers
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Reset All'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error.withOpacity(0.8)),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }
}
