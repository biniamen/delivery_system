import 'package:creavers_delivery_mobile/app/app_controller.dart';
import 'package:flutter/material.dart';

final class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({
    required this.state,
    required this.message,
    required this.apiOrigin,
    required this.onRetry,
    super.key,
  });

  final BackendConnectionState state;
  final String message;
  final Uri apiOrigin;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final online = state == BackendConnectionState.online;
    final checking = state == BackendConnectionState.checking;
    final accent = checking
        ? colors.secondary
        : online
        ? const Color(0xFF23856D)
        : colors.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            if (checking)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                color: accent,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    apiOrigin.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (!checking)
              IconButton(
                tooltip: 'Retry connection',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
              ),
          ],
        ),
      ),
    );
  }
}
