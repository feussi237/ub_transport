import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/dashboard_models.dart';
import '../widgets/common_widgets.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';

/// Admin "Reports": platform-wide numbers — agencies, users, trips,
/// bookings, total revenue, a simple revenue-by-month trend, and the
/// top 5 agencies by booking volume.
class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  late Future<PlatformReport> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.getReports();
  }

  Future<void> _refresh() async {
    final future = AdminService.instance.getReports();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<PlatformReport>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(children: const [StateMessage(icon: Icons.wifi_off, message: 'Could not load reports.')]);
          }
          final r = snapshot.data!;
          final maxMonthly = r.revenueByMonth.isEmpty
              ? 1.0
              : r.revenueByMonth.map((m) => m.total).reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.5,
                children: [
                  _StatTile(label: 'Total revenue', value: formatFcfa(r.revenueTotal.round()), icon: Icons.payments, color: AppColors.gold),
                  _StatTile(label: 'Agencies', value: '${r.agenciesTotal} (${r.agenciesVerified} verified)', icon: Icons.apartment, color: AppColors.indigo),
                  _StatTile(label: 'Passengers', value: '${r.passengersTotal}', icon: Icons.people_outline, color: AppColors.textSecondary),
                  _StatTile(label: 'Trips', value: '${r.tripsTotal}', icon: Icons.directions_bus, color: AppColors.textSecondary),
                  _StatTile(label: 'Bookings confirmed', value: '${r.bookingsConfirmed}', icon: Icons.check_circle_outline, color: AppColors.success),
                  _StatTile(label: 'Bookings cancelled', value: '${r.bookingsCancelled}', icon: Icons.cancel_outlined, color: AppColors.danger),
                ],
              ),
              const SizedBox(height: 28),
              const Text('Revenue, last months', style: AppTextStyles.h2),
              const SizedBox(height: 16),
              if (r.revenueByMonth.isEmpty)
                const Text('No revenue recorded yet.', style: AppTextStyles.subtitle)
              else
                SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: r.revenueByMonth
                        .map((m) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(formatFcfa(m.total.round()), style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 90 * (m.total / maxMonthly),
                                      decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(6)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(m.month.substring(5), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 28),
              const Text('Top agencies', style: AppTextStyles.h2),
              const SizedBox(height: 12),
              if (r.topAgencies.isEmpty)
                const Text('No agency activity yet.', style: AppTextStyles.subtitle)
              else
                ...r.topAgencies.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(child: Text(a.name, style: AppTextStyles.label)),
                          Text('${a.bookingsCount} bookings', style: AppTextStyles.subtitle),
                        ],
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: AppTextStyles.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
