import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';

class SettingsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const SettingsCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              // If padding is provided, use it. Otherwise default to 0 to allow full-width rows.
              // The spec says "Card padding: 16 dp inside the card", but also "Make each row full-width and tappable".
              // To achieve both, we apply padding to the content of the rows, not the card container, 
              // OR we accept that the ripple is constrained by padding.
              // However, "full-width and tappable" usually implies edge-to-edge ripple.
              // We will default to 0 here and let the child handle padding if needed, 
              // but for the lists, we want 0.
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool showChevron;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16), // Match card padding spec
        child: Row(
          children: [
            // Icon with padding
            Padding(
              padding: const EdgeInsets.only(right: 16.0), // "Left icon padding: 12 dp" (interpreted as gap)
              child: Icon(icon, size: 20, color: AppColors.primaryText),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF666666),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && showChevron)
              const Icon(Icons.chevron_right, color: Color(0xFF999999), size: 20),
          ],
        ),
      ),
    );
  }
}

class InviteBannerCard extends StatelessWidget {
  final VoidCallback onInviteTap;

  const InviteBannerCard({super.key, required this.onInviteTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: const DecorationImage(
          // Using a placeholder image that fits the "journey" theme
          image: NetworkImage('https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?auto=format&fit=crop&w=1350&q=80'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Dark overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'The journey\nis easier together.',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onInviteTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF111111),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Refer a friend to earn \$10',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderboardCard extends StatelessWidget {
  final VoidCallback onTap;

  const LeaderboardCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.leaderboard, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leaderboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    Text(
                      'See top users',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppColors.secondaryText, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
