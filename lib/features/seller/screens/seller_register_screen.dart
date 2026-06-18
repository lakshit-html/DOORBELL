import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/services/location_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/shop_model.dart';
import '../../auth/providers/auth_providers.dart';

class SellerRegisterScreen extends ConsumerStatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  ConsumerState<SellerRegisterScreen> createState() =>
      _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends ConsumerState<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _address = TextEditingController();
  final _gst = TextEditingController();
  final _categories = TextEditingController(text: 'Grocery');

  File? _photo;
  double? _lat;
  double? _lng;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _desc, _address, _gst, _categories]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _detectLocation() async {
    final service = ref.read(locationServiceProvider);
    final result = await service.requestPosition();
    if (!mounted) return;
    if (result.isOk) {
      final pos = result.position!;
      _lat = pos.latitude;
      _lng = pos.longitude;
      setState(() {});
      final addr =
          await service.addressFromCoordinates(pos.latitude, pos.longitude);
      if (addr != null && _address.text.isEmpty) _address.text = addr;
      if (mounted) AppSnackbar.success(context, 'Location captured');
      return;
    }
    AppSnackbar.error(context, result.message);
    if (result.status == LocationStatus.serviceDisabled) {
      service.openLocationSettings();
    } else if (result.status == LocationStatus.deniedForever) {
      service.openAppSettings();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    if (_lat == null || _lng == null) {
      AppSnackbar.error(context, 'Please capture your store location');
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(shopRepositoryProvider);
      final shopId = await repo.createShop(ShopModel(
        shopId: '',
        ownerId: user.uid,
        shopName: _name.text.trim(),
        description: _desc.text.trim(),
        address: _address.text.trim(),
        latitude: _lat!,
        longitude: _lng!,
        categories: _categories.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        gstNumber: _gst.text.trim(),
      ));
      if (_photo != null) {
        final url = await ref
            .read(storageServiceProvider)
            .uploadToFolder('shops/$shopId/images', _photo!);
        await repo.updateShop(shopId, {
          'images': [url]
        });
      }
      if (mounted) {
        AppSnackbar.success(
            context, 'Store submitted! Awaiting admin approval.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Store')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _photo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_photo!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: AppColors.primary, size: 32),
                            SizedBox(height: 8),
                            Text('Upload shop photo'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                  label: 'Shop Name',
                  controller: _name,
                  validator: (v) => Validators.required(v, 'Shop name')),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Description', controller: _desc, maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Categories (comma separated)',
                  controller: _categories),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'GST Number (optional)', controller: _gst),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Address',
                  controller: _address,
                  maxLines: 2,
                  validator: (v) => Validators.required(v, 'Address')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _detectLocation,
                icon: const Icon(Icons.my_location),
                label: Text(_lat == null
                    ? 'Capture Store Location'
                    : 'Location captured ✓'),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                  label: 'Submit for Approval',
                  isLoading: _saving,
                  onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
