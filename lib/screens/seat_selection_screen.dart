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
  late Future<List<BusSeat>> _seatsFuture;
  final List<BusSeat> _selected = [];

  @override
  void initState() {
    super.initState();
    _seatsFuture = _load();
  }

  Future<List<BusSeat>> _load() async {
    final trip = await TripService.instance.getTrip(widget.trip.id);
    return trip.seats.map(BusSeat.fromApi).toList();
  }

  int get _totalFare =>
      widget.trip.priceFcfa * (_selected.isEmpty ? widget.passengerCount : _selected.length);

  void _toggleSeat(BusSeat seat) {
    if (seat.status == SeatStatus.booked) return;
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
          final seats = snapshot.data!;
          return Column(
            children: [
              _buildLegend(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: seats.map(_seatTile).toList(),
                  ),
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
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _seatColor(status),
              borderRadius: BorderRadius.circular(4),
              border: status == SeatStatus.available
                  ? Border.all(color: AppColors.border)
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.subtitle),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          legendItem(SeatStatus.available, 'Available'),
          const SizedBox(width: 18),
          legendItem(SeatStatus.selected, 'Selected'),
          const SizedBox(width: 18),
          legendItem(SeatStatus.booked, 'Booked'),
        ],
      ),
    );
  }

  Widget _seatTile(BusSeat seat) {
    return GestureDetector(
      onTap: () => _toggleSeat(seat),
      child: Container(
        width: 56,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _seatColor(seat.status),
          borderRadius: BorderRadius.circular(10),
          border: seat.status == SeatStatus.available
              ? Border.all(color: AppColors.border)
              : null,
        ),
        child: Text(
          seat.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: seat.status == SeatStatus.selected
                ? Colors.white
                : seat.status == SeatStatus.booked
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Color _seatColor(SeatStatus status) {
    switch (status) {
      case SeatStatus.available:
        return AppColors.white;
      case SeatStatus.selected:
        return AppColors.teal;
      case SeatStatus.booked:
        return AppColors.seatBooked;
    }
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
