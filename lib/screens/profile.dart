import 'package:flutter/material.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../utils/constants.dart';
import '../widgets/widgets.dart';

/// Profile page — identity card, account actions, account-level
/// preferences, and logout.
///
/// UI-mockup implementation: [_profile] and both preference toggles hold
/// local, in-memory dummy state. Nothing is persisted yet; this is tracked
/// as the Local Database / Authentication modules.
class ProfilePage extends StatefulWidget {
  /// Creates a [ProfilePage].
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile _profile = UserProfile(
    name: 'Kent',
    email: 'kent@example.com',
    joinDate: DateTime(2025, 3, 12),
  );

  // --- Preferences (account-level — deliberately distinct from the
  // app-wide toggles already on the Settings page) ---
  bool _weeklyEmailSummary = true;
  bool _personalizedInsights = true;

  /// Opens a dialog to edit [_profile]'s name/email, and applies the
  /// result. This is the one Account-section action that's actually
  /// functional in this mockup — the rest are placeholders, same as
  /// Settings' About links.
  Future<void> _editProfile() async {
    final result = await _showEditProfileDialog(context, _profile);
    if (result == null || !mounted) return;
    setState(() => _profile = result);
  }

  /// Placeholder action for Account items with no real destination yet.
  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
  }

  /// Confirms, then logs out.
  ///
  /// `pushNamedAndRemoveUntil` clears the entire navigation stack rather
  /// than just replacing the current route, so the back button can't
  /// re-enter a page from the "logged in" session after logging out.
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Log out?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          "You'll need to sign back in to access your saved trips and "
          'preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final hPad = isWide ? 40.0 : 20.0;
            const maxW = 480.0;

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      ProfileHeaderCard(profile: _profile),
                      const SizedBox(height: 16),
                      _buildInsightsTeaser(context),
                      const SizedBox(height: 16),
                      SettingsSection(
                        title: 'Account',
                        icon: Icons.account_circle_outlined,
                        children: [
                          SettingsLinkTile(
                            icon: Icons.edit_outlined,
                            label: 'Edit Profile',
                            onTap: _editProfile,
                          ),
                          SettingsLinkTile(
                            icon: Icons.lock_outline_rounded,
                            label: 'Change Password',
                            onTap: () => _showComingSoon('Change Password'),
                          ),
                          SettingsLinkTile(
                            icon: Icons.link_rounded,
                            label: 'Linked Accounts',
                            onTap: () => _showComingSoon('Linked Accounts'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SettingsSection(
                        title: 'Preferences',
                        icon: Icons.tune_rounded,
                        children: [
                          SettingsSwitchTile(
                            icon: Icons.mail_outline_rounded,
                            label: 'Weekly Email Summary',
                            subtitle: 'Trips and savings, once a week',
                            value: _weeklyEmailSummary,
                            onChanged: (value) => setState(
                              () => _weeklyEmailSummary = value,
                            ),
                          ),
                          SettingsSwitchTile(
                            icon: Icons.insights_rounded,
                            label: 'Personalized Insights',
                            subtitle: 'Use your trip history for savings tips',
                            value: _personalizedInsights,
                            onChanged: (value) => setState(
                              () => _personalizedInsights = value,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _confirmLogout,
                          icon: const Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          label: const Text('Log Out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Entry point to the Insights & Analytics Dashboard.
  ///
  /// Kept here rather than added to the top bar (which already has 5 icons)
  /// or the bottom nav — this stays within a file this module already
  /// owns, avoiding another edit to `top_bar.dart`/`homepage.dart`.
  Widget _buildInsightsTeaser(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.of(context).pushNamed(AppRoutes.insightsDashboard),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A1A2CC8),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insights & Analytics',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'This month: saved RM222.50',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Shows a dialog to edit [current]'s name/email.
///
/// Returns the updated [UserProfile], or `null` if cancelled.
Future<UserProfile?> _showEditProfileDialog(
  BuildContext context,
  UserProfile current,
) {
  final nameController = TextEditingController(text: current.name);
  final emailController = TextEditingController(text: current.email);
  final formKey = GlobalKey<FormState>();
  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  return showDialog<UserProfile>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Edit profile',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a name'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter an email';
                }
                if (!emailPattern.hasMatch(value.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            if (!(formKey.currentState?.validate() ?? false)) return;
            Navigator.of(dialogContext).pop(
              current.copyWith(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    ),
  ).whenComplete(() {
    nameController.dispose();
    emailController.dispose();
  });
}
