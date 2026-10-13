import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../state/booking_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/booking_card.dart';
import '../customer/ticket_detail_screen.dart';

class AdminBookingsTab extends StatefulWidget {
  const AdminBookingsTab({super.key});

  @override
  State<AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<AdminBookingsTab> {
  BookingStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BookingState>();
    final all = [...state.bookings]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final list = _filter == null ? all : all.where((b) => b.effectiveStatus == _filter).toList();

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            children: [
              _chip('All (${all.length})', _filter == null, () => setState(() => _filter = null)),
              for (final s in BookingStatus.values)
                _chip(s.label, _filter == s, () => setState(() => _filter = s)),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No bookings found.', style: TextStyle(color: AppColors.textSecondary)))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        for (final booking in list)
                          BookingCard(
                            booking: booking,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => TicketDetailScreen(bookingId: booking.id)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
