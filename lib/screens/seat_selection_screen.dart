import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import '../services/trip_service.dart';
import '../services/api_client.dart';
import 'passenger_details_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final BusTrip trip;
  final int passengerCount;

  const SeatSelectionScreen({
    super.key,
    required this.trip,
    required this.passengerCount,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  static const _pollInterval = Duration(seconds: 5);

  late Future<List<BusSeat>> _seatsFuture;
  List<BusSeat> _seats = [];
  final List<BusSeat> _selected = [];
  Timer? _pollTimer;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _seatsFuture = _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<List<BusSeat>> _load() async {
    final trip = await TripService.instance.getTrip(widget.trip.id);
    final seats = trip.seats.map(BusSeat.fromApi).toList();
    _seats = seats;
    return seats;
  }

  /// Live sync: pulls the latest seat statuses from the server every few
  /// seconds so a seat someone else just booked or is mid-checkout on shows
  /// up immediately, without resetting what the current passenger picked.
  Future<void> _refresh() async {
    if (_refreshing || !mounted) return;
    _refreshing = true;
    try {
      final trip = await TripService.instance.getTrip(widget.trip.id);
      if (!mounted) return;
      final freshById = {for (final s in trip.seats) s.id: s};
      var lostASelectedSeat = false;

      setState(() {
        for (final seat in _seats) {
          final fresh = freshById[seat.tripSeatId];
          if (fresh == null) continue;
          final isMine = _selected.any((s) => s.tripSeatId == seat.tripSeatId);
          if (isMine) {
            // Someone else's action beat mine to this seat — drop it locally.
            if (fresh.status == 'booked') {
              seat.status = SeatStatus.booked;
              _selected.removeWhere((s) => s.tripSeatId == seat.tripSeatId);
              lostASelectedSeat = true;
            }
            continue;
          }
          seat.status = switch (fresh.status) {
            'booked' => SeatStatus.booked,
            'locked' => SeatStatus.locked,
            _ => SeatStatus.available,
          };
        }
      });

      if (lostASelectedSeat && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('One of your selected seats was just booked by someone else.')),
        );
      }
    } catch (_) {
      // Silent — a missed background refresh isn't worth interrupting the user for.
    } finally {
      _refreshing = false;
    }
  }

  int get _totalFare =>
      widget.trip.priceFcfa * (_selected.isEmpty ? widget.passengerCount : _selected.length);

  void _toggleSeat(BusSeat seat) {
    if (seat.status == SeatStatus.booked || seat.status == SeatStatus.locked) return;
    setState(() {
      if (seat.status == SeatStatus.selected) {
        seat.status = SeatStatus.available;
        _selected.removeWhere((s) => s.tripSeatId == seat.tripSeatId);
      } else {
        if (_selected.length >= widget.passengerCount) return;
        seat.status = SeatStatus.selected;
        _selected.add(seat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenHeader(title: 'Select Seats'),
      body: FutureBuilder<List<BusSeat>>(
        future: _seatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Could not load the seat map.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(message, textAlign: TextAlign.center, style: AppTextStyles.subtitle),
              ),
            );
          }
          return Column(
            children: [
              _buildLegend(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _BusLayout(seats: _seats, onTapSeat: _toggleSeat),
                ),
              ),
              _buildFooter(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    Widget legendItem(SeatStatus status, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _seatColor(status),
              borderRadius: BorderRadius.circular(4),
              border: status == SeatStatus.available ? Border.all(color: AppColors.border) : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 6,
        children: [
          legendItem(SeatStatus.available, 'Available'),
          legendItem(SeatStatus.selected, 'Selected'),
          legendItem(SeatStatus.locked, 'In progress'),
          legendItem(SeatStatus.booked, 'Booked'),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selected Seats (${_selected.length})', style: AppTextStyles.subtitle),
                    Text(
                      _selected.isEmpty ? '—' : _selected.map((s) => s.label).join(', '),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Fare', style: AppTextStyles.subtitle),
                    Text(formatFcfa(_totalFare),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Continue',
              onPressed: _selected.length == widget.passengerCount
                  ? () {
                      _pollTimer?.cancel();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PassengerDetailsScreen(
                            trip: widget.trip,
                            selectedSeats: List.of(_selected),
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

Color _seatColor(SeatStatus status) {
  switch (status) {
    case SeatStatus.available:
      return AppColors.white;
    case SeatStatus.selected:
      return AppColors.teal;
    case SeatStatus.booked:
      return AppColors.seatBooked;
    case SeatStatus.locked:
      return AppColors.goldDark;
  }
}

/// Renders the seats as an actual bus floor plan: a rounded cabin outline,
/// a driver's seat + door up front, and rows of 2-aisle-2 seating behind it —
/// rather than a plain wrapped grid of tiles.
class _BusLayout extends StatelessWidget {
  final List<BusSeat> seats;
  final ValueChanged<BusSeat> onTapSeat;

  const _BusLayout({required this.seats, required this.onTapSeat});

  @override
  Widget build(BuildContext context) {
    const perRow = 4; // 2 seats | aisle | 2 seats
    final rows = <List<BusSeat?>>[];
    for (var i = 0; i < seats.length; i += perRow) {
      rows.add(List.generate(perRow, (j) => (i + j) < seats.length ? seats[i + j] : null));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          // Driver + door, front of the bus.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.chipFill, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.airline_seat_recline_normal, size: 18, color: AppColors.textMuted),
              ),
              const Icon(Icons.sensor_door_outlined, color: AppColors.textMuted, size: 22),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(color: AppColors.border),
          const SizedBox(height: 10),
          for (final row in rows) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _seatOrGap(row[0]),
                const SizedBox(width: 8),
                _seatOrGap(row.length > 1 ? row[1] : null),
                const SizedBox(width: 24), // aisle
                _seatOrGap(row.length > 2 ? row[2] : null),
                const SizedBox(width: 8),
                _seatOrGap(row.length > 3 ? row[3] : null),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _seatOrGap(BusSeat? seat) {
    if (seat == null) return const SizedBox(width: 52, height: 44);
    return _SeatTile(seat: seat, onTap: () => onTapSeat(seat));
  }
}

class _SeatTile extends StatelessWidget {
  final BusSeat seat;
  final VoidCallback onTap;

  const _SeatTile({required this.seat, required this.onTap});

  bool get _tappable => seat.status == SeatStatus.available || seat.status == SeatStatus.selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tappable ? onTap : null,
      child: Container(
        width: 52,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _seatColor(seat.status),
          borderRadius: BorderRadius.circular(10),
          border: seat.status == SeatStatus.available ? Border.all(color: AppColors.border) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              seat.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: seat.status == SeatStatus.selected
                    ? Colors.white
                    : seat.status == SeatStatus.booked || seat.status == SeatStatus.locked
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
              ),
            ),
            if (seat.seatType == 'vip')
              Icon(Icons.star,
                  size: 9,
                  color: seat.status == SeatStatus.selected ? Colors.white : AppColors.goldDark),
          ],
        ),
      ),
    );
  }
}
