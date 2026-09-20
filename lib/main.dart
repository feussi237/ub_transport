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
      statusBarColor: AppColors.darkOlive,
      statusBarIconBrightness: Brightness.light, // Icônes blanches (Android)
      statusBarBrightness: Brightness.dark,      // Icônes blanches (iOS)
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

/// Restores a persisted session (if any) before deciding whether to open on
/// the sign-up flow or straight into the app.
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
      return const Scaffold(
        backgroundColor: AppColors.darkOlive,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }
    return _signedIn ? homeScreenForRole() : const SignUpScreen();
  }
}
