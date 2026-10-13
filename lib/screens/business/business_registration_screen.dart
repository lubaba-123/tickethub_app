import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../state/business_state.dart';
import '../../models/business_model.dart';
import '../../theme/app_theme.dart';
import 'business_owner_home_screen.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  const BusinessRegistrationScreen({super.key});

  @override
  State<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState extends State<BusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  String _category = kBusinessCategories.first;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final auth = context.read<AuthState>();
    final business = context.read<BusinessState>();

    final success = await business.registerBusiness(
      ownerId: auth.currentUser!.id,
      name: _nameController.text,
      category: _category,
      description: _descriptionController.text,
      location: _locationController.text,
      contactPhone: _phoneController.text,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BusinessOwnerHomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(business.error ?? 'Registration failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Your Business')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your business goes live only after Admin approval. You can still add listings while pending.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Business Name', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'e.g. Grand Cinema Islamabad'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Business name is required' : null,
                ),
                const SizedBox(height: 18),
                const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  items: kBusinessCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 18),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Tell customers about your business'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                ),
                const SizedBox(height: 18),
                const Text('Location / Address', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(hintText: 'e.g. F-7 Markaz, Islamabad'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                ),
                const SizedBox(height: 18),
                const Text('Contact Phone', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '+92 3xx xxxxxxx'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Contact phone is required' : null,
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
                      : const Text('Register Business'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
