import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/mock_data.dart';
import '../../state/review_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/open_listing.dart';
import '../../widgets/listing_card.dart';

class BusinessDetailsScreen extends StatelessWidget {
  final String businessId;

  const BusinessDetailsScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    final business = businessById(businessId);
    final listings = listingsForBusiness(businessId);
    final reviewState = context.watch<ReviewState>();
    final summary = reviewState.summaryFor(business.id, business.rating, business.reviewCount);
    final reviews = reviewState.forBusiness(business.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 56),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(business.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              business.category,
                              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.star_rounded, size: 16, color: AppColors.pending),
                          const SizedBox(width: 2),
                          Text(
                            summary.count == 0
                                ? 'No reviews yet'
                                : '${summary.rating.toStringAsFixed(1)} (${summary.count} reviews)',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        business.description,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      _infoRow(Icons.location_on_outlined, business.location),
                      const SizedBox(height: 8),
                      _infoRow(Icons.call_outlined, business.contactPhone),
                      const SizedBox(height: 24),
                      const Text('Upcoming Listings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      if (listings.isEmpty)
                        const Text('No active listings right now.', style: TextStyle(color: AppColors.textSecondary))
                      else
                        ...listings.map(
                          (listing) => ListingCard(
                            listing: listing,
                            onTap: () => openListing(context, listing),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Text(
                        'Reviews (${reviews.length})',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      if (reviews.isEmpty)
                        const Text(
                          'No guest reviews yet. Reviews appear after guests attend an event.',
                          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                        )
                      else
                        for (final review in reviews.take(6))
                          Container(
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
                                      child: Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                    ),
                                    Text(
                                      DateFormat('d MMM yyyy').format(review.createdAt),
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    for (var i = 1; i <= 5; i++)
                                      Icon(
                                        i <= review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                        size: 16,
                                        color: AppColors.pending,
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
      ],
    );
  }
}