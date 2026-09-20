import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import '../services/trip_service.dart';
import '../services/api_client.dart';
import 'seat_selection_screen.dart';

/// "See All" from the home screen's Popular Routes strip — every upcoming
/// trip across every route, soonest first, tap straight into seat selection.
class AllTripsScreen extends StatefulWidget {
  final int passengers;

  const AllTripsScreen({super.key, required this.passengers});

  @override
  State<AllTripsScreen> createState() => _AllTripsScreenState();
}

class _AllTripsScreenState extends State<AllTripsScreen> {
  late Future<List<BusTrip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = _load();
  }

  Future<List<BusTrip>> _load() async {
    final trips = await TripService.instance.browseUpcoming();
    return trips.map(BusTrip.fromApi).toList();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _tripsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenHeader(title: 'All Trips', subtitle: 'Every upcoming departure'),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<BusTrip>>(
          future: _tripsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final message = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Could not load trips. Check your connection and try again.';
              return ListView(children: [StateMessage(icon: Icons.wifi_off, message: message)]);
            }
            final trips = snapshot.data!;
            if (trips.isEmpty) {
              return ListView(children: const [
                StateMessage(icon: Icons.directions_bus_outlined, message: 'No upcoming trips right now.'),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              itemCount: trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) => _AllTripCard(trip: trips[index], passengers: widget.passengers),
            );
          },
        ),
      ),
    );
  }
}

class _AllTripCard extends StatelessWidget {
  final BusTrip trip;
  final int passengers;

  const _AllTripCard({required this.trip, required this.passengers});

  @override
  Widget build(BuildContext context) {
    final seatsLeft = trip.seatsRemaining ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: seatsLeft == 0
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SeatSelectionScreen(trip: trip, passengerCount: passengers)),
              ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${trip.origin} → ${trip.destination}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${trip.agencyName} · ${formatDate(trip.departureAt)} · ${trip.departureTime}', style: AppTextStyles.subtitle),
                  const SizedBox(height: 6),
                  Text(
                    seatsLeft == 0 ? 'Fully booked' : '$seatsLeft seats remaining',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: seatsLeft <= 6 ? AppColors.danger : AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Text(formatFcfa(trip.priceFcfa), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.teal)),
          ],
        ),
      ),
    );
  }
}
