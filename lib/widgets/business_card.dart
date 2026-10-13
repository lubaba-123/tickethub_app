import 'package:flutter/material.dart';
import '../models/business_model.dart';
import '../theme/app_theme.dart';

class BusinessCard extends StatelessWidget {
  final Business business;
  final VoidCallback onTap;

  const BusinessCard({super.key, required this.business, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              alignment: Alignment.center,
              child: Icon(_categoryIcon(business.category), size: 36, color: AppColors.primary),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    business.category,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: AppColors.pending),
                      const SizedBox(width: 2),
                      Text(
                        business.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          business.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Cinema':
        return Icons.local_movies_outlined;
      case 'Theatre':
        return Icons.theater_comedy_outlined;
      case 'Concerts':
        return Icons.music_note_outlined;
      case 'Sports':
        return Icons.sports_soccer_outlined;
      case 'Workshops':
        return Icons.build_outlined;
      case 'Attractions':
        return Icons.park_outlined;
      default:
        return Icons.storefront_outlined;
    }
  }
}
