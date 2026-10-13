import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../state/business_state.dart';
import '../../models/listing_model.dart';
import '../../models/ticket_type_model.dart';
import '../../theme/app_theme.dart';
import '../customer/seat_selection_screen.dart';

class TicketTypesScreen extends StatelessWidget {
  final Listing listing;

  const TicketTypesScreen({super.key, required this.listing});

  Future<void> _openForm(BuildContext context, {TicketType? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TicketTypeForm(listingId: listing.id, existing: existing),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TicketType type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ticket type?'),
        content: Text('"${type.name}" will be removed from this listing.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<BusinessState>().deleteTicketType(type.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = context.watch<BusinessState>().ticketTypesForListing(listing.id);
    final totalCapacity = types.fold<int>(0, (a, t) => a + t.totalQty);
    final totalSold = types.fold<int>(0, (a, t) => a + t.soldQty);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Types'),
        actions: [
          if (listing.requiresSeatSelection && types.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.event_seat_outlined),
              tooltip: 'Preview seat map',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SeatSelectionScreen(listing: listing, ticketTypes: types),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Ticket Type'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('d MMM yyyy').format(listing.date)} • ${listing.startTime} - ${listing.endTime}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _stat('Types', '${types.length}'),
                    _stat('Capacity', '$totalCapacity'),
                    _stat('Sold', '$totalSold'),
                    _stat('Remaining', '${totalCapacity - totalSold}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (types.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 36, color: AppColors.textSecondary),
                  SizedBox(height: 10),
                  Text(
                    'No ticket types yet. Add Regular, Premium or VIP tickets with prices.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...types.map(
              (type) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(type.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        Text(
                          'Rs. ${NumberFormat('#,###').format(type.price)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _openForm(context, existing: type),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                          onPressed: () => _confirmDelete(context, type),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: type.totalQty == 0 ? 0 : type.soldQty / type.totalQty,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        color: type.remaining == 0 ? AppColors.danger : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total ${type.totalQty}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('Sold ${type.soldQty}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          type.remaining == 0 ? 'Sold out' : 'Remaining ${type.remaining}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: type.remaining == 0 ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _TicketTypeForm extends StatefulWidget {
  final String listingId;
  final TicketType? existing;

  const _TicketTypeForm({required this.listingId, this.existing});

  @override
  State<_TicketTypeForm> createState() => _TicketTypeFormState();
}

class _TicketTypeFormState extends State<_TicketTypeForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  bool _submitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _priceController = TextEditingController(text: e == null ? '' : e.price.toStringAsFixed(0));
    _qtyController = TextEditingController(text: e == null ? '' : e.totalQty.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final state = context.read<BusinessState>();
    final price = double.parse(_priceController.text.trim());
    final qty = int.parse(_qtyController.text.trim());

    final success = _isEditing
        ? await state.updateTicketType(
            ticketTypeId: widget.existing!.id,
            name: _nameController.text,
            price: price,
            totalQty: qty,
          )
        : await state.addTicketType(
            listingId: widget.listingId,
            name: _nameController.text,
            price: price,
            totalQty: qty,
          );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error ?? 'Could not save ticket type.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Ticket Type' : 'Add Ticket Type',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 18),
            const Text('Name', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'e.g. Regular, Premium, VIP'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Price (Rs.)', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '800'),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          return (n == null || n <= 0) ? 'Enter valid price' : null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Quantity', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '150'),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          return (n == null || n <= 0) ? 'Enter valid quantity' : null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Add Ticket Type'),
            ),
          ],
        ),
      ),
    );
  }
}