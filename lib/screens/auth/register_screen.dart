import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../customer/home_screen.dart';
import '../business/business_owner_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.customer;
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final auth = context.read<AuthState>();
    final success = await auth.register(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      role: _role,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      final destination = _role == UserRole.customer
          ? const CustomerHomeScreen()
          : const BusinessOwnerHomeScreen();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed.')),
      );
    }
  }

  Widget _roleOption(UserRole role, String label, IconData icon) {
    final selected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('I am a', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _roleOption(UserRole.customer, 'Customer', Icons.person_outline),
                    const SizedBox(width: 12),
                    _roleOption(UserRole.businessOwner, 'Business Owner', Icons.storefront_outlined),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Your full name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 18),
                const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'you@example.com'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    final ok = RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w\-.]+$').hasMatch(v.trim());
                    return ok ? null : 'Enter a valid email';
                  },
                ),
                const SizedBox(height: 18),
                const Text('Phone', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '+92 3xx xxxxxxx'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                ),
                const SizedBox(height: 18),
                const Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
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
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Already have an account? Log in'),
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