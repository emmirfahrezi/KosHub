part of '../../main.dart';

bool _roomBlocksAvailability(String status) =>
    status != 'Dibatalkan' && status != 'Selesai';

bool _roomIsOccupied(String status) => status == 'Sudah Check-in';

String _roomAvailabilityLabel(BookingData? booking) {
  if (booking == null || booking.id.isEmpty) {
    return 'Tersedia';
  }
  return _roomIsOccupied(booking.status) ? 'Terisi' : 'Dibooking';
}

String _roomAvailabilitySubtitle(BookingData? booking) {
  if (booking == null || booking.id.isEmpty) {
    return 'Kamar kosong dan siap diisi';
  }
  if (_roomIsOccupied(booking.status)) {
    return '${booking.userName} - sampai ${booking.endDate}';
  }
  return '${booking.userName} - masuk ${booking.startDate}';
}

Map<String, BookingData> _activeBookingsByRoom(
  List<BookingData> bookings,
  List<String> roomLabels,
) {
  final assignments = <String, BookingData>{};
  final unassigned = <BookingData>[];
  final activeBookings =
      bookings
          .where((booking) => _roomBlocksAvailability(booking.status))
          .toList()
        ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

  for (final booking in activeBookings) {
    final roomLabel = booking.roomLabel.trim();
    if (roomLabels.contains(roomLabel) && !assignments.containsKey(roomLabel)) {
      assignments[roomLabel] = booking;
    } else {
      unassigned.add(booking);
    }
  }

  final emptyRooms = roomLabels
      .where((roomLabel) => !assignments.containsKey(roomLabel))
      .iterator;
  for (final booking in unassigned) {
    if (!emptyRooms.moveNext()) {
      break;
    }
    assignments[emptyRooms.current] = booking;
  }
  return assignments;
}

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

            final bookings = (bookingsSnapshot.data ?? const <BookingData>[])
                .where((booking) => booking.kos.id == kos.id)
                .toList();
            final activeRoomBookings = bookings
                .where((booking) => _roomBlocksAvailability(booking.status))
                .toList();
            final totalRooms = math.max(
              kos.totalRooms,
              activeRoomBookings.length,
            );
            final roomLabels = <String>[
              ...List.generate(
                totalRooms,
                (index) => 'Kamar ${(index + 1).toString().padLeft(2, '0')}',
              ),
            ];
            final currentBookingsByRoom = _activeBookingsByRoom(
              bookings,
              roomLabels,
            );
            final currentRoomBookings = currentBookingsByRoom.values.toList();
            final occupiedCount = currentRoomBookings
                .where((booking) => _roomIsOccupied(booking.status))
                .length;
            final bookedCount = currentRoomBookings.length - occupiedCount;
            final availableCount = math.max(
              roomLabels.length - currentRoomBookings.length,
              0,
            );

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
                          '${kos.area} - ${kos.address}',
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
                            _SmallPill(label: '$availableCount tersedia'),
                            _SmallPill(label: '$bookedCount dibooking'),
                            _SmallPill(label: '$occupiedCount terisi'),
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
                          label: const Text('Edit Kos'),
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
                  ...roomLabels.map((roomLabel) {
                    final currentBooking = currentBookingsByRoom[roomLabel];
                    final occupied =
                        currentBooking != null &&
                        _roomIsOccupied(currentBooking.status);
                    final booked =
                        currentBooking != null &&
                        currentBooking.id.isNotEmpty &&
                        !occupied;
                    final roomHistory =
                        bookings
                            .where(
                              (booking) =>
                                  booking.roomLabel == roomLabel ||
                                  booking.id == currentBooking?.id,
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
                              roomLabel: roomLabel,
                              currentResident: currentBooking,
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
                                    : booked
                                    ? const Color(0xFFEAF1FF)
                                    : const Color(0xFFFFF5DD),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                occupied
                                    ? Icons.person_rounded
                                    : booked
                                    ? Icons.schedule_rounded
                                    : Icons.meeting_room_outlined,
                                color: occupied
                                    ? const Color(0xFF006A6A)
                                    : booked
                                    ? const Color(0xFF35589F)
                                    : const Color(0xFFB78103),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    roomLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _roomAvailabilitySubtitle(currentBooking),
                                    style: const TextStyle(
                                      color: Color(0xFF5D6B6B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusBadge(
                              label: _roomAvailabilityLabel(currentBooking),
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
