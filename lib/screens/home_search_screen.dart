import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import '../services/auth_service.dart';
import 'search_results_screen.dart';
import 'sign_up_screen.dart';

const List<String> kCameroonCities = [
  'Douala', 'Yaoundé', 'Bafoussam', 'Bamenda', 'Garoua',
  'Maroua', 'Ngaoundéré', 'Buea', 'Limbe', 'Kribi', 'Ebolowa', 'Bertoua',
];

class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({super.key});

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  String origin = 'Douala';
  String destination = 'Yaoundé';
  DateTime departureDate = DateTime.now().add(const Duration(days: 1));
  int passengers = 1;

  final List<PopularRoute> _popularRoutes = const [
    PopularRoute(
      imageUrl: 'city_skyline',
      origin: 'Douala',
      destination: 'Yaoundé',
      duration: '3h 30m',
      priceFcfa: 12000,
    ),
    PopularRoute(
      imageUrl: 'colonial_building',
      origin: 'Yaoundé',
      destination: 'Bamenda',
      duration: '6h 00m',
      priceFcfa: 18000,
    ),
  ];

  Future<void> _showAccountMenu(BuildContext context) async {
    final user = AuthService.instance.currentUser;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppTextStyles.h2),
                    Text(user.email, style: AppTextStyles.subtitle),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text('Log out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
              onTap: () => Navigator.of(context).pop('logout'),
            ),
          ],
        ),
      ),
    );
    if (action == 'logout') {
      await AuthService.instance.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignUpScreen()),
        (route) => false,
      );
    }
  }

  void _swapOriginDestination() {
    setState(() {
      final tmp = origin;
      origin = destination;
      destination = tmp;
    });
  }

  Future<void> _pickCity({required bool isOrigin}) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(isOrigin ? 'Departure city' : 'Destination city', style: AppTextStyles.h2),
            ),
            ...kCameroonCities.map((city) => ListTile(
                  title: Text(city, style: AppTextStyles.body),
                  onTap: () => Navigator.of(context).pop(city),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isOrigin) {
        origin = picked;
      } else {
        destination = picked;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: departureDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => departureDate = picked);
  }

  Future<void> _pickPassengers() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int value = passengers;
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Passengers', style: AppTextStyles.h2),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: value > 1 ? () => setSheetState(() => value--) : null,
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('$value', textAlign: TextAlign.center, style: AppTextStyles.h1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: value < 6 ? () => setSheetState(() => value++) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(label: 'Done', onPressed: () => Navigator.of(context).pop(value)),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (picked != null) setState(() => passengers = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(context),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Popular Routes', style: AppTextStyles.h2),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See All',
                        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 190,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _popularRoutes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) =>
                    _PopularRouteCard(route: _popularRoutes[index]),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.darkOlive,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('WELCOME TO UB TRANSPORT',
                          style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6)),
                      SizedBox(height: 4),
                      Text('Where is your next trip?',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAccountMenu(context),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.gold,
                    child: Icon(Icons.person, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _RouteRow(
                    label: 'From (Origin)',
                    value: origin,
                    leadingColor: AppColors.gold,
                    onTap: () => _pickCity(isOrigin: true),
                    trailing: InkWell(
                      onTap: _swapOriginDestination,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.swap_vert,
                            size: 18, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const Divider(height: 22, color: AppColors.border),
                  _RouteRow(
                    label: 'To (Destination)',
                    value: destination,
                    leadingColor: AppColors.textSecondary,
                    onTap: () => _pickCity(isOrigin: false),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: _MiniInfoTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Departure Date',
                            value: formatDate(departureDate),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickPassengers,
                          child: _MiniInfoTile(
                            icon: Icons.person_outline,
                            label: 'Passengers',
                            value: '$passengers Seats',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Search Buses',
                    onPressed: origin != destination
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SearchResultsScreen(
                                  origin: origin,
                                  destination: destination,
                                  date: departureDate,
                                  passengers: passengers,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String label;
  final String value;
  final Color leadingColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _RouteRow({
    required this.label,
    required this.value,
    required this.leadingColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Icon(Icons.location_on, color: leadingColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.subtitle),
                Text(value, style: AppTextStyles.label.copyWith(fontSize: 15)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.chipFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularRouteCard extends StatelessWidget {
  final PopularRoute route;

  const _PopularRouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: double.infinity,
            color: AppColors.chipFill,
            child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 32),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${route.origin} → ${route.destination}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(route.duration,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(formatFcfa(route.priceFcfa),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
