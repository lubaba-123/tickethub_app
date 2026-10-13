import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/mock_data.dart';
import '../../models/review_model.dart';
import '../../state/review_state.dart';
import '../../theme/app_theme.dart';

class AdminReviewsTab extends StatelessWidget {
  const AdminReviewsTab({super.key});

  String _businessName(String id) {
    for (final b in mockBusinesses) {
      if (b.id == id) return b.name;
    }
    return 'Business';
  }

  Future<void> _delete(BuildContext context, Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove review?'),
        content: const Text('This review will be permanently removed from the business profile.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ReviewState>().deleteReview(review.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewState>().reviews;

    if (reviews.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No reviews yet. Customer reviews appear here for moderation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final review in reviews)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_businessName(review.businessId), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              for (var i = 1; i <= 5; i++)
                                Icon(
                                  i <= review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 17,
                                  color: AppColors.pending,
                                ),
                              const SizedBox(width: 8),
                              Text(
                                '${review.customerName}  •  ${DateFormat('d MMM yyyy').format(review.createdAt)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          if (review.comment.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(review.comment, style: const TextStyle(fontSize: 13.5, height: 1.35)),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                      tooltip: 'Remove review',
                      onPressed: () => _delete(context, review),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
