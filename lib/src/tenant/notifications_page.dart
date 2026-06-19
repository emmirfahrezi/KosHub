part of '../../main.dart';

class TenantNotificationsPage extends StatefulWidget {
  const TenantNotificationsPage({super.key});

  @override
  State<TenantNotificationsPage> createState() =>
      _TenantNotificationsPageState();
}

class _TenantNotificationsPageState extends State<TenantNotificationsPage> {
  final Set<String> _locallyReadKeys = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Notifikasi'),
      ),
      body: _TenantNotificationFeed(
        locallyReadKeys: _locallyReadKeys,
        builder: (context, notifications) {
          if (notifications.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Tidak ada notifikasi baru',
                subtitle:
                    'Balasan chat dan perubahan status booking akan muncul di sini.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: ListTile(
                  onTap: () => _openNotification(notification),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEAF5F5),
                    child: Icon(
                      notification.icon,
                      color: const Color(0xFF006A6A),
                    ),
                  ),
                  title: Text(notification.title),
                  subtitle: Text(notification.subtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openNotification(_TenantNotificationData notification) async {
    setState(() => _locallyReadKeys.add(notification.key));
    try {
      await SupabaseService.instance.markNotificationRead(notification.key);
    } catch (_) {
      if (mounted) {
        setState(() => _locallyReadKeys.remove(notification.key));
      }
      return;
    }
    if (!mounted) {
      return;
    }
    await notification.open(context);
  }
}

class _TenantNotificationBadgeButton extends StatefulWidget {
  const _TenantNotificationBadgeButton();

  @override
  State<_TenantNotificationBadgeButton> createState() =>
      _TenantNotificationBadgeButtonState();
}

class _TenantNotificationBadgeButtonState
    extends State<_TenantNotificationBadgeButton> {
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return _TenantNotificationFeed(
      key: ValueKey(_refreshKey),
      builder: (context, notifications) {
        final count = notifications.length;
        return Badge(
          isLabelVisible: count > 0,
          backgroundColor: const Color(0xFFD92D20),
          label: Text(count > 99 ? '99+' : '$count'),
          child: IconButton(
            tooltip: 'Notifikasi',
            onPressed: () async {
              await Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const TenantNotificationsPage(),
                ),
              );
              if (mounted) {
                setState(() => _refreshKey++);
              }
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        );
      },
    );
  }
}

class _TenantNotificationFeed extends StatelessWidget {
  const _TenantNotificationFeed({
    super.key,
    required this.builder,
    this.locallyReadKeys = const <String>{},
  });

  final Set<String> locallyReadKeys;
  final Widget Function(
    BuildContext context,
    List<_TenantNotificationData> notifications,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    final user = SupabaseAuth.instance.currentUser!;
    return StreamBuilder<List<ChatPreviewData>>(
      stream: SupabaseService.instance.userChatsStream(user.id),
      builder: (context, chatsSnapshot) {
        return StreamBuilder<List<BookingData>>(
          stream: SupabaseService.instance.userBookingsStream(user.id),
          builder: (context, bookingsSnapshot) {
            return StreamBuilder<Set<String>>(
              stream: SupabaseService.instance.notificationReadKeysStream(
                user.id,
              ),
              builder: (context, readsSnapshot) {
                final readKeys = <String>{
                  ...?readsSnapshot.data,
                  ...locallyReadKeys,
                };
                final notifications =
                    _tenantNotifications(
                      context,
                      userId: user.id,
                      chats: chatsSnapshot.data ?? const <ChatPreviewData>[],
                      bookings: bookingsSnapshot.data ?? const <BookingData>[],
                    )..removeWhere(
                      (notification) => readKeys.contains(notification.key),
                    );
                notifications.sort((a, b) => b.sortKey.compareTo(a.sortKey));
                return builder(context, notifications);
              },
            );
          },
        );
      },
    );
  }
}

List<_TenantNotificationData> _tenantNotifications(
  BuildContext context, {
  required String userId,
  required List<ChatPreviewData> chats,
  required List<BookingData> bookings,
}) {
  final notifications = <_TenantNotificationData>[];

  for (final chat in chats.where(
    (chat) =>
        chat.lastMessage.isNotEmpty &&
        chat.lastSenderId.isNotEmpty &&
        chat.lastSenderId != userId,
  )) {
    notifications.add(
      _TenantNotificationData(
        key: 'chat:${chat.id}:${chat.sortKey.microsecondsSinceEpoch}',
        title: 'Pesan baru dari ${chat.displayNameFor(userId)}',
        subtitle: chat.lastMessage,
        icon: Icons.chat_bubble_rounded,
        sortKey: chat.sortKey,
        open: (context) => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ChatDetailPage(kos: chat.kos, chatId: chat.id),
          ),
        ),
      ),
    );
  }

  for (final booking in bookings.where(
    (booking) => booking.status != 'Menunggu Konfirmasi',
  )) {
    final isCompleted = booking.status == 'Selesai';
    notifications.add(
      _TenantNotificationData(
        key: 'booking:${booking.id}:${booking.status}',
        title: isCompleted
            ? 'Masa sewa berakhir'
            : 'Status booking ${booking.status}',
        subtitle: isCompleted
            ? 'Masa sewa di ${booking.kos.name} telah selesai.'
            : '${booking.kos.name} - ${booking.roomLabel}',
        icon: isCompleted ? Icons.history_rounded : Icons.fact_check_rounded,
        sortKey: booking.sortKey,
        open: (context) => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => isCompleted
                ? const BookingHistoryPage()
                : BookingDetailPage(booking: booking),
          ),
        ),
      ),
    );
  }
  return notifications;
}

class _TenantNotificationData {
  const _TenantNotificationData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sortKey,
    required this.open,
  });

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final DateTime sortKey;
  final Future<void> Function(BuildContext context) open;
}
