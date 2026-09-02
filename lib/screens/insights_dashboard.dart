import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/constants.dart';
import '../widgets/widgets.dart';

/// Insights & Analytics Dashboard — spending summary, a retrospective
/// what-if comparison, a monthly savings trend, achievements, and smart
/// tips.
///
/// UI-mockup implementation: every figure below is dummy data, but
/// deliberately anchored to the numbers already used in the team's own
/// pitch (the "~RM230 saved per month" example from the problem-statement
/// slides) rather than arbitrary placeholders — the monthly chart's final
/// bar matches the "What if" card's savings figure exactly, so the two
/// tell one consistent story instead of two unrelated ones.
class InsightsDashboardPage extends StatelessWidget {
  /// Creates an [InsightsDashboardPage].
  const InsightsDashboardPage({super.key});

  // --- Dummy data -----------------------------------------------------

  static const double _actualSpentRM = 145.50;
  static const double _transitSpentRM = 82.00;
  static const double _drivingSpentRM = 63.50;
  static const double _alwaysDrivingSpentRM = 368.00;

  static List<MonthlySavings> _dummyMonthlySavings() {
    final now = DateTime.now();
    const amounts = [165.0, 178.0, 195.0, 188.0, 210.0, 222.50];
    return [
      for (var i = 0; i < amounts.length; i++)
        MonthlySavings(
          month: DateTime(now.year, now.month - (amounts.length - 1 - i)),
          savedRM: amounts[i],
        ),
    ];
  }

  static const _achievements = [
    Achievement(
      title: 'First Saver',
      description: 'Save on your first trip',
      isUnlocked: true,
    ),
    Achievement(
      title: 'Century Club',
      description: 'Save RM100 total',
      isUnlocked: true,
    ),
    Achievement(
      title: 'Green Commuter',
      description: 'Take transit 10 times',
      isUnlocked: true,
    ),
    Achievement(
      title: 'Big Saver',
      description: 'Save RM500 total',
      isUnlocked: false,
      progressCurrent: 222.50,
      progressTarget: 500,
    ),
  ];

  static const _achievementIcons = [
    Icons.emoji_events_rounded,
    Icons.workspace_premium_rounded,
    Icons.eco_rounded,
    Icons.military_tech_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final monthlySavings = _dummyMonthlySavings();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final hPad = isWide ? 40.0 : 20.0;
            const maxW = 480.0;

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      const SpendingCard(
                        totalSpentRM: _actualSpentRM,
                        transitSpentRM: _transitSpentRM,
                        drivingSpentRM: _drivingSpentRM,
                      ),
                      const SizedBox(height: 16),
                      const WhatIfCard(
                        actualSpentRM: _actualSpentRM,
                        alwaysDrivingSpentRM: _alwaysDrivingSpentRM,
                      ),
                      const SizedBox(height: 16),
                      MonthlySavingsChart(points: monthlySavings),
                      const SizedBox(height: 16),
                      const _SectionLabel('Achievements'),
                      const SizedBox(height: 10),
                      _buildAchievementsRow(),
                      const SizedBox(height: 16),
                      const _SectionLabel('Smart Tips'),
                      const SizedBox(height: 10),
                      const SmartTipCard(
                        icon: Icons.local_gas_station_rounded,
                        text: 'Fuel prices are up this week — transit '
                            'saves you even more than usual right now.',
                      ),
                      const SizedBox(height: 8),
                      const SmartTipCard(
                        icon: Icons.cloud_outlined,
                        text: 'Rain is forecast later this week — transit '
                            'avoids the traffic delays that come with it.',
                      ),
                      const SizedBox(height: 8),
                      const SmartTipCard(
                        icon: Icons.flag_rounded,
                        text: "You're RM277.50 away from unlocking "
                            "'Big Saver' — keep it up!",
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Insights & Analytics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsRow() {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _achievements.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) => AchievementBadge(
          achievement: _achievements[index],
          icon: _achievementIcons[index],
        ),
      ),
    );
  }
}

/// Small uppercase section label, matching the one used on Favorites.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
      ),
    );
  }
}
