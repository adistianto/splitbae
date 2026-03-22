import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// v0 [bottom-nav]: two tabs with an M3-style animated pill behind the active item.
class SplitBaeV0BottomNav extends StatelessWidget {
  const SplitBaeV0BottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<SplitBaeV0BottomNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      elevation: 0,
      color: cs.surface.withValues(alpha: 0.94),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 8, 20, 8 + bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Row(
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Expanded(
                    child: _NavSlot(
                      selected: selectedIndex == i,
                      destination: destinations[i],
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onDestinationSelected(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SplitBaeV0BottomNavDestination {
  const SplitBaeV0BottomNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.selected,
    required this.destination,
    required this.onTap,
  });

  final bool selected;
  final SplitBaeV0BottomNavDestination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: const Cubic(0.34, 1.56, 0.64, 1),
                  alignment: Alignment.center,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    curve: const Cubic(0.34, 1.56, 0.64, 1),
                    scale: selected ? 1 : 0.92,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 280),
                      opacity: selected ? 1 : 0,
                      child: Container(
                        width: 64,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: cs.primary.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      size: 26,
                      color: selected
                          ? cs.primary
                          : cs.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? cs.primary
                                : cs.onSurfaceVariant.withValues(alpha: 0.65),
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
}
