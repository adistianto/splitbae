import 'posted_bill_summary.dart';

/// Dashboard metrics for the Bills tab (v0 hero + chips), single-currency only.
class BillsInsights {
  const BillsInsights({
    required this.currencyCode,
    required this.totalMinor,
    required this.thisWeekMinor,
    required this.lastWeekMinor,
    required this.weekTrendPercent,
    required this.avgMinor,
    required this.biggestMinor,
    required this.streakDays,
    required this.billCount,
  });

  final String currencyCode;
  final int totalMinor;
  final int thisWeekMinor;
  final int lastWeekMinor;

  /// NaN when no comparison baseline.
  final double weekTrendPercent;
  final int avgMinor;
  final int biggestMinor;
  final int streakDays;
  final int billCount;
}

BillsInsights computeBillsInsights(
  List<PostedBillSummary> list, {
  String emptyStateCurrencyCode = 'IDR',
}) {
  if (list.isEmpty) {
    return BillsInsights(
      currencyCode: emptyStateCurrencyCode,
      totalMinor: 0,
      thisWeekMinor: 0,
      lastWeekMinor: 0,
      weekTrendPercent: 0,
      avgMinor: 0,
      biggestMinor: 0,
      streakDays: 0,
      billCount: 0,
    );
  }

  final cc = list.first.transaction.currencyCode;
  final same = list.where((s) => s.transaction.currencyCode == cc).toList();

  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));
  final twoWeeksAgo = now.subtract(const Duration(days: 14));

  int total = 0;
  int thisWeek = 0;
  int lastWeek = 0;
  int biggest = 0;

  for (final s in same) {
    final m = s.totalMinorPrimary;
    total += m;
    if (m > biggest) biggest = m;
    final d = DateTime.fromMillisecondsSinceEpoch(s.transaction.createdAtMs);
    if (!d.isBefore(weekAgo)) {
      thisWeek += m;
    } else if (!d.isBefore(twoWeeksAgo) && d.isBefore(weekAgo)) {
      lastWeek += m;
    }
  }

  double trend = 0;
  if (lastWeek > 0) {
    trend = ((thisWeek - lastWeek) / lastWeek) * 100;
  } else if (thisWeek > 0) {
    trend = 100;
  }

  final avg = same.isEmpty ? 0 : total ~/ same.length;

  final streak = _activityStreakDays(same.map((s) => DateTime.fromMillisecondsSinceEpoch(s.transaction.createdAtMs)).toList());

  return BillsInsights(
    currencyCode: cc,
    totalMinor: total,
    thisWeekMinor: thisWeek,
    lastWeekMinor: lastWeek,
    weekTrendPercent: trend,
    avgMinor: avg,
    biggestMinor: biggest,
    streakDays: streak,
    billCount: same.length,
  );
}

int _activityStreakDays(List<DateTime> dates) {
  if (dates.isEmpty) return 0;
  final days = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
    ..sort((a, b) => b.compareTo(a));
  if (days.isEmpty) return 0;
  final today = DateTime.now();
  final todayD = DateTime(today.year, today.month, today.day);
  final yestD = todayD.subtract(const Duration(days: 1));
  if (days.first != todayD && days.first != yestD) return 0;
  var streak = 1;
  for (var i = 1; i < days.length; i++) {
    final diff = days[i - 1].difference(days[i]).inDays;
    if (diff == 1) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}
