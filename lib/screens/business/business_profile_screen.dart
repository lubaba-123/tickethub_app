import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/business_state.dart';
import '../../models/business_model.dart';
import '../../theme/app_theme.dart';

class BusinessProfileScreen extends StatefulWidget {
  final String businessId;

  const BusinessProfileScreen({super.key, required this.businessId});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  late String _category;
  bool _editing = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final business = context.read<BusinessState>().businesses.firstWhere((b) => b.id == widget.businessId);
    _nameController = TextEditingController(text: business.name);
    _descriptionController = TextEditingController(text: business.description);
    _locationController = TextEditingController(text: business.location);
    _phoneController = TextEditingController(text: business.contactPhone);
    _category = business.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final businessState = context.read<BusinessState>();
    final success = await businessState.updateBusiness(
      businessId: widget.businessId,
      name: _nameController.text,
      category: _category,
      description: _descriptionController.text,
      location: _locationController.text,
      contactPhone: _phoneController.text,
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (success) _editing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Business details updated.' : 'Update failed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessState>().businesses.firstWhere((b) => b.id == widget.businessId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close_rounded : Icons.edit_outlined),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 40),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Business Name', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  enabled: _editing,
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
                  onChanged: _editing ? (v) => setState(() => _category = v!) : null,
                ),
                const SizedBox(height: 18),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  enabled: _editing,
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                ),
                const SizedBox(height: 18),
                const Text('Location / Address', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  enabled: _editing,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                ),
                const SizedBox(height: 18),
                const Text('Contact Phone', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  enabled: _editing,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Contact phone is required' : null,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      business.status.name[0].toUpperCase() + business.status.name.substring(1),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (_editing) ...[
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _submitting ? null : _save,
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
