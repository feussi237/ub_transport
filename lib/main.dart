import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/sign_up_screen.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const UBTransportApp());
}

class UBTransportApp extends StatelessWidget {
  const UBTransportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UB Transport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _checking = true;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final signedIn = await AuthService.instance.tryRestoreSession();
    if (!mounted) return;
    setState(() {
      _signedIn = signedIn;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppGradients.hero,
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: AppGradients.secondary,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bus_filled_rounded,
                    color: AppColors.primaryDark,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'UB Transport',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your journey starts here',
                  style: TextStyle(
                    color: Color(0xFFB8C5D6),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: AppColors.secondary,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _signedIn ? homeScreenForRole() : const SignUpScreen();
  }
}
