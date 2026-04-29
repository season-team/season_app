import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/features/vendor/presentation/providers/vendor_providers.dart';
import 'package:season_app/core/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:season_app/shared/widgets/custom_button.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:season_app/shared/widgets/custom_text_field.dart';
import 'package:season_app/shared/widgets/custom_dropdown.dart';
import 'package:file_picker/file_picker.dart' as file_picker;

class VendorServiceFormScreen extends ConsumerStatefulWidget {
  final int? serviceId;
  const VendorServiceFormScreen({super.key, this.serviceId});

  @override
  ConsumerState<VendorServiceFormScreen> createState() =>
      _VendorServiceFormScreenState();
}

class _VendorServiceFormScreenState
    extends ConsumerState<VendorServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _serviceTypeId;
  int? _countryId;
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _contact = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  File? _registerFile;
  String? _existingRegisterUrl; // Store URL for existing register
  final List<File> _images = [];
  final List<String> _existingImages = [];
  final List<String> _removedImages = [];
  bool _isSubmitting = false;

  bool get isEdit => widget.serviceId != null;
  bool _loadedExisting = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _contact.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final typesAsync = ref.watch(serviceTypesProvider);
    final countriesAsync = ref.watch(countriesProvider);

    // If editing, load existing details once and prefill
    if (isEdit && !_loadedExisting) {
      _loadedExisting = true;
      ref
          .read(vendorServiceDetailsProvider(widget.serviceId!).future)
          .then((d) {
        _name.text = d.name;
        _description.text = d.description;
        _contact.text = d.contactNumber;
        _address.text = d.address;
        _lat.text = d.latitude;
        _lng.text = d.longitude;
        _existingImages
          ..clear()
          ..addAll(d.images);
        _existingRegisterUrl = d.commercialRegisterUrl;

        // Prefill service type if possible
        typesAsync.whenData((types) {
          final matchingType = types.firstWhere(
            (type) => type.name == d.serviceType,
            orElse: () => types.first,
          );
          _serviceTypeId = matchingType.id;
        });

        setState(() {});
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? loc.editService : loc.newService,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(e.toString())),
        data: (types) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service type
                  CustomDropdown(
                    hintText: loc.serviceType,
                    value: _serviceTypeId?.toString(),
                    items: types
                        .where((t) => t.isActive)
                        .map(
                          (t) => DropdownMenuItem<String>(
                            value: t.id.toString(),
                            child: Text(t.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _serviceTypeId = int.tryParse(val ?? '')),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                    prefixIcon: const Icon(Icons.category),
                  ),
                  const SizedBox(height: 12),

                  // Country dropdown
                  countriesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child:
                          LinearProgressIndicator(minHeight: 2),
                    ),
                    error: (e, s) => Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        e.toString(),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    data: (countries) {
                      return Column(
                        children: [
                          CustomDropdown(
                            hintText: loc.country,
                            value: _countryId?.toString(),
                            items: countries
                                .map(
                                  (c) => DropdownMenuItem<String>(
                                    value: c.id.toString(),
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setState(
                                () => _countryId = int.tryParse(val ?? '')),
                            validator: (val) => val == null || val.isEmpty
                                ? loc.required
                                : null,
                            prefixIcon: const Icon(Icons.public),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),

                  CustomTextField(
                    controller: _name,
                    hintText: loc.serviceName,
                    prefixIcon: const Icon(Icons.badge),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _description,
                    hintText: loc.description,
                    prefixIcon: const Icon(Icons.description),
                    validator: _required,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _contact,
                    hintText: loc.phone,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _address,
                    hintText: loc.address,
                    prefixIcon: const Icon(Icons.place),
                  ),
                  const SizedBox(height: 12),
                  // Hide manual lat/lng input; show current selection read-only only for create
                  if (!isEdit &&
                      _lat.text.isNotEmpty &&
                      _lng.text.isNotEmpty)
                    Row(children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _lat,
                          hintText: loc.latitude,
                          prefixIcon:
                              const Icon(Icons.my_location),
                          onChanged: null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _lng,
                          hintText: loc.longitude,
                          prefixIcon:
                              const Icon(Icons.my_location),
                          onChanged: null,
                        ),
                      ),
                    ]),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        final lat = double.tryParse(_lat.text);
                        final lng = double.tryParse(_lng.text);
                        final result = await context.push<ll.LatLng>(
                          '${Routes.locationPicker}?lat=${lat ?? 24.7136}&lng=${lng ?? 46.6753}',
                        );
                        if (result != null) {
                          _lat.text =
                              result.latitude.toStringAsFixed(6);
                          _lng.text =
                              result.longitude.toStringAsFixed(6);
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.location_on),
                      label: Text(loc.selectOnMap),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register file
                  _FilePickTile(
                    label: loc.commercialRegister,
                    buttonText: loc.chooseFile,
                    valueText: () {
                      if (_registerFile != null) {
                        // Extract filename from file path (cross-platform safe)
                        return _registerFile!.path.split(Platform.pathSeparator).last;
                      } else if (_existingRegisterUrl != null) {
                        // Extract filename from URL
                        try {
                          final uri = Uri.parse(_existingRegisterUrl!);
                          final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
                          if (segments.isNotEmpty) {
                            return segments.last;
                          }
                        } catch (e) {
                          // Fallback to simple split if URI parsing fails
                        }
                        // Fallback: split by '/' and get last non-empty segment
                        final parts = _existingRegisterUrl!.split('/').where((s) => s.isNotEmpty).toList();
                        return parts.isNotEmpty ? parts.last : loc.chooseFile;
                      }
                      return loc.chooseFile;
                    }(),
                    onPick: () async {
                      final res = await file_picker.FilePicker.platform.pickFiles(
                          type: file_picker.FileType.custom,
                          allowedExtensions: ['pdf']);
                      if (res != null &&
                          res.files.isNotEmpty &&
                          res.files.first.path != null) {
                        setState(() => _registerFile =
                            File(res.files.first.path!));
                      }
                    },
                  ),

                  const SizedBox(height: 12),
                  // Images picker
                  const SizedBox(height: 6),
                  Text(loc.serviceImages,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700)),

                  // Existing images (edit)
                  if (_existingImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final url in _existingImages)
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(8),
                                child: Image.network(url,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 3,
                                right: 3,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _existingImages.remove(url);
                                      _removedImages.add(url);
                                    });
                                  },
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(25),
                                    ),
                                    child: const Icon(
                                        Icons.cancel,
                                        color: AppColors.error),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // New images picker
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in _images)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(8),
                              child: Image.file(f,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 3,
                              right: 3,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() =>
                                        _images.remove(f)),
                                child: Container(
                                  padding:
                                      const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(25),
                                  ),
                                  child: const Icon(
                                      Icons.cancel,
                                      color: AppColors.error),
                                ),
                              ),
                            ),
                          ],
                        ),
                      InkWell(
                        onTap: () async {
                          final res = await file_picker.FilePicker.platform
                              .pickFiles(
                                  type: file_picker.FileType.image,
                                  allowMultiple: true);
                          if (res != null) {
                            setState(() {
                              _images.addAll(res.paths
                                  .whereType<String>()
                                  .map((p) => File(p)));
                            });
                          }
                        },
                        child: Container(
                          width: 90,
                          height: 90,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withOpacity(0.06),
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(Icons.add_a_photo,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  CustomButton(
                    text: isEdit ? loc.update : loc.create,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _serviceTypeId == null ||
        _countryId == null) return;

    try {
      setState(() => _isSubmitting = true);
      final controller = ref.read(vendorServiceFormControllerProvider);
      final fields = {
        'service_type_id': _serviceTypeId,
        'country_id': _countryId,
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'contact_number': _contact.text.trim(),
        'address': _address.text.trim(),
        'latitude': _lat.text.trim(),
        'longitude': _lng.text.trim(),
        if (_removedImages.isNotEmpty) 'remove_images': _removedImages,
        if (_existingImages.isNotEmpty) 'keep_images': _existingImages,
      };

      if (isEdit) {
        await controller.update(
          widget.serviceId!,
          fields,
          register: _registerFile,
          images: _images,
        );
      } else {
        await controller.create(
          fields,
          register: _registerFile,
          images: _images,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _FilePickTile extends StatelessWidget {
  final String label;
  final String valueText;
  final VoidCallback onPick;
  final String buttonText;
  const _FilePickTile({
    required this.label,
    required this.valueText,
    required this.onPick,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valueText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onPick,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
