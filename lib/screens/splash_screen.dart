import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import 'onboarding_screen.dart';
import 'customer/home_screen.dart';
import 'business/business_owner_home_screen.dart';
import 'admin/admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthState>();
    await auth.bootstrap();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (!auth.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    _routeForRole(auth.currentUser!.role);
  }

  void _routeForRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        );
        break;
      case UserRole.businessOwner:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BusinessOwnerHomeScreen()),
        );
        break;
      case UserRole.admin:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo/logo_horizontal_white.png', width: 300),
            const SizedBox(height: 36),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}