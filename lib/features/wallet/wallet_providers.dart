import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../data/models/wallet_model.dart';
import '../auth/providers/auth_providers.dart';

final walletProvider = StreamProvider.autoDispose<WalletModel>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const WalletModel(userId: ''));
  return ref.watch(walletRepositoryProvider).walletStream(user.uid);
});

final walletTransactionsProvider =
    StreamProvider.autoDispose<List<WalletTransaction>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(walletRepositoryProvider).transactions(user.uid);
});
