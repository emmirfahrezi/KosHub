part of '../../main.dart';

class BookingFormPage extends StatefulWidget {
  const BookingFormPage({super.key, required this.kos});

  final KosData kos;

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _picker = ImagePicker();
  late final TextEditingController _startDateController;
  Future<_OwnerTransferInfo>? _transferInfoFuture;
  final _phoneController = TextEditingController();
  final _roomController = TextEditingController(
    text: 'Dipilih otomatis saat booking dikonfirmasi',
  );
  final _noteController = TextEditingController();
  final _proofController = TextEditingController();
  Uint8List? _selectedProofBytes;
  String? _selectedProofName;
  String _selectedDuration = '6 bulan';
  String _selectedPayment = 'Transfer Bank';
  late DateTime _selectedStartDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = DateTime.now().add(const Duration(days: 3));
    _transferInfoFuture = _fetchOwnerTransferInfo();
    _startDateController = TextEditingController(
      text: _formatLongDate(_selectedStartDate),
    );
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _phoneController.dispose();
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                      Text(
                        '${widget.kos.availableRooms} kamar tersedia',
                        style: const TextStyle(color: Color(0xFF5D6B6B)),
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
            controller: _roomController,
            label: 'Nomor kamar',
            hintText: 'Dipilih otomatis sesuai kamar yang masih kosong',
            readOnly: true,
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
            items: const ['Transfer Bank'],
            onChanged: (value) => setState(() => _selectedPayment = value),
          ),
          const SizedBox(height: 16),
          FutureBuilder<_OwnerTransferInfo>(
            future: _ensureTransferInfoFuture(),
            builder: (context, snapshot) {
              final transferInfo = snapshot.data;
              return _buildTransferInfoCard(
                latestKos: transferInfo?.latestKos,
                ownerProfile: transferInfo?.ownerProfile,
                isLoading:
                    snapshot.connectionState == ConnectionState.waiting &&
                    transferInfo == null,
              );
            },
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _noteController,
            label: 'Catatan untuk pemilik',
            hintText: 'Contoh: Saya ingin survei dulu sebelum masuk',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _UploadImageCard(
            label: 'Bukti pembayaran DP',
            hint:
                'Upload bukti transfer DP dari galeri setelah transfer ke rekening pemilik di atas.',
            imageUrl: _proofController.text.trim(),
            imageBytes: _selectedProofBytes,
            fileName: _selectedProofName,
            onPick: _pickProofImage,
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _createBooking,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF006A6A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
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
        ],
      ),
    );
  }

  Widget _buildTransferInfoCard({
    KosData? latestKos,
    AppUserData? ownerProfile,
    bool isLoading = false,
  }) {
    final bankAccount = _ownerBankAccount(
      latestKos: latestKos,
      ownerProfile: ownerProfile,
    );
    final ownerName = latestKos?.ownerName ?? widget.kos.ownerName;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9E9F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Info Transfer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (isLoading && bankAccount == null) ...[
            const Text(
              'Memuat rekening penerima...',
              style: TextStyle(
                color: Color(0xFF5D6B6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (bankAccount == null) ...[
            const Text(
              'Pemilik kos belum mengisi rekening penerima.',
              style: TextStyle(
                color: Color(0xFF9F4035),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Minta pemilik melengkapi nama bank, nomor rekening, dan atas nama terlebih dulu sebelum upload bukti transfer.',
              style: TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
            ),
          ] else ...[
            _SummaryRow(label: 'Pemilik', value: ownerName),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Rekening penerima', value: bankAccount),
            const SizedBox(height: 10),
            const Text(
              'Pastikan nomor rekening dan nama penerima sesuai sebelum upload bukti transfer DP.',
              style: TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickProofImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedProofBytes = bytes;
      _selectedProofName = file.name;
    });
  }

  Future<void> _createBooking() async {
    final phone = _phoneController.text.trim();
    var proof = _proofController.text.trim();
    final hasProof = _selectedProofBytes != null || proof.isNotEmpty;
    final transferInfo = await _ensureTransferInfoFuture();
    if (!mounted) {
      return;
    }
    final ownerBankAccount = _ownerBankAccount(
      latestKos: transferInfo.latestKos,
      ownerProfile: transferInfo.ownerProfile,
    );
    final availableRooms =
        transferInfo.latestKos?.availableRooms ?? widget.kos.availableRooms;

    if (availableRooms <= 0) {
      _showLightDialog(
        context,
        title: 'Kamar tidak tersedia',
        message: 'Kos ini sedang penuh dan belum bisa dibooking.',
      );
      return;
    }
    if (ownerBankAccount == null) {
      _showLightDialog(
        context,
        title: 'Rekening belum tersedia',
        message:
            'Pemilik kos belum mengisi rekening penerima. Minta pemilik melengkapi data transfer dulu sebelum booking.',
      );
      return;
    }
    if (phone.isEmpty || !hasProof) {
      _showLightDialog(
        context,
        title: 'Data belum lengkap',
        message: 'Tanggal masuk, nomor HP, dan bukti DP wajib diisi.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = SupabaseAuth.instance.currentUser!;
      if (_selectedProofBytes != null && _selectedProofName != null) {
        proof = await SupabaseService.instance.uploadPublicImage(
          user: user,
          bytes: _selectedProofBytes!,
          fileName: _selectedProofName!,
          folder: 'booking-proofs',
        );
        _proofController.text = proof;
      }
      await SupabaseService.instance.createBooking(
        kos: widget.kos,
        durationLabel: _selectedDuration,
        paymentMethod: _selectedPayment,
        startDate: _selectedStartDate,
        startDateLabel: _startDateController.text.trim(),
        phoneNumber: phone,
        roomLabel: '',
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
            'Permintaan booking sudah dikirim. Nomor kamar akan dipilih otomatis dan bisa dicek di menu Booking.',
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    } on SupabaseAppException catch (error) {
      if (!mounted) {
        return;
      }
      _showLightDialog(
        context,
        title: 'Booking belum berhasil',
        message: _supabaseMessage(error),
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

  Future<_OwnerTransferInfo> _fetchOwnerTransferInfo() async {
    KosData? latestKos;
    AppUserData? ownerProfile;

    try {
      latestKos = await SupabaseService.instance.fetchKosById(widget.kos.id);
    } catch (_) {}

    if (latestKos == null) {
      try {
        latestKos = await SupabaseService.instance.fetchOwnerKosByOwnerId(
          widget.kos.ownerId,
        );
      } catch (_) {}
    }

    try {
      ownerProfile = await SupabaseService.instance.fetchUserProfile(
        widget.kos.ownerId,
      );
    } catch (_) {}

    return _OwnerTransferInfo(latestKos: latestKos, ownerProfile: ownerProfile);
  }

  Future<_OwnerTransferInfo> _ensureTransferInfoFuture() {
    return _transferInfoFuture ??= _fetchOwnerTransferInfo();
  }

  String? _ownerBankAccount({KosData? latestKos, AppUserData? ownerProfile}) {
    final latestListingValue = latestKos?.ownerBankAccount.trim() ?? '';
    if (latestListingValue.isNotEmpty && latestListingValue != 'Belum diisi') {
      return latestListingValue;
    }
    final listingValue = widget.kos.ownerBankAccount.trim();
    if (listingValue.isNotEmpty && listingValue != 'Belum diisi') {
      return listingValue;
    }
    final profileValue = ownerProfile?.bankAccountLabel.trim() ?? '';
    if (profileValue.isNotEmpty && profileValue != 'Belum diisi') {
      return profileValue;
    }
    return null;
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

class _OwnerTransferInfo {
  const _OwnerTransferInfo({this.latestKos, this.ownerProfile});

  final KosData? latestKos;
  final AppUserData? ownerProfile;
}

class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Booking'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<List<BookingData>>(
        stream: SupabaseService.instance.userBookingsStream(user.id),
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
                    'Booking yang kamu buat dari detail kos akan muncul di sini.',
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
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: booking.kos.gallery.isEmpty
                            ? Container(
                                width: 68,
                                height: 68,
                                color: const Color(0xFFE8EFEF),
                                child: const Icon(
                                  Icons.apartment_rounded,
                                  color: Color(0xFF5D6B6B),
                                ),
                              )
                            : Image.network(
                                booking.kos.gallery.first,
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 68,
                                  height: 68,
                                  color: const Color(0xFFE8EFEF),
                                  child: const Icon(
                                    Icons.apartment_rounded,
                                    color: Color(0xFF5D6B6B),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.kos.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${booking.roomLabel} - ${booking.startDate}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF5D6B6B),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _StatusBadge(label: booking.status),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF7B8A8A),
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

class BookingDetailPage extends StatefulWidget {
  const BookingDetailPage({super.key, required this.booking});

  final BookingData booking;

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  late Future<ReviewData?> _reviewFuture;

  @override
  void initState() {
    super.initState();
    _reviewFuture = SupabaseService.instance.fetchBookingReview(
      widget.booking.id,
    );
  }

  void _reloadReview() {
    setState(() {
      _reviewFuture = SupabaseService.instance.fetchBookingReview(
        widget.booking.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isHistory =
        booking.status == 'Selesai' || booking.status == 'Dibatalkan';

    return Scaffold(
      appBar: AppBar(
        title: Text(isHistory ? 'Detail Riwayat' : 'Detail Booking'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          booking.status == 'Selesai' || !isHistory ? 120 : 28,
        ),
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
                  child: booking.kos.gallery.isEmpty
                      ? Container(
                          width: 88,
                          height: 88,
                          color: const Color(0xFFE8EFEF),
                          child: const Icon(
                            Icons.apartment_rounded,
                            color: Color(0xFF5D6B6B),
                          ),
                        )
                      : Image.network(
                          booking.kos.gallery.first,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 88,
                            height: 88,
                            color: const Color(0xFFE8EFEF),
                            child: const Icon(
                              Icons.apartment_rounded,
                              color: Color(0xFF5D6B6B),
                            ),
                          ),
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
            title: isHistory ? 'Ringkasan sewa' : 'Informasi booking',
            subtitle: isHistory
                ? 'Informasi utama dari riwayat booking ini.'
                : 'Ringkasan kamar, durasi, dan pembayaran.',
            child: Column(
              children: [
                _SummaryRow(label: 'Kamar', value: booking.roomLabel),
                const SizedBox(height: 6),
                if (isHistory)
                  _SummaryRow(
                    label: 'Periode sewa',
                    value: '${booking.startDate} - ${booking.endDate}',
                  )
                else ...[
                  _SummaryRow(label: 'Tanggal masuk', value: booking.startDate),
                  const SizedBox(height: 6),
                  _SummaryRow(
                    label: 'Durasi sewa',
                    value: booking.durationLabel,
                  ),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'Tanggal selesai', value: booking.endDate),
                ],
                const SizedBox(height: 6),
                _SummaryRow(label: 'Status booking', value: booking.status),
                if (isHistory && booking.cancelReason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _SummaryRow(
                    label: 'Alasan pembatalan',
                    value: booking.cancelReason,
                  ),
                ],
                if (!isHistory) ...[
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
                ],
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
          if (booking.status == 'Selesai') ...[
            FutureBuilder<ReviewData?>(
              future: _reviewFuture,
              builder: (context, snapshot) {
                final review = snapshot.data;
                return _OwnerSectionCard(
                  title: 'Ulasan kamu',
                  subtitle:
                      'Rating hanya bisa diberikan setelah booking selesai.',
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Text(
                          'Memuat ulasan...',
                          style: TextStyle(color: Color(0xFF5D6B6B)),
                        )
                      : review == null
                      ? const Text(
                          'Belum ada rating untuk kos ini dari booking kamu.',
                          style: TextStyle(color: Color(0xFF5D6B6B)),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ReviewStarsDisplay(rating: review.rating),
                            if (review.comment.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                review.comment,
                                style: const TextStyle(
                                  color: Color(0xFF5D6B6B),
                                  height: 1.45,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              'Diperbarui ${_formatLongDate(review.updatedAt)}',
                              style: const TextStyle(
                                color: Color(0xFF839090),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          if (!isHistory)
            _OwnerSectionCard(
              title: 'Catatan & bukti',
              subtitle: 'Informasi tambahan dari penyewa dan pemilik.',
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Catatan penyewa',
                    value: booking.note.isEmpty ? '-' : booking.note,
                  ),
                  if (booking.paymentProofUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ImageProofPreview(
                      title: 'Bukti DP',
                      imageUrl: booking.paymentProofUrl,
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    const _SummaryRow(label: 'Bukti DP', value: 'Belum ada'),
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
                                  '- $note',
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
      bottomSheet: booking.status == 'Dibatalkan'
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (booking.status == 'Selesai')
                      FutureBuilder<ReviewData?>(
                        future: _reviewFuture,
                        builder: (context, snapshot) {
                          final review = snapshot.data;
                          return _ActionBarButton(
                            label: review == null
                                ? 'Beri Rating'
                                : 'Ubah Rating',
                            icon: Icons.star_outline_rounded,
                            onPressed:
                                snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? null
                                : () => _openReviewSheet(
                                    context,
                                    booking: booking,
                                    existingReview: review,
                                  ),
                          );
                        },
                      ),
                    if (!isHistory) ...[
                      _ActionBarButton(
                        label: 'Chat Pemilik',
                        icon: Icons.chat_bubble_outline_rounded,
                        onPressed: () async {
                          try {
                            final chatId = await SupabaseService.instance
                                .createOrGetChat(booking.kos);
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
                          } on SupabaseAppException catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            _showLightDialog(
                              context,
                              title: 'Chat belum bisa dibuka',
                              message: _supabaseMessage(error),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _ActionBarButton(
                        label: 'Lihat Bukti',
                        icon: Icons.photo_library_outlined,
                        onPressed: booking.paymentProofUrl.isEmpty
                            ? null
                            : () {
                                _showImagePreviewDialog(
                                  context,
                                  title: 'Bukti Pembayaran',
                                  imageUrl: booking.paymentProofUrl,
                                );
                              },
                      ),
                      const SizedBox(height: 10),
                      _ActionBarButton(
                        label: 'Batalkan Booking',
                        icon: Icons.cancel_outlined,
                        variant: _ActionBarButtonVariant.filled,
                        onPressed: booking.status == 'Menunggu Konfirmasi'
                            ? () => _confirmCancelBooking(context, booking)
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _openReviewSheet(
    BuildContext context, {
    required BookingData booking,
    ReviewData? existingReview,
  }) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) =>
            _ReviewFormPage(booking: booking, existingReview: existingReview),
      ),
    );

    if (!mounted || submitted != true) {
      return;
    }

    _reloadReview();
    ScaffoldMessenger.of(this.context).showSnackBar(
      const SnackBar(
        content: Text('Rating tersimpan. Terima kasih atas ulasan kamu.'),
      ),
    );
  }
}

class _ReviewFormPage extends StatefulWidget {
  const _ReviewFormPage({required this.booking, this.existingReview});

  final BookingData booking;
  final ReviewData? existingReview;

  @override
  State<_ReviewFormPage> createState() => _ReviewFormPageState();
}

class _ReviewFormPageState extends State<_ReviewFormPage> {
  late final TextEditingController _commentController;
  late int _selectedRating;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.existingReview?.rating ?? 5;
    _commentController = TextEditingController(
      text: widget.existingReview?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReview != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isEditing ? 'Ubah Rating' : 'Beri Rating'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.booking.kos.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bagikan pengalamanmu setelah masa sewa selesai.',
            style: TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
          ),
          const SizedBox(height: 24),
          const Text('Rating', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _ReviewStarsInput(
            rating: _selectedRating,
            onChanged: (value) => setState(() => _selectedRating = value),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Komentar (opsional)',
              hintText: 'Contoh: Kamarnya bersih dan pemilik responsif.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isEditing ? 'Simpan Perubahan' : 'Kirim Rating'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await SupabaseService.instance.submitBookingReview(
        booking: widget.booking,
        rating: _selectedRating,
        comment: _commentController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } on SupabaseAppException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_supabaseMessage(error))));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating belum tersimpan. Silakan coba lagi.'),
        ),
      );
    }
  }
}

class _ReviewStarsDisplay extends StatelessWidget {
  const _ReviewStarsDisplay({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFF4B400),
          size: 24,
        );
      }),
    );
  }
}

class _ReviewStarsInput extends StatelessWidget {
  const _ReviewStarsInput({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final value = index + 1;
        return IconButton(
          onPressed: () => onChanged(value),
          icon: Icon(
            value <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: const Color(0xFFF4B400),
            size: 30,
          ),
        );
      }),
    );
  }
}
