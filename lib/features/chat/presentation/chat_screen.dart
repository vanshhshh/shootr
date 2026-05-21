import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants/app_colors.dart';
import '../../../shared/models/shootr_package.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/glass_card.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send({String? quickReply}) async {
    final state = ref.read(appControllerProvider);
    final user = state.currentUser;
    final body = quickReply ?? _controller.text.trim();

    if (body.isEmpty) {
      return;
    }

    await ref.read(appControllerProvider.notifier).sendMessage(
          bookingId: widget.bookingId,
          senderId: user?.id ?? 'guest',
          senderName: user?.name ?? 'Guest',
          body: body,
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final bookingMatches =
        state.bookings.where((item) => item.id == widget.bookingId).toList();
    if (bookingMatches.isEmpty) {
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }

    final booking = bookingMatches.first;
    final messages = state.chatThreads[widget.bookingId] ?? const [];
    final quickReplies = const <String>[
      'On my way',
      '5 mins away',
      'Reel is ready!',
    ];

    return AppScaffold(
      title: 'Chat',
      child: Column(
        children: <Widget>[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(booking.shootrName, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('${booking.packageType.label}  •  ${booking.location.address}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (messages.isEmpty)
            const EmptyStateView(
              title: 'No messages yet',
              subtitle: 'Start with a quick reply to coordinate the shoot.',
            )
          else
            SizedBox(
              height: 420,
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final mine = message.senderId == state.currentUser?.id;

                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: mine
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(message.body),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (mine) ...<Widget>[
                                const SizedBox(width: 6),
                                const Icon(Icons.done_all, size: 16, color: AppColors.primary),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickReplies
                .map(
                  (reply) => ActionChip(
                    label: Text(reply),
                    onPressed: () => _send(quickReply: reply),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    suffixIcon: Icon(Icons.attach_file_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _send,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
