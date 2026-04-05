import 'package:flutter/material.dart';
import 'theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppConstants.paddingLarge),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Une erreur est survenue',
      subtitle: message,
      action: onRetry != null
          ? ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            )
          : null,
    );
  }
}

class VisitorsEmptyState extends StatelessWidget {
  const VisitorsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.security,
      title: 'Aucun visiteur',
      subtitle: 'Les detections de visiteurs apparaitront ici',
    );
  }
}

class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.history,
      title: 'Aucun historique',
      subtitle: 'L\'historique des detections apparaitra ici',
    );
  }
}
