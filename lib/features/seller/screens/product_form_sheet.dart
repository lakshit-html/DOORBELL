import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/product_model.dart';

/// Bottom sheet to create or edit a product.
class ProductFormSheet extends ConsumerStatefulWidget {
  const ProductFormSheet({super.key, required this.shopId, this.existing});

  final String shopId;
  final ProductModel? existing;

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _desc = TextEditingController(text: widget.existing?.description);
  late final _price =
      TextEditingController(text: widget.existing?.price.toStringAsFixed(0));
  late final _discount = TextEditingController(
      text: widget.existing?.discountedPrice?.toStringAsFixed(0));
  late final _unit =
      TextEditingController(text: widget.existing?.unit ?? '1 pc');
  late final _stock =
      TextEditingController(text: '${widget.existing?.stock ?? 0}');
  late final _category =
      TextEditingController(text: widget.existing?.categoryId);

  File? _imageFile;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    for (final c in [
      _name,
      _desc,
      _price,
      _discount,
      _unit,
      _stock,
      _category
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      String? imageUrl = widget.existing?.image;
      if (_imageFile != null) {
        imageUrl = await ref.read(storageServiceProvider).uploadToFolder(
            StoragePaths.productImages(
                widget.existing?.productId ?? widget.shopId),
            _imageFile!);
      }

      final discount = double.tryParse(_discount.text);
      if (_isEdit) {
        await repo.updateProduct(widget.existing!.productId, {
          'name': _name.text.trim(),
          'description': _desc.text.trim(),
          'price': double.parse(_price.text),
          'discountedPrice': discount,
          'unit': _unit.text.trim(),
          'stock': int.tryParse(_stock.text) ?? 0,
          'isAvailable': (int.tryParse(_stock.text) ?? 0) > 0,
          'categoryId': _category.text.trim(),
          if (imageUrl != null) 'image': imageUrl,
        });
      } else {
        await repo.addProduct(ProductModel(
          productId: '',
          shopId: widget.shopId,
          categoryId: _category.text.trim(),
          name: _name.text.trim(),
          description: _desc.text.trim(),
          image: imageUrl,
          price: double.parse(_price.text),
          discountedPrice: discount,
          unit: _unit.text.trim(),
          stock: int.tryParse(_stock.text) ?? 0,
        ));
      }
      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(context, _isEdit ? 'Product updated' : 'Product added');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
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
              Text(_isEdit ? 'Edit Product' : 'Add Product',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : widget.existing?.image != null
                          ? AppNetworkImage(url: widget.existing!.image)
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined,
                                    color: AppColors.primary),
                                SizedBox(height: 8),
                                Text('Add product photo'),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                  label: 'Name',
                  controller: _name,
                  validator: (v) => Validators.required(v, 'Name')),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Description', controller: _desc, maxLines: 2),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                        label: 'Price (₹)',
                        controller: _price,
                        keyboardType: TextInputType.number,
                        validator: Validators.price),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                        label: 'Discount Price',
                        controller: _discount,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(label: 'Unit', controller: _unit),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                        label: 'Stock',
                        controller: _stock,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Category ID', controller: _category, hint: 'e.g. grocery'),
              const SizedBox(height: 20),
              PrimaryButton(
                  label: _isEdit ? 'Update Product' : 'Add Product',
                  isLoading: _saving,
                  onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
