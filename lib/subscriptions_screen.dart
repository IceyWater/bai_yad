export 'features/subscriptions/presentation/subscriptions_screen.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_colors.dart';
import 'core/utils/currency_format.dart';
import 'core/utils/name_initials.dart';
import 'features/about/about_screen.dart';
import 'features/subscriptions/domain/billing_cycle.dart';
import 'features/subscriptions/domain/cost_calculator.dart';
import 'features/subscriptions/domain/renewal_calculator.dart';
import 'features/subscriptions/domain/subscription.dart';
import 'features/subscriptions/domain/subscription_category.dart';
import 'bai_yad_screens.dart';

const _ink = AppColors.ink;
const _panel = AppColors.panel;
const _panelRaised = AppColors.panelRaised;
const _mint = AppColors.mint;
const _mintBright = AppColors.brightGreen;
const _slate = AppColors.muted;
const _line = AppColors.line;

String _formatPeso(double amount) => formatPeso(amount);

extension on Subscription {
  IconData get icon => switch (category) {
    SubscriptionCategory.utilities => Icons.wifi_rounded,
    SubscriptionCategory.streaming => Icons.movie_outlined,
    SubscriptionCategory.software => Icons.draw_outlined,
    SubscriptionCategory.workTools => Icons.cloud_outlined,
    SubscriptionCategory.productivity => Icons.checklist_rounded,
  };

  Color get color => Color(colorArgb ?? AppColors.mint.toARGB32());

  String get cadence => switch (billingCycle) {
    BillingCycle.weekly => '/wk',
    BillingCycle.monthly => '/mo',
    BillingCycle.quarterly => '/qtr',
    BillingCycle.biAnnual => '/6 mo',
    BillingCycle.yearly => '/yr',
  };

  String get dateLabel =>
      '${_monthNames[anchorDate.month - 1]} ${anchorDate.day}, ${anchorDate.year}';

  String get amountLabel => _formatPeso(amount);
}

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  Timer? _launchTimer;

  @override
  void initState() {
    super.initState();
    _launchTimer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, animation, _) => ProfileSetupScreen(
            destinationBuilder: (name) => SubscriptionsScreen(name: name),
          ),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 260),
        ),
      );
    });
  }

  @override
  void dispose() {
    _launchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _ink,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 46),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _mint.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: _mint.withValues(alpha: 0.28),
                      blurRadius: 32,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'B',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                AppStrings.shortTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _slate,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 42),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  value: 1,
                  minHeight: 4,
                  backgroundColor: Color(0xFF17201E),
                  valueColor: AlwaysStoppedAnimation(_mint),
                ),
              ),
              const SizedBox(height: 13),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Vault ready. Launching...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _slate,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '100%',
                    style: TextStyle(
                      color: _mintBright,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key, this.name = 'Anonymous'});

  final String name;

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String _query = '';
  int _selectedTab = 0;
  bool _homeYearly = false;
  bool _breakdownAnnualized = false;
  bool _alertVisible = true;
  late final List<Subscription> _subscriptions = [
    Subscription(
      id: 'adobe-creative-cloud',
      name: 'Adobe Creative Cloud',
      amount: 1199,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.software,
      anchorDate: DateTime(2026, 10, 16),
      createdAt: DateTime(2026, 1, 1),
      colorArgb: 0xFF10B9A4,
    ),
    Subscription(
      id: 'pldt-home-fiber',
      name: 'PLDT Home Fiber',
      amount: 1499,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.utilities,
      anchorDate: DateTime(2026, 10, 14),
      createdAt: DateTime(2026, 1, 1),
      colorArgb: 0xFF20B8EA,
    ),
    Subscription(
      id: 'netflix-ph',
      name: 'Netflix PH (4K)',
      amount: 549,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.streaming,
      anchorDate: DateTime(2026, 10, 23),
      createdAt: DateTime(2026, 1, 1),
      colorArgb: 0xFFF04464,
    ),
    Subscription(
      id: 'spotify-premium',
      name: 'Spotify Premium',
      amount: 149,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.streaming,
      anchorDate: DateTime(2026, 10, 30),
      createdAt: DateTime(2026, 1, 1),
      colorArgb: 0xFF10B981,
    ),
    Subscription(
      id: 'google-one',
      name: 'Google One (100GB)',
      amount: 890,
      billingCycle: BillingCycle.yearly,
      category: SubscriptionCategory.workTools,
      anchorDate: DateTime(2026, 11, 20),
      createdAt: DateTime(2026, 1, 1),
      colorArgb: 0xFF20B8EA,
    ),
  ];

  static const _categories = SubscriptionCategory.values;

  List<Subscription> get _visibleSubscriptions {
    final query = _query.trim().toLowerCase();
    return _subscriptions.where((item) {
      final matchesCategory =
          _selectedCategory == null || item.category.label == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.category.label.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<CategorySpending> _categorySpending({required bool annualized}) {
    const order = [
      'Utilities & Fiber',
      'Software & Cloud',
      'Streaming & Media',
      'Work & Misc',
    ];
    const colors = {
      'Utilities & Fiber': Color(0xFF3B82F6),
      'Software & Cloud': Color(0xFF10B981),
      'Streaming & Media': Color(0xFFF59E0B),
      'Work & Misc': Color(0xFF8B5CF6),
    };
    final categoryTotals = categoryCostTotals(
      _subscriptions,
      annualized: annualized,
    );
    final totals = <String, double>{};
    for (final entry in categoryTotals.entries) {
      final category = switch (entry.key) {
        SubscriptionCategory.utilities => 'Utilities & Fiber',
        SubscriptionCategory.software => 'Software & Cloud',
        SubscriptionCategory.streaming => 'Streaming & Media',
        SubscriptionCategory.workTools ||
        SubscriptionCategory.productivity => 'Work & Misc',
      };
      totals.update(
        category,
        (total) => total + entry.value,
        ifAbsent: () => entry.value,
      );
    }
    return [
      for (final category in order)
        if ((totals[category] ?? 0) > 0)
          CategorySpending(
            name: category,
            amount: totals[category]!,
            color: colors[category]!,
          ),
    ];
  }

  double get _monthlyTotal => totalMonthlyCost(_subscriptions);

  double get _annualTotal => totalAnnualCost(_subscriptions);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddSheet() async {
    final entry = await showModalBottomSheet<Subscription>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddSubscriptionSheet(),
    );
    if (!mounted || entry == null) return;
    setState(() {
      _subscriptions.insert(0, entry);
      _selectedCategory = null;
      _query = '';
      _searchController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${entry.name} added to your subscriptions'),
        backgroundColor: _panelRaised,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteSubscription(Subscription entry) {
    setState(() => _subscriptions.remove(entry));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${entry.name} removed'),
        backgroundColor: _panelRaised,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleSubscriptions = _visibleSubscriptions;
    return Scaffold(
      backgroundColor: _ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SubscriptionsHeader(name: widget.name, onAdd: _openAddSheet),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _HomeTab(
                    subscriptions: _subscriptions,
                    renewals: upcomingRenewals(_subscriptions, limit: 4),
                    monthlyTotal: _monthlyTotal,
                    annualTotal: _annualTotal,
                    monthlyCategories: _categorySpending(annualized: false),
                    yearly: _homeYearly,
                    onYearlyChanged: (value) =>
                        setState(() => _homeYearly = value),
                    alertVisible: _alertVisible,
                    onDismissAlert: () => setState(() => _alertVisible = false),
                    onMarkUsed: () => setState(() => _alertVisible = false),
                    onDelete: _deleteSubscription,
                  ),
                  _buildSubscriptionsList(visibleSubscriptions),
                  _BreakdownTab(
                    annualized: _breakdownAnnualized,
                    categories: _categorySpending(
                      annualized: _breakdownAnnualized,
                    ),
                    total: _breakdownAnnualized ? _annualTotal : _monthlyTotal,
                    itemCount: _subscriptions.length,
                    onPeriodChanged: (value) =>
                        setState(() => _breakdownAnnualized = value),
                    onOptimize: () => setState(() => _selectedTab = 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _SubscriptionsNavigation(
        selectedIndex: _selectedTab,
        onSelected: (index) => setState(() => _selectedTab = index),
      ),
    );
  }

  Widget _buildSubscriptionsList(List<Subscription> visibleSubscriptions) =>
      CustomScrollView(
        key: const PageStorageKey('subscriptionList'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            sliver: SliverList.list(
              children: [
                _SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _CategoryChip(
                          label: 'All (${_subscriptions.length})',
                          selected: _selectedCategory == null,
                          onTap: () => setState(() => _selectedCategory = null),
                        );
                      }
                      final category = _categories[index - 1];
                      return _CategoryChip(
                        label: category.label,
                        selected: _selectedCategory == category.label,
                        onTap: () =>
                            setState(() => _selectedCategory = category.label),
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
                        onDelete: () => _deleteSubscription(entry),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}

class CategorySpending {
  const CategorySpending({
    required this.name,
    required this.amount,
    required this.color,
  });

  final String name;
  final double amount;
  final Color color;
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.subscriptions,
    required this.renewals,
    required this.monthlyTotal,
    required this.annualTotal,
    required this.monthlyCategories,
    required this.yearly,
    required this.onYearlyChanged,
    required this.alertVisible,
    required this.onDismissAlert,
    required this.onMarkUsed,
    required this.onDelete,
  });

  final List<Subscription> subscriptions;
  final List<UpcomingRenewal> renewals;
  final double monthlyTotal;
  final double annualTotal;
  final List<CategorySpending> monthlyCategories;
  final bool yearly;
  final ValueChanged<bool> onYearlyChanged;
  final bool alertVisible;
  final VoidCallback onDismissAlert;
  final VoidCallback onMarkUsed;
  final ValueChanged<Subscription> onDelete;

  @override
  Widget build(BuildContext context) {
    final total = yearly ? annualTotal : monthlyTotal;
    final cadence = yearly ? '/ yr' : '/ mo';
    final categories = monthlyCategories
        .where((item) => item.amount > 0)
        .toList();
    final categoryTotal = categories.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 25),
      children: [
        const Text(
          'TOTAL COMMITMENT',
          style: TextStyle(
            color: _slate,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _formatPeso(total.roundToDouble()),
              key: const Key('homeTotalAmount'),
              style: const TextStyle(
                fontSize: 30,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(width: 7),
            Text(cadence, style: const TextStyle(fontSize: 12, color: _slate)),
          ],
        ),
        const SizedBox(height: 10),
        _PeriodPill(
          firstLabel: 'Monthly',
          secondLabel: 'Yearly (${_formatPeso(annualTotal.roundToDouble())})',
          secondSelected: yearly,
          onFirst: () => onYearlyChanged(false),
          onSecond: () => onYearlyChanged(true),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              for (final category in categories)
                Expanded(
                  flex: math.max(
                    1,
                    (category.amount /
                            (categoryTotal == 0 ? 1 : categoryTotal) *
                            100)
                        .round(),
                  ),
                  child: ColoredBox(
                    color: category.color,
                    child: const SizedBox(height: 4),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 10,
          runSpacing: 7,
          children: [
            for (final category in categories)
              _CategoryLegend(
                category: category,
                percent: categoryTotal == 0
                    ? 0
                    : category.amount / categoryTotal * 100,
              ),
          ],
        ),
        const SizedBox(height: 19),
        if (alertVisible) ...[
          _UnusedSubscriptionAlert(
            onMarkUsed: onMarkUsed,
            onDismiss: onDismissAlert,
          ),
          const SizedBox(height: 18),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'UPCOMING RENEWALS',
              style: TextStyle(
                color: _slate,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${subscriptions.length} Active',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 3),
        for (final renewal in renewals)
          _HomeRenewalRow(
            renewal: renewal,
            onDelete: () => onDelete(renewal.subscription),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 13),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 13, color: _mintBright),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Your financial data stays on this device',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _slate, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({required this.category, required this.percent});
  final CategorySpending category;
  final double percent;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: category.color,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        '${_shortCategory(category.name)} ${percent.round()}%',
        style: const TextStyle(color: Color(0xFFB8C0CC), fontSize: 9),
      ),
    ],
  );
}

String _shortCategory(String category) => switch (category) {
  'Utilities & Fiber' => 'Utilities',
  'Software & Cloud' => 'Software',
  'Streaming & Media' => 'Media',
  _ => 'Work',
};

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({
    required this.firstLabel,
    required this.secondLabel,
    required this.secondSelected,
    required this.onFirst,
    required this.onSecond,
  });

  final String firstLabel;
  final String secondLabel;
  final bool secondSelected;
  final VoidCallback onFirst;
  final VoidCallback onSecond;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFF131720),
      border: Border.all(color: const Color(0xFF262B35)),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PeriodPillButton(
          key: const Key('monthlyPeriodButton'),
          label: firstLabel,
          selected: !secondSelected,
          onTap: onFirst,
        ),
        _PeriodPillButton(
          key: const Key('annualPeriodButton'),
          label: secondLabel,
          selected: secondSelected,
          onTap: onSecond,
        ),
      ],
    ),
  );
}

class _PeriodPillButton extends StatelessWidget {
  const _PeriodPillButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: selected ? Colors.white : _slate,
      backgroundColor: selected ? const Color(0xFF2A2D33) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const StadiumBorder(),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
  );
}

class _UnusedSubscriptionAlert extends StatelessWidget {
  const _UnusedSubscriptionAlert({
    required this.onMarkUsed,
    required this.onDismiss,
  });

  final VoidCallback onMarkUsed;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF211B0D),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFF493615)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFF573C0A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 15,
                color: Color(0xFFFBBF24),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'UNUSED FLAG DETECTED',
                style: TextStyle(
                  color: Color(0xFFFCD34D),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const Text(
              'Savings Alert',
              style: TextStyle(color: Color(0xFFFDE68A), fontSize: 8),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Adobe CC hasn't been logged into in 28 days. Potential save: ₱1,199/mo.",
          style: TextStyle(color: Color(0xFFFFF5DC), fontSize: 10, height: 1.4),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 4,
          children: [
            TextButton(
              onPressed: onMarkUsed,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFE8A3),
                backgroundColor: const Color(0xFF493615),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Mark as Used', style: TextStyle(fontSize: 9)),
            ),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFCD34D),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Dismiss', style: TextStyle(fontSize: 9)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _HomeRenewalRow extends StatelessWidget {
  const _HomeRenewalRow({required this.renewal, required this.onDelete});
  final UpcomingRenewal renewal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final entry = renewal.subscription;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final renewalDate = DateTime(
      renewal.date.year,
      renewal.date.month,
      renewal.date.day,
    );
    final days = renewalDate.difference(today).inDays;
    final due = days < 0
        ? 'Overdue'
        : days == 0
        ? 'Today'
        : 'In $days days';
    final dueColor = days < 0 ? const Color(0xFFFB7185) : _mintBright;
    final dueBackground = days < 0
        ? const Color(0xFFFB7185).withValues(alpha: 0.12)
        : _mint.withValues(alpha: 0.10);
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: entry.color.withValues(alpha: 0.25)),
            ),
            child: Icon(entry.icon, size: 18, color: entry.color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE7EAF0),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.amountLabel} ${entry.billingCycle.label}',
                  style: const TextStyle(color: _slate, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: dueBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  due,
                  style: TextStyle(
                    color: dueColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                entry.amountLabel,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Remove ${entry.name}',
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              size: 15,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownTab extends StatelessWidget {
  const _BreakdownTab({
    required this.annualized,
    required this.categories,
    required this.total,
    required this.itemCount,
    required this.onPeriodChanged,
    required this.onOptimize,
  });

  final bool annualized;
  final List<CategorySpending> categories;
  final double total;
  final int itemCount;
  final ValueChanged<bool> onPeriodChanged;
  final VoidCallback onOptimize;

  @override
  Widget build(BuildContext context) {
    final cadence = annualized ? '/yr' : '/mo';
    final roundedTotal = total.round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 25),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CATEGORY BREAKDOWN',
                    style: TextStyle(
                      color: _slate,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Normalized cost distribution\nacross categories',
                    style: TextStyle(
                      color: Color(0xFF748093),
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            _PeriodPill(
              firstLabel: 'Monthly',
              secondLabel: 'Annualized',
              secondSelected: annualized,
              onFirst: () => onPeriodChanged(false),
              onSecond: () => onPeriodChanged(true),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 186,
          child: Center(
            child: SizedBox(
              width: 148,
              height: 148,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(148),
                    painter: _DonutPainter(categories: categories),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatPeso(roundedTotal.toDouble()),
                        key: const Key('breakdownTotalAmount'),
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$itemCount active items',
                        style: const TextStyle(color: _slate, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _panel,
            border: Border.all(color: const Color(0xFF1D2431)),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Column(
            children: [
              for (var index = 0; index < categories.length; index++)
                _BreakdownCategoryRow(
                  category: categories[index],
                  percent: total <= 0
                      ? 0
                      : categories[index].amount / total * 100,
                  cadence: cadence,
                  showDivider: index != categories.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _SpendingInsights(annualized: annualized, onOptimize: onOptimize),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.categories});
  final List<CategorySpending> categories;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const strokeWidth = 16.0;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final total = categories.fold<double>(0, (sum, item) => sum + item.amount);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final category in categories) {
      final sweep = category.amount / total * math.pi * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..color = category.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.categories != categories;
}

class _BreakdownCategoryRow extends StatelessWidget {
  const _BreakdownCategoryRow({
    required this.category,
    required this.percent,
    required this.cadence,
    required this.showDivider,
  });

  final CategorySpending category;
  final double percent;
  final String cadence;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 45),
    decoration: BoxDecoration(
      border: showDivider
          ? const Border(bottom: BorderSide(color: Color(0x17FFFFFF)))
          : null,
    ),
    child: Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: category.color,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE0E5ED),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${percent.round()}%',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _slate, fontSize: 9),
          ),
        ),
        Text(
          _formatPeso(category.amount.roundToDouble()),
          style: const TextStyle(
            color: Color(0xFFE7EAF0),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(cadence, style: const TextStyle(color: _slate, fontSize: 9)),
      ],
    ),
  );
}

class _SpendingInsights extends StatelessWidget {
  const _SpendingInsights({required this.annualized, required this.onOptimize});

  final bool annualized;
  final VoidCallback onOptimize;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFF111821),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF202B35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, size: 15, color: _mintBright),
            SizedBox(width: 7),
            Text(
              "Miguel's Spending Insights",
              style: TextStyle(
                color: Color(0xFFE1E7ED),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _InsightLine(
          color: _mintBright,
          text: 'Software & freelance tools make up 54% of your monthly recurring budget.',
        ),
        const SizedBox(height: 6),
        const _InsightLine(
          color: Color(0xFFFBBF24),
          text: 'Normalizing yearly plans saves you ₱1,400/yr compared to paying standard monthly rates.',
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            const Icon(Icons.lock_outline, size: 12, color: Color(0xFF5C987E)),
            const SizedBox(width: 5),
            const Expanded(
              child: Text(
                'Calculated completely on-device',
                style: TextStyle(color: _slate, fontSize: 9),
              ),
            ),
            TextButton(
              onPressed: onOptimize,
              style: TextButton.styleFrom(
                foregroundColor: _mintBright,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Optimize',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: _mintBright),
          ],
        ),
      ],
    ),
  );
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Icon(Icons.circle, size: 5, color: color),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: _slate, fontSize: 9, height: 1.4),
        ),
      ),
    ],
  );
}

class _SubscriptionsHeader extends StatelessWidget {
  const _SubscriptionsHeader({required this.name, required this.onAdd});

  final String name;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
    ),
    child: Row(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: _mint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _mint.withValues(alpha: 0.3)),
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            size: 18,
            color: _mintBright,
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
          icon: const Icon(Icons.info_outline_rounded, color: _mintBright),
        ),
        OutlinedButton.icon(
          key: const Key('addSubscriptionButton'),
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 17),
          label: const Text('Add'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _mintBright,
            side: BorderSide(color: _mint.withValues(alpha: 0.35)),
            backgroundColor: _mint.withValues(alpha: 0.08),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        const SizedBox(width: 4),
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF202633),
          child: Text(
            nameInitials(name),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC8CDD6),
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
    style: const TextStyle(fontSize: 14, color: Color(0xFFDDE3ED)),
    decoration: InputDecoration(
      hintText: 'Search subscriptions...',
      hintStyle: const TextStyle(color: Color(0xFF7C8494), fontSize: 14),
      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF687286)),
      filled: true,
      fillColor: const Color(0xFF101625),
      contentPadding: const EdgeInsets.symmetric(vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Color(0xFF252D3E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Color(0xFF252D3E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: _mint, width: 1.3),
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
      color: selected ? _ink : const Color(0xFFC0C7D2),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    side: BorderSide(color: selected ? _mint : const Color(0xFF2A2D33)),
    backgroundColor: const Color(0xFF11141A),
    selectedColor: _mint,
    shape: const StadiumBorder(),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    super.key,
    required this.entry,
    required this.onDelete,
  });
  final Subscription entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isUnused = entry.name == 'Adobe Creative Cloud';
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: const Color(0xFF1D2431)),
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
                        color: Color(0xFFE7EAF0),
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
                          TextSpan(text: 'Next: ${entry.dateLabel}'),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _slate,
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
                      color: Color(0xFFE7EAF0),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    entry.cadence,
                    style: const TextStyle(color: _slate, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Divider(height: 1, color: Color(0xFF1B202A)),
          ),
          SizedBox(
            height: 42,
            child: Row(
              children: [
                if (isUnused)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A2C13),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF59441B)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: Color(0xFFFBBF24),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Unused (28d)',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove ${entry.name}',
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 17,
                    color: Color(0xFF64748B),
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
        Icon(Icons.search_off_rounded, size: 30, color: Color(0xFF64748B)),
        SizedBox(height: 11),
        Text(
          'No subscriptions found',
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Try another search or category.',
          style: TextStyle(color: _slate, fontSize: 12),
        ),
      ],
    ),
  );
}

class _SubscriptionsNavigation extends StatelessWidget {
  const _SubscriptionsNavigation({
    required this.selectedIndex,
    required this.onSelected,
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
      color: Color(0xF20B0D10),
      border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: List.generate(_items.length, (index) {
            final (icon, label) = _items[index];
            final selected = selectedIndex == index;
            final color = selected ? _mintBright : const Color(0xFF64748B);
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

class _AddSubscriptionSheet extends StatefulWidget {
  const _AddSubscriptionSheet();

  @override
  State<_AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<_AddSubscriptionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  BillingCycle _cycle = BillingCycle.monthly;
  SubscriptionCategory _category = SubscriptionCategory.streaming;
  DateTime _renewalDate = DateTime.now();
  Color _selectedColor = _mint;

  static const _cycles = BillingCycle.values;
  static const _categories = SubscriptionCategory.values;
  static const _colors = [
    Color(0xFFEF4444),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
  ];

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
            primary: _mint,
            onPrimary: _ink,
            surface: _panelRaised,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _renewalDate = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final entry = Subscription(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      billingCycle: _cycle,
      category: _category,
      anchorDate: _renewalDate,
      createdAt: DateTime.now(),
      colorArgb: _selectedColor.toARGB32(),
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
          color: Color(0xFF12161D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF525B6A),
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
                        const Text(
                          'Add Subscription',
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
                              color: _mintBright,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Manual entry  •  Stored on device',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _slate.withValues(alpha: 0.9),
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
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      foregroundColor: const Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _line),
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
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a service name'
                          : null,
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
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                validator: (value) {
                                  final amount = double.tryParse(value ?? '');
                                  return amount == null || amount <= 0
                                      ? 'Enter a valid cost'
                                      : null;
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
                                dropdownColor: _panelRaised,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                icon: const Icon(
                                  Icons.expand_more,
                                  color: _slate,
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
                                dropdownColor: _panelRaised,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                icon: const Icon(
                                  Icons.expand_more,
                                  color: _slate,
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
                                    '${_monthNames[_renewalDate.month - 1]} ${_renewalDate.day}, ${_renewalDate.year}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE2E8F0),
                                    side: const BorderSide(
                                      color: Color(0xFF2B3342),
                                    ),
                                    backgroundColor: const Color(0xFF0A0E18),
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
                                    ? Border.all(color: Colors.white, width: 2)
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
                                      color: _ink,
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
                        label: const Text('Save Subscription'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _mint,
                          foregroundColor: _ink,
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
      color: Color(0xFFC6CCD7),
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
  );
}

InputDecoration _inputDecoration({String? hint, String? prefix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF687286), fontSize: 12),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: _slate, fontWeight: FontWeight.w700),
      filled: true,
      fillColor: const Color(0xFF0A0E18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2B3342)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2B3342)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _mint, width: 1.3),
      ),
      errorStyle: const TextStyle(fontSize: 10),
    );
