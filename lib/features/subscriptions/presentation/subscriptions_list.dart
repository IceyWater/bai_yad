import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/name_initials.dart';
import '../../about/about_screen.dart';
import '../domain/subscription.dart';
import '../domain/subscription_category.dart';
import '../domain/subscription_sort.dart';
import '../domain/renewal_calculator.dart';
import 'subscription_presentation.dart';

class SubscriptionsList extends StatelessWidget {
  const SubscriptionsList({
    required this.controller,
    required this.selectedCategory,
    required this.visibleSubscriptions,
    required this.subscriptions,
    required this.onQueryChanged,
    required this.onCategoryChanged,
    required this.sort,
    required this.onSortChanged,
    required this.onEdit,
    required this.onToggleRarelyUsed,
    required this.onDelete,
    this.deleteNoticeVisible = false,
    super.key,
  });

  final TextEditingController controller;
  final String? selectedCategory;
  final List<Subscription> visibleSubscriptions;
  final List<Subscription> subscriptions;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onCategoryChanged;
  final SubscriptionSort sort;
  final ValueChanged<SubscriptionSort> onSortChanged;
  final ValueChanged<Subscription> onEdit;
  final ValueChanged<Subscription> onToggleRarelyUsed;
  final ValueChanged<Subscription> onDelete;
  final bool deleteNoticeVisible;

  static const _categories = SubscriptionCategory.values;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const PageStorageKey('subscriptionList'),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    slivers: [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          deleteNoticeVisible ? 104 : 28,
        ),
        sliver: SliverList.list(
          children: [
            _SearchField(controller: controller, onChanged: onQueryChanged),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Sort by',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: DropdownButton<SubscriptionSort>(
                      key: const Key('subscriptionSortDropdown'),
                      value: sort,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      dropdownColor: AppColors.panelRaised,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      items: SubscriptionSort.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                value.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) onSortChanged(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CategoryChip(
                      label: 'All (${subscriptions.length})',
                      selected: selectedCategory == null,
                      onTap: () => onCategoryChanged(null),
                    );
                  }
                  final category = _categories[index - 1];
                  return _CategoryChip(
                    label: category.label,
                    selected: selectedCategory == category.label,
                    onTap: () => onCategoryChanged(category.label),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            if (visibleSubscriptions.isEmpty)
              const _EmptySubscriptions()
            else
              ...visibleSubscriptions.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _SubscriptionCard(
                    key: ValueKey(entry.id),
                    entry: entry,
                    onEdit: () => onEdit(entry),
                    onToggleRarelyUsed: () => onToggleRarelyUsed(entry),
                    onDelete: () => onDelete(entry),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class SubscriptionsHeader extends StatelessWidget {
  const SubscriptionsHeader({
    required this.name,
    required this.onAdd,
    required this.onReminders,
    super.key,
  });

  final String name;
  final VoidCallback onAdd;
  final VoidCallback onReminders;

  @override
  Widget build(BuildContext context) {
    final compactHeader = MediaQuery.sizeOf(context).width < 420;
    final brand = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.mint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.mint.withValues(alpha: 0.3)),
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            size: 20,
            color: AppColors.brightGreen,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            AppStrings.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('reminderSettingsButton'),
          tooltip: 'Renewal reminders',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: EdgeInsets.zero,
          onPressed: onReminders,
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.brightGreen,
          ),
        ),
        IconButton(
          tooltip: 'About',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen())),
          icon: const Icon(
            Icons.info_outline_rounded,
            color: AppColors.brightGreen,
          ),
        ),
        const SizedBox(width: 2),
        OutlinedButton.icon(
          key: const Key('addSubscriptionButton'),
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 17),
          label: const Text('Add'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brightGreen,
            side: BorderSide(color: AppColors.mint.withValues(alpha: 0.35)),
            backgroundColor: AppColors.mint.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(80, 44),
            shape: const StadiumBorder(),
          ),
        ),
        if (!compactHeader) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.avatarSurface,
            child: Text(
              nameInitials(name),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.avatarText,
              ),
            ),
          ),
        ],
      ],
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: EdgeInsets.symmetric(horizontal: compactHeader ? 14 : 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.subtleBorder)),
      ),
      child: Row(
        children: [
          Expanded(child: brand),
          actions,
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: controller,
    builder: (context, value, _) => TextField(
      key: const Key('subscriptionSearchField'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.inputText,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Search subscriptions...',
        hintStyle: const TextStyle(color: AppColors.inputHint, fontSize: 14),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: AppColors.inputPlaceholder,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        suffixIcon: value.text.isEmpty
            ? null
            : IconButton(
                key: const Key('clearSubscriptionSearchButton'),
                tooltip: 'Clear search',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        filled: true,
        fillColor: AppColors.searchSurface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.searchBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.searchBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.mint, width: 1.3),
        ),
      ),
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    labelStyle: TextStyle(
      fontSize: 11,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      color: selected ? AppColors.ink : AppColors.chipText,
    ),
    labelPadding: const EdgeInsets.symmetric(horizontal: 3),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    side: BorderSide(
      color: selected ? AppColors.mint : AppColors.selectedControl,
    ),
    backgroundColor: AppColors.chipSurface,
    selectedColor: AppColors.mint,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onToggleRarelyUsed,
    required this.onDelete,
  });
  final Subscription entry;
  final VoidCallback onEdit;
  final VoidCallback onToggleRarelyUsed;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final nextDate = nextRenewal(entry.anchorDate, entry.billingCycle);
    final dueLabel = renewalLabel(nextDate);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(17),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 11),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.11),
                  border: Border.all(
                    color: entry.color.withValues(alpha: 0.24),
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(entry.icon, size: 20, color: entry.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Next: ${formatSubscriptionDate(nextDate)} · $dueLabel',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: dueLabel == 'Overdue'
                            ? AppColors.danger
                            : AppColors.textSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        entry.amountLabel,
                        style: const TextStyle(
                          color: AppColors.textMain,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      entry.cadence,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Divider(height: 1, color: AppColors.cardDivider),
          ),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                if (entry.isRarelyUsed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningChipSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.warningChipBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: AppColors.warningAccent,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Rarely used',
                          style: TextStyle(
                            color: AppColors.warningAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                IconButton(
                  key: Key('editSubscription-${entry.id}'),
                  tooltip: 'Edit ${entry.name}',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                    color: AppColors.textMuted,
                  ),
                ),
                IconButton(
                  key: Key('rarelyUsedToggle-${entry.id}'),
                  tooltip: entry.isRarelyUsed
                      ? 'Mark ${entry.name} as used'
                      : 'Mark ${entry.name} as rarely used',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onToggleRarelyUsed,
                  icon: Icon(
                    entry.isRarelyUsed
                        ? Icons.flag_rounded
                        : Icons.outlined_flag_rounded,
                    size: 17,
                    color: entry.isRarelyUsed
                        ? AppColors.warningAccent
                        : AppColors.textMuted,
                  ),
                ),
                IconButton(
                  key: Key('deleteSubscription-${entry.id}'),
                  tooltip: 'Remove ${entry.name}',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 17,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySubscriptions extends StatelessWidget {
  const _EmptySubscriptions();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 58),
    child: Column(
      children: [
        Icon(Icons.search_off_rounded, size: 30, color: AppColors.textMuted),
        SizedBox(height: 11),
        Text(
          'No subscriptions found',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Try another search or category.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class SubscriptionsNavigation extends StatelessWidget {
  const SubscriptionsNavigation({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.grid_view_rounded, 'HOME', 'Home'),
    (Icons.credit_card_rounded, 'SUBSCRIPTIONS', 'Subscriptions'),
    (Icons.bar_chart_rounded, 'BREAKDOWN', 'Breakdown'),
  ];

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navigationSurface,
        border: Border(top: BorderSide(color: AppColors.lightBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: textScale > 1 ? 72 * textScale : 72,
          child: Row(
            children: List.generate(_items.length, (index) {
              final (icon, keyLabel, label) = _items[index];
              final selected = selectedIndex == index;
              final color = selected ? AppColors.brightGreen : AppColors.muted;
              return Expanded(
                child: InkWell(
                  key: Key('bottomNav$keyLabel'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 42,
                          minHeight: 30,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.mint.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 21, color: color),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
