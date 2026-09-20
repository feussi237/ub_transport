import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import '../services/trip_service.dart';
import '../services/api_client.dart';
import 'seat_selection_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String origin;
  final String destination;
  final DateTime date;
  final int passengers;

  const SearchResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
    required this.passengers,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late Future<List<BusTrip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = _load();
  }

  Future<List<BusTrip>> _load() async {
    final trips = await TripService.instance.search(
      originCity: widget.origin,
      destinationCity: widget.destination,
      date: widget.date,
    );
    return trips.map(BusTrip.fromApi).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenHeader(
        title: '${widget.origin} → ${widget.destination}',
        subtitle: '${formatDate(widget.date)} • ${widget.passengers} passenger(s)',
      ),
      body: FutureBuilder<List<BusTrip>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Could not load trips. Check your connection and try again.';
            return _StateMessage(icon: Icons.wifi_off, message: message);
          }
          final trips = snapshot.data!;
          if (trips.isEmpty) {
            return const _StateMessage(
              icon: Icons.directions_bus_outlined,
              message: 'No trips found for this route and date yet.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) =>
                _TripCard(trip: trips[index], passengers: widget.passengers),
          );
        },
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _StateMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final BusTrip trip;
  final int passengers;

  const _TripCard({required this.trip, required this.passengers});

  @override
  Widget build(BuildContext context) {
    final seatsLeft = trip.seatsRemaining ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.agencyName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Pill(text: trip.travelClass.toUpperCase()),
                  ],
                ),
              ),
              Text(formatFcfa(trip.priceFcfa),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.teal)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.departureTime,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(trip.origin, style: AppTextStyles.subtitle),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.chipFill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_bus,
                          size: 14, color: AppColors.textSecondary),
                    ),
                    const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(trip.destination, style: AppTextStyles.subtitle),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 16, color: seatsLeft <= 6 ? AppColors.danger : AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '$seatsLeft seats remaining',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: seatsLeft <= 6 ? AppColors.danger : AppColors.textMuted,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: seatsLeft == 0
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SeatSelectionScreen(
                              trip: trip,
                              passengerCount: passengers,
                            ),
                          ),
                        );
                      },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.chipFill,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Choose',
                        style: TextStyle(
                            color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: AppColors.textPrimary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
