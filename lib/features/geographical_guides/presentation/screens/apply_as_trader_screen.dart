import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/core/router/routes.dart';
import 'package:season_app/features/geographical_guides/data/models/geographical_guide_models.dart';
import 'package:season_app/features/geographical_guides/providers/geographical_guides_providers.dart';
import 'package:season_app/features/vendor/data/vendor_models.dart';
import 'package:season_app/features/vendor/presentation/providers/vendor_providers.dart';
import 'package:season_app/shared/widgets/custom_button.dart';
import 'package:season_app/shared/widgets/custom_dropdown.dart';
import 'package:season_app/shared/widgets/custom_text_field.dart';

class ApplyAsTraderScreen extends ConsumerStatefulWidget {
  final int? guideId; // For editing
  const ApplyAsTraderScreen({super.key, this.guideId});

  @override
  ConsumerState<ApplyAsTraderScreen> createState() =>
      _ApplyAsTraderScreenState();
}

class _ApplyAsTraderScreenState extends ConsumerState<ApplyAsTraderScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _geographicalCategoryId;
  int? _geographicalSubCategoryId;
  int? _countryId;
  String? _countryCode; // Store country code for cities API
  int? _cityId;
  final _serviceName = TextEditingController();
  final _description = TextEditingController();
  final _phone1 = TextEditingController();
  final _phone2 = TextEditingController();
  final _address = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _website = TextEditingController();
  final _establishmentNumber = TextEditingController();
  File? _commercialRegister;
  String? _existingRegisterUrl;
  bool _isSubmitting = false;
  bool _loadedExisting = false;

  bool get isEdit => widget.guideId != null;

  @override
  void dispose() {
    _serviceName.dispose();
    _description.dispose();
    _phone1.dispose();
    _phone2.dispose();
    _address.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _website.dispose();
    _establishmentNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(geographicalCategoriesProvider);
    final countriesAsync = ref.watch(countriesProvider);

    // If editing, watch the my-service provider to load existing details
    final existingGuideAsync = isEdit
        ? ref.watch(myGeographicalGuideProvider(widget.guideId!))
        : null;

    // Prefill form fields when data is loaded (only once)
    existingGuideAsync?.whenData((guide) {
      if (!_loadedExisting) {
        _loadedExisting = true;
        _serviceName.text = guide.serviceName;
        _description.text = guide.description ?? '';
        _phone1.text = guide.phone1 ?? '';
        _phone2.text = guide.phone2 ?? '';
        _address.text = guide.address ?? '';
        _latitude.text = guide.latitude ?? '';
        _longitude.text = guide.longitude ?? '';
        _website.text = guide.website ?? '';
        _establishmentNumber.text = guide.establishmentNumber ?? '';
        _existingRegisterUrl = guide.commercialRegister;
        _geographicalCategoryId = guide.category.id;
        _geographicalSubCategoryId = guide.subCategory?.id;
        _countryId = guide.country.id;
        _countryCode = guide.country.code;
        _cityId = guide.city.id;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? loc.editService : loc.applyAsTrader,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isEdit && existingGuideAsync != null
          ? existingGuideAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        loc.errorLoadingProfile,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.toString(),
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(myGeographicalGuideProvider(widget.guideId!));
                        },
                        child: Text(loc.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (_) {
                // Watch cities when country is selected (using country code)
                final citiesAsync = _countryCode != null
                    ? ref.watch(citiesByCountryProvider(_countryCode))
                    : null;
                return _buildForm(context, loc, categoriesAsync, countriesAsync, citiesAsync);
              },
            )
          : () {
              // Watch cities when country is selected (using country code)
              final citiesAsync = _countryCode != null
                  ? ref.watch(citiesByCountryProvider(_countryCode))
                  : null;
              return _buildForm(context, loc, categoriesAsync, countriesAsync, citiesAsync);
            }(),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations loc,
    AsyncValue<List<GeographicalCategory>> categoriesAsync,
    AsyncValue<List<CountryModel>> countriesAsync,
    AsyncValue<List<City>>? citiesAsync,
  ) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Geographical Category
            categoriesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
                error: (e, s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    e.toString(),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                data: (categories) {
                  final isRtl = Localizations.localeOf(context).languageCode == 'ar';
                  return CustomDropdown(
                    hintText: isRtl ? 'التصنيف الجغرافي' : 'Geographical Category',
                    value: _geographicalCategoryId?.toString(),
                    items: categories
                        .where((c) => c.isActive)
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c.id.toString(),
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _geographicalCategoryId = int.tryParse(val ?? '');
                        _geographicalSubCategoryId = null; // Reset sub-category
                      });
                    },
                    validator: (val) =>
                        val == null || val.isEmpty ? loc.required : null,
                    prefixIcon: const Icon(Icons.category),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Geographical Sub-Category (optional) - from nested sub_categories
              if (_geographicalCategoryId != null)
                categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                  data: (categories) {
                    final selectedCategory = categories.firstWhere(
                      (c) => c.id == _geographicalCategoryId,
                      orElse: () => categories.first,
                    );
                    if (selectedCategory.subCategories == null ||
                        selectedCategory.subCategories!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
                    return Column(
                      children: [
                        CustomDropdown(
                          hintText: isRtl 
                              ? 'التصنيف الفرعي الجغرافي (اختياري)' 
                              : 'Geographical Sub-Category (Optional)',
                          value: _geographicalSubCategoryId?.toString(),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(loc.optional),
                            ),
                            ...selectedCategory.subCategories!
                                .where((sc) => sc.isActive)
                                .map(
                                  (sc) => DropdownMenuItem<String>(
                                    value: sc.id.toString(),
                                    child: Text(sc.name),
                                  ),
                                ),
                          ],
                          onChanged: (val) => setState(() =>
                              _geographicalSubCategoryId = val != null
                                  ? int.tryParse(val)
                                  : null),
                          prefixIcon: const Icon(Icons.subdirectory_arrow_right),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),

              // Service Name
              CustomTextField(
                controller: _serviceName,
                hintText: loc.serviceName,
                prefixIcon: const Icon(Icons.badge),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? loc.required : null,
              ),
              const SizedBox(height: 12),

              // Description
              CustomTextField(
                controller: _description,
                hintText: loc.description,
                prefixIcon: const Icon(Icons.description),
                keyboardType: TextInputType.multiline,
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Phone 1
              CustomTextField(
                controller: _phone1,
                hintText: loc.phone,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone),
              ),
              const SizedBox(height: 12),

              // Phone 2
              CustomTextField(
                controller: _phone2,
                hintText: '${loc.phone} 2',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone),
              ),
              const SizedBox(height: 12),

              // Country
              countriesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
                error: (e, s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    e.toString(),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                data: (countries) {
                  return CustomDropdown(
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
                    onChanged: (val) {
                      final countryId = int.tryParse(val ?? '');
                      final country = countries.firstWhere(
                        (c) => c.id == countryId,
                        orElse: () => countries.first,
                      );
                      setState(() {
                        _countryId = countryId;
                        _countryCode = country.code; // Store country code
                        _cityId = null; // Reset city
                      });
                    },
                    validator: (val) =>
                        val == null || val.isEmpty ? loc.required : null,
                    prefixIcon: const Icon(Icons.public),
                  );
                },
              ),
              const SizedBox(height: 12),

              // City (using country code)
              if (_countryCode != null && citiesAsync != null)
                citiesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                  error: (e, s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      e.toString(),
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  data: (cities) {
                    return CustomDropdown(
                      hintText: loc.city,
                      value: _cityId?.toString(),
                      items: cities
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c.id.toString(),
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _cityId = int.tryParse(val ?? '')),
                      validator: (val) =>
                          val == null || val.isEmpty ? loc.required : null,
                      prefixIcon: const Icon(Icons.location_city),
                    );
                  },
                ),

              if (_countryCode != null && citiesAsync != null)
                const SizedBox(height: 12),

              // Address
              CustomTextField(
                controller: _address,
                hintText: loc.address,
                prefixIcon: const Icon(Icons.place),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? loc.required : null,
              ),
              const SizedBox(height: 12),

              // Latitude and Longitude
              if (_latitude.text.isNotEmpty && _longitude.text.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _latitude,
                        hintText: loc.latitude,
                        prefixIcon: const Icon(Icons.my_location),
                        onChanged: null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _longitude,
                        hintText: loc.longitude,
                        prefixIcon: const Icon(Icons.my_location),
                        onChanged: null,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final lat = double.tryParse(_latitude.text);
                    final lng = double.tryParse(_longitude.text);
                    final result = await context.push<ll.LatLng>(
                      '${Routes.locationPicker}?lat=${lat ?? 24.7136}&lng=${lng ?? 46.6753}',
                    );
                    if (result != null) {
                      _latitude.text = result.latitude.toStringAsFixed(6);
                      _longitude.text = result.longitude.toStringAsFixed(6);
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.location_on),
                  label: Text(loc.selectOnMap),
                ),
              ),
              const SizedBox(height: 12),

              // Website
              CustomTextField(
                controller: _website,
                hintText: Localizations.localeOf(context).languageCode == 'ar' 
                    ? 'الموقع الإلكتروني' 
                    : 'Website',
                keyboardType: TextInputType.url,
                prefixIcon: const Icon(Icons.language),
              ),
              const SizedBox(height: 12),

              // Establishment Number
              CustomTextField(
                controller: _establishmentNumber,
                hintText: Localizations.localeOf(context).languageCode == 'ar' 
                    ? 'رقم المنشأة' 
                    : 'Establishment Number',
                prefixIcon: const Icon(Icons.numbers),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? loc.required : null,
              ),
              const SizedBox(height: 12),

              // Commercial Register File
              _FilePickTile(
                label: loc.commercialRegister,
                buttonText: loc.chooseFile,
                valueText: _commercialRegister?.path.split('/').last ??
                    (_existingRegisterUrl != null
                        ? _existingRegisterUrl!.split('/').last
                        : loc.chooseFile),
                onPick: () async {
                  final res = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  );
                  if (res != null && res.files.single.path != null) {
                    setState(() {
                      _commercialRegister = File(res.files.single.path!);
                      _existingRegisterUrl = null; // Clear existing URL when new file is selected
                    });
                  }
                },
              ),

              const SizedBox(height: 24),
              CustomButton(
                text: isEdit ? loc.update : (Localizations.localeOf(context).languageCode == 'ar' ? 'إرسال' : 'Submit'),
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      );
      
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // For create, require category, country, city, address, and establishment number
    if (!isEdit &&
        (_geographicalCategoryId == null ||
            _countryId == null ||
            _cityId == null ||
            _address.text.trim().isEmpty ||
            _establishmentNumber.text.trim().isEmpty)) {
      return;
    }
    
    // For edit, require address and establishment number if not already validated by form
    if (isEdit &&
        (_address.text.trim().isEmpty ||
            _establishmentNumber.text.trim().isEmpty)) {
      // This should be caught by validators, but as a safety check
      return;
    }

    try {
      setState(() => _isSubmitting = true);
      final controller =
          ref.read(geographicalGuideFormControllerProvider);

      if (isEdit) {
        await controller.updateGeographicalGuide(
          id: widget.guideId!,
          geographicalCategoryId: _geographicalCategoryId,
          geographicalSubCategoryId: _geographicalSubCategoryId,
          serviceName: _serviceName.text.trim().isEmpty
              ? null
              : _serviceName.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          phone1: _phone1.text.trim().isEmpty ? null : _phone1.text.trim(),
          phone2: _phone2.text.trim().isEmpty ? null : _phone2.text.trim(),
          countryId: _countryId,
          cityId: _cityId,
          address: _address.text.trim(), // Required field - validator ensures it's not empty
          latitude: _latitude.text.trim().isEmpty
              ? null
              : double.tryParse(_latitude.text.trim()),
          longitude: _longitude.text.trim().isEmpty
              ? null
              : double.tryParse(_longitude.text.trim()),
          website: _website.text.trim().isEmpty ? null : _website.text.trim(),
          commercialRegister: _commercialRegister,
          establishmentNumber: _establishmentNumber.text.trim(), // Required field - validator ensures it's not empty
        );
      } else {
        await controller.createGeographicalGuide(
          geographicalCategoryId: _geographicalCategoryId!,
          geographicalSubCategoryId: _geographicalSubCategoryId,
          serviceName: _serviceName.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          phone1: _phone1.text.trim().isEmpty ? null : _phone1.text.trim(),
          phone2: _phone2.text.trim().isEmpty ? null : _phone2.text.trim(),
          countryId: _countryId!,
          cityId: _cityId!,
          address: _address.text.trim(), // Required field - validator ensures it's not empty
          latitude: _latitude.text.trim().isEmpty
              ? null
              : double.tryParse(_latitude.text.trim()),
          longitude: _longitude.text.trim().isEmpty
              ? null
              : double.tryParse(_longitude.text.trim()),
          website: _website.text.trim().isEmpty ? null : _website.text.trim(),
          commercialRegister: _commercialRegister,
          establishmentNumber: _establishmentNumber.text.trim(), // Required field - validator ensures it's not empty
        );
      }

      if (mounted) {
        final isRtl = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? (isRtl ? 'تم تحديث الخدمة بنجاح' : 'Service updated successfully')
                : (isRtl ? 'تم إنشاء الدليل الجغرافي بنجاح' : 'Geographical guide created successfully')),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
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

