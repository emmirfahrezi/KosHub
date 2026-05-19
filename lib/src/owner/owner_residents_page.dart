part of '../../main.dart';

class OwnerResidentsPage extends StatefulWidget {
  const OwnerResidentsPage({
    super.key,
    this.initialTab = 0,
    this.initialQuery = '',
  });

  final int initialTab;
  final String initialQuery;

  @override
  State<OwnerResidentsPage> createState() => _OwnerResidentsPageState();
}

class _OwnerResidentsPageState extends State<OwnerResidentsPage> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab.clamp(0, 3),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Penghuni'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Akan Keluar'),
              Tab(text: 'Riwayat'),
              Tab(text: 'Blacklist'),
            ],
          ),
        ),
        body: StreamBuilder<List<BookingData>>(
          stream: FirestoreService.instance.ownerBookingsStream(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(label: 'Memuat data penghuni...');
            }

            final bookings = snapshot.data ?? const <BookingData>[];
            final active = bookings
                .where((booking) => booking.status == 'Sudah Check-in')
                .toList();
            final leavingSoon = active
                .where(
                  (booking) =>
                      booking.endDateValue.difference(DateTime.now()).inDays <=
                      30,
                )
                .toList();
            final history = bookings
                .where(
                  (booking) =>
                      booking.status == 'Selesai' ||
                      booking.status == 'Dibatalkan',
                )
                .toList();
            final blacklist = bookings
                .where(
                  (booking) => booking.cancelReason == 'Tidak sesuai aturan',
                )
                .toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText:
                            'Cari nama penghuni, kamar, atau status bayar...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildResidents(
                        _filterResidents(active),
                        showActions: true,
                      ),
                      _buildResidents(_filterResidents(leavingSoon)),
                      _buildResidents(_filterResidents(history)),
                      _buildResidents(_filterResidents(blacklist)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResidents(
    List<BookingData> bookings, {
    bool showActions = false,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      children: [
        if (bookings.isEmpty)
          const _EmptyStateCard(
            title: 'Belum ada data penghuni',
            subtitle:
                'Saat ada penghuni aktif, akan keluar, atau riwayat sewa, datanya muncul di sini.',
          )
        else
          ...List.generate(bookings.length, (index) {
            final booking = bookings[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == bookings.length - 1 ? 0 : 14,
              ),
              child: InkWell(
                onTap: () => _openResidentDetail(booking),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFEAF5F5),
                            backgroundImage: booking.userPhoto.isNotEmpty
                                ? NetworkImage(booking.userPhoto)
                                : null,
                            child: booking.userPhoto.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Color(0xFF006A6A),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.userName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${booking.roomLabel} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${booking.kos.name}',
                                  style: const TextStyle(
                                    color: Color(0xFF5D6B6B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StatusBadge(label: booking.paymentStatus),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SummaryRow(
                        label: 'Tanggal masuk',
                        value: booking.startDate,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Tanggal keluar',
                        value: booking.endDate,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'No emergency',
                        value: booking.emergencyContact,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Status booking',
                        value: booking.status,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Pembayaran',
                        value: booking.paymentMethod,
                      ),
                      if (booking.note.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Catatan pemilik/penghuni: ${booking.note}',
                          style: const TextStyle(
                            color: Color(0xFF5D6B6B),
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (showActions) ...[
                        const Divider(height: 24),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (value) =>
                                  _updatePaymentStatus(booking, value),
                              itemBuilder: (context) {
                                return _paymentStatuses
                                    .map(
                                      (status) => PopupMenuItem<String>(
                                        value: status,
                                        child: Text(status),
                                      ),
                                    )
                                    .toList();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF5F5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Ubah Status Bayar',
                                  style: const TextStyle(
                                    color: Color(0xFF006A6A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            FilledButton(
                              onPressed: () => _finishResident(booking),
                              child: const Text('Pindah ke Riwayat'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _updatePaymentStatus(
    BookingData booking,
    String paymentStatus,
  ) async {
    try {
      await FirestoreService.instance.updateBookingPaymentStatus(
        bookingId: booking.id,
        paymentStatus: paymentStatus,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status pembayaran diubah ke $paymentStatus.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }

  Future<void> _finishResident(BookingData booking) async {
    try {
      await FirestoreService.instance.updateBookingStatus(
        booking: booking,
        status: 'Selesai',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penghuni dipindahkan ke riwayat.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }

  List<BookingData> _filterResidents(List<BookingData> bookings) {
    if (_query.isEmpty) {
      return bookings;
    }
    return bookings.where((booking) {
      return booking.userName.toLowerCase().contains(_query) ||
          booking.roomLabel.toLowerCase().contains(_query) ||
          booking.paymentStatus.toLowerCase().contains(_query) ||
          booking.status.toLowerCase().contains(_query);
    }).toList();
  }

  void _openResidentDetail(BookingData booking) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ResidentDetailPage(booking: booking),
      ),
    );
  }
}
