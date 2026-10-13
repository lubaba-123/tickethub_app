import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/listing_model.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const ListingCard({super.key, required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final business = businessById(listing.businessId);
    final price = lowestPriceForListing(listing.id);
    final dateLabel = DateFormat('d MMM').format(listing.date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dateLabel.split(' ')[0],
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.accent),
                  ),
                  Text(
                    dateLabel.split(' ')[1],
                    style: const TextStyle(fontSize: 12, color: AppColors.accent),
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
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    business.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(listing.startTime, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          listing.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Rs. ${price.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
