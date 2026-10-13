import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_model.dart';
import '../../state/auth_state.dart';
import '../../state/business_state.dart';
import '../../state/notification_state.dart';
import '../../theme/app_theme.dart';

class AdminBusinessesTab extends StatefulWidget {
  const AdminBusinessesTab({super.key});

  @override
  State<AdminBusinessesTab> createState() => _AdminBusinessesTabState();
}

class _AdminBusinessesTabState extends State<AdminBusinessesTab> {
  BusinessStatus? _filter;

  Color _color(BusinessStatus status) {
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

  String _label(BusinessStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }

  Future<void> _change(Business business, BusinessStatus next, String verb) async {
    final businessState = context.read<BusinessState>();
    final notifications = context.read<NotificationState>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await businessState.setBusinessStatus(business.id, next);
    if (!mounted) return;
    if (ok) {
      await notifications.notify(
        business.ownerId,
        'Business ${_label(next).toLowerCase()}',
        '${business.name} was $verb by the platform admin.',
      );
      messenger.showSnackBar(SnackBar(content: Text('${business.name} $verb.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessState = context.watch<BusinessState>();
    final users = context.watch<AuthState>().users;
    final all = businessState.businesses;
    final list = _filter == null ? all : all.where((b) => b.status == _filter).toList();

    String ownerName(String id) {
      for (final u in users) {
        if (u.id == id) return u.name;
      }
      return 'Unknown owner';
    }

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            children: [
              _chip('All (${all.length})', _filter == null, () => setState(() => _filter = null)),
              for (final s in BusinessStatus.values)
                _chip(
                  '${_label(s)} (${all.where((b) => b.status == s).length})',
                  _filter == s,
                  () => setState(() => _filter = s),
                ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text('No businesses found.', style: TextStyle(color: AppColors.textSecondary)),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        for (final business in list)
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(business.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _color(business.status).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _label(business.status),
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _color(business.status)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${business.category}  •  ${business.location}',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Owner: ${ownerName(business.ownerId)}  •  ${business.contactPhone}',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  business.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, height: 1.35),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: _actions(business),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  List<Widget> _actions(Business business) {
    switch (business.status) {
      case BusinessStatus.pending:
        return [
          _button('Approve', AppColors.success, () => _change(business, BusinessStatus.approved, 'approved')),
          _button('Reject', AppColors.danger, () => _change(business, BusinessStatus.rejected, 'rejected')),
        ];
      case BusinessStatus.approved:
        return [
          _button('Suspend', AppColors.danger, () => _change(business, BusinessStatus.suspended, 'suspended')),
        ];
      case BusinessStatus.suspended:
        return [
          _button('Reactivate', AppColors.success, () => _change(business, BusinessStatus.approved, 'reactivated')),
        ];
      case BusinessStatus.rejected:
        return [
          _button('Approve', AppColors.success, () => _change(business, BusinessStatus.approved, 'approved')),
        ];
    }
  }

  Widget _button(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(96, 38),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
