/// A gamification badge shown on the Insights Dashboard.
///
/// Kept free of `IconData`/`Widget` dependencies, like every other file in
/// `models/` — icon choice is passed separately to
/// `widgets/insights/achievement_badge.dart` rather than stored here,
/// since each achievement is a one-off (not a fixed category like
/// `NotificationCategory`), so there's nothing to switch on internally.
class Achievement {
  /// Creates an [Achievement].
  const Achievement({
    required this.title,
    required this.description,
    required this.isUnlocked,
    this.progressCurrent,
    this.progressTarget,
  });

  /// Badge title, e.g. "Century Club".
  final String title;

  /// What it takes to earn this badge.
  final String description;

  /// Whether this badge has been earned.
  final bool isUnlocked;

  /// Current progress toward [progressTarget], for a locked achievement
  /// that shows a progress bar (e.g. 223 of 500). Null when this
  /// achievement doesn't track incremental progress.
  final double? progressCurrent;

  /// Target value for [progressCurrent]. Null when there's no progress bar.
  final double? progressTarget;
}
