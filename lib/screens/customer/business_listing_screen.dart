import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/business_model.dart';
import '../../theme/app_theme.dart';
import 'business_details_screen.dart';

class BusinessListingScreen extends StatefulWidget {
  final String? initialCategory;

  const BusinessListingScreen({super.key, this.initialCategory});

  @override
  State<BusinessListingScreen> createState() => _BusinessListingScreenState();
}

class _BusinessListingScreenState extends State<BusinessListingScreen> {
  String? _category;
  String _sort = 'Popular';

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  List<Business> get _filtered {
    var list = mockBusinesses.where((b) {
      return _category == null || b.category == _category;
    }).toList();

    switch (_sort) {
      case 'Highest Rated':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Newest':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default: // Popular
        list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_category ?? 'All Businesses')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...mockCategories.map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sort,
                    decoration: const InputDecoration(labelText: 'Sort by'),
                    items: const [
                      DropdownMenuItem(value: 'Popular', child: Text('Popular')),
                      DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                      DropdownMenuItem(value: 'Highest Rated', child: Text('Highest Rated')),
                    ],
                    onChanged: (v) => setState(() => _sort = v!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No businesses found.', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final business = _filtered[i];
                      return _BusinessRow(
                        business: business,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => BusinessDetailsScreen(businessId: business.id)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BusinessRow extends StatelessWidget {
  final Business business;
  final VoidCallback onTap;

  const _BusinessRow({required this.business, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.storefront_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(business.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(business.category, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: AppColors.pending),
                      const SizedBox(width: 2),
                      Text('${business.rating} (${business.reviewCount})', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          business.location,
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
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
