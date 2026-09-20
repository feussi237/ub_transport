import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/api_models.dart';
import '../widgets/common_widgets.dart';
import '../services/booking_service.dart';
import '../services/api_client.dart';
import 'booking_confirmation_screen.dart';

enum PaymentMethod { mtnMomo, orangeMoney }

class PaymentScreen extends StatefulWidget {
  final BusTrip trip;
  final List<Passenger> passengers;

  const PaymentScreen({
    super.key,
    required this.trip,
    required this.passengers,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final BookingService _bookings = BookingService.instance;

  PaymentMethod _method = PaymentMethod.mtnMomo;
  bool _isProcessing = false;
  String? _error;

  late Future<List<ApiBooking>> _bookingsFuture;

  int get _total => widget.trip.priceFcfa * widget.passengers.length;

  @override
  void initState() {
    super.initState();
    // Seats are only really reserved once a booking exists on the backend
    // (that's what row-locks the seat), so this happens as soon as the
    // passenger reaches the payment screen, not when they tap "Pay".
    _bookingsFuture = _createBookings();
  }

  Future<List<ApiBooking>> _createBookings() async {
    final created = <ApiBooking>[];
    try {
      for (final passenger in widget.passengers) {
        created.add(await _bookings.book(passenger.tripSeatId));
      }
      return created;
    } catch (e) {
      // Roll back any seat(s) we did manage to lock before the failure.
      for (final booking in created) {
        await _bookings.cancel(booking.id, reason: 'Booking failed for another seat in this reservation.');
      }
      rethrow;
    }
  }

  Future<void> _pay(List<ApiBooking> bookings) async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      final provider = _method == PaymentMethod.mtnMomo ? 'mtn_momo' : 'orange_money';
      for (final booking in bookings) {
        final payment = await _bookings.initiatePayment(booking.id, provider: provider);
        await _bookings.simulateProviderConfirmation(payment.transactionRef);
      }
      final tickets = <ApiTicket>[];
      for (final booking in bookings) {
        tickets.add(await _bookings.getTicket(booking.id));
      }
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(
            trip: widget.trip,
            passengers: widget.passengers,
            tickets: tickets,
            totalFcfa: _total,
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Payment could not be completed. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenHeader(
        title: 'Payment Checkout',
        subtitle: 'Complete your reservation',
      ),
      body: FutureBuilder<List<ApiBooking>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Reserving your seat(s)…', style: AppTextStyles.subtitle),
                  ],
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'One of your seats was taken before checkout completed.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Choose another seat'),
                    ),
                  ],
                ),
              ),
            );
          }

          final bookings = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.darkOlive,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${widget.trip.origin} → ${widget.trip.destination}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                          Text(formatDate(widget.trip.departureAt),
                              style: const TextStyle(
                                  color: AppColors.teal, fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Color(0x33FFFFFF), height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Seats Selected',
                                  style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
                              Text(widget.passengers.map((p) => p.seatLabel).join(', '),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total Price',
                                  style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
                              Text(formatFcfa(_total),
                                  style: const TextStyle(
                                      color: AppColors.teal, fontSize: 18, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Select Payment Method', style: AppTextStyles.h2),
                const SizedBox(height: 14),
                _PaymentOptionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'MTN Mobile Money',
                  subtitle: 'Pay with your MTN MoMo wallet',
                  selected: _method == PaymentMethod.mtnMomo,
                  onTap: () => setState(() => _method = PaymentMethod.mtnMomo),
                ),
                const SizedBox(height: 10),
                _PaymentOptionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Orange Money',
                  subtitle: 'Pay with your Orange Money wallet',
                  selected: _method == PaymentMethod.orangeMoney,
                  onTap: () => setState(() => _method = PaymentMethod.orangeMoney),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isProcessing ? 'Processing…' : 'Pay ${formatFcfa(_total)} Now',
                  onPressed: _isProcessing ? null : () => _pay(bookings),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.teal : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.chipFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: AppTextStyles.subtitle),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.teal : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.teal : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
