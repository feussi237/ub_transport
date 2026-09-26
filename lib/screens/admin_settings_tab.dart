import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';
import '../models/dashboard_models.dart';

/// Admin "Settings": platform-wide configuration — default commission rate
/// for new agencies, how long a seat stays locked mid-checkout, the support
/// contact shown to passengers, and a maintenance-mode switch.
class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  late Future<SystemSettings> _future;
  final _commissionController = TextEditingController();
  final _seatLockController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _supportEmailController = TextEditingController();
  bool _maintenanceMode = false;
  bool _loaded = false;
  bool _saving = false;
  String? _error;
  String? _savedMessage;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<SystemSettings> _load() async {
    final settings = await AdminService.instance.getSettings();
    _commissionController.text = settings.defaultCommissionRate.toString();
    _seatLockController.text = settings.seatLockMinutes.toString();
    _supportPhoneController.text = settings.supportPhone;
    _supportEmailController.text = settings.supportEmail;
    _maintenanceMode = settings.maintenanceMode;
    _loaded = true;
    return settings;
  }

  @override
  void dispose() {
    _commissionController.dispose();
    _seatLockController.dispose();
    _supportPhoneController.dispose();
    _supportEmailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _savedMessage = null;
    });
    try {
      await AdminService.instance.updateSettings({
        'default_commission_rate': double.tryParse(_commissionController.text.trim()) ?? 10,
        'seat_lock_minutes': int.tryParse(_seatLockController.text.trim()) ?? 5,
        'support_phone': _supportPhoneController.text.trim(),
        'support_email': _supportEmailController.text.trim(),
        'maintenance_mode': _maintenanceMode.toString(),
      });
      if (mounted) setState(() => _savedMessage = 'Settings saved.');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SystemSettings>(
      future: _future,
      builder: (context, snapshot) {
        if (!_loaded && snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!_loaded && snapshot.hasError) {
          return const StateMessage(icon: Icons.wifi_off, message: 'Could not load settings.');
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_savedMessage != null) ...[
              Text(_savedMessage!, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
            ],
            LabeledField(
              label: 'Default commission rate (%)',
              hint: '10',
              controller: _commissionController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Seat lock duration (minutes)',
              hint: '5',
              controller: _seatLockController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            LabeledField(label: 'Support phone', hint: '+237...', controller: _supportPhoneController),
            const SizedBox(height: 16),
            LabeledField(label: 'Support email', hint: 'support@ubtransport.cm', controller: _supportEmailController),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Maintenance mode', style: AppTextStyles.label),
              subtitle: const Text('Shows a maintenance notice to passengers when on.', style: AppTextStyles.subtitle),
              value: _maintenanceMode,
              activeColor: AppColors.gold,
              onChanged: (v) => setState(() => _maintenanceMode = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 20),
            PrimaryButton(label: _saving ? 'Saving…' : 'Save settings', onPressed: _saving ? null : _save),
          ],
        );
      },
    );
  }
}
