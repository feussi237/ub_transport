import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/dashboard_models.dart';
import '../widgets/common_widgets.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';

/// Admin "Trips": every trip across every agency, with the ability to
/// override its status (e.g. force-cancel a problematic trip).
class AdminTripsTab extends StatefulWidget {
  const AdminTripsTab({super.key});

  @override
  State<AdminTripsTab> createState() => _AdminTripsTabState();
}

class _AdminTripsTabState extends State<AdminTripsTab> {
  static const _pollInterval = Duration(seconds: 15);

  late Future<List<DashboardTrip>> _future;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.listTrips();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final future = AdminService.instance.listTrips();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {
      // Silent on background polling failures.
    }
  }

  Future<void> _updateStatus(DashboardTrip trip, String status) async {
    try {
      await AdminService.instance.updateTripStatus(trip.id, status);
      _refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Color _statusColor(String status) => switch (status) {
        'completed' => AppColors.success,
        'cancelled' => AppColors.danger,
        'delayed' => AppColors.goldDark,
        _ => AppColors.indigo,
      };

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<DashboardTrip>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(children: const [StateMessage(icon: Icons.wifi_off, message: 'Could not load trips.')]);
          }
          final trips = snapshot.data!;
          if (trips.isEmpty) {
            return ListView(children: const [StateMessage(icon: Icons.directions_bus_outlined, message: 'No trips yet.')]);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${trip.originCity} → ${trip.destinationCity}', style: AppTextStyles.label)),
                        Pill(text: trip.status, background: _statusColor(trip.status).withValues(alpha: 0.15), textColor: _statusColor(trip.status)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.agencyName ?? 'Unknown agency'} · ${formatDate(trip.departureAt)} · ${formatFcfa(trip.price.round())}',
                      style: AppTextStyles.subtitle,
                    ),
                    if (trip.status == 'scheduled' || trip.status == 'delayed') ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 4, children: [
                        if (trip.status != 'delayed')
                          TextButton(onPressed: () => _updateStatus(trip, 'delayed'), child: const Text('Mark delayed')),
                        TextButton(
                          onPressed: () => _updateStatus(trip, 'cancelled'),
                          child: const Text('Cancel trip', style: TextStyle(color: AppColors.danger)),
                        ),
                      ]),
                    ],
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
