import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splitbae/core/theme/splitbae_v0_ui_contract.dart';
import 'package:splitbae/core/ui/splitbae_motion.dart';
import 'package:splitbae/l10n/app_localizations.dart';

/// v0-style speed dial: New Bill, Scan Bill, Create Report (→ Balances).
class SplitBaeFabMenu extends StatefulWidget {
  const SplitBaeFabMenu({
    super.key,
    required this.onNewBill,
    required this.onScanBill,
    required this.onCreateReport,
    this.visible = true,
  });

  final VoidCallback onNewBill;
  final VoidCallback onScanBill;
  final VoidCallback onCreateReport;

  /// Hides the dial when scrolling down (v0 [fab-menu] behavior).
  final bool visible;

  @override
  State<SplitBaeFabMenu> createState() => _SplitBaeFabMenuState();
}

class _SplitBaeFabMenuState extends State<SplitBaeFabMenu> {
  bool _open = false;

  void _closeAnd(VoidCallback fn) {
    setState(() => _open = false);
    fn();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    const navBarReserve = SplitBaeV0Layout.fabBottomNavReserve;

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          if (_open && widget.visible)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _open = false),
                behavior: HitTestBehavior.opaque,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.2)),
              ),
            ),
          Positioned(
            right: 20,
            bottom: navBarReserve + bottomSafe,
            child: AnimatedOpacity(
              opacity: widget.visible ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: IgnorePointer(
                ignoring: !widget.visible,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_open) ...[
                      _FabPill(
                        label: l10n.fabCreateReport,
                        background: _fabVioletBg(context),
                        foreground: _fabVioletFg(context),
                        icon: Icons.description_outlined,
                        open: _open,
                        staggerIndex: 0,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _closeAnd(widget.onCreateReport);
                        },
                      ),
                      const SizedBox(height: 12),
                      _FabPill(
                        label: l10n.fabScanBill,
                        background: _fabAmberBg(context),
                        foreground: _fabAmberFg(context),
                        icon: Icons.photo_camera_outlined,
                        open: _open,
                        staggerIndex: 1,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _closeAnd(widget.onScanBill);
                        },
                      ),
                      const SizedBox(height: 12),
                      _FabPill(
                        label: l10n.fabNewBill,
                        background: _fabTealBg(context),
                        foreground: _fabTealFg(context),
                        icon: Icons.receipt_long_outlined,
                        open: _open,
                        staggerIndex: 2,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _closeAnd(widget.onNewBill);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    AnimatedContainer(
                      duration: splitBaeAnimationDuration(
                        context,
                        const Duration(milliseconds: 200),
                      ),
                      curve: splitBaeAnimationCurve(context),
                      width: SplitBaeV0Layout.fabMainSize,
                      height: SplitBaeV0Layout.fabMainSize,
                      decoration: BoxDecoration(
                        color: _open ? cs.onSurface : cs.primary,
                        borderRadius: BorderRadius.circular(
                          _open
                              ? SplitBaeV0Layout.fabMainCornerRadiusOpen
                              : SplitBaeV0Layout.fabMainCornerRadiusClosed,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() => _open = !_open);
                          },
                          borderRadius: BorderRadius.circular(
                            _open
                                ? SplitBaeV0Layout.fabMainCornerRadiusOpen
                                : SplitBaeV0Layout.fabMainCornerRadiusClosed,
                          ),
                          child: Center(
                            child: Icon(
                              _open ? Icons.close : Icons.add,
                              size: 32,
                              color: _open ? cs.surface : cs.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _fabTealBg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF134E4A)
        : const Color(0xFFCCFBF1);

Color _fabTealFg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF5EEAD4)
        : const Color(0xFF0F766E);

Color _fabAmberBg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF78350F)
        : const Color(0xFFFEF3C7);

Color _fabAmberFg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFCD34D)
        : const Color(0xFFB45309);

Color _fabVioletBg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4C1D95)
        : const Color(0xFFEDE9FE);

Color _fabVioletFg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFC4B5FD)
        : const Color(0xFF5B21B6);

class _FabPill extends StatelessWidget {
  const _FabPill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.onTap,
    required this.open,
    required this.staggerIndex,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;
  final VoidCallback onTap;
  final bool open;
  final int staggerIndex;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: Duration(milliseconds: 240 + staggerIndex * 55),
      curve: const Cubic(0.34, 1.56, 0.64, 1),
      offset: open ? Offset.zero : const Offset(0.2, 0),
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 200 + staggerIndex * 55),
        opacity: open ? 1 : 0,
        child: Material(
          elevation: 4,
          borderRadius:
              BorderRadius.circular(SplitBaeV0Layout.fabPillRadius),
          color: background,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onTap,
            borderRadius:
                BorderRadius.circular(SplitBaeV0Layout.fabPillRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: foreground),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
