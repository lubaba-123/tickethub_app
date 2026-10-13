import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../theme/app_theme.dart';

Color bookingStatusColor(BookingStatus status) {
  switch (status) {
    case BookingStatus.paid:
    case BookingStatus.confirmed:
      return AppColors.success;
    case BookingStatus.pending:
      return AppColors.pending;
    case BookingStatus.cancelled:
    case BookingStatus.refunded:
      return AppColors.danger;
    case BookingStatus.completed:
      return AppColors.primary;
    case BookingStatus.used:
      return AppColors.textSecondary;
  }
}

class BookingStatusChip extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = bookingStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
