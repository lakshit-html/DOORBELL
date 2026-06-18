import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../data/models/address_model.dart';
import '../auth/providers/auth_providers.dart';

final addressesProvider =
    StreamProvider.autoDispose<List<AddressModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(userRepositoryProvider).addressStream(user.uid);
});
