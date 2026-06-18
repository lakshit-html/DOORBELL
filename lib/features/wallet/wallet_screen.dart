import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/wallet_model.dart';
import '../../data/services/payment_service.dart';
import '../auth/providers/auth_providers.dart';
import 'wallet_providers.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _gateway = RazorpayGateway();

  @override
  void dispose() {
    _gateway.dispose();
    super.dispose();
  }

  Future<void> _addMoney() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Money'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                prefixText: '₹ ', hintText: 'Enter amount'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, double.tryParse(controller.text)),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (amount == null || amount <= 0) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final result = await _gateway.pay(
      amount: amount,
      name: 'DoorBell Wallet',
      description: 'Wallet top-up',
      email: user.email,
      contact: user.phone,
    );
    if (!result.success) {
      if (mounted) AppSnackbar.error(context, result.error ?? 'Payment failed');
      return;
    }
    await ref.read(walletRepositoryProvider).applyTransaction(
          user.uid,
          type: TransactionType.credit,
          amount: amount,
          description: 'Wallet top-up',
        );
    if (mounted) AppSnackbar.success(context, 'Wallet topped up!');
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final txns = ref.watch(walletTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Balance',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 8),
                Text(
                  Formatters.currency(wallet.value?.balance ?? 0),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
              label: 'Add Money',
              icon: Icons.add,
              onPressed: _addMoney),
          const SizedBox(height: 24),
          Text('Transactions',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          txns.when(
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                        child: Text('No transactions yet',
                            style:
                                TextStyle(color: AppColors.textSecondary))),
                  )
                : Column(
                    children: list.map((t) {
                      final credit = t.type == TransactionType.credit;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: (credit
                                  ? AppColors.success
                                  : AppColors.error)
                              .withValues(alpha: 0.15),
                          child: Icon(
                              credit
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: credit
                                  ? AppColors.success
                                  : AppColors.error),
                        ),
                        title: Text(t.description),
                        subtitle: t.createdAt != null
                            ? Text(Formatters.dateTime(t.createdAt!))
                            : null,
                        trailing: Text(
                          '${credit ? '+' : '-'}${Formatters.currency(t.amount)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: credit
                                  ? AppColors.success
                                  : AppColors.error),
                        ),
                      );
                    }).toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Text('$e'),
          ),
        ],
      ),
    );
  }
}
