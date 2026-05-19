part of '../../main.dart';

class ResidentDetailPage extends StatelessWidget {
  const ResidentDetailPage({super.key, required this.booking});

  final BookingData booking;

  @override
  Widget build(BuildContext context) {
    final dueDate = _nextBillingDueDate(booking.startDateValue, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Penghuni'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _OwnerDetailHeader(
            title: booking.userName,
            subtitle:
                '${booking.kos.name} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${booking.roomLabel}',
            badge: booking.paymentStatus,
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
            subtitle:
                'Semua status aktif dan tanggal penting dalam satu tempat.',
            child: Column(
              children: [
                _SummaryRow(label: 'Nomor kamar', value: booking.roomLabel),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Tanggal masuk', value: booking.startDate),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Durasi sewa', value: booking.durationLabel),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Tanggal jatuh tempo',
                  value: _formatLongDate(dueDate),
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Status pembayaran',
                  value: booking.paymentStatus,
                ),
              ],
            ),
          ),
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
                      child: Text('ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ $note'),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
                _TimelineTile(
                  title: 'Jatuh tempo berikutnya',
                  subtitle: _formatLongDate(dueDate),
                ),
                if (booking.paymentUpdatedAt != null)
                  _TimelineTile(
                    title: 'Update pembayaran',
                    subtitle: _formatLongDate(booking.paymentUpdatedAt!),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              OutlinedButton.icon(
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
                icon: const Icon(Icons.chat_rounded),
                label: const Text('Chat'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          OwnerTransactionsPage(initialQuery: booking.userName),
                    ),
                  );
                },
                child: const Text('Lihat Transaksi'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => _showAddNoteSheet(context),
                child: const Text('Tambah Catatan'),
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

  Future<void> _showAddNoteSheet(BuildContext context) async {
    final controller = TextEditingController();
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah catatan owner',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Sering telat bayar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  child: const Text('Simpan Catatan'),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();

    if (note == null || note.isEmpty) {
      return;
    }

    try {
      await FirestoreService.instance.addOwnerNote(
        bookingId: booking.id,
        note: note,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Catatan owner disimpan.')));
    } on FirebaseException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
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
      await FirestoreService.instance.extendBooking(
        booking: booking,
        additionalMonths: selected,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sewa diperpanjang $selected bulan.')),
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }

  Future<void> _finishResident(BuildContext context) async {
    try {
      await FirestoreService.instance.updateBookingStatus(
        booking: booking,
        status: 'Selesai',
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Penghuni dikeluarkan.')));
    } on FirebaseException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }
}
