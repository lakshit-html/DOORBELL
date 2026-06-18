import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/address_model.dart';
import '../../../data/services/location_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../address_providers.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
      body: addresses.when(
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.location_off_outlined,
                title: 'No saved addresses',
                subtitle: 'Add an address to speed up checkout.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final a = list[i];
                  final user = ref.read(currentUserProvider).value;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                          a.label.toLowerCase() == 'work'
                              ? Icons.work_outline
                              : Icons.home_outlined,
                          color: AppColors.primary),
                      title: Row(
                        children: [
                          Text(a.label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          if (a.isDefault)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Default',
                                  style: TextStyle(fontSize: 10)),
                            ),
                        ],
                      ),
                      subtitle: Text(a.formatted),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (user == null) return;
                          if (v == 'default') {
                            ref
                                .read(userRepositoryProvider)
                                .setDefaultAddress(user.uid, a.id);
                          } else if (v == 'delete') {
                            ref
                                .read(userRepositoryProvider)
                                .deleteAddress(user.uid, a.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'default', child: Text('Set as default')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => EmptyState(icon: Icons.error_outline, title: '$e'),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddAddressSheet(),
    );
  }
}

class _AddAddressSheet extends ConsumerStatefulWidget {
  const _AddAddressSheet();

  @override
  ConsumerState<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<_AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController(text: 'Home');
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  double? _lat;
  double? _lng;
  bool _saving = false;
  bool _locating = false;

  @override
  void dispose() {
    for (final c in [_label, _line1, _line2, _city, _pincode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final service = ref.read(locationServiceProvider);
    final result = await service.requestPosition();
    if (result.isOk) {
      final pos = result.position!;
      _lat = pos.latitude;
      _lng = pos.longitude;
      final addr =
          await service.addressFromCoordinates(pos.latitude, pos.longitude);
      if (addr != null && _line1.text.isEmpty) _line1.text = addr;
    }
    if (!mounted) return;
    setState(() => _locating = false);
    if (!result.isOk) {
      AppSnackbar.error(context, result.message);
      if (result.status == LocationStatus.serviceDisabled) {
        service.openLocationSettings();
      } else if (result.status == LocationStatus.deniedForever) {
        service.openAppSettings();
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => _saving = true);
    final address = AddressModel(
      id: '',
      label: _label.text.trim(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim(),
      city: _city.text.trim(),
      pincode: _pincode.text.trim(),
      latitude: _lat ?? 0,
      longitude: _lng ?? 0,
    );
    await ref.read(userRepositoryProvider).addAddress(user.uid, address);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Address',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              SecondaryButton(
                label: _locating
                    ? 'Detecting…'
                    : 'Use my current location',
                icon: Icons.my_location,
                onPressed: _locating ? null : _useCurrentLocation,
              ),
              const SizedBox(height: 16),
              AppTextField(
                  label: 'Label (Home / Work)', controller: _label),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Address line 1',
                  controller: _line1,
                  validator: (v) => Validators.required(v, 'Address')),
              const SizedBox(height: 12),
              AppTextField(label: 'Address line 2', controller: _line2),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                        label: 'City',
                        controller: _city,
                        validator: (v) => Validators.required(v, 'City')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                        label: 'Pincode',
                        controller: _pincode,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            Validators.required(v, 'Pincode')),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                  label: 'Save Address',
                  isLoading: _saving,
                  onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
