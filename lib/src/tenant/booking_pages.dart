part of '../../main.dart';

class BookingFormPage extends StatefulWidget {
  const BookingFormPage({super.key, required this.kos});

  final KosData kos;

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  late final TextEditingController _startDateController;
  final _phoneController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _roomController = TextEditingController(text: 'Kamar 01');
  final _noteController = TextEditingController();
  final _proofController = TextEditingController();
  String _selectedDuration = '6 bulan';
  String _selectedPayment = 'Transfer Bank';
  late DateTime _selectedStartDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = DateTime.now().add(const Duration(days: 3));
    _startDateController = TextEditingController(
      text: _formatLongDate(_selectedStartDate),
    );
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _phoneController.dispose();
    _emergencyController.dispose();
    _roomController.dispose();
    _noteController.dispose();
    _proofController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Kamar'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    widget.kos.gallery.isNotEmpty
                        ? widget.kos.gallery.first
                        : '',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.kos.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Kamar Demo',
                        style: TextStyle(color: Color(0xFF5D6B6B)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_currency(widget.kos.price)} / bulan',
                        style: const TextStyle(
                          color: Color(0xFF006A6A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InputField(
            controller: _startDateController,
            label: 'Tanggal mulai sewa',
            hintText: 'Pilih tanggal masuk',
            readOnly: true,
            onTap: _pickStartDate,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _phoneController,
            label: 'Nomor HP',
            hintText: 'Contoh: 081234567890',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _emergencyController,
            label: 'Nomor emergency',
            hintText: 'Contoh: 081298765432',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _roomController,
            label: 'Kamar dipilih',
            hintText: 'Contoh: Kamar 01',
          ),
          const SizedBox(height: 16),
          _SelectCard(
            label: 'Durasi sewa',
            value: _selectedDuration,
            items: const ['1 bulan', '3 bulan', '6 bulan', '12 bulan'],
            onChanged: (value) => setState(() => _selectedDuration = value),
          ),
          const SizedBox(height: 16),
          _SelectCard(
            label: 'Metode pembayaran',
            value: _selectedPayment,
            items: const ['Transfer Bank', 'E-Wallet', 'Virtual Account'],
            onChanged: (value) => setState(() => _selectedPayment = value),
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _noteController,
            label: 'Catatan untuk pemilik',
            hintText: 'Contoh: Saya ingin survei dulu sebelum masuk',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _proofController,
            label: 'URL bukti pembayaran DP',
            hintText: 'Tempel link bukti transfer DP',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5DD),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Info Booking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.kos.approvalMode == 'Auto Approval'
                      ? 'Kos ini memakai Auto Approval. Booking otomatis dikonfirmasi kalau bukti DP sudah diisi.'
                      : 'Kos ini memakai Manual Approval. Pemilik akan review booking dan bukti DP lebih dulu.',
                  style: const TextStyle(
                    color: Color(0xFF735B00),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Pembayaran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                _SummaryRow(
                  label: 'Harga sewa',
                  value:
                      '${_currency(widget.kos.price)} x ${_selectedDuration.split(' ').first}',
                ),
                const SizedBox(height: 8),
                const _SummaryRow(label: 'Biaya layanan', value: 'Rp 0'),
                const Divider(height: 24),
                _SummaryRow(
                  label: 'Total',
                  value: _currency(
                    _totalPrice(widget.kos.price, _selectedDuration),
                  ),
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton(
          onPressed: _saving ? null : _createBooking,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF006A6A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Konfirmasi Booking'),
        ),
      ),
    );
  }

  Future<void> _createBooking() async {
    final phone = _phoneController.text.trim();
    final emergency = _emergencyController.text.trim();
    final roomLabel = _roomController.text.trim();
    final proof = _proofController.text.trim();

    if (widget.kos.availableRooms <= 0) {
      _showLightDialog(
        context,
        title: 'Kamar tidak tersedia',
        message: 'Kos ini sedang penuh dan belum bisa dibooking.',
      );
      return;
    }
    if (phone.isEmpty ||
        emergency.isEmpty ||
        roomLabel.isEmpty ||
        proof.isEmpty) {
      _showLightDialog(
        context,
        title: 'Data belum lengkap',
        message:
            'Tanggal masuk, nomor HP, kontak darurat, kamar, dan bukti DP wajib diisi.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirestoreService.instance.createBooking(
        kos: widget.kos,
        durationLabel: _selectedDuration,
        paymentMethod: _selectedPayment,
        startDate: _selectedStartDate,
        startDateLabel: _startDateController.text.trim(),
        phoneNumber: phone,
        emergencyContact: emergency,
        roomLabel: roomLabel,
        note: _noteController.text.trim(),
        paymentProofUrl: proof,
      );
      if (!mounted) {
        return;
      }
      await _showLightDialog(
        context,
        title: 'Booking berhasil',
        message:
            'Permintaan booking sudah dikirim. Silakan cek statusnya di menu Booking.',
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      _showLightDialog(
        context,
        title: 'Booking belum berhasil',
        message: _firebaseMessage(error),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showLightDialog(
        context,
        title: 'Booking gagal dibuat',
        message: 'Coba lagi dalam beberapa saat.',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (selectedDate == null) {
      return;
    }

    setState(() {
      _selectedStartDate = selectedDate;
      _startDateController.text = _formatLongDate(selectedDate);
    });
  }
}

class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Booking'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<List<BookingData>>(
        stream: FirestoreService.instance.userBookingsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen(label: 'Memuat booking...');
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Booking gagal dimuat',
                subtitle: _streamErrorMessage(snapshot.error),
              ),
            );
          }

          final bookings = snapshot.data ?? const <BookingData>[];
          if (bookings.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Belum ada booking',
                subtitle:
                    'Saat kamu melakukan booking dari detail kos, data akan masuk ke Firestore dan muncul di sini.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => BookingDetailPage(booking: booking),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.kos.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _StatusBadge(label: booking.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(label: 'Kamar', value: booking.roomLabel),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Mulai sewa',
                        value: booking.startDate,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Durasi',
                        value: booking.durationLabel,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Status pembayaran',
                        value: booking.paymentStatus,
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        label: 'Total',
                        value: booking.total,
                        bold: true,
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

class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({super.key, required this.booking});

  final BookingData booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Booking'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    booking.kos.gallery.first,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.kos.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        booking.kos.address,
                        style: const TextStyle(color: Color(0xFF5D6B6B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Informasi booking',
            subtitle: 'Ringkasan kamar, durasi, dan pembayaran.',
            child: Column(
              children: [
                _SummaryRow(label: 'Kamar', value: booking.roomLabel),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Tanggal masuk', value: booking.startDate),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Durasi sewa', value: booking.durationLabel),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Tanggal selesai', value: booking.endDate),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Status booking', value: booking.status),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Status pembayaran',
                  value: booking.paymentStatus,
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Metode pembayaran',
                  value: booking.paymentMethod,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: 'Total harga',
                  value: booking.total,
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Catatan & bukti',
            subtitle: 'Informasi tambahan dari penyewa dan pemilik.',
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Catatan penyewa',
                  value: booking.note.isEmpty ? '-' : booking.note,
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Bukti DP',
                  value: booking.paymentProofUrl.isEmpty
                      ? 'Belum ada'
                      : booking.paymentProofUrl,
                ),
                if (booking.cancelReason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _SummaryRow(
                    label: 'Alasan pembatalan',
                    value: booking.cancelReason,
                  ),
                ],
                if (booking.ownerNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: booking.ownerNotes
                          .map(
                            (note) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ $note',
                                style: const TextStyle(
                                  color: Color(0xFF5D6B6B),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          )
                          .toList(),
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
                try {
                  final chatId = await FirestoreService.instance
                      .createOrGetChat(booking.kos);
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
                } on FirebaseException catch (error) {
                  if (!context.mounted) {
                    return;
                  }
                  _showLightDialog(
                    context,
                    title: 'Chat belum bisa dibuka',
                    message: _firebaseMessage(error),
                  );
                }
              },
              child: const Text('Chat Pemilik'),
            ),
            OutlinedButton(
              onPressed: booking.paymentProofUrl.isEmpty
                  ? null
                  : () {
                      _showLightDialog(
                        context,
                        title: 'Bukti Pembayaran',
                        message: booking.paymentProofUrl,
                      );
                    },
              child: const Text('Lihat Bukti'),
            ),
            FilledButton(
              onPressed: booking.status == 'Menunggu Konfirmasi'
                  ? () => _confirmCancelBooking(context, booking)
                  : null,
              child: const Text('Batalkan Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
