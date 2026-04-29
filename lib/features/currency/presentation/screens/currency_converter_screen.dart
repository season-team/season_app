import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/constants/app_colors.dart';
import 'package:season_app/core/localization/generated/l10n.dart';
import 'package:season_app/features/currency/providers/currency_providers.dart';

class CurrencyConverterScreen extends ConsumerStatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  ConsumerState<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState
    extends ConsumerState<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'SAR';
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'flag': '🇺🇸'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'flag': '🇸🇦'},
    {'code': 'EGP', 'name': 'Egyptian Pound', 'flag': '🇪🇬'},
    {'code': 'EUR', 'name': 'Euro', 'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'British Pound', 'flag': '🇬🇧'},
    {'code': 'AED', 'name': 'UAE Dirham', 'flag': '🇦🇪'},
    {'code': 'KWD', 'name': 'Kuwaiti Dinar', 'flag': '🇰🇼'},
    {'code': 'QAR', 'name': 'Qatari Riyal', 'flag': '🇶🇦'},
    {'code': 'BHD', 'name': 'Bahraini Dinar', 'flag': '🇧🇭'},
    {'code': 'OMR', 'name': 'Omani Rial', 'flag': '🇴🇲'},
    {'code': 'JOD', 'name': 'Jordanian Dinar', 'flag': '🇯🇴'},
    {'code': 'LBP', 'name': 'Lebanese Pound', 'flag': '🇱🇧'},
    {'code': 'TRY', 'name': 'Turkish Lira', 'flag': '🇹🇷'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'flag': '🇯🇵'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'flag': '🇨🇳'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _convertCurrency() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text);
      if (amount != null && amount > 0) {
        ref.read(currencyControllerProvider.notifier).convertCurrency(
              from: _fromCurrency,
              to: _toCurrency,
              amount: amount,
            );
      }
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    // Convert again if there's a valid amount
    if (_amountController.text.isNotEmpty) {
      _convertCurrency();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyState = ref.watch(currencyControllerProvider);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Header with more height and no border radius
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.currency_exchange,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    loc.currencyConverter,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    loc.currencyConverterSubtitle,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Main Conversion Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Amount Section
                          _buildAmountSection(context, loc),
                          SizedBox(height: 10,),
                          // Separator with Swap Button
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Divider(
                                height: 40,
                                thickness: 1,
                                color: Colors.grey[300],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A5F), // Dark blue
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1E3A5F).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _swapCurrencies,
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(
                                        Icons.swap_vert,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Converted Amount Section
                          _buildConvertedAmountSection(context, loc, currencyState),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Exchange Rate Info
                    if (currencyState.conversion != null)
                      _buildExchangeRateInfo(context, loc, currencyState.conversion!),
                    
                    if (currencyState.error != null)
                      _buildErrorCard(currencyState.error!),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection(BuildContext context, AppLocalizations loc) {
    final selectedCurrency = _currencies.firstWhere(
      (c) => c['code'] == _fromCurrency,
      orElse: () => _currencies[0],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.currencyAmount,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Currency Selector
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: () => _showCurrencyPicker(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        selectedCurrency['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        selectedCurrency['code']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Amount Input
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontFamily: 'Cairo',
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.currencyAmountRequired;
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return loc.currencyAmountInvalid;
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final amount = double.tryParse(value);
                    if (amount != null && amount > 0) {
                      _convertCurrency();
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConvertedAmountSection(BuildContext context, AppLocalizations loc, currencyState) {
    final selectedCurrency = _currencies.firstWhere(
      (c) => c['code'] == _toCurrency,
      orElse: () => _currencies[0],
    );

    final convertedAmount = currencyState.conversion?.convertedAmount ?? 0.0;
    final displayAmount = convertedAmount > 0 ? convertedAmount.toStringAsFixed(2) : '0.00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.currencyConvertedAmount,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Currency Selector
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: () => _showCurrencyPicker(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        selectedCurrency['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        selectedCurrency['code']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          fontFamily: 'Cairo',
                        ),
                      ),
                      ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Converted Amount Display
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  displayAmount,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExchangeRateInfo(BuildContext context, AppLocalizations loc, conversion) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Text(
            loc.currencyExchangeRate,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1 ${conversion.from} = ${conversion.rate.toStringAsFixed(4)} ${conversion.to}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, bool isFrom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _currencies.length,
                itemBuilder: (context, index) {
                  final currency = _currencies[index];
                  final isSelected = (isFrom ? _fromCurrency : _toCurrency) == currency['code'];
                  return ListTile(
                    leading: Text(currency['flag']!, style: const TextStyle(fontSize: 28)),
                    title: Text(
                      currency['code']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(currency['name']!),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    selected: isSelected,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        if (isFrom) {
                          _fromCurrency = currency['code']!;
                        } else {
                          _toCurrency = currency['code']!;
                        }
                      });
                      // Trigger conversion if amount is entered
                      if (_amountController.text.isNotEmpty) {
                        Future.microtask(() => _convertCurrency());
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.error,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
