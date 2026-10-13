import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/auth_state.dart';
import 'state/booking_state.dart';
import 'state/business_state.dart';
import 'state/seat_state.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const TicketHubApp());
}

class TicketHubApp extends StatelessWidget {
  const TicketHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => BusinessState()..bootstrap()),
        ChangeNotifierProvider(create: (_) => SeatState()),
        ChangeNotifierProvider(create: (_) => BookingState()..bootstrap()),
      ],
      child: MaterialApp(
        title: 'TicketHub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}