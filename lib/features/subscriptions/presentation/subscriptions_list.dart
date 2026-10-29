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

  static const _categories = SubscriptionCategory.values;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const PageStorageKey('subscriptionList'),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        sliver: SliverList.list(
          children: [
            _SearchField(controller: controller, onChanged: onQueryChanged),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'SORT BY',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                DropdownButton<SubscriptionSort>(
                  key: const Key('subscriptionSortDropdown'),
                  value: sort,
                  underline: const SizedBox.shrink(),
                  dropdownColor: AppColors.panelRaised,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 12,
                  ),
                  items: SubscriptionSort.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onSortChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
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
            const SizedBox(height: 19),
            if (visibleSubscriptions.isEmpty)
              const _EmptySubscriptions()
            else
              ...visibleSubscriptions.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
    super.key,
  });

  final String name;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.subtleBorder)),
    ),
    child: Row(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: AppColors.mint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.mint.withValues(alpha: 0.3)),
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            size: 18,
            color: AppColors.brightGreen,
          ),
        ),
        const SizedBox(width: 9),
        const Text(
          AppStrings.appName,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'About',
          visualDensity: const VisualDensity(horizontal: -2, vertical: 0),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 48),
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen())),
          icon: const Icon(
            Icons.info_outline_rounded,
            color: AppColors.brightGreen,
          ),
        ),
        OutlinedButton.icon(
          key: const Key('addSubscriptionButton'),
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 17),
          label: const Text('Add'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brightGreen,
            side: BorderSide(color: AppColors.mint.withValues(alpha: 0.35)),
            backgroundColor: AppColors.mint.withValues(alpha: 0.08),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        const SizedBox(width: 4),
        CircleAvatar(
          radius: 16,
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
    ),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    key: const Key('subscriptionSearchField'),
    controller: controller,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 14, color: AppColors.inputText),
    decoration: InputDecoration(
      hintText: 'Search subscriptions...',
      hintStyle: const TextStyle(color: AppColors.inputHint, fontSize: 14),
      prefixIcon: const Icon(
        Icons.search,
        size: 20,
        color: AppColors.inputPlaceholder,
      ),
      filled: true,
      fillColor: AppColors.searchSurface,
      contentPadding: const EdgeInsets.symmetric(vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppColors.searchBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppColors.searchBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: AppColors.mint, width: 1.3),
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
      fontSize: 12,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      color: selected ? AppColors.ink : AppColors.chipText,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    side: BorderSide(
      color: selected ? AppColors.mint : AppColors.selectedControl,
    ),
    backgroundColor: AppColors.chipSurface,
    selectedColor: AppColors.mint,
    shape: const StadiumBorder(),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                width: 42,
                height: 42,
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: entry.category.label),
                          const TextSpan(text: '  •  '),
                          TextSpan(
                            text:
                                'Next: ${formatSubscriptionDate(nextDate)} · $dueLabel',
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.amountLabel,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    entry.cadence,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
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
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
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
                  onPressed: onToggleRarelyUsed,
                  visualDensity: VisualDensity.compact,
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
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
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
    (Icons.grid_view_rounded, 'HOME'),
    (Icons.credit_card_rounded, 'SUBSCRIPTIONS'),
    (Icons.bar_chart_rounded, 'BREAKDOWN'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppColors.navigationSurface,
      border: Border(top: BorderSide(color: AppColors.lightBorder)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: List.generate(_items.length, (index) {
            final (icon, label) = _items[index];
            final selected = selectedIndex == index;
            final color = selected
                ? AppColors.brightGreen
                : AppColors.textMuted;
            return Expanded(
              child: InkWell(
                key: Key('bottomNav$label'),
                onTap: () => onSelected(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: selected
                            ? FontWeight.w700
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
