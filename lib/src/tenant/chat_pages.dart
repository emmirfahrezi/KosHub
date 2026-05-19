part of '../../main.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Pemilik Kos'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ChatPreviewData>>(
        stream: FirestoreService.instance.userChatsStream(user.uid),
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
                    'Buka detail kos lalu tekan tombol chat agar percakapan pertama dibuat di Firestore.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemCount: chats.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final chat = chats[index];
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
                        backgroundImage: NetworkImage(chat.kos.ownerPhoto),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat.kos.ownerName,
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
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.kos.ownerPhoto),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kos.ownerName,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  widget.kos.ownerStatus,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5D6B6B),
                  ),
                ),
              ],
            ),
          ],
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
              stream: FirestoreService.instance.messagesStream(widget.chatId),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
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
      await FirestoreService.instance.sendMessage(widget.chatId, text);
      _controller.clear();
    } on FirebaseException catch (error) {
      if (mounted) {
        _showLightDialog(
          context,
          title: 'Pesan belum terkirim',
          message: _firebaseMessage(error),
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
