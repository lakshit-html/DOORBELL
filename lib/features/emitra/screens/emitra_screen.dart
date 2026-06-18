import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/emitra_order_model.dart';
import '../../../data/models/enums.dart';
import '../../auth/providers/auth_providers.dart';

class EMitraScreen extends ConsumerStatefulWidget {
  const EMitraScreen({super.key});

  @override
  ConsumerState<EMitraScreen> createState() => _EMitraScreenState();
}

class _EMitraScreenState extends ConsumerState<EMitraScreen> {
  EMitraServiceType _service = EMitraServiceType.aadharPrint;
  final _notesController = TextEditingController();
  int _copies = 1;
  bool _colour = false;
  final List<File> _files = [];
  bool _loading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _files.add(File(picked.path)));
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    if (_files.isEmpty) {
      AppSnackbar.error(context, 'Please upload at least one document');
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(emitraRepositoryProvider);
      final urls = <String>[];
      for (final file in _files) {
        final filename = file.path.split('/').last;
        urls.add(await repo.uploadDocument(user.uid, filename, file));
      }
      final pricePerPage = _colour ? 10.0 : 5.0;
      final order = EMitraOrderModel(
        orderId: '',
        customerId: user.uid,
        serviceType: _service,
        description: _service.label,
        documentUrls: urls,
        printCopies: _copies,
        isColour: _colour,
        totalAmount: pricePerPage * _copies,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      final result = await repo.placeOrder(order);
      if (!mounted) return;
      result.when(
        success: (_) {
          AppSnackbar.success(
              context, 'Order placed! We will deliver your prints shortly.');
          setState(() {
            _files.clear();
            _notesController.clear();
            _copies = 1;
            _colour = false;
          });
        },
        failure: (f) => AppSnackbar.error(context, f.message),
      );
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Mitra Services'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Upload your documents and we deliver the prints to your door. '
                  'Government certificates are processed within 24 hours.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Service type
          Text('Service Type',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EMitraServiceType.values
                .map((s) => ChoiceChip(
                      label:
                          Text(s.label, style: const TextStyle(fontSize: 12)),
                      selected: _service == s,
                      onSelected: (_) => setState(() => _service = s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),

          // Upload
          Text('Upload Documents',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...List.generate(
            _files.length,
            (i) => ListTile(
              dense: true,
              leading:
                  const Icon(Icons.description_outlined, color: AppColors.primary),
              title: Text(_files[i].path.split('/').last,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _files.removeAt(i)),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Add Document / Photo'),
          ),
          const SizedBox(height: 20),

          // Print options
          Text('Print Options',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Copies:'),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed:
                  _copies > 1 ? () => setState(() => _copies--) : null,
            ),
            Text('$_copies',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => setState(() => _copies++),
            ),
            const Spacer(),
            const Text('Colour:'),
            Switch(
                value: _colour,
                onChanged: (v) => setState(() => _colour = v)),
          ]),
          Text(
            'Estimated: ₹${(_colour ? 10 : 5) * _copies}  '
            '(₹${_colour ? 10 : 5}/page × $_copies)',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Notes
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Additional notes (optional)',
              hintText: 'e.g. Please laminate the certificate',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Place E-Mitra Order',
            isLoading: _loading,
            onPressed: _submit,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
