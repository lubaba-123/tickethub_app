import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/business_card.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/notification_bell.dart';
import 'categories_screen.dart';
import 'search_screen.dart';
import 'my_tickets_screen.dart';
import 'profile_screen.dart';
import 'business_listing_screen.dart';
import 'business_details_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find your next event', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    SizedBox(height: 2),
                    Text('Islamabad', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  ],
                ),
                const NotificationBell(),
              ],
            ),
            const SizedBox(height: 20),

            // Search bar
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Search businesses, events...', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Categories
            _SectionHeader(
              title: 'Categories',
              onSeeAll: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: mockCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final cat = mockCategories[i];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => BusinessListingScreen(initialCategory: cat)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(_categoryIcon(cat), color: AppColors.primary),
                        ),
                        const SizedBox(height: 6),
                        Text(cat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Featured businesses
            _SectionHeader(
              title: 'Featured Businesses',
              onSeeAll: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BusinessListingScreen()),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: mockBusinesses.length,
                itemBuilder: (context, i) {
                  final business = mockBusinesses[i];
                  return BusinessCard(
                    business: business,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => BusinessDetailsScreen(businessId: business.id)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Upcoming events
            const _SectionHeader(title: 'Upcoming Events'),
            const SizedBox(height: 12),
            ...mockListings.map(
              (listing) => ListingCard(
                listing: listing,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BusinessDetailsScreen(businessId: listing.businessId),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.confirmation_number_outlined), selectedIcon: Icon(Icons.confirmation_number), label: 'My Tickets'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (i) {
          if (i == 1) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
          } else if (i == 2) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyTicketsScreen()));
          } else if (i == 3) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
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
      case 'Experiences':
        return Icons.auto_awesome_outlined;
      default:
        return Icons.event_outlined;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: const Text('See all', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
      ],
    );
  }
}