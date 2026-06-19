part of '../../main.dart';

class OwnerBookingDetailPage extends StatelessWidget {
  const OwnerBookingDetailPage({super.key, required this.booking});

  final BookingData booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Booking'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _OwnerDetailHeader(
            title: booking.userName,
            subtitle: '${booking.kos.name} - ${booking.roomLabel}',
            badge: booking.status,
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Data calon penghuni',
            subtitle: 'Informasi dasar sebelum pemilik memutuskan booking.',
            child: Column(
              children: [
                _SummaryRow(label: 'Nomor HP', value: booking.userPhone),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Email', value: booking.userEmail),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Kontak darurat',
                  value: booking.emergencyContact,
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Tanggal booking',
                  value: _formatLongDate(booking.sortKey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Informasi booking',
            subtitle: 'Rangkuman booking, pembayaran, dan bukti DP.',
            child: Column(
              children: [
                _SummaryRow(label: 'Tanggal masuk', value: booking.startDate),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Durasi sewa', value: booking.durationLabel),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Status bayar',
                  value: booking.paymentStatus,
                ),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Metode', value: booking.paymentMethod),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Total', value: booking.total, bold: true),
                if (booking.note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Catatan user: ${booking.note}',
                      style: const TextStyle(
                        color: Color(0xFF5D6B6B),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
                if (booking.paymentProofUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ImageProofPreview(
                    title: 'Bukti pembayaran',
                    imageUrl: booking.paymentProofUrl,
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
          children: _buildActions(context),
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[
      OutlinedButton.icon(
        onPressed: () async {
          final chatId = await SupabaseService.instance.createOrGetOwnerChat(
            booking,
          );
          if (!context.mounted) {
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ChatDetailPage(kos: booking.kos, chatId: chatId),
            ),
          );
        },
        icon: const Icon(Icons.chat_rounded),
        label: const Text('Chat User'),
      ),
    ];

    if (booking.status == 'Menunggu Konfirmasi') {
      actions.add(
        FilledButton(
          onPressed: () => _updateBookingStatus(context, 'Sudah Dikonfirmasi'),
          child: const Text('Terima'),
        ),
      );
      actions.add(
        FilledButton.tonal(
          onPressed: () => _rejectBooking(context),
          child: const Text('Tolak'),
        ),
      );
    } else if (booking.status == 'Sudah Dikonfirmasi') {
      actions.add(
        FilledButton(
          onPressed: () => _updateBookingStatus(context, 'Sudah Check-in'),
          child: const Text('Tandai Check-in'),
        ),
      );
    } else if (booking.status == 'Sudah Check-in') {
      actions.add(
        FilledButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ResidentDetailPage(booking: booking),
              ),
            );
          },
          child: const Text('Lihat Penghuni'),
        ),
      );
    }

    return actions;
  }

  Future<void> _updateBookingStatus(BuildContext context, String status) async {
    try {
      await SupabaseService.instance.updateBookingStatus(
        booking: booking,
        status: status,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status booking diubah menjadi $status.')),
      );
      Navigator.pop(context, true);
    } on SupabaseAppException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_supabaseMessage(error))));
    }
  }

  Future<void> _rejectBooking(BuildContext context) async {
    final reason = await showModalBottomSheet<String>(
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
                  'Pilih alasan pembatalan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ..._cancelReasons.map((reason) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(reason),
                    onTap: () => Navigator.pop(context, reason),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (reason == null) {
      return;
    }

    try {
      await SupabaseService.instance.updateBookingStatus(
        booking: booking,
        status: 'Dibatalkan',
        cancelReason: reason,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking dibatalkan: $reason')));
      Navigator.pop(context, true);
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
