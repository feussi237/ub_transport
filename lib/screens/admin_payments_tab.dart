import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/dashboard_models.dart';
import '../widgets/common_widgets.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';

/// Admin "Payments": every payment on the platform, with a refund action
/// for successful ones (the actual mobile-money reversal happens outside
/// this system — this just records it and updates the payment's status).
class AdminPaymentsTab extends StatefulWidget {
  const AdminPaymentsTab({super.key});

  @override
  State<AdminPaymentsTab> createState() => _AdminPaymentsTabState();
}

class _AdminPaymentsTabState extends State<AdminPaymentsTab> {
  late Future<List<AdminPayment>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.listPayments();
  }

  Future<void> _refresh() async {
    final future = AdminService.instance.listPayments();
    setState(() => _future = future);
    await future;
  }

  Future<void> _refund(AdminPayment payment) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refund payment'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Reason (required)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(reasonController.text.trim()), child: const Text('Refund')),
        ],
      ),
    );
    if (confirmed == null || confirmed.isEmpty) return;

    try {
      await AdminService.instance.refundPayment(payment.id, confirmed);
      _refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Color _statusColor(String status) => switch (status) {
        'success' => AppColors.success,
        'refunded' => AppColors.indigo,
        'failed' => AppColors.danger,
        _ => AppColors.goldDark,
      };

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<AdminPayment>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(children: const [StateMessage(icon: Icons.wifi_off, message: 'Could not load payments.')]);
          }
          final payments = snapshot.data!;
          if (payments.isEmpty) {
            return ListView(children: const [StateMessage(icon: Icons.payments_outlined, message: 'No payments yet.')]);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = payments[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${p.passengerName} · ${p.provider}', style: AppTextStyles.label),
                          Text('${p.originCity} → ${p.destinationCity}', style: AppTextStyles.subtitle),
                          if (p.agencyName != null) Text(p.agencyName!, style: AppTextStyles.subtitle),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatFcfa(p.amount.round()), style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Pill(text: p.status, background: _statusColor(p.status).withValues(alpha: 0.15), textColor: _statusColor(p.status)),
                        if (p.status == 'success')
                          TextButton(onPressed: () => _refund(p), child: const Text('Refund')),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
