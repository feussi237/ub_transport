import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/api_models.dart';
import '../widgets/common_widgets.dart';
import '../services/booking_service.dart';
import '../services/api_client.dart';
import 'reviews_screen.dart';
import 'messages_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final ApiBooking booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late ApiBooking _booking;
  bool _cancelling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  bool get _canCancel => _booking.status != 'cancelled' && !_booking.isCompleted;
  bool get _canReview => _booking.isCompleted && _booking.status == 'confirmed';
  bool get _canMessage => _booking.agencyId != null;

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: const Text('This releases your seat. Refunds apply only more than 24h before departure.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep booking')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cancel booking')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _cancelling = true;
      _error = null;
    });
    try {
      await BookingService.instance.cancel(_booking.id);
      if (!mounted) return;
      setState(() {
        _booking = ApiBooking(
          id: _booking.id,
          tripId: _booking.tripId,
          tripSeatId: _booking.tripSeatId,
          seatNumber: _booking.seatNumber,
          status: 'cancelled',
          agencyId: _booking.agencyId,
          agencyName: _booking.agencyName,
          originCity: _booking.originCity,
          destinationCity: _booking.destinationCity,
          departureAt: _booking.departureAt,
          price: _booking.price,
          tripStatus: _booking.tripStatus,
          ticket: _booking.ticket,
          lastPaymentStatus: _booking.lastPaymentStatus,
        );
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _booking;
    return Scaffold(
      appBar: ScreenHeader(title: '${b.originCity ?? ''} → ${b.destinationCity ?? ''}', subtitle: b.agencyName),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TicketCard(booking: b),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 12),
            ],
            if (_canReview)
              PrimaryButton(
                label: 'Rate this trip',
                icon: Icons.star_border,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ReviewsScreen(
                    agencyId: b.agencyId!,
                    agencyName: b.agencyName ?? 'Agency',
                    tripId: b.tripId,
                  ),
                )),
              ),
            if (_canReview) const SizedBox(height: 12),
            if (_canMessage)
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MessagesScreen(
                    agencyId: b.agencyId!,
                    agencyName: b.agencyName ?? 'Agency',
                    tripId: b.tripId,
                  ),
                )),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Message the agency'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              ),
            if (_canCancel) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _cancelling ? null : _cancel,
                child: _cancelling
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Cancel booking', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final ApiBooking booking;

  const _TicketCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TRAVEL TICKET', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.chipFill, borderRadius: BorderRadius.circular(10)),
                child: Text('#${booking.tripId}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.originCity ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.teal)),
                    if (booking.departureAt != null)
                      Text(formatDate(booking.departureAt!), style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.directions_bus, color: AppColors.textMuted, size: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(booking.destinationCity ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.teal)),
                    Text('Seat ${booking.seatNumber}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(color: AppColors.border, height: 1),
          ),
          if (booking.price != null)
            Center(
              child: Text('TOTAL  ${formatFcfa(booking.price!.round())}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.teal)),
            ),
          const SizedBox(height: 20),
          if (booking.ticket != null) ...[
            Center(
              child: Container(
                width: 150,
                height: 150,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.chipFill, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(
                  data: booking.ticket!.qrCode,
                  version: QrVersions.auto,
                  backgroundColor: AppColors.chipFill,
                  eyeStyle: const QrEyeStyle(color: AppColors.textPrimary),
                  dataModuleStyle: const QrDataModuleStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                booking.ticket!.boardingStatus == 'boarded' ? 'Already boarded' : 'Present QR code during boarding',
                style: AppTextStyles.subtitle,
              ),
            ),
          ] else
            Center(
              child: Text(
                booking.status == 'cancelled' ? 'This booking was cancelled.' : 'Ticket is issued once payment is confirmed.',
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
