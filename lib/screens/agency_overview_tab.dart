import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/dashboard_models.dart';
import '../widgets/common_widgets.dart';
import '../services/agency_dashboard_service.dart';
import '../services/api_client.dart';

/// Agency dashboard "Overview": bookings, revenue, rating and unread
/// messages at a glance. Polls periodically so the numbers stay current
/// without the agency having to pull-to-refresh.
class AgencyOverviewTab extends StatefulWidget {
  const AgencyOverviewTab({super.key});

  @override
  State<AgencyOverviewTab> createState() => _AgencyOverviewTabState();
}

class _AgencyOverviewTabState extends State<AgencyOverviewTab> {
  static const _pollInterval = Duration(seconds: 12);

  late Future<AgencyStats> _statsFuture;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _statsFuture = AgencyDashboardService.instance.getStats();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    try {
      final stats = await AgencyDashboardService.instance.getStats();
      if (mounted) setState(() => _statsFuture = Future.value(stats));
    } catch (_) {
      // Silent — a missed background refresh isn't worth interrupting for.
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<AgencyStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Could not load your stats.';
            return ListView(children: [StateMessage(icon: Icons.wifi_off, message: message)]);
          }
          final stats = snapshot.data!;
          final cards = [
            _StatCard(label: 'Upcoming trips', value: '${stats.tripsUpcoming}', icon: Icons.event_available, color: AppColors.indigo),
            _StatCard(label: 'Total trips', value: '${stats.tripsTotal}', icon: Icons.directions_bus, color: AppColors.textSecondary),
            _StatCard(label: 'Confirmed bookings', value: '${stats.bookingsConfirmed}', icon: Icons.confirmation_number, color: AppColors.success),
            _StatCard(label: 'Total bookings', value: '${stats.bookingsTotal}', icon: Icons.event_seat, color: AppColors.textSecondary),
            _StatCard(label: 'Revenue', value: formatFcfa(stats.revenueTotal.round()), icon: Icons.payments, color: AppColors.gold),
            _StatCard(
              label: 'Rating',
              value: stats.averageRating != null ? '${stats.averageRating!.toStringAsFixed(1)} \u2605' : '\u2014',
              icon: Icons.star,
              color: AppColors.goldDark,
              footnote: '${stats.reviewsCount} review(s)',
            ),
            _StatCard(
              label: 'Unread messages',
              value: '${stats.unreadMessagesCount}',
              icon: Icons.chat_bubble_outline,
              color: stats.unreadMessagesCount > 0 ? AppColors.danger : AppColors.textSecondary,
            ),
          ];
          return GridView.count(
            padding: const EdgeInsets.all(20),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: cards,
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? footnote;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, this.footnote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (footnote != null) Text(footnote!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
