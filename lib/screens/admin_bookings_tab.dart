import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/dashboard_models.dart';
import '../widgets/common_widgets.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';

/// Admin "Bookings": every booking on the platform, with the ability to
/// force-cancel one (fraud, dispute, unreachable passenger).
class AdminBookingsTab extends StatefulWidget {
  const AdminBookingsTab({super.key});

  @override
  State<AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<AdminBookingsTab> {
  static const _pollInterval = Duration(seconds: 15);

  late Future<List<DashboardBooking>> _future;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.listBookings();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final future = AdminService.instance.listBookings();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {
      // Silent on background polling failures.
    }
  }

  Future<void> _suspend(DashboardBooking booking) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend booking'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Reason (required)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
    if (confirmed == null || confirmed.isEmpty) return;

    try {
      await AdminService.instance.suspendBooking(booking.id, confirmed);
      _refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<DashboardBooking>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(children: const [StateMessage(icon: Icons.wifi_off, message: 'Could not load bookings.')]);
          }
          final bookings = snapshot.data!;
          if (bookings.isEmpty) {
            return ListView(children: const [StateMessage(icon: Icons.confirmation_number_outlined, message: 'No bookings yet.')]);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final b = bookings[index];
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
                          Text('${b.passengerName} · seat ${b.seatNumber}', style: AppTextStyles.label),
                          Text('${b.originCity} → ${b.destinationCity}  ·  ${formatDate(b.departureAt)}', style: AppTextStyles.subtitle),
                          if (b.agencyName != null) Text(b.agencyName!, style: AppTextStyles.subtitle),
                          Text(b.passengerPhone, style: AppTextStyles.subtitle),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Pill(
                          text: b.status,
                          background: (b.status == 'confirmed' ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
                          textColor: b.status == 'confirmed' ? AppColors.success : AppColors.danger,
                        ),
                        if (b.status != 'cancelled')
                          TextButton(
                            onPressed: () => _suspend(b),
                            child: const Text('Suspend', style: TextStyle(color: AppColors.danger)),
                          ),
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
