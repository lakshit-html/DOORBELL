import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/rider_model.dart';
import '../../auth/providers/auth_providers.dart';

class RiderRegisterScreen extends ConsumerStatefulWidget {
  const RiderRegisterScreen({super.key});

  @override
  ConsumerState<RiderRegisterScreen> createState() =>
      _RiderRegisterScreenState();
}

class _RiderRegisterScreenState extends ConsumerState<RiderRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumber = TextEditingController();
  final _licenseNumber = TextEditingController();
  VehicleType _vehicleType = VehicleType.bike;

  bool _saving = false;

  @override
  void dispose() {
    _vehicleNumber.dispose();
    _licenseNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(riderRepositoryProvider).register(RiderModel(
            riderId: user.uid,
            name: user.name,
            phone: user.phone ?? '',
            vehicleType: _vehicleType,
            vehicleNumber: _vehicleNumber.text.trim().toUpperCase(),
            licenseNumber: _licenseNumber.text.trim().toUpperCase(),
          ));
      if (mounted) {
        AppSnackbar.success(
            context, 'Submitted! We will verify your details soon.');
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
      appBar: AppBar(title: const Text('Rider Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Vehicle Details',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              DropdownButtonFormField<VehicleType>(
                initialValue: _vehicleType,
                decoration: const InputDecoration(labelText: 'Vehicle Type'),
                items: VehicleType.values
                    .map((v) => DropdownMenuItem(
                        value: v, child: Text(v.name.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _vehicleType = v!),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Vehicle Number',
                controller: _vehicleNumber,
                hint: 'KA01AB1234',
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(12),
                ],
                validator: (v) => Validators.required(v, 'Vehicle number'),
              ),
              const SizedBox(height: 24),
              const Text('Driving License',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Driving License Number',
                controller: _licenseNumber,
                hint: 'KA0120220001234',
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(20),
                ],
                validator: (v) {
                  final req = Validators.required(v, 'License number');
                  if (req != null) return req;
                  if (v!.trim().length < 8) return 'Enter a valid license number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                  label: 'Submit Application',
                  isLoading: _saving,
                  onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uppercases input as the user types (vehicle / license numbers).
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
