import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/auth_service.dart';
import '../services/agency_dashboard_service.dart';
import '../services/api_client.dart';
import 'sign_up_screen.dart';

/// Agency dashboard "Account": edit the signed-in staff member's own name/
/// phone, the agency's public contact details, and sign out.
class AgencyAccountTab extends StatefulWidget {
  const AgencyAccountTab({super.key});

  @override
  State<AgencyAccountTab> createState() => _AgencyAccountTabState();
}

class _AgencyAccountTabState extends State<AgencyAccountTab> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _agencyPhoneController = TextEditingController();
  final _agencyEmailController = TextEditingController();

  bool _savingUser = false;
  bool _savingAgency = false;
  String? _userError;
  String? _agencyError;
  String? _savedMessage;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _agencyPhoneController.text = user?.agencyContactPhone ?? '';
    _agencyEmailController.text = user?.agencyContactEmail ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _agencyPhoneController.dispose();
    _agencyEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    setState(() {
      _savingUser = true;
      _userError = null;
      _savedMessage = null;
    });
    try {
      await AuthService.instance.updateProfile(name: _nameController.text.trim(), phone: _phoneController.text.trim());
      if (mounted) setState(() => _savedMessage = 'Profile updated.');
    } on ApiException catch (e) {
      setState(() => _userError = e.message);
    } finally {
      if (mounted) setState(() => _savingUser = false);
    }
  }

  Future<void> _saveAgency() async {
    setState(() {
      _savingAgency = true;
      _agencyError = null;
      _savedMessage = null;
    });
    try {
      await AgencyDashboardService.instance.updateProfile(
        contactPhone: _agencyPhoneController.text.trim(),
        contactEmail: _agencyEmailController.text.trim(),
      );
      if (mounted) setState(() => _savedMessage = 'Agency details updated.');
    } on ApiException catch (e) {
      setState(() => _agencyError = e.message);
    } finally {
      if (mounted) setState(() => _savingAgency = false);
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        if (_savedMessage != null) ...[
          Text(_savedMessage!, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
        ],
        const Text('Your account', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        LabeledField(label: 'Name', hint: 'Your name', controller: _nameController),
        const SizedBox(height: 14),
        LabeledField(label: 'Phone', hint: '+237...', controller: _phoneController),
        if (_userError != null) ...[
          const SizedBox(height: 8),
          Text(_userError!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 14),
        PrimaryButton(label: _savingUser ? 'Saving…' : 'Save', onPressed: _savingUser ? null : _saveUser),
        const SizedBox(height: 28),
        const Divider(color: AppColors.border),
        const SizedBox(height: 20),
        const Text('Agency contact details', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        LabeledField(label: 'Agency phone', hint: '+237...', controller: _agencyPhoneController),
        const SizedBox(height: 14),
        LabeledField(label: 'Agency email', hint: 'contact@agency.cm', controller: _agencyEmailController),
        if (_agencyError != null) ...[
          const SizedBox(height: 8),
          Text(_agencyError!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 14),
        PrimaryButton(label: _savingAgency ? 'Saving…' : 'Save agency details', onPressed: _savingAgency ? null : _saveAgency),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout, color: AppColors.danger),
          label: const Text('Log out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), side: const BorderSide(color: AppColors.danger)),
        ),
      ],
    );
  }
}
