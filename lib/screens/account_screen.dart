import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'sign_up_screen.dart';

/// Passenger "Account" tab: edit your own name/phone, or log out.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _saving = false;
  String? _error;
  String? _savedMessage;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _savedMessage = null;
    });
    try {
      await AuthService.instance.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) setState(() => _savedMessage = 'Profile updated.');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: const ScreenHeader(title: 'Account'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.chipFill,
                  child: Text(
                    (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '', style: AppTextStyles.h2.copyWith(fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '', style: AppTextStyles.subtitle),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_savedMessage != null) ...[
            Text(_savedMessage!, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
          ],
          const Text('Edit profile', style: AppTextStyles.label),
          const SizedBox(height: 12),
          LabeledField(label: 'Name', hint: 'Your name', controller: _nameController),
          const SizedBox(height: 14),
          LabeledField(label: 'Phone', hint: '+237...', controller: _phoneController),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 14),
          PrimaryButton(label: _saving ? 'Saving…' : 'Save changes', onPressed: _saving ? null : _save),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('Log out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
