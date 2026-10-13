import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import 'business_listing_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: mockCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.3,
          ),
          itemBuilder: (context, i) {
            final cat = mockCategories[i];
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BusinessListingScreen(initialCategory: cat)),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_categoryIcon(cat), color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(height: 10),
                    Text(cat, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
