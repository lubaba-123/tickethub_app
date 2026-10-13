import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../theme/app_theme.dart';
import 'booking_status_chip.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const BookingCard({super.key, required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dim = !booking.holdsInventory;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: dim ? 0.65 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('d').format(booking.eventDate),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary),
                    ),
                    Text(
                      DateFormat('MMM').format(booking.eventDate),
                      style: const TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.listingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${booking.startTime}  •  ${booking.quantity} ticket(s)',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.bookingCode,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BookingStatusChip(status: booking.effectiveStatus),
                  const SizedBox(height: 10),
                  Text(
                    'Rs. ${NumberFormat('#,###').format(booking.totalAmount)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
