import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/cost_calculator.dart';
import '../domain/renewal_calculator.dart';
import '../domain/subscription.dart';
import '../domain/subscription_category.dart';
import '../application/subscription_providers.dart';
import '../data/shared_preferences_subscription_repository.dart';
import '../../onboarding/profile_setup_screen.dart';
import 'add_subscription_form.dart';
import 'subscriptions_list.dart';
import 'breakdown_tab.dart';
import 'home_tab.dart';
import 'subscription_tabs.dart';

class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({super.key});

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends ConsumerState<LaunchScreen> {
  Timer? _launchTimer;
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    _launchTimer = Timer(const Duration(milliseconds: 1100), _openDestination);
  }

  Future<void> _openDestination() async {
    try {
      final savedName = await ref.read(profileControllerProvider.future);
      if (!mounted) return;
      final destination = savedName == null
          ? ProfileSetupScreen(
              destinationBuilder: (name) => SubscriptionsScreen(name: name),
            )
          : SubscriptionsScreen(name: savedName);
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, animation, _) => destination,
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 260),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _startupError = error);
    }
  }

  @override
  void dispose() {
    _launchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.ink,
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
                  color: AppColors.mint.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mint.withValues(alpha: 0.28),
                      blurRadius: 32,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'B',
                    style: TextStyle(
                      color: AppColors.ink,
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
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 42),
              if (_startupError == null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 1,
                    minHeight: 4,
                    backgroundColor: AppColors.progressTrack,
                    valueColor: AlwaysStoppedAnimation(AppColors.mint),
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
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '100%',
                      style: TextStyle(
                        color: AppColors.brightGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  'Your saved profile could not be loaded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _startupError = null);
                    ref.invalidate(profileControllerProvider);
                    _openDestination();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key, this.name = 'Anonymous'});

  final String name;

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String _query = '';
  int _selectedTab = 0;
  bool _homeYearly = false;
  bool _breakdownAnnualized = false;
  bool _alertVisible = true;

  List<Subscription> _visibleSubscriptions(List<Subscription> subscriptions) {
    final query = _query.trim().toLowerCase();
    return subscriptions.where((item) {
      final matchesCategory =
          _selectedCategory == null || item.category.label == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.category.label.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<CategorySpending> _categorySpending(
    List<Subscription> subscriptions, {
    required bool annualized,
  }) {
    const order = [
      'Utilities & Fiber',
      'Software & Cloud',
      'Streaming & Media',
      'Work & Misc',
    ];
    const colors = {
      'Utilities & Fiber': AppColors.categoryUtilities,
      'Software & Cloud': AppColors.mint,
      'Streaming & Media': AppColors.categoryStreaming,
      'Work & Misc': AppColors.categoryWork,
    };
    final categoryTotals = categoryCostTotals(
      subscriptions,
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
      builder: (_) => const AddSubscriptionSheet(),
    );
    if (!mounted || entry == null) return;
    try {
      await ref.read(subscriptionControllerProvider.notifier).add(entry);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save subscription: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _selectedCategory = null;
      _query = '';
      _searchController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${entry.name} added to your subscriptions'),
        backgroundColor: AppColors.panelRaised,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteSubscription(Subscription entry) async {
    try {
      await ref.read(subscriptionControllerProvider.notifier).remove(entry);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove subscription: $error')),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${entry.name} removed'),
        backgroundColor: AppColors.panelRaised,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsState = ref.watch(subscriptionControllerProvider);
    return subscriptionsState.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(child: CircularProgressIndicator(color: AppColors.mint)),
      ),
      error: (error, _) => _buildLoadError(error),
      data: (subscriptions) => _buildLoadedScreen(context, subscriptions),
    );
  }

  Widget _buildLoadError(Object error) {
    final isCorruptData = error is CorruptSubscriptionDataException;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.brightGreen, size: 36),
              const SizedBox(height: 14),
              Text(
                isCorruptData
                    ? 'Saved subscription data could not be read.'
                    : 'Subscriptions could not be loaded.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCorruptData
                    ? 'You can reset the unreadable local data. This only clears subscriptions.'
                    : error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isCorruptData
                    ? () => _clearCorruptSubscriptions()
                    : () => ref
                          .read(subscriptionControllerProvider.notifier)
                          .retry(),
                child: Text(
                  isCorruptData ? 'Reset subscription data' : 'Retry',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearCorruptSubscriptions() async {
    try {
      await ref
          .read(subscriptionControllerProvider.notifier)
          .clearCorruptData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reset saved data: $error')),
      );
    }
  }

  Widget _buildLoadedScreen(
    BuildContext context,
    List<Subscription> subscriptions,
  ) {
    final visibleSubscriptions = _visibleSubscriptions(subscriptions);
    final monthlyTotal = totalMonthlyCost(subscriptions);
    final annualTotal = totalAnnualCost(subscriptions);
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SubscriptionsHeader(name: widget.name, onAdd: _openAddSheet),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  HomeTab(
                    subscriptions: subscriptions,
                    renewals: upcomingRenewals(subscriptions, limit: 4),
                    monthlyTotal: monthlyTotal,
                    annualTotal: annualTotal,
                    monthlyCategories: _categorySpending(
                      subscriptions,
                      annualized: false,
                    ),
                    yearly: _homeYearly,
                    onYearlyChanged: (value) =>
                        setState(() => _homeYearly = value),
                    alertVisible: _alertVisible,
                    onDismissAlert: () => setState(() => _alertVisible = false),
                    onMarkUsed: () => setState(() => _alertVisible = false),
                    onDelete: _deleteSubscription,
                  ),
                  SubscriptionsList(
                    controller: _searchController,
                    selectedCategory: _selectedCategory,
                    visibleSubscriptions: visibleSubscriptions,
                    subscriptions: subscriptions,
                    onQueryChanged: (value) => setState(() => _query = value),
                    onCategoryChanged: (category) =>
                        setState(() => _selectedCategory = category),
                    onDelete: _deleteSubscription,
                  ),
                  BreakdownTab(
                    annualized: _breakdownAnnualized,
                    categories: _categorySpending(
                      subscriptions,
                      annualized: _breakdownAnnualized,
                    ),
                    total: _breakdownAnnualized ? annualTotal : monthlyTotal,
                    itemCount: subscriptions.length,
                    onPeriodChanged: (value) =>
                        setState(() => _breakdownAnnualized = value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SubscriptionsNavigation(
        selectedIndex: _selectedTab,
        onSelected: (index) => setState(() => _selectedTab = index),
      ),
    );
  }


}