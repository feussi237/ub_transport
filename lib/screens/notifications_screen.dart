import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/api_models.dart';
import '../widgets/common_widgets.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<ApiNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = NotificationService.instance.list();
  }

  Future<void> _refresh() async {
    final future = NotificationService.instance.list();
    setState(() => _future = future);
    await future;
  }

  Future<void> _markAllRead() async {
    await NotificationService.instance.markAllRead();
    _refresh();
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'delay':
        return Icons.schedule;
      case 'cancellation':
        return Icons.cancel_outlined;
      case 'reminder':
        return Icons.notifications_active_outlined;
      default:
        return Icons.confirmation_number_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenHeader(
        title: 'Notifications',
        trailing: TextButton(
          onPressed: _markAllRead,
          child: const Text('Mark all read', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ApiNotification>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(children: const [
                StateMessage(icon: Icons.wifi_off, message: 'Could not load notifications.'),
              ]);
            }
            final notifications = snapshot.data!;
            if (notifications.isEmpty) {
              return ListView(children: const [
                StateMessage(icon: Icons.notifications_none, message: 'You\'re all caught up — no notifications yet.'),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: n.isRead
                      ? null
                      : () async {
                          await NotificationService.instance.markRead(n.id);
                          _refresh();
                        },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: n.isRead ? AppColors.white : AppColors.chipFill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_iconFor(n.type), color: n.isRead ? AppColors.textMuted : AppColors.indigo),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: AppTextStyles.label),
                              const SizedBox(height: 4),
                              Text(n.body, style: AppTextStyles.subtitle),
                            ],
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4, left: 6),
                            decoration: const BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
