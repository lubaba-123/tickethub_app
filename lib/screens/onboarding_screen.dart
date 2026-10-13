import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

class _OnboardPage {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardPage(this.icon, this.title, this.subtitle);
}

const _pages = [
  _OnboardPage(
    Icons.explore_outlined,
    'Discover Anything, Anywhere',
    'Browse cinemas, theatres, concerts, sports and workshops — all in one place.',
  ),
  _OnboardPage(
    Icons.confirmation_number_outlined,
    'Book Tickets in Seconds',
    'Pick your date, choose your tickets or seats, and check out instantly.',
  ),
  _OnboardPage(
    Icons.qr_code_2_rounded,
    'Your Ticket, Always With You',
    'Get a digital ticket with a QR code — no printing, no hassle.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  void _next() {
    if (_index == _pages.length - 1) {
      _goToLogin();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/logo/logo_no_tagline.png', height: 34),
                  TextButton(
                    onPressed: _goToLogin,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 64, color: AppColors.primary),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _next,
                    child: Text(_index == _pages.length - 1 ? 'Get Started' : 'Next'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _goToRegister,
                    child: const Text('Create a new account'),
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