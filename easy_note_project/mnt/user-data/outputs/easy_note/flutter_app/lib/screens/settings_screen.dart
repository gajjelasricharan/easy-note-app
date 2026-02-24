// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = ref.watch(darkModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User info
          if (user != null) ...[
            _buildSection(context, 'Account', [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.softTan,
                  child: Text(
                    (user.displayName ?? user.email ?? 'U').substring(0, 1).toUpperCase(),
                    style: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
                  ),
                ),
                title: Text(user.displayName ?? 'User'),
                subtitle: Text(user.email ?? ''),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          _buildSection(context, 'Appearance', [
            SwitchListTile(
              title: Text('Dark mode', style: GoogleFonts.dmSans()),
              subtitle: Text('Switch to dark theme', style: GoogleFonts.dmSans(fontSize: 12)),
              value: isDark,
              onChanged: (val) => ref.read(darkModeProvider.notifier).state = val,
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection(context, 'About', [
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text('Version', style: GoogleFonts.dmSans()),
              trailing: Text('1.0.0', style: GoogleFonts.dmSans(color: AppTheme.warmGray)),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text('Privacy Policy', style: GoogleFonts.dmSans()),
              trailing: const Icon(Icons.chevron_right_rounded, size: 18),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text('Sign out', style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
