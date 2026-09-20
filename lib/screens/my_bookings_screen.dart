import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/api_models.dart';
import '../widgets/common_widgets.dart';
import '../services/booking_service.dart';
import '../services/api_client.dart';
import 'booking_detail_screen.dart';

/// "My Bookings": the passenger's full reservation history, most recent
/// first, with a status pill per card. Tapping a card opens the ticket
/// (QR + cancel/review/message actions) in [BookingDetailScreen].
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late Future<List<ApiBooking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = BookingService.instance.list();
  }

  Future<void> _refresh() async {
    final future = BookingService.instance.list();
    setState(() => _bookingsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenHeader(title: 'My Bookings', subtitle: 'Your trip history'),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ApiBooking>>(
          future: _bookingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final message = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Could not load your bookings. Check your connection and try again.';
              return ListView(children: [StateMessage(icon: Icons.wifi_off, message: message)]);
            }
            final bookings = snapshot.data!;
            if (bookings.isEmpty) {
              return ListView(children: const [
                StateMessage(
                  icon: Icons.confirmation_number_outlined,
                  message: 'No bookings yet — search a trip to get started.',
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) => _BookingCard(booking: bookings[index]),
            );
          },
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final ApiBooking booking;

  const _BookingCard({required this.booking});

  Color get _statusColor {
    switch (booking.status) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.goldDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: booking)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${booking.originCity ?? '?'} → ${booking.destinationCity ?? '?'}',
                    style: AppTextStyles.h2.copyWith(fontSize: 16),
                  ),
                ),
                Pill(
                  text: booking.status[0].toUpperCase() + booking.status.substring(1),
                  background: _statusColor.withValues(alpha: 0.15),
                  textColor: _statusColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(booking.agencyName ?? '', style: AppTextStyles.subtitle),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.departureAt != null ? formatDate(booking.departureAt!) : '',
                  style: AppTextStyles.label,
                ),
                Text('Seat ${booking.seatNumber}', style: AppTextStyles.label),
                Text(
                  booking.price != null ? formatFcfa(booking.price!.round()) : '',
                  style: AppTextStyles.label.copyWith(color: AppColors.teal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
