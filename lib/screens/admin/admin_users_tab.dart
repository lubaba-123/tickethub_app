import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  UserRole? _role;
  String _query = '';

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.businessOwner:
        return 'Business Owner';
      case UserRole.admin:
        return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<AuthState>().users.where((u) => u.role != UserRole.admin).toList();
    final list = all.where((u) {
      final matchesRole = _role == null || u.role == _role;
      final q = _query.toLowerCase();
      final matchesQuery = q.isEmpty || u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
      return matchesRole && matchesQuery;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final customers = all.where((u) => u.role == UserRole.customer).length;
    final owners = all.where((u) => u.role == UserRole.businessOwner).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search users by name or email',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            children: [
              _chip('All (${all.length})', _role == null, () => setState(() => _role = null)),
              _chip('Customers ($customers)', _role == UserRole.customer, () => setState(() => _role = UserRole.customer)),
              _chip('Business Owners ($owners)', _role == UserRole.businessOwner, () => setState(() => _role = UserRole.businessOwner)),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('No users found.', style: TextStyle(color: AppColors.textSecondary)))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        for (final user in list)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                                      const SizedBox(height: 2),
                                      Text(user.email, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${user.phone}  •  Joined ${DateFormat('d MMM yyyy').format(user.createdAt)}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: (user.role == UserRole.customer ? AppColors.primary : AppColors.accent).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _roleLabel(user.role),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: user.role == UserRole.customer ? AppColors.primary : AppColors.accent,
                                    ),
                                  ),
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
