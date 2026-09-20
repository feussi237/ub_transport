import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/dashboard_models.dart';
import '../widgets/common_widgets.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import 'sign_up_screen.dart';

/// Web dashboard for the `admin` role: verify/suspend agencies, adjust their
/// commission rate, and lock/unlock user accounts. Reuses the same Laravel
/// API and Flutter codebase as the passenger app — this screen is simply
/// never reachable from a passenger account.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('UB Transport — Admin'),
          backgroundColor: AppColors.darkOlive,
          foregroundColor: AppColors.white,
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.textOnDark,
            tabs: [Tab(text: 'Agencies'), Tab(text: 'Users')],
          ),
          actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
        ),
        body: const TabBarView(children: [_AgenciesTab(), _UsersTab()]),
      ),
    );
  }
}

class _AgenciesTab extends StatefulWidget {
  const _AgenciesTab();

  @override
  State<_AgenciesTab> createState() => _AgenciesTabState();
}

class _AgenciesTabState extends State<_AgenciesTab> {
  late Future<List<DashboardAgency>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.listAgencies();
  }

  void _reload() => setState(() => _future = AdminService.instance.listAgencies());

  Future<void> _approve(DashboardAgency agency) async {
    await AdminService.instance.approveAgency(agency.id);
    _reload();
  }

  Future<void> _suspend(DashboardAgency agency) async {
    final reason = await _promptText(context, title: 'Suspend ${agency.name}', hint: 'Reason for suspension');
    if (reason == null || reason.isEmpty) return;
    await AdminService.instance.suspendAgency(agency.id, reason);
    _reload();
  }

  Future<void> _editCommission(DashboardAgency agency) async {
    final value = await _promptText(
      context,
      title: 'Commission for ${agency.name}',
      hint: 'Rate in % (e.g. 10)',
      initial: agency.commissionRate.toString(),
    );
    if (value == null) return;
    final rate = double.tryParse(value);
    if (rate == null) return;
    await AdminService.instance.updateCommission(agency.id, rate);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DashboardAgency>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const StateMessage(icon: Icons.wifi_off, message: 'Could not load agencies.');
        }
        final agencies = snapshot.data!;
        if (agencies.isEmpty) {
          return const StateMessage(icon: Icons.apartment, message: 'No agencies registered yet.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: agencies.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final agency = agencies[index];
            return _DashboardCard(
              title: agency.name,
              subtitle: '${agency.contactPhone ?? ''}  •  commission ${agency.commissionRate.toStringAsFixed(0)}%',
              status: agency.status,
              statusColor: switch (agency.status) {
                'verified' => AppColors.success,
                'suspended' => AppColors.danger,
                _ => AppColors.goldDark,
              },
              actions: [
                if (agency.status != 'verified')
                  TextButton(onPressed: () => _approve(agency), child: const Text('Approve')),
                if (agency.status != 'suspended')
                  TextButton(
                    onPressed: () => _suspend(agency),
                    child: const Text('Suspend', style: TextStyle(color: AppColors.danger)),
                  ),
                TextButton(onPressed: () => _editCommission(agency), child: const Text('Commission')),
              ],
            );
          },
        );
      },
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  late Future<List<DashboardUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.listUsers();
  }

  void _reload() => setState(() => _future = AdminService.instance.listUsers());

  Future<void> _lock(DashboardUser user) async {
    final reason = await _promptText(context, title: 'Lock ${user.name}', hint: 'Reason for locking this account');
    if (reason == null || reason.isEmpty) return;
    await AdminService.instance.lockUser(user.id, reason);
    _reload();
  }

  Future<void> _unlock(DashboardUser user) async {
    await AdminService.instance.unlockUser(user.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DashboardUser>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const StateMessage(icon: Icons.wifi_off, message: 'Could not load users.');
        }
        final users = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = users[index];
            return _DashboardCard(
              title: user.name,
              subtitle: '${user.email}  •  ${user.role}',
              status: user.isLocked ? 'locked' : 'active',
              statusColor: user.isLocked ? AppColors.danger : AppColors.success,
              actions: [
                if (!user.isLocked)
                  TextButton(
                    onPressed: () => _lock(user),
                    child: const Text('Lock', style: TextStyle(color: AppColors.danger)),
                  )
                else
                  TextButton(onPressed: () => _unlock(user), child: const Text('Unlock')),
              ],
            );
          },
        );
      },
    );
  }
}

/// Shared row layout used by both admin tabs: title/subtitle on the left,
/// a status pill and a row of text-button actions on the right.
class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final List<Widget> actions;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: AppTextStyles.label)),
              Pill(text: status, background: statusColor.withValues(alpha: 0.15), textColor: statusColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Wrap(spacing: 4, children: actions),
        ],
      ),
    );
  }
}

/// Small blocking dialog with a single text field — used for every
/// "reason"/"value" prompt across the admin and agency dashboards.
Future<String?> _promptText(BuildContext context, {required String title, String? hint, String? initial}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}
