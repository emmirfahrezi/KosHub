part of '../../main.dart';

class KosDetailPage extends StatelessWidget {
  const KosDetailPage({super.key, required this.kos});

  final KosData kos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = SupabaseAuth.instance.currentUser;
    final isOwnKos = currentUser?.id == kos.ownerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: PageView(
                children: kos.gallery
                    .map((image) => Image.network(image, fit: BoxFit.cover))
                    .toList(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TagChip(
                        label: kos.category,
                        color: kos.category == 'Eksklusif'
                            ? const Color(0xFF006A6A)
                            : const Color(0xFF9F4035),
                      ),
                      _StatusPill(
                        label: '${kos.availableRooms} kamar tersedia',
                        color: const Color(0xFFB78103),
                        background: const Color(0xFFFFF5DD),
                      ),
                      _StatusPill(
                        label: kos.approvalMode,
                        color: const Color(0xFF35589F),
                        background: const Color(0xFFEAF1FF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    kos.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF5D6B6B),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          kos.address,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF4B400),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${kos.rating.toStringAsFixed(1)} (${kos.reviewCount} ulasan)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '${_currency(kos.price)} / bulan',
                        style: const TextStyle(
                          color: Color(0xFF006A6A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _InfoBlock(
                    title: 'Deskripsi',
                    child: Text(
                      kos.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoBlock(
                    title: 'Fasilitas',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kos.facilities
                          .map((facility) => _FacilityChip(label: facility))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoBlock(
                    title: 'Pemilik Kos',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E7E7)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundImage: kos.ownerPhoto.isNotEmpty
                                ? NetworkImage(kos.ownerPhoto)
                                : null,
                            child: kos.ownerPhoto.isEmpty
                                ? const Icon(Icons.person_rounded)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kos.ownerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  kos.ownerStatus,
                                  style: const TextStyle(
                                    color: Color(0xFF5D6B6B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoBlock(
                    title: 'Lokasi',
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDDF5EF), Color(0xFFF8F8FB)],
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_rounded,
                              size: 42,
                              color: Color(0xFF006A6A),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Lokasi kos akan ditampilkan di sini',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: StreamBuilder<AppUserData?>(
        stream: currentUser == null
            ? null
            : SupabaseService.instance.userProfileStream(currentUser.id),
        builder: (context, snapshot) {
          final isOwner = snapshot.data?.canAccessOwnerShell == true;

          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final chatId = await SupabaseService.instance
                              .createOrGetChat(kos);
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ChatDetailPage(kos: kos, chatId: chatId),
                            ),
                          );
                        } on SupabaseAppException catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          _showLightDialog(
                            context,
                            title: 'Chat belum bisa dibuka',
                            message: _supabaseMessage(error),
                          );
                        } catch (_) {
                          if (!context.mounted) {
                            return;
                          }
                          _showLightDialog(
                            context,
                            title: 'Chat gagal dibuat',
                            message: 'Coba lagi dalam beberapa saat.',
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text('Chat Pemilik'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isOwnKos
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      OwnerRegistrationPage(existingKos: kos),
                                ),
                              );
                            }
                          : isOwner
                          ? null
                          : () {
                              if (kos.availableRooms <= 0) {
                                _showLightDialog(
                                  context,
                                  title: 'Kamar penuh',
                                  message:
                                      'Saat ini kamar di kos ini sedang penuh.',
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => BookingFormPage(kos: kos),
                                ),
                              );
                            },
                      child: Text(
                        isOwnKos
                            ? 'Edit Listing'
                            : isOwner
                            ? 'Akun Pemilik'
                            : kos.availableRooms <= 0
                            ? 'Kamar Penuh'
                            : 'Booking Sekarang',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
