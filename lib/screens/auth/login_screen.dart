import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../customer/home_screen.dart';
import '../business/business_owner_home_screen.dart';
import '../admin/admin_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final auth = context.read<AuthState>();
    final success = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      final role = auth.currentUser!.role;
      final Widget destination = switch (role) {
        UserRole.customer => const CustomerHomeScreen(),
        UserRole.businessOwner => const BusinessOwnerHomeScreen(),
        UserRole.admin => const AdminHomeScreen(),
      };
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Image.asset('assets/logo/app_icon.png', width: 72, height: 72),
                const SizedBox(height: 24),
                const Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Log in to continue booking tickets.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'you@example.com'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                ),
                const SizedBox(height: 18),
                const Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password is required' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                        )
                      : const Text('Log In'),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text("Don't have an account? Register"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}