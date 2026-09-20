import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import 'payment_screen.dart';

class PassengerDetailsScreen extends StatefulWidget {
  final BusTrip trip;
  final List<BusSeat> selectedSeats;

  const PassengerDetailsScreen({
    super.key,
    required this.trip,
    required this.selectedSeats,
  });

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  late final List<Passenger> _passengers;
  late final List<TextEditingController> _nameControllers;
  late final List<TextEditingController> _ageControllers;

  @override
  void initState() {
    super.initState();
    _passengers = widget.selectedSeats
        .map((seat) => Passenger(tripSeatId: seat.tripSeatId, seatLabel: seat.label, gender: 'Female'))
        .toList();
    _nameControllers = _passengers.map((_) => TextEditingController()).toList();
    _ageControllers = _passengers.map((_) => TextEditingController()).toList();
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _ageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isFormComplete {
    for (int i = 0; i < _passengers.length; i++) {
      if (_nameControllers[i].text.trim().isEmpty) return false;
      if (_ageControllers[i].text.trim().isEmpty) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenHeader(
        title: 'Passenger Details',
        subtitle: 'Provide travel info',
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: _passengers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _PassengerCard(
                index: index,
                passenger: _passengers[index],
                nameController: _nameControllers[index],
                ageController: _ageControllers[index],
                onGenderChanged: (gender) {
                  setState(() => _passengers[index].gender = gender);
                },
                onChanged: () => setState(() {}),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: PrimaryButton(
              label: 'Proceed to Payment',
              onPressed: _isFormComplete
                  ? () {
                      for (int i = 0; i < _passengers.length; i++) {
                        _passengers[i].fullName = _nameControllers[i].text.trim();
                        _passengers[i].age = int.tryParse(_ageControllers[i].text.trim());
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            trip: widget.trip,
                            passengers: _passengers,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PassengerCard extends StatelessWidget {
  final int index;
  final Passenger passenger;
  final TextEditingController nameController;
  final TextEditingController ageController;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onChanged;

  const _PassengerCard({
    required this.index,
    required this.passenger,
    required this.nameController,
    required this.ageController,
    required this.onGenderChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Passenger ${index + 1}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Seat ${passenger.seatLabel}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tealDark)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Full Name(As on your National ID)', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            onChanged: (_) => onChanged(),
            style: AppTextStyles.body,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.chipFill,
              hintText: 'Full name',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Age', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ageController,
                      onChanged: (_) => onChanged(),
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.chipFill,
                        hintText: 'Age',
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gender', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.chipFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _GenderToggle(
                              label: 'Female',
                              selected: passenger.gender == 'Female',
                              onTap: () => onGenderChanged('Female'),
                            ),
                          ),
                          Expanded(
                            child: _GenderToggle(
                              label: 'Male',
                              selected: passenger.gender == 'Male',
                              onTap: () => onGenderChanged('Male'),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _GenderToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
