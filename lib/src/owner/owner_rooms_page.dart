part of '../../main.dart';

class OwnerRoomsPage extends StatelessWidget {
  const OwnerRoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseAuth.instance.currentUser!;

    return StreamBuilder<KosData?>(
      stream: SupabaseService.instance.ownerKosStream(user.id),
      builder: (context, kosSnapshot) {
        if (kosSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(label: 'Memuat data kamar...');
        }

        final kos = kosSnapshot.data;
        if (kos == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: const Text('Kamar'),
            ),
            body: const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Listing kos belum tersedia',
                subtitle:
                    'Lengkapi data listing dulu dari profil supaya kamar dan pengaturan owner bisa dikelola.',
              ),
            ),
          );
        }

        return StreamBuilder<List<BookingData>>(
          stream: SupabaseService.instance.ownerBookingsStream(user.id),
          builder: (context, bookingsSnapshot) {
            if (bookingsSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(label: 'Menghitung kondisi kamar...');
            }

            final bookings = bookingsSnapshot.data ?? const <BookingData>[];
            final activeResidents = bookings
                .where((booking) => booking.status == 'Sudah Check-in')
                .toList();
            final totalRooms = math.max(kos.totalRooms, activeResidents.length);
            final generatedRooms = List.generate(totalRooms, (index) {
              final roomLabel =
                  'Kamar ${(index + 1).toString().padLeft(2, '0')}';
              final resident = activeResidents.firstWhere(
                (booking) => booking.roomLabel == roomLabel,
                orElse: () => BookingData.empty(roomLabel, kos),
              );
              return resident;
            });

            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: const Text('Kamar'),
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kos.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${kos.area} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${kos.address}',
                          style: const TextStyle(
                            color: Color(0xFF5D6B6B),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SmallPill(label: 'Mode ${kos.approvalMode}'),
                            _SmallPill(label: '${kos.availableRooms} tersedia'),
                            _SmallPill(
                              label: '${activeResidents.length} terisi',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    OwnerRegistrationPage(existingKos: kos),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit Listing Kos'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Status Kamar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...generatedRooms.map((resident) {
                    final occupied = resident.id.isNotEmpty;
                    final roomHistory =
                        bookings
                            .where(
                              (booking) =>
                                  booking.roomLabel == resident.roomLabel,
                            )
                            .toList()
                          ..sort((a, b) => b.sortKey.compareTo(a.sortKey));
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => RoomDetailPage(
                              kos: kos,
                              roomLabel: resident.roomLabel,
                              currentResident: occupied ? resident : null,
                              history: roomHistory,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: occupied
                                    ? const Color(0xFFEAF5F5)
                                    : const Color(0xFFFFF5DD),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                occupied
                                    ? Icons.person_rounded
                                    : Icons.meeting_room_outlined,
                                color: occupied
                                    ? const Color(0xFF006A6A)
                                    : const Color(0xFFB78103),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resident.roomLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    occupied
                                        ? '${resident.userName} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ sampai ${resident.endDate}'
                                        : 'Kamar kosong dan siap diisi',
                                    style: const TextStyle(
                                      color: Color(0xFF5D6B6B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusBadge(
                              label: occupied ? 'Terisi' : 'Tersedia',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
