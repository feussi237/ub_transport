import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/dashboard_models.dart';
import '../widgets/common_widgets.dart';
import '../services/message_service.dart';
import '../services/api_client.dart';
import 'agency_conversation_screen.dart';

/// Agency dashboard "Messages": one row per passenger who has messaged the
/// agency, most recently active first. Polls so new messages show up
/// without a manual refresh.
class AgencyMessagesTab extends StatefulWidget {
  const AgencyMessagesTab({super.key});

  @override
  State<AgencyMessagesTab> createState() => _AgencyMessagesTabState();
}

class _AgencyMessagesTabState extends State<AgencyMessagesTab> {
  static const _pollInterval = Duration(seconds: 8);

  late Future<List<AgencyConversation>> _future;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _future = MessageService.instance.agencyConversations();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final future = MessageService.instance.agencyConversations();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {
      // Silent on background polling failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<AgencyConversation>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Could not load conversations.';
            return ListView(children: [StateMessage(icon: Icons.wifi_off, message: message)]);
          }
          final conversations = snapshot.data!;
          if (conversations.isEmpty) {
            return ListView(children: const [
              StateMessage(icon: Icons.chat_bubble_outline, message: 'No messages from passengers yet.'),
            ]);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final c = conversations[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(
                      builder: (_) => AgencyConversationScreen(passengerId: c.passengerId, passengerName: c.passengerName),
                    ))
                    .then((_) => _refresh()),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.unreadCount > 0 ? AppColors.chipFill : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.chipFill,
                        child: Text(c.passengerName.isNotEmpty ? c.passengerName[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.passengerName, style: AppTextStyles.label),
                            if (c.lastMessage != null)
                              Text(c.lastMessage!, style: AppTextStyles.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (c.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.indigo, borderRadius: BorderRadius.circular(10)),
                          child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
