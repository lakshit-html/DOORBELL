import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/address_model.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

/// Reads/writes the user's profile and saved addresses.
class UserRepository {
  UserRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final StorageService _storage;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(FirestoreCollections.users).doc(uid);

  Future<void> updateProfile(
    String uid, {
    String? name,
    String? phone,
    String? profileImage,
  }) {
    return _userDoc(uid).update({
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (profileImage != null) 'profileImage': profileImage,
    });
  }

  Future<String> uploadProfileImage(String uid, File file) async {
    final url = await _storage.uploadFile(StoragePaths.userProfile(uid), file);
    await updateProfile(uid, profileImage: url);
    return url;
  }

  // ---- Addresses (sub-collection) ----
  CollectionReference<Map<String, dynamic>> _addresses(String uid) =>
      _userDoc(uid).collection(FirestoreCollections.addresses);

  Stream<List<AddressModel>> addressStream(String uid) =>
      _addresses(uid).snapshots().map((snap) => snap.docs
          .map((d) => AddressModel.fromMap({...d.data(), 'id': d.id}))
          .toList());

  Future<void> addAddress(String uid, AddressModel address) async {
    final ref = _addresses(uid).doc();
    await ref.set(address.toMap()..['id'] = ref.id);
  }

  Future<void> deleteAddress(String uid, String addressId) =>
      _addresses(uid).doc(addressId).delete();

  Future<void> setDefaultAddress(String uid, String addressId) async {
    final batch = _firestore.batch();
    final all = await _addresses(uid).get();
    for (final doc in all.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }
    await batch.commit();
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    return doc.exists ? UserModel.fromDoc(doc) : null;
  }

  Stream<UserModel?> userStream(String uid) =>
      _userDoc(uid).snapshots().map((d) => d.exists ? UserModel.fromDoc(d) : null);

  /// All users — admin only.
  Stream<List<UserModel>> allUsers() => _firestore
      .collection(FirestoreCollections.users)
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromDoc).toList());

  /// Update a user's account status (admin only).
  Future<void> updateStatus(String uid, AccountStatus status) =>
      _userDoc(uid).update({'status': status.name});
}

