part of '../../main.dart';

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key, required this.booking});

  final BookingData booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Transaksi'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _OwnerDetailHeader(
            title: booking.userName,
            subtitle:
                '${booking.kos.name} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${booking.roomLabel}',
            badge: booking.paymentStatus,
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Rincian transaksi',
            subtitle:
                'Data pembayaran yang bisa dipakai owner untuk approval dan follow up.',
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Tanggal pembayaran',
                  value: booking.paymentUpdatedAt == null
                      ? 'Belum ada'
                      : _formatLongDate(booking.paymentUpdatedAt!),
                ),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Nominal', value: booking.total, bold: true),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Metode pembayaran',
                  value: booking.paymentMethod,
                ),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Status', value: booking.paymentStatus),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Jenis pembayaran',
                  value: booking.paymentProofUrl.isEmpty
                      ? 'Belum ada DP'
                      : 'DP / verifikasi manual',
                ),
                const SizedBox(height: 6),
                const _SummaryRow(label: 'Admin fee', value: 'Rp 0'),
                if (booking.paymentProofUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bukti transfer: ${booking.paymentProofUrl}',
                      style: const TextStyle(
                        color: Color(0xFF006A6A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () async {
                final chatId = await FirestoreService.instance
                    .createOrGetOwnerChat(booking);
                if (!context.mounted) {
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ChatDetailPage(kos: booking.kos, chatId: chatId),
                  ),
                );
              },
              child: const Text('Kirim Reminder'),
            ),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Invoice demo siap diunduh pada versi berikutnya.',
                    ),
                  ),
                );
              },
              child: const Text('Download Invoice'),
            ),
            FilledButton(
              onPressed: booking.paymentStatus == 'Lunas'
                  ? null
                  : () async {
                      try {
                        await FirestoreService.instance
                            .updateBookingPaymentStatus(
                              bookingId: booking.id,
                              paymentStatus: 'Lunas',
                            );
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pembayaran berhasil di-approve.'),
                          ),
                        );
                      } on FirebaseException catch (error) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_firebaseMessage(error))),
                        );
                      }
                    },
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomDetailPage extends StatelessWidget {
  const RoomDetailPage({
    super.key,
    required this.kos,
    required this.roomLabel,
    required this.currentResident,
    required this.history,
  });

  final KosData kos;
  final String roomLabel;
  final BookingData? currentResident;
  final List<BookingData> history;

  @override
  Widget build(BuildContext context) {
    final occupied = currentResident != null && currentResident!.id.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Kamar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.network(
              kos.gallery.isNotEmpty ? kos.gallery.first : '',
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          _OwnerDetailHeader(
            title: roomLabel,
            subtitle: kos.name,
            badge: occupied ? 'Terisi' : 'Tersedia',
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Informasi kamar',
            subtitle: 'Status ruang, penghuni sekarang, dan fasilitas utama.',
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Penghuni sekarang',
                  value: occupied ? currentResident!.userName : 'Belum ada',
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Harga sewa',
                  value: '${_currency(kos.price)} / bulan',
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Status kamar',
                  value: occupied ? 'Aktif ditempati' : 'Siap dipasarkan',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kos.facilities
                        .map((facility) => _SmallPill(label: facility))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Riwayat penghuni',
            subtitle: 'Semua penghuni yang pernah menempati kamar ini.',
            child: history.isEmpty
                ? const Text(
                    'Belum ada riwayat penghuni untuk kamar ini.',
                    style: TextStyle(color: Color(0xFF5D6B6B)),
                  )
                : Column(
                    children: history.map((booking) {
                      return _OwnerListTile(
                        title: booking.userName,
                        subtitle:
                            '${booking.startDate} sampai ${booking.endDate}',
                        trailing: booking.status,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ResidentDetailPage(booking: booking),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => OwnerRegistrationPage(existingKos: kos),
                  ),
                );
              },
              child: const Text('Edit Kamar'),
            ),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Mode nonaktifkan kamar bisa disambung ke backend berikutnya.',
                    ),
                  ),
                );
              },
              child: const Text('Nonaktifkan'),
            ),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kamar ditandai maintenance secara lokal.'),
                  ),
                );
              },
              child: const Text('Maintenance'),
            ),
          ],
        ),
      ),
    );
  }
}
