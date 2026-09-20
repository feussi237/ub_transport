import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/dashboard_models.dart';
import '../widgets/common_widgets.dart';
import '../services/agency_dashboard_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'sign_up_screen.dart';
import 'agency_overview_tab.dart';
import 'agency_messages_tab.dart';
import 'agency_account_tab.dart';
import 'scan_ticket_screen.dart';

/// Web dashboard for the `agency_staff` role: manage the agency's buses,
/// publish/update trips, see who has booked them, chat with passengers,
/// scan boarding tickets, and edit the agency's own account.
class AgencyDashboardScreen extends StatefulWidget {
  const AgencyDashboardScreen({super.key});

  @override
  State<AgencyDashboardScreen> createState() => _AgencyDashboardScreenState();
}

class _AgencyDashboardScreenState extends State<AgencyDashboardScreen> {
  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('UB Transport — Agency'),
          backgroundColor: AppColors.darkOlive,
          foregroundColor: AppColors.white,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.gold,
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.textOnDark,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Trips'),
              Tab(text: 'Buses'),
              Tab(text: 'Bookings'),
              Tab(text: 'Messages'),
              Tab(text: 'Account'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Scan ticket',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanTicketScreen())),
              icon: const Icon(Icons.qr_code_scanner),
            ),
            IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
          ],
        ),
        body: const TabBarView(children: [
          AgencyOverviewTab(),
          _TripsTab(),
          _BusesTab(),
          _BookingsTab(),
          AgencyMessagesTab(),
          AgencyAccountTab(),
        ]),
      ),
    );
  }
}

class _TripsTab extends StatefulWidget {
  const _TripsTab();

  @override
  State<_TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends State<_TripsTab> {
  late Future<List<DashboardTrip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = AgencyDashboardService.instance.listTrips();
  }

  void _reload() => setState(() => _tripsFuture = AgencyDashboardService.instance.listTrips());

  Future<void> _openCreateTrip() async {
    final buses = await AgencyDashboardService.instance.listBuses();
    if (!mounted) return;
    if (buses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a bus first — a trip needs one.')),
      );
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _CreateTripScreen(buses: buses)),
    );
    if (created == true) _reload();
  }

  Future<void> _updateStatus(DashboardTrip trip, String status) async {
    await AgencyDashboardService.instance.updateTripStatus(trip.id, status);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTrip,
        icon: const Icon(Icons.add),
        label: const Text('New trip'),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.textPrimary,
      ),
      body: FutureBuilder<List<DashboardTrip>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Could not load trips.';
            return StateMessage(icon: Icons.wifi_off, message: message);
          }
          final trips = snapshot.data!;
          if (trips.isEmpty) {
            return const StateMessage(icon: Icons.directions_bus_outlined, message: 'No trips yet — publish your first one.');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final trip = trips[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${trip.originCity} → ${trip.destinationCity}', style: AppTextStyles.label)),
                        Pill(
                          text: trip.status,
                          background: _statusColor(trip.status).withValues(alpha: 0.15),
                          textColor: _statusColor(trip.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${formatDate(trip.departureAt)}  •  ${formatFcfa(trip.price.round())}', style: AppTextStyles.subtitle),
                    if (trip.status == 'scheduled') ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 4, children: [
                        TextButton(
                          onPressed: () => _updateStatus(trip, 'delayed'),
                          child: const Text('Mark delayed'),
                        ),
                        TextButton(
                          onPressed: () => _updateStatus(trip, 'cancelled'),
                          child: const Text('Cancel trip', style: TextStyle(color: AppColors.danger)),
                        ),
                        TextButton(
                          onPressed: () => _updateStatus(trip, 'completed'),
                          child: const Text('Mark completed'),
                        ),
                      ]),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'completed' => AppColors.success,
        'cancelled' => AppColors.danger,
        'delayed' => AppColors.goldDark,
        _ => AppColors.indigo,
      };
}

class _CreateTripScreen extends StatefulWidget {
  final List<DashboardBus> buses;

  const _CreateTripScreen({required this.buses});

  @override
  State<_CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<_CreateTripScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _priceController = TextEditingController();
  late DashboardBus _bus;
  DateTime _departure = DateTime.now().add(const Duration(days: 1));
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bus = widget.buses.first;
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDeparture() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departure,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_departure));
    if (time == null) return;
    setState(() => _departure = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    final price = double.tryParse(_priceController.text.trim());
    if (_originController.text.trim().isEmpty || _destinationController.text.trim().isEmpty || price == null) {
      setState(() => _error = 'Fill in origin, destination and a valid price.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await AgencyDashboardService.instance.createTrip(
        busId: _bus.id,
        originCity: _originController.text.trim(),
        destinationCity: _destinationController.text.trim(),
        departureAt: _departure,
        price: price,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenHeader(title: 'New trip'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text('Bus', style: AppTextStyles.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<DashboardBus>(
            initialValue: _bus,
            items: widget.buses
                .map((b) => DropdownMenuItem(value: b, child: Text('${b.plateNumber} — ${b.category} (${b.seatCount} seats)')))
                .toList(),
            onChanged: (b) => setState(() => _bus = b!),
          ),
          const SizedBox(height: 18),
          LabeledField(label: 'Origin city', hint: 'Douala', controller: _originController),
          const SizedBox(height: 18),
          LabeledField(label: 'Destination city', hint: 'Yaoundé', controller: _destinationController),
          const SizedBox(height: 18),
          LabeledField(
            label: 'Price (FCFA)',
            hint: '6000',
            controller: _priceController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          const Text('Departure', style: AppTextStyles.label),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pickDeparture,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), alignment: Alignment.centerLeft),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(formatDate(_departure)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: _submitting ? 'Publishing…' : 'Publish trip',
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _BusesTab extends StatefulWidget {
  const _BusesTab();

  @override
  State<_BusesTab> createState() => _BusesTabState();
}

class _BusesTabState extends State<_BusesTab> {
  late Future<List<DashboardBus>> _busesFuture;

  @override
  void initState() {
    super.initState();
    _busesFuture = AgencyDashboardService.instance.listBuses();
  }

  void _reload() => setState(() => _busesFuture = AgencyDashboardService.instance.listBuses());

  Future<void> _openCreateBus() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _CreateBusScreen()),
    );
    if (created == true) _reload();
  }

  Future<void> _editBus(DashboardBus bus) async {
    final plateController = TextEditingController(text: bus.plateNumber);
    String category = bus.category;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit bus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: plateController, decoration: const InputDecoration(labelText: 'Plate number')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: const [
                  DropdownMenuItem(value: 'standard', child: Text('Standard')),
                  DropdownMenuItem(value: 'vip', child: Text('VIP')),
                  DropdownMenuItem(value: 'express', child: Text('Express')),
                ],
                onChanged: (v) => setDialogState(() => category = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true) return;
    try {
      await AgencyDashboardService.instance.updateBus(bus.id, plateNumber: plateController.text.trim(), category: category);
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateBus,
        icon: const Icon(Icons.add),
        label: const Text('New bus'),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.textPrimary,
      ),
      body: FutureBuilder<List<DashboardBus>>(
        future: _busesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const StateMessage(icon: Icons.wifi_off, message: 'Could not load buses.');
          }
          final buses = snapshot.data!;
          if (buses.isEmpty) {
            return const StateMessage(icon: Icons.directions_bus_outlined, message: 'No buses registered yet.');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
            itemCount: buses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final bus = buses[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _editBus(bus),
                child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bus.plateNumber, style: AppTextStyles.label),
                        Text('${bus.category} • ${bus.seatCount} seats', style: AppTextStyles.subtitle),
                      ],
                    ),
                    const Icon(Icons.edit_outlined, color: AppColors.textMuted),
                  ],
                ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CreateBusScreen extends StatefulWidget {
  const _CreateBusScreen();

  @override
  State<_CreateBusScreen> createState() => _CreateBusScreenState();
}

class _CreateBusScreenState extends State<_CreateBusScreen> {
  final _plateController = TextEditingController();
  final _seatCountController = TextEditingController(text: '30');
  String _category = 'standard';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _plateController.dispose();
    _seatCountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final seatCount = int.tryParse(_seatCountController.text.trim());
    if (_plateController.text.trim().isEmpty || seatCount == null || seatCount < 1) {
      setState(() => _error = 'Fill in a plate number and a valid seat count.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // One row of "vip" seats up front, the rest "standard" — a simple
      // default layout the agency can refine later from a real seat editor.
      final vipCount = _category == 'vip' ? seatCount : (seatCount / 5).ceil();
      final layout = List.generate(seatCount, (i) => {
            'seat_number': '${i + 1}',
            'seat_type': i < vipCount ? 'vip' : 'standard',
          });
      await AgencyDashboardService.instance.createBus(
        plateNumber: _plateController.text.trim(),
        category: _category,
        seatLayout: layout,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScreenHeader(title: 'New bus'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          LabeledField(label: 'Plate number', hint: 'CE-123-AB', controller: _plateController),
          const SizedBox(height: 18),
          const Text('Category', style: AppTextStyles.label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: const [
              DropdownMenuItem(value: 'standard', child: Text('Standard')),
              DropdownMenuItem(value: 'vip', child: Text('VIP')),
              DropdownMenuItem(value: 'express', child: Text('Express')),
            ],
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 18),
          LabeledField(
            label: 'Seat count',
            hint: '30',
            controller: _seatCountController,
            keyboardType: TextInputType.number,
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: _submitting ? 'Saving…' : 'Register bus',
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _BookingsTab extends StatefulWidget {
  const _BookingsTab();

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  static const _pollInterval = Duration(seconds: 10);

  late Future<List<DashboardBooking>> _future;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _future = AgencyDashboardService.instance.listBookings();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final future = AgencyDashboardService.instance.listBookings();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {
      // Silent on background polling failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<DashboardBooking>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const StateMessage(icon: Icons.wifi_off, message: 'Could not load bookings.');
        }
        final bookings = snapshot.data!;
        if (bookings.isEmpty) {
          return const StateMessage(icon: Icons.confirmation_number_outlined, message: 'No bookings yet.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final b = bookings[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${b.passengerName}  •  seat ${b.seatNumber}', style: AppTextStyles.label),
                      Text('${b.originCity} → ${b.destinationCity}  •  ${formatDate(b.departureAt)}', style: AppTextStyles.subtitle),
                      Text(b.passengerPhone, style: AppTextStyles.subtitle),
                    ],
                  ),
                  Pill(
                    text: b.status,
                    background: (b.status == 'confirmed' ? AppColors.success : AppColors.danger).withValues(alpha: 0.15),
                    textColor: b.status == 'confirmed' ? AppColors.success : AppColors.danger,
                  ),
                ],
              ),
            );
          },
        );
      },
      ),
    );
  }
}
