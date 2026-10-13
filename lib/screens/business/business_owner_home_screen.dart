import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../state/auth_state.dart';
import '../../state/business_state.dart';
import '../../models/business_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/notification_bell.dart';
import '../auth/login_screen.dart';
import 'business_registration_screen.dart';
import 'business_profile_screen.dart';
import 'add_edit_listing_screen.dart';
import 'ticket_types_screen.dart';
import 'business_dashboard_screen.dart';
import 'owner_bookings_screen.dart';
import 'qr_scanner_screen.dart';

class BusinessOwnerHomeScreen extends StatelessWidget {
  const BusinessOwnerHomeScreen({super.key});

  Color _statusColor(BusinessStatus status) {
    switch (status) {
      case BusinessStatus.approved:
        return AppColors.success;
      case BusinessStatus.pending:
        return AppColors.pending;
      case BusinessStatus.rejected:
      case BusinessStatus.suspended:
        return AppColors.danger;
    }
  }

  String _statusLabel(BusinessStatus status) {
    switch (status) {
      case BusinessStatus.approved:
        return 'Approved';
      case BusinessStatus.pending:
        return 'Pending Review';
      case BusinessStatus.rejected:
        return 'Rejected';
      case BusinessStatus.suspended:
        return 'Suspended';
    }
  }

  String _statusMessage(BusinessStatus status) {
    switch (status) {
      case BusinessStatus.approved:
        return '';
      case BusinessStatus.pending:
        return 'Your business is awaiting admin approval. It goes live for customers once approved.';
      case BusinessStatus.rejected:
        return 'Your business was rejected by the admin. Update your details or contact support.';
      case BusinessStatus.suspended:
        return 'Your business is suspended and hidden from customers until the admin reactivates it.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final businessState = context.watch<BusinessState>();
    final owner = auth.currentUser!;
    final business = businessState.businessForOwner(owner.id);

    if (business == null) {
      return const BusinessRegistrationScreen();
    }

    final listings = businessState.listingsForBusiness(business.id);
    final message = _statusMessage(business.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Business'),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Center(child: NotificationBell()),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BusinessProfileScreen(businessId: business.id)),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(business.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(business.category, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(business.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel(business.status),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(business.status)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusColor(business.status).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: _statusColor(business.status)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(message, style: const TextStyle(fontSize: 12.5, height: 1.35))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  _action(context, Icons.insights_rounded, 'Dashboard', const BusinessDashboardScreen()),
                  const SizedBox(width: 12),
                  _action(context, Icons.receipt_long_outlined, 'Bookings', const OwnerBookingsScreen()),
                  const SizedBox(width: 12),
                  _action(context, Icons.qr_code_scanner_rounded, 'Scan Tickets', const QrScannerScreen()),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Listings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AddEditListingScreen(businessId: business.id)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Listing'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (listings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.event_busy_outlined, size: 36, color: AppColors.textSecondary),
                      SizedBox(height: 10),
                      Text(
                        'No listings yet. Add your first event or service.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ...listings.map((listing) {
                  final typeCount = businessState.ticketTypesForListing(listing.id).length;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(listing.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('d MMM yyyy').format(listing.date)} • ${listing.startTime}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                typeCount == 0 ? 'No ticket types yet' : '$typeCount ticket type(s)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: typeCount == 0 ? AppColors.pending : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.confirmation_number_outlined, size: 20, color: AppColors.primary),
                          tooltip: 'Ticket types',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => TicketTypesScreen(listing: listing)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddEditListingScreen(
                                businessId: business.id,
                                existingListing: listing,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                          onPressed: () => businessState.deleteListing(listing.id),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label, Widget page) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}