import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

/// **Dynamic color (Material You)** drives [ColorScheme] surfaces, primary, nav,
/// FAB chrome, etc.
///
/// **This extension** holds semantic colors. **Critical** roles (pay vs receive,
/// destructive/error) stay **fixed** for WCAG and predictable meaning.
///
/// **Non-critical** accents (insight chips, category icon tints) are built from
/// fixed baselines then **partially harmonized** toward different [ColorScheme]
/// roles ([primary], [secondary], [tertiary], [error]) via
/// [Color.harmonizeWith] + a light [Color.lerp] so wallpaper hues blend in while
/// categories stay visually distinct (M3 custom-color harmonization pattern).
@immutable
class SplitBaeSemanticColors extends ThemeExtension<SplitBaeSemanticColors> {
  const SplitBaeSemanticColors({
    required this.balancePay,
    required this.onBalancePay,
    required this.balancePayContainer,
    required this.onBalancePayContainer,
    required this.balanceReceive,
    required this.onBalanceReceive,
    required this.balanceReceiveContainer,
    required this.onBalanceReceiveContainer,
    required this.destructive,
    required this.onDestructive,
    required this.destructiveContainer,
    required this.onDestructiveContainer,
    required this.insightTrendWorseBg,
    required this.insightTrendWorseFg,
    required this.insightTrendBetterBg,
    required this.insightTrendBetterFg,
    required this.insightTopBg,
    required this.insightTopFg,
    required this.insightStreakBg,
    required this.insightStreakFg,
    required this.categoryFoodBg,
    required this.categoryFoodFg,
    required this.categoryTransportBg,
    required this.categoryTransportFg,
    required this.categoryAccommodationBg,
    required this.categoryAccommodationFg,
    required this.categorySettlementBg,
    required this.categorySettlementFg,
    required this.categoryOtherBg,
    required this.categoryOtherFg,
  });

  /// “Pays” / outgoing — fixed red family (not wallpaper primary).
  final Color balancePay;
  final Color onBalancePay;
  final Color balancePayContainer;
  final Color onBalancePayContainer;

  /// “Receives” / incoming — fixed green family (not wallpaper tertiary).
  final Color balanceReceive;
  final Color onBalanceReceive;
  final Color balanceReceiveContainer;
  final Color onBalanceReceiveContainer;

  /// Delete, destructive confirm, form errors — also merged into [ColorScheme.error].
  final Color destructive;
  final Color onDestructive;
  final Color destructiveContainer;
  final Color onDestructiveContainer;

  final Color insightTrendWorseBg;
  final Color insightTrendWorseFg;
  final Color insightTrendBetterBg;
  final Color insightTrendBetterFg;
  final Color insightTopBg;
  final Color insightTopFg;
  final Color insightStreakBg;
  final Color insightStreakFg;

  final Color categoryFoodBg;
  final Color categoryFoodFg;
  final Color categoryTransportBg;
  final Color categoryTransportFg;
  final Color categoryAccommodationBg;
  final Color categoryAccommodationFg;
  final Color categorySettlementBg;
  final Color categorySettlementFg;
  final Color categoryOtherBg;
  final Color categoryOtherFg;

  static const SplitBaeSemanticColors light = SplitBaeSemanticColors(
    balancePay: Color(0xFFB3261E),
    onBalancePay: Color(0xFFFFFFFF),
    balancePayContainer: Color(0xFFF9DEDC),
    onBalancePayContainer: Color(0xFF410E0B),
    balanceReceive: Color(0xFF146C2E),
    onBalanceReceive: Color(0xFFFFFFFF),
    balanceReceiveContainer: Color(0xFFE8F5E9),
    onBalanceReceiveContainer: Color(0xFF1B5E20),
    destructive: Color(0xFFB3261E),
    onDestructive: Color(0xFFFFFFFF),
    destructiveContainer: Color(0xFFF9DEDC),
    onDestructiveContainer: Color(0xFF410E0B),
    insightTrendWorseBg: Color(0xFFFFE4E6),
    insightTrendWorseFg: Color(0xFFBE123C),
    insightTrendBetterBg: Color(0xFFD1FAE5),
    insightTrendBetterFg: Color(0xFF059669),
    insightTopBg: Color(0xFFFEF3C7),
    insightTopFg: Color(0xFF92400E),
    insightStreakBg: Color(0xFFFFEDD5),
    insightStreakFg: Color(0xFF9A3412),
    categoryFoodBg: Color(0xFFFFF7ED),
    categoryFoodFg: Color(0xFFC2410C),
    categoryTransportBg: Color(0xFFEFF6FF),
    categoryTransportFg: Color(0xFF1D4ED8),
    categoryAccommodationBg: Color(0xFFF5F3FF),
    categoryAccommodationFg: Color(0xFF6D28D9),
    categorySettlementBg: Color(0xFFF1F5F9),
    categorySettlementFg: Color(0xFF475569),
    categoryOtherBg: Color(0xFFF0FDFA),
    categoryOtherFg: Color(0xFF0F766E),
  );

  static const SplitBaeSemanticColors dark = SplitBaeSemanticColors(
    balancePay: Color(0xFFF2B8B5),
    onBalancePay: Color(0xFF601410),
    balancePayContainer: Color(0xFF8C1D18),
    onBalancePayContainer: Color(0xFFF9DEDC),
    balanceReceive: Color(0xFF9BD69A),
    onBalanceReceive: Color(0xFF0D1F12),
    balanceReceiveContainer: Color(0xFF1B5E20),
    onBalanceReceiveContainer: Color(0xFFE8F5E9),
    destructive: Color(0xFFF2B8B5),
    onDestructive: Color(0xFF601410),
    destructiveContainer: Color(0xFF8C1D18),
    onDestructiveContainer: Color(0xFFF9DEDC),
    insightTrendWorseBg: Color(0xFF4C0519),
    insightTrendWorseFg: Color(0xFFFDA4AF),
    insightTrendBetterBg: Color(0xFF052E16),
    insightTrendBetterFg: Color(0xFF6EE7B7),
    insightTopBg: Color(0xFF422006),
    insightTopFg: Color(0xFFFCD34D),
    insightStreakBg: Color(0xFF431407),
    insightStreakFg: Color(0xFFFDBA74),
    categoryFoodBg: Color(0xFF422006),
    categoryFoodFg: Color(0xFFFDBA74),
    categoryTransportBg: Color(0xFF172554),
    categoryTransportFg: Color(0xFF93C5FD),
    categoryAccommodationBg: Color(0xFF3B0764),
    categoryAccommodationFg: Color(0xFFD8B4FE),
    categorySettlementBg: Color(0xFF1E293B),
    categorySettlementFg: Color(0xFFCBD5E1),
    categoryOtherBg: Color(0xFF134E4A),
    categoryOtherFg: Color(0xFF99F6E4),
  );

  /// Blends [base] accents toward the live [scheme] so Material You wallpapers
  /// feel cohesive; **does not** alter pay/receive/destructive (see class doc).
  factory SplitBaeSemanticColors.harmonizedWithScheme({
    required SplitBaeSemanticColors base,
    required ColorScheme scheme,
  }) {
    Color blend(Color from, Color toward, double amount) {
      final shifted = from.harmonizeWith(toward);
      return Color.lerp(from, shifted, amount)!;
    }

    return SplitBaeSemanticColors(
      balancePay: base.balancePay,
      onBalancePay: base.onBalancePay,
      balancePayContainer: base.balancePayContainer,
      onBalancePayContainer: base.onBalancePayContainer,
      balanceReceive: base.balanceReceive,
      onBalanceReceive: base.onBalanceReceive,
      balanceReceiveContainer: base.balanceReceiveContainer,
      onBalanceReceiveContainer: base.onBalanceReceiveContainer,
      destructive: base.destructive,
      onDestructive: base.onDestructive,
      destructiveContainer: base.destructiveContainer,
      onDestructiveContainer: base.onDestructiveContainer,
      insightTrendWorseBg: blend(base.insightTrendWorseBg, scheme.error, 0.48),
      insightTrendWorseFg: blend(base.insightTrendWorseFg, scheme.error, 0.36),
      insightTrendBetterBg:
          blend(base.insightTrendBetterBg, scheme.tertiary, 0.46),
      insightTrendBetterFg:
          blend(base.insightTrendBetterFg, scheme.tertiary, 0.34),
      insightTopBg: blend(base.insightTopBg, scheme.secondary, 0.44),
      insightTopFg: blend(base.insightTopFg, scheme.secondary, 0.34),
      insightStreakBg: blend(base.insightStreakBg, scheme.tertiary, 0.44),
      insightStreakFg: blend(base.insightStreakFg, scheme.tertiary, 0.34),
      categoryFoodBg: blend(base.categoryFoodBg, scheme.tertiary, 0.44),
      categoryFoodFg: blend(base.categoryFoodFg, scheme.tertiary, 0.38),
      categoryTransportBg: blend(base.categoryTransportBg, scheme.primary, 0.44),
      categoryTransportFg:
          blend(base.categoryTransportFg, scheme.primary, 0.38),
      categoryAccommodationBg:
          blend(base.categoryAccommodationBg, scheme.secondary, 0.44),
      categoryAccommodationFg:
          blend(base.categoryAccommodationFg, scheme.secondary, 0.38),
      categorySettlementBg:
          blend(base.categorySettlementBg, scheme.primary, 0.22),
      categorySettlementFg: blend(
        base.categorySettlementFg,
        scheme.onSurfaceVariant,
        0.26,
      ),
      categoryOtherBg: blend(base.categoryOtherBg, scheme.primary, 0.4),
      categoryOtherFg: blend(base.categoryOtherFg, scheme.primary, 0.36),
    );
  }

  (Color background, Color foreground) categoryIconColors(String category) {
    switch (category) {
      case 'food':
        return (categoryFoodBg, categoryFoodFg);
      case 'transport':
        return (categoryTransportBg, categoryTransportFg);
      case 'accommodation':
        return (categoryAccommodationBg, categoryAccommodationFg);
      case 'entertainment':
      case 'shopping':
      case 'utilities':
        return (categoryOtherBg, categoryOtherFg);
      case 'settlement':
        return (categorySettlementBg, categorySettlementFg);
      default:
        return (categoryOtherBg, categoryOtherFg);
    }
  }

  @override
  SplitBaeSemanticColors copyWith({
    Color? balancePay,
    Color? onBalancePay,
    Color? balancePayContainer,
    Color? onBalancePayContainer,
    Color? balanceReceive,
    Color? onBalanceReceive,
    Color? balanceReceiveContainer,
    Color? onBalanceReceiveContainer,
    Color? destructive,
    Color? onDestructive,
    Color? destructiveContainer,
    Color? onDestructiveContainer,
    Color? insightTrendWorseBg,
    Color? insightTrendWorseFg,
    Color? insightTrendBetterBg,
    Color? insightTrendBetterFg,
    Color? insightTopBg,
    Color? insightTopFg,
    Color? insightStreakBg,
    Color? insightStreakFg,
    Color? categoryFoodBg,
    Color? categoryFoodFg,
    Color? categoryTransportBg,
    Color? categoryTransportFg,
    Color? categoryAccommodationBg,
    Color? categoryAccommodationFg,
    Color? categorySettlementBg,
    Color? categorySettlementFg,
    Color? categoryOtherBg,
    Color? categoryOtherFg,
  }) {
    return SplitBaeSemanticColors(
      balancePay: balancePay ?? this.balancePay,
      onBalancePay: onBalancePay ?? this.onBalancePay,
      balancePayContainer: balancePayContainer ?? this.balancePayContainer,
      onBalancePayContainer: onBalancePayContainer ?? this.onBalancePayContainer,
      balanceReceive: balanceReceive ?? this.balanceReceive,
      onBalanceReceive: onBalanceReceive ?? this.onBalanceReceive,
      balanceReceiveContainer:
          balanceReceiveContainer ?? this.balanceReceiveContainer,
      onBalanceReceiveContainer:
          onBalanceReceiveContainer ?? this.onBalanceReceiveContainer,
      destructive: destructive ?? this.destructive,
      onDestructive: onDestructive ?? this.onDestructive,
      destructiveContainer: destructiveContainer ?? this.destructiveContainer,
      onDestructiveContainer:
          onDestructiveContainer ?? this.onDestructiveContainer,
      insightTrendWorseBg: insightTrendWorseBg ?? this.insightTrendWorseBg,
      insightTrendWorseFg: insightTrendWorseFg ?? this.insightTrendWorseFg,
      insightTrendBetterBg: insightTrendBetterBg ?? this.insightTrendBetterBg,
      insightTrendBetterFg: insightTrendBetterFg ?? this.insightTrendBetterFg,
      insightTopBg: insightTopBg ?? this.insightTopBg,
      insightTopFg: insightTopFg ?? this.insightTopFg,
      insightStreakBg: insightStreakBg ?? this.insightStreakBg,
      insightStreakFg: insightStreakFg ?? this.insightStreakFg,
      categoryFoodBg: categoryFoodBg ?? this.categoryFoodBg,
      categoryFoodFg: categoryFoodFg ?? this.categoryFoodFg,
      categoryTransportBg: categoryTransportBg ?? this.categoryTransportBg,
      categoryTransportFg: categoryTransportFg ?? this.categoryTransportFg,
      categoryAccommodationBg:
          categoryAccommodationBg ?? this.categoryAccommodationBg,
      categoryAccommodationFg:
          categoryAccommodationFg ?? this.categoryAccommodationFg,
      categorySettlementBg: categorySettlementBg ?? this.categorySettlementBg,
      categorySettlementFg: categorySettlementFg ?? this.categorySettlementFg,
      categoryOtherBg: categoryOtherBg ?? this.categoryOtherBg,
      categoryOtherFg: categoryOtherFg ?? this.categoryOtherFg,
    );
  }

  @override
  SplitBaeSemanticColors lerp(
    ThemeExtension<SplitBaeSemanticColors>? other,
    double t,
  ) {
    if (other is! SplitBaeSemanticColors) return this;
    return SplitBaeSemanticColors(
      balancePay: Color.lerp(balancePay, other.balancePay, t)!,
      onBalancePay: Color.lerp(onBalancePay, other.onBalancePay, t)!,
      balancePayContainer:
          Color.lerp(balancePayContainer, other.balancePayContainer, t)!,
      onBalancePayContainer:
          Color.lerp(onBalancePayContainer, other.onBalancePayContainer, t)!,
      balanceReceive: Color.lerp(balanceReceive, other.balanceReceive, t)!,
      onBalanceReceive: Color.lerp(onBalanceReceive, other.onBalanceReceive, t)!,
      balanceReceiveContainer: Color.lerp(
            balanceReceiveContainer,
            other.balanceReceiveContainer,
            t,
          )!,
      onBalanceReceiveContainer: Color.lerp(
            onBalanceReceiveContainer,
            other.onBalanceReceiveContainer,
            t,
          )!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      onDestructive: Color.lerp(onDestructive, other.onDestructive, t)!,
      destructiveContainer:
          Color.lerp(destructiveContainer, other.destructiveContainer, t)!,
      onDestructiveContainer:
          Color.lerp(onDestructiveContainer, other.onDestructiveContainer, t)!,
      insightTrendWorseBg:
          Color.lerp(insightTrendWorseBg, other.insightTrendWorseBg, t)!,
      insightTrendWorseFg:
          Color.lerp(insightTrendWorseFg, other.insightTrendWorseFg, t)!,
      insightTrendBetterBg:
          Color.lerp(insightTrendBetterBg, other.insightTrendBetterBg, t)!,
      insightTrendBetterFg:
          Color.lerp(insightTrendBetterFg, other.insightTrendBetterFg, t)!,
      insightTopBg: Color.lerp(insightTopBg, other.insightTopBg, t)!,
      insightTopFg: Color.lerp(insightTopFg, other.insightTopFg, t)!,
      insightStreakBg: Color.lerp(insightStreakBg, other.insightStreakBg, t)!,
      insightStreakFg: Color.lerp(insightStreakFg, other.insightStreakFg, t)!,
      categoryFoodBg: Color.lerp(categoryFoodBg, other.categoryFoodBg, t)!,
      categoryFoodFg: Color.lerp(categoryFoodFg, other.categoryFoodFg, t)!,
      categoryTransportBg:
          Color.lerp(categoryTransportBg, other.categoryTransportBg, t)!,
      categoryTransportFg:
          Color.lerp(categoryTransportFg, other.categoryTransportFg, t)!,
      categoryAccommodationBg:
          Color.lerp(categoryAccommodationBg, other.categoryAccommodationBg, t)!,
      categoryAccommodationFg:
          Color.lerp(categoryAccommodationFg, other.categoryAccommodationFg, t)!,
      categorySettlementBg:
          Color.lerp(categorySettlementBg, other.categorySettlementBg, t)!,
      categorySettlementFg:
          Color.lerp(categorySettlementFg, other.categorySettlementFg, t)!,
      categoryOtherBg: Color.lerp(categoryOtherBg, other.categoryOtherBg, t)!,
      categoryOtherFg: Color.lerp(categoryOtherFg, other.categoryOtherFg, t)!,
    );
  }
}

extension SplitBaeSemanticColorsX on BuildContext {
  SplitBaeSemanticColors get splitBaeSemantic {
    final ext = Theme.of(this).extension<SplitBaeSemanticColors>();
    if (ext != null) return ext;
    return Theme.of(this).brightness == Brightness.dark
        ? SplitBaeSemanticColors.dark
        : SplitBaeSemanticColors.light;
  }
}
