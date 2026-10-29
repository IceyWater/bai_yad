import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/billing_cycle.dart';
import '../domain/subscription.dart';
import '../domain/subscription_category.dart';
import 'subscription_presentation.dart';

class AddSubscriptionSheet extends StatefulWidget {
  const AddSubscriptionSheet({super.key, this.subscription});

  final Subscription? subscription;

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  late BillingCycle _cycle;
  late SubscriptionCategory _category;
  late DateTime _renewalDate;
  late Color _selectedColor;

  static const _cycles = BillingCycle.values;
  static const _categories = SubscriptionCategory.values;
  static const _colors = [
    AppColors.categoryDanger,
    AppColors.mint,
    AppColors.categoryUtilities,
    AppColors.categoryWork,
    AppColors.categoryStreaming,
  ];

  @override
  void initState() {
    super.initState();
    final subscription = widget.subscription;
    _nameController.text = subscription?.name ?? '';
    _amountController.text = subscription?.amount.toString() ?? '';
    _cycle = subscription?.billingCycle ?? BillingCycle.monthly;
    _category = subscription?.category ?? SubscriptionCategory.streaming;
    _renewalDate = subscription?.anchorDate ?? DateTime.now();
    _selectedColor = subscription?.color ?? AppColors.mint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _renewalDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.mint,
            onPrimary: AppColors.ink,
            surface: AppColors.panelRaised,
            onSurface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _renewalDate = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.subscription;
    final entry = Subscription(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      billingCycle: _cycle,
      category: _category,
      anchorDate: _renewalDate,
      createdAt: existing?.createdAt ?? DateTime.now(),
      colorArgb: _selectedColor.toARGB32(),
      isRarelyUsed: existing?.isRarelyUsed ?? false,
      notes: existing?.notes,
    );
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return FractionallySizedBox(
      heightFactor: MediaQuery.sizeOf(context).height < 700 ? 0.92 : 0.80,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.sheetSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.sheetBorder)),
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.sheetHandle,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 18, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subscription == null
                              ? 'Add Subscription'
                              : 'Edit Subscription',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: AppColors.brightGreen,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Manual entry  •  Stored on device',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.muted.withValues(alpha: 0.9),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('closeAddSubscriptionButton'),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.white.withValues(alpha: 0.06),
                      foregroundColor: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(22, 18, 22, 18 + bottomInset),
                  children: [
                    _FormLabel('SERVICE / BILL NAME'),
                    const SizedBox(height: 7),
                    TextFormField(
                      key: const Key('newSubscriptionNameField'),
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 80,
                      buildCounter:
                          (context, {required currentLength, required isFocused, maxLength}) =>
                              null,
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        if (name.isEmpty) return 'Enter a service name';
                        if (name.length > 80) {
                          return 'Use 80 characters or fewer';
                        }
                        return null;
                      },
                      decoration: _inputDecoration(
                        hint: 'e.g. Spotify Premium',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormLabel('COST (₱)'),
                              const SizedBox(height: 7),
                              TextFormField(
                                key: const Key('newSubscriptionAmountField'),
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}$'),
                                  ),
                                ],
                                validator: (value) {
                                  final amount = double.tryParse(value ?? '');
                                  if (amount == null ||
                                      !amount.isFinite ||
                                      amount <= 0) {
                                    return 'Enter a valid cost';
                                  }
                                  if (amount > 99999999.99) {
                                    return 'Maximum cost is ₱99,999,999.99';
                                  }
                                  return null;
                                },
                                decoration: _inputDecoration(prefix: '₱'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormLabel('BILLING CYCLE'),
                              const SizedBox(height: 7),
                              DropdownButtonFormField<BillingCycle>(
                                key: const Key('billingCycleDropdown'),
                                isExpanded: true,
                                initialValue: _cycle,
                                items: _cycles
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _cycle = value);
                                  }
                                },
                                decoration: _inputDecoration(),
                                dropdownColor: AppColors.panelRaised,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 12,
                                ),
                                icon: const Icon(
                                  Icons.expand_more,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormLabel('CATEGORY'),
                              const SizedBox(height: 7),
                              DropdownButtonFormField<SubscriptionCategory>(
                                key: const Key('subscriptionCategoryDropdown'),
                                isExpanded: true,
                                initialValue: _category,
                                items: _categories
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _category = value);
                                  }
                                },
                                decoration: _inputDecoration(),
                                dropdownColor: AppColors.panelRaised,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 12,
                                ),
                                icon: const Icon(
                                  Icons.expand_more,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormLabel('NEXT RENEWAL'),
                              const SizedBox(height: 7),
                              SizedBox(
                                height: 56,
                                child: OutlinedButton.icon(
                                  key: const Key('renewalDateButton'),
                                  onPressed: _selectDate,
                                  icon: const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    formatSubscriptionDate(_renewalDate),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textSecondary,
                                    side: const BorderSide(
                                      color: AppColors.inputBorder,
                                    ),
                                    backgroundColor: AppColors.inputSurface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 19),
                    const _FormLabel('ICON THEME COLOR'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      children: _colors.map((color) {
                        final selected = color == _selectedColor;
                        return Semantics(
                          button: true,
                          selected: selected,
                          label:
                              'Theme color ${color.toARGB32().toRadixString(16)}',
                          child: InkWell(
                            key: Key(
                              'subscriptionColor${_colors.indexOf(color)}',
                            ),
                            onTap: () => setState(() => _selectedColor = color),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(color: AppColors.white, width: 2)
                                    : null,
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.35),
                                          blurRadius: 12,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: AppColors.ink,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 23),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        key: const Key('saveSubscriptionButton'),
                        onPressed: _save,
                        icon: const Icon(Icons.check_rounded, size: 19),
                        label: Text(
                          widget.subscription == null
                              ? 'Save Subscription'
                              : 'Save Changes',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.mint,
                          foregroundColor: AppColors.ink,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textLabel,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
  );
}

InputDecoration _inputDecoration({String? hint, String? prefix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.inputPlaceholder, fontSize: 12),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
      filled: true,
      fillColor: AppColors.inputSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.mint, width: 1.3),
      ),
      errorStyle: const TextStyle(fontSize: 10),
    );
