import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/api_models.dart';
import '../widgets/common_widgets.dart';
import 'main_shell.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final BusTrip trip;
  final List<Passenger> passengers;
  final List<ApiTicket> tickets;
  final int totalFcfa;

  const BookingConfirmationScreen({
    super.key,
    required this.trip,
    required this.passengers,
    required this.tickets,
    required this.totalFcfa,
  });

  @override
  Widget build(BuildContext context) {
    final passengerNames = passengers
        .map((p) => p.fullName.isEmpty ? 'Passenger' : p.fullName.split(' ').first)
        .join(', ');
    final seatLabels = passengers.map((p) => p.seatLabel).join(', ');
    // One booking per seat means one QR code per seat; a group reservation
    // boards by scanning each passenger's own ticket.
    final qrPayload = tickets.map((t) => t.qrCode).join(',');

    return Scaffold(
      backgroundColor: AppColors.darkOlive,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.teal, width: 2),
                ),
                child: const Icon(Icons.check, color: AppColors.teal, size: 34),
              ),
              const SizedBox(height: 18),
              const Text('Booking Confirmed!',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Trip details are successfully booked',
                  style: TextStyle(color: AppColors.teal, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 28),
              Expanded(child: _buildTicketCard(passengerNames, seatLabels, qrPayload)),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Download E-Ticket',
                icon: Icons.download_outlined,
                onPressed: () {},
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  );
                },
                child: const Text('Go back to Home',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(String passengerNames, String seatLabels, String qrPayload) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TRAVEL TICKET',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.chipFill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('#${trip.id}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.departureTime,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(trip.origin.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
                  ],
                ),
                const Icon(Icons.directions_bus, color: AppColors.textMuted, size: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatDate(trip.departureAt),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(trip.destination.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Divider(color: AppColors.border, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PASSENGERS',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(passengerNames,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('SEATS',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(seatLabels,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text('TOTAL  ${formatFcfa(totalFcfa)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.teal)),
            ),
            const SizedBox(height: 22),
            Center(
              child: Container(
                width: 150,
                height: 150,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.chipFill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  backgroundColor: AppColors.chipFill,
                  eyeStyle: const QrEyeStyle(color: AppColors.textPrimary),
                  dataModuleStyle: const QrDataModuleStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text('Present QR code during boarding', style: AppTextStyles.subtitle),
            ),
          ],
        ),
      ),
    );
  }
}
