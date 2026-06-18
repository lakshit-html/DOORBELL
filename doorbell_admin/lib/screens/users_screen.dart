import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../providers/admin_providers.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'User Management',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filtered = _search.isEmpty
                    ? users
                    : users
                          .where(
                            (u) =>
                                u.name.toLowerCase().contains(_search) ||
                                u.email.toLowerCase().contains(_search) ||
                                (u.phone?.contains(_search) ?? false),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _UserTile(user: filtered[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = user.status.name == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF34C759).withAlpha(30),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Color(0xFF34C759),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${user.email} • ${user.role.label}',
          style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withAlpha(30)
                    : Colors.red.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'Active' : 'Suspended',
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (action) => handleAction(context, ref, action),
              itemBuilder: (_) => [
                if (isActive)
                  const PopupMenuItem(value: 'suspend', child: Text('Suspend'))
                else
                  const PopupMenuItem(
                    value: 'reactivate',
                    child: Text('Reactivate'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void handleAction(BuildContext context, WidgetRef ref, String action) async {
    final actions = ref.read(adminActionsProvider);
    switch (action) {
      case 'suspend':
        await actions.suspendUser(user.uid);
        break;
      case 'reactivate':
        await actions.reactivateUser(user.uid);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete User'),
            content: Text('Are you sure you want to delete ${user.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirm == true) await actions.deleteUser(user.uid);
        break;
    }
  }
}
