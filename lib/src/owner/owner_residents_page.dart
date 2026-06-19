part of '../../main.dart';

int _leaseDaysRemaining(DateTime endDate) {
  final today = DateUtils.dateOnly(DateTime.now());
  return DateUtils.dateOnly(endDate).difference(today).inDays;
}

String _leaseEndStatusLabel(DateTime endDate) {
  final remainingDays = _leaseDaysRemaining(endDate);
  if (remainingDays < 0) {
    return 'Lewat ${remainingDays.abs()} hari';
  }
  if (remainingDays == 0) {
    return 'Berakhir hari ini';
  }
  return '$remainingDays hari lagi';
}

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
  late Stream<List<BookingData>> _bookingsStream;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final user = SupabaseAuth.instance.currentUser!;
    _query = widget.initialQuery;
    _searchController = TextEditingController(text: widget.initialQuery);
    _bookingsStream = SupabaseService.instance.ownerBookingsStream(user.id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab.clamp(0, 2),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Penghuni'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Masa Sewa Berakhir'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: StreamBuilder<List<BookingData>>(
          stream: _bookingsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(label: 'Memuat data penghuni...');
            }

            final bookings = snapshot.data ?? const <BookingData>[];
            final active = bookings
                .where((booking) => booking.status == 'Sudah Check-in')
                .toList();
            final leavingSoon =
                active
                    .where(
                      (booking) =>
                          _leaseDaysRemaining(booking.endDateValue) <= 30,
                    )
                    .toList()
                  ..sort((a, b) => a.endDateValue.compareTo(b.endDateValue));
            final history = bookings
                .where(
                  (booking) =>
                      booking.status == 'Selesai' ||
                      booking.status == 'Dibatalkan',
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
                            'Cari nama penghuni, kamar, atau status booking...',
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
                                  '${booking.roomLabel} - ${booking.kos.name}',
                                  style: const TextStyle(
                                    color: Color(0xFF5D6B6B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StatusBadge(label: booking.status),
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
                      if (booking.status == 'Sudah Check-in') ...[
                        const SizedBox(height: 6),
                        _SummaryRow(
                          label: 'Sisa masa sewa',
                          value: _leaseEndStatusLabel(booking.endDateValue),
                        ),
                      ],
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

  Future<void> _finishResident(BookingData booking) async {
    if (!await _confirmFinishResident(context, booking) || !mounted) {
      return;
    }
    try {
      await SupabaseService.instance.updateBookingStatus(
        booking: booking,
        status: 'Selesai',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penghuni dipindahkan ke riwayat.')),
      );
    } on SupabaseAppException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_supabaseMessage(error))));
    }
  }

  List<BookingData> _filterResidents(List<BookingData> bookings) {
    if (_query.isEmpty) {
      return bookings;
    }
    return bookings.where((booking) {
      return booking.userName.toLowerCase().contains(_query) ||
          booking.roomLabel.toLowerCase().contains(_query) ||
          booking.status.toLowerCase().contains(_query);
    }).toList();
  }

  Future<void> _openResidentDetail(BookingData booking) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ResidentDetailPage(booking: booking),
      ),
    );
    if (changed == true && mounted) {
      final user = SupabaseAuth.instance.currentUser!;
      setState(() {
        _bookingsStream = SupabaseService.instance.ownerBookingsStream(user.id);
      });
    }
  }
}
