part of '../../main.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat'), backgroundColor: Colors.white),
      body: StreamBuilder<List<ChatPreviewData>>(
        stream: SupabaseService.instance.userChatsStream(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen(label: 'Memuat percakapan...');
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Chat gagal dimuat',
                subtitle: _streamErrorMessage(snapshot.error),
              ),
            );
          }

          final chats = snapshot.data ?? const <ChatPreviewData>[];
          if (chats.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Belum ada chat',
                subtitle:
                    'Percakapan aktif dengan penyewa atau pemilik kos akan muncul di sini.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemCount: chats.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final displayName = chat.displayNameFor(user.id);
              final displayPhoto = chat.displayPhotoFor(user.id);
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ChatDetailPage(kos: chat.kos, chatId: chat.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Ink(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE7ECEC)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: displayPhoto.isNotEmpty
                            ? NetworkImage(displayPhoto)
                            : null,
                        child: displayPhoto.isEmpty
                            ? const Icon(Icons.person_rounded)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chat.kos.name,
                              style: const TextStyle(
                                color: Color(0xFF006A6A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              chat.lastMessage.isEmpty
                                  ? 'Belum ada pesan'
                                  : chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF5D6B6B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        chat.timeLabel,
                        style: const TextStyle(
                          color: Color(0xFF5D6B6B),
                          fontSize: 12,
                        ),
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

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({super.key, required this.kos, required this.chatId});

  final KosData kos;
  final String chatId;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseAuth.instance.currentUser!.id;
    final isOwner = currentUserId == widget.kos.ownerId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: StreamBuilder<ChatPreviewData?>(
          stream: SupabaseService.instance.chatPreviewStream(
            chatId: widget.chatId,
            fallbackKos: widget.kos,
          ),
          builder: (context, snapshot) {
            final chat = snapshot.data;
            final displayName =
                chat?.displayNameFor(currentUserId) ??
                (isOwner ? 'Penyewa' : widget.kos.ownerName);
            final displayPhoto =
                chat?.displayPhotoFor(currentUserId) ??
                (isOwner ? '' : widget.kos.ownerPhoto);

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: displayPhoto.isNotEmpty
                      ? NetworkImage(displayPhoto)
                      : null,
                  child: displayPhoto.isEmpty
                      ? const Icon(Icons.person_rounded, size: 18)
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: const TextStyle(fontSize: 16)),
                    Text(
                      isOwner ? 'Penyewa' : widget.kos.ownerStatus,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5D6B6B),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    widget.kos.gallery.first,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.kos.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currency(widget.kos.price)} / bulan',
                        style: const TextStyle(
                          color: Color(0xFF006A6A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatMessageData>>(
              stream: SupabaseService.instance.messagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingScreen(label: 'Memuat pesan...');
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _EmptyStateCard(
                        title: 'Pesan gagal dimuat',
                        subtitle: _streamErrorMessage(snapshot.error),
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? const <ChatMessageData>[];
                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: _EmptyStateCard(
                        title: 'Mulai percakapan pertama',
                        subtitle:
                            'Tanyakan kamar, jadwal survei, atau aturan kos langsung ke pemilik.',
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMine = message.senderId == currentUserId;
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isMine
                              ? const Color(0xFF006A6A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                color: isMine
                                    ? Colors.white
                                    : const Color(0xFF182022),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              message.timeLabel,
                              style: TextStyle(
                                color: isMine
                                    ? Colors.white70
                                    : const Color(0xFF5D6B6B),
                                fontSize: 11,
                              ),
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
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _sending ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF006A6A),
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() => _sending = true);
    try {
      await SupabaseService.instance.sendMessage(
        chatId: widget.chatId,
        text: text,
        kos: widget.kos,
      );
      _controller.clear();
    } on SupabaseAppException catch (error) {
      if (mounted) {
        _showLightDialog(
          context,
          title: 'Pesan belum terkirim',
          message: _supabaseMessage(error),
        );
      }
    } catch (_) {
      if (mounted) {
        _showLightDialog(
          context,
          title: 'Pesan gagal dikirim',
          message: 'Coba lagi dalam beberapa saat.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}
