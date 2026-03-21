import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splitbae/l10n/app_localizations.dart';

/// v0-style speed dial: New Bill, Scan Bill, Create Report (→ Balances).
class SplitBaeFabMenu extends StatefulWidget {
  const SplitBaeFabMenu({
    super.key,
    required this.onNewBill,
    required this.onScanBill,
    required this.onCreateReport,
  });

  final VoidCallback onNewBill;
  final VoidCallback onScanBill;
  final VoidCallback onCreateReport;

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
    const navBarReserve = 80.0;

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          if (_open)
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_open) ...[
                  _FabPill(
                    label: l10n.fabCreateReport,
                    background: cs.secondaryContainer,
                    foreground: cs.onSecondaryContainer,
                    icon: Icons.description_outlined,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _closeAnd(widget.onCreateReport);
                    },
                  ),
                  const SizedBox(height: 12),
                  _FabPill(
                    label: l10n.fabScanBill,
                    background: cs.tertiaryContainer,
                    foreground: cs.onTertiaryContainer,
                    icon: Icons.photo_camera_outlined,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _closeAnd(widget.onScanBill);
                    },
                  ),
                  const SizedBox(height: 12),
                  _FabPill(
                    label: l10n.fabNewBill,
                    background: cs.primaryContainer,
                    foreground: cs.onPrimaryContainer,
                    icon: Icons.receipt_long_outlined,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _closeAnd(widget.onNewBill);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                Material(
                  elevation: 6,
                  shadowColor: cs.primary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(_open ? 28 : 20),
                  color: _open ? cs.onSurface : cs.primary,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _open = !_open);
                    },
                    borderRadius: BorderRadius.circular(_open ? 28 : 20),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(
                        _open ? Icons.close : Icons.add,
                        size: 32,
                        color: _open ? cs.surface : cs.onPrimary,
                      ),
                    ),
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

class _FabPill extends StatelessWidget {
  const _FabPill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      color: background,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
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
    );
  }
}
