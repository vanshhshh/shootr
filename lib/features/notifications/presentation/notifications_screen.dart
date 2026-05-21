import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/glass_card.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final role = state.selectedRole;
    final items =
        state.notifications.where((item) => item.targetRole == role).toList();

    return AppScaffold(
      title: 'Notifications',
      child: items.isEmpty
          ? const EmptyStateView(
              title: 'All caught up',
              subtitle: 'Your alerts and updates will appear here.',
            )
          : Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        onTap: () => ref
                            .read(appControllerProvider.notifier)
                            .markNotificationRead(item.id),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 6),
                                  Text(item.body),
                                ],
                              ),
                            ),
                            if (!item.read) const Icon(Icons.circle, size: 10),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
