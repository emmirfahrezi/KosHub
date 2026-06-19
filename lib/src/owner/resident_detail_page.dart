part of '../../main.dart';

class ResidentDetailPage extends StatelessWidget {
  const ResidentDetailPage({super.key, required this.booking});

  final BookingData booking;

  @override
  Widget build(BuildContext context) {
    final isActiveResident = booking.status == 'Sudah Check-in';
    final isHistory =
        booking.status == 'Selesai' || booking.status == 'Dibatalkan';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isHistory ? 'Detail Riwayat' : 'Detail Penghuni'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, isActiveResident ? 120 : 28),
        children: [
          _OwnerDetailHeader(
            title: booking.userName,
            subtitle: '${booking.kos.name} - ${booking.roomLabel}',
            badge: booking.status,
            photoUrl: booking.userPhoto,
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Informasi pribadi',
            subtitle:
                'Ringkasan data penghuni yang bisa dipakai owner untuk operasional harian.',
            child: Column(
              children: [
                _SummaryRow(label: 'Gender', value: '-'),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Nomor HP', value: booking.userPhone),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Email', value: booking.userEmail),
                const SizedBox(height: 6),
                _SummaryRow(label: 'KTP', value: '-'),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Kontak darurat',
                  value: booking.emergencyContact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Informasi sewa',
            subtitle: isHistory
                ? 'Ringkasan masa sewa yang sudah berakhir.'
                : 'Semua status aktif dan tanggal penting dalam satu tempat.',
            child: Column(
              children: [
                _SummaryRow(label: 'Nomor kamar', value: booking.roomLabel),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Tanggal masuk', value: booking.startDate),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Tanggal keluar', value: booking.endDate),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Durasi sewa', value: booking.durationLabel),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Status penghuni', value: booking.status),
              ],
            ),
          ),
          if (!isHistory) ...[
            const SizedBox(height: 16),
            _OwnerSectionCard(
              title: 'Catatan penghuni',
              subtitle:
                  'Catatan dari penyewa dan owner tersimpan agar histori penghuni tetap kebaca.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.note.isEmpty
                        ? 'Belum ada catatan dari penyewa.'
                        : booking.note,
                    style: const TextStyle(
                      color: Color(0xFF5D6B6B),
                      height: 1.45,
                    ),
                  ),
                  if (booking.ownerNotes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...booking.ownerNotes.map(
                      (note) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('- $note'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Timeline penghuni',
            subtitle:
                'Riwayat singkat biar semua interaksi penghuni tetap ter-track.',
            child: Column(
              children: [
                _TimelineTile(
                  title: 'Booking kamar',
                  subtitle: _formatLongDate(booking.sortKey),
                ),
                _TimelineTile(
                  title: 'Check-in terjadwal',
                  subtitle: booking.startDate,
                ),
                if (isHistory)
                  _TimelineTile(
                    title: booking.status == 'Dibatalkan'
                        ? 'Booking dibatalkan'
                        : 'Masa sewa selesai',
                    subtitle:
                        booking.status == 'Dibatalkan' &&
                            booking.cancelReason.isNotEmpty
                        ? booking.cancelReason
                        : booking.endDate,
                  ),
              ],
            ),
          ),
          if (isHistory) ...[
            const SizedBox(height: 16),
            _OwnerSectionCard(
              title: 'Data riwayat',
              subtitle: 'Masa sewa ini sudah ditutup.',
              child: const Text(
                'Data hanya dapat dilihat. Kamar sudah tidak terikat dengan penghuni ini dan dapat digunakan untuk booking berikutnya.',
                style: TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
              ),
            ),
          ],
        ],
      ),
      bottomSheet: !isActiveResident
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final chatId = await SupabaseService.instance
                            .createOrGetOwnerChat(booking);
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ChatDetailPage(
                              kos: booking.kos,
                              chatId: chatId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text('Chat'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => _showExtendSheet(context),
                      child: const Text('Perpanjang'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => _finishResident(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF9F4035),
                      ),
                      child: const Text('Keluarkan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _showExtendSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perpanjang sewa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ...const [1, 3, 6].map((months) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Tambah $months bulan'),
                    onTap: () => Navigator.pop(context, months),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    try {
      await SupabaseService.instance.extendBooking(
        booking: booking,
        additionalMonths: selected,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sewa diperpanjang $selected bulan.')),
      );
    } on SupabaseAppException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_supabaseMessage(error))));
    }
  }

  Future<void> _finishResident(BuildContext context) async {
    if (!await _confirmFinishResident(context, booking) || !context.mounted) {
      return;
    }
    try {
      await SupabaseService.instance.updateBookingStatus(
        booking: booking,
        status: 'Selesai',
      );
      if (!context.mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Penghuni dikeluarkan dan dipindahkan ke riwayat.'),
        ),
      );
    } on SupabaseAppException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_supabaseMessage(error))));
    }
  }
}
