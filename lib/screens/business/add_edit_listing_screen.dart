import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../state/booking_state.dart';
import '../../state/business_state.dart';
import '../../state/notification_state.dart';
import '../../models/business_model.dart';
import '../../models/listing_model.dart';
import '../../theme/app_theme.dart';

class AddEditListingScreen extends StatefulWidget {
  final String businessId;
  final Listing? existingListing;

  const AddEditListingScreen({
    super.key,
    required this.businessId,
    this.existingListing,
  });

  @override
  State<AddEditListingScreen> createState() => _AddEditListingScreenState();
}

class _AddEditListingScreenState extends State<AddEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late String _category;
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _requiresSeatSelection = false;
  bool _submitting = false;

  bool get _isEditing => widget.existingListing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingListing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _locationController = TextEditingController(text: existing?.location ?? '');
    _category = existing?.category ?? kBusinessCategories.first;
    _date = existing?.date;
    _requiresSeatSelection = existing?.requiresSeatSelection ?? false;
    if (existing != null) {
      _startTime = _parseTime(existing.startTime);
      _endTime = _parseTime(existing.endTime);
    }
  }

  TimeOfDay? _parseTime(String value) {
    try {
      final parsed = DateFormat('h:mm a').parse(value);
      return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (_) {
      return null;
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date, start time and end time.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final businessState = context.read<BusinessState>();
    final bookingState = context.read<BookingState>();
    final notificationState = context.read<NotificationState>();

    bool success;
    if (_isEditing) {
      success = await businessState.updateListing(
        listingId: widget.existingListing!.id,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        date: _date!,
        startTime: _formatTime(_startTime!),
        endTime: _formatTime(_endTime!),
        location: _locationController.text,
        requiresSeatSelection: _requiresSeatSelection,
      );
    } else {
      final id = await businessState.addListing(
        businessId: widget.businessId,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        date: _date!,
        startTime: _formatTime(_startTime!),
        endTime: _formatTime(_endTime!),
        location: _locationController.text,
        requiresSeatSelection: _requiresSeatSelection,
      );
      success = id != null;
    }

    if (success && _isEditing) {
      final updatedTitle = _titleController.text.trim();
      final affected = bookingState.bookings.where(
        (b) => b.listingId == widget.existingListing!.id && b.holdsInventory && b.isUpcoming,
      );
      for (final booking in affected) {
        await notificationState.notify(
          booking.customerId,
          'Event updated',
          '$updatedTitle was updated by the organizer. Please check the latest date, time and location.',
        );
      }
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(businessState.error ?? 'Could not save listing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Listing' : 'Add Listing')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: 'e.g. Avengers: Example Movie'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title is required' : null,
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
                  decoration: const InputDecoration(hintText: 'Describe the event or service'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                ),
                const SizedBox(height: 18),
                const Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(hintText: 'e.g. Hall 2, Grand Cinema'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                ),
                const SizedBox(height: 18),
                const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _pickerField(
                  label: _date == null ? 'Select date' : DateFormat('EEE, d MMM yyyy').format(_date!),
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Time', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _pickerField(
                            label: _startTime == null ? 'Select' : _formatTime(_startTime!),
                            icon: Icons.access_time_rounded,
                            onTap: _pickStartTime,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Time', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _pickerField(
                            label: _endTime == null ? 'Select' : _formatTime(_endTime!),
                            icon: Icons.access_time_filled_rounded,
                            onTap: _pickEndTime,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Requires seat selection', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Enable for cinemas, theatres, auditoriums, stadiums', style: TextStyle(fontSize: 12)),
                    value: _requiresSeatSelection,
                    onChanged: (v) => setState(() => _requiresSeatSelection = v),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppColors.accent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ticket types and pricing are added in the next step, after this listing is saved.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                        )
                      : Text(_isEditing ? 'Save Changes' : 'Create Listing'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickerField({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }
}