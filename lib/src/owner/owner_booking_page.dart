part of '../../main.dart';

class OwnerBookingPage extends StatefulWidget {
  const OwnerBookingPage({
    super.key,
    this.initialTab = 0,
    this.initialQuery = '',
  });

  final int initialTab;
  final String initialQuery;

  @override
  State<OwnerBookingPage> createState() => _OwnerBookingPageState();
}

class _OwnerBookingPageState extends State<OwnerBookingPage> {
  late final TextEditingController _searchController;
  late Stream<List<BookingData>> _bookingsStream;
  final Set<String> _updatingBookingIds = <String>{};
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
      length: 4,
      initialIndex: widget.initialTab.clamp(0, 3),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Daftar Booking'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Menunggu Konfirmasi'),
              Tab(text: 'Sudah Dikonfirmasi'),
              Tab(text: 'Sudah Check-in'),
              Tab(text: 'Dibatalkan'),
            ],
          ),
        ),
        body: StreamBuilder<List<BookingData>>(
          stream: _bookingsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(label: 'Memuat booking owner...');
            }

            final bookings = (snapshot.data ?? const <BookingData>[])
                .where(_matchesBookingQuery)
                .toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildSearchCard(
                    hintText:
                        'Cari nama penghuni, kamar, atau status booking...',
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildBookingTab(
                        bookings
                            .where((b) => b.status == 'Menunggu Konfirmasi')
                            .toList(),
                      ),
                      _buildBookingTab(
                        bookings
                            .where((b) => b.status == 'Sudah Dikonfirmasi')
                            .toList(),
                      ),
                      _buildBookingTab(
                        bookings
                            .where((b) => b.status == 'Sudah Check-in')
                            .toList(),
                      ),
                      _buildBookingTab(
                        bookings
                            .where((b) => b.status == 'Dibatalkan')
                            .toList(),
                      ),
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

  Widget _buildBookingTab(List<BookingData> bookings) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      children: [
        if (bookings.isEmpty)
          const _EmptyStateCard(
            title: 'Belum ada data di status ini',
            subtitle:
                'Saat booking baru masuk atau status diubah, datanya akan tampil di sini.',
          )
        else
          ...List.generate(bookings.length, (index) {
            final booking = bookings[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == bookings.length - 1 ? 0 : 14,
              ),
              child: InkWell(
                onTap: () => _openBookingDetail(booking),
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
                                  '${booking.kos.name} - ${booking.roomLabel}',
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
                      _SummaryRow(label: 'Nomor HP', value: booking.userPhone),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Tanggal masuk',
                        value: booking.startDate,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Durasi',
                        value: booking.durationLabel,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Pembayaran',
                        value: booking.paymentMethod,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Status bayar',
                        value: booking.paymentStatus,
                      ),
                      if (booking.note.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Catatan penyewa: ${booking.note}',
                          style: const TextStyle(
                            color: Color(0xFF5D6B6B),
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (booking.paymentProofUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ImageProofPreview(
                          title: 'Bukti DP',
                          imageUrl: booking.paymentProofUrl,
                        ),
                      ],
                      if (booking.status == 'Sudah Dikonfirmasi') ...[
                        const SizedBox(height: 12),
                        Text(
                          _checkInCountdownLabel(booking.startDateValue),
                          style: const TextStyle(
                            color: Color(0xFFB78103),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (booking.status == 'Dibatalkan' &&
                          booking.cancelReason.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Alasan pembatalan: ${booking.cancelReason}',
                            style: const TextStyle(
                              color: Color(0xFF9F4035),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _buildActions(context, booking),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSearchCard({required String hintText}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            setState(() => _query = value.trim().toLowerCase()),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }

  bool _matchesBookingQuery(BookingData booking) {
    if (_query.isEmpty) {
      return true;
    }
    return booking.userName.toLowerCase().contains(_query) ||
        booking.roomLabel.toLowerCase().contains(_query) ||
        booking.userPhone.toLowerCase().contains(_query) ||
        booking.paymentStatus.toLowerCase().contains(_query);
  }

  Future<void> _openBookingDetail(BookingData booking) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => OwnerBookingDetailPage(booking: booking),
      ),
    );
    if (changed == true && mounted) {
      _refreshBookings();
    }
  }

  List<Widget> _buildActions(BuildContext context, BookingData booking) {
    final isUpdating = _updatingBookingIds.contains(booking.id);
    final actions = <Widget>[
      OutlinedButton.icon(
        onPressed: isUpdating ? null : () => _openChat(booking),
        icon: const Icon(Icons.chat_rounded),
        label: const Text('Chat Penyewa'),
      ),
    ];

    if (booking.status == 'Menunggu Konfirmasi') {
      actions.addAll([
        FilledButton(
          onPressed: isUpdating
              ? null
              : () => _updateBookingStatus(booking, 'Sudah Dikonfirmasi'),
          child: const Text('Terima'),
        ),
        FilledButton.tonal(
          onPressed: isUpdating ? null : () => _rejectBooking(booking),
          child: const Text('Tolak'),
        ),
      ]);
    } else if (booking.status == 'Sudah Dikonfirmasi') {
      actions.addAll([
        FilledButton(
          onPressed: isUpdating
              ? null
              : () => _updateBookingStatus(booking, 'Sudah Check-in'),
          child: const Text('Tandai Check-in'),
        ),
        FilledButton.tonal(
          onPressed: isUpdating ? null : () => _rejectBooking(booking),
          child: const Text('Batalkan'),
        ),
      ]);
    } else if (booking.status == 'Sudah Check-in') {
      actions.add(
        FilledButton(
          onPressed: isUpdating
              ? null
              : () => _updateBookingStatus(booking, 'Selesai'),
          child: const Text('Pindah ke Riwayat'),
        ),
      );
    }

    return actions;
  }

  Future<void> _openChat(BookingData booking) async {
    try {
      final chatId = await SupabaseService.instance.createOrGetOwnerChat(
        booking,
      );
      if (!mounted) {
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChatDetailPage(kos: booking.kos, chatId: chatId),
        ),
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

  Future<void> _updateBookingStatus(BookingData booking, String status) async {
    if (status == 'Selesai' &&
        !await _confirmFinishResident(context, booking)) {
      return;
    }
    _setBookingUpdating(booking.id, true);
    try {
      await SupabaseService.instance.updateBookingStatus(
        booking: booking,
        status: status,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status booking diubah menjadi $status.')),
      );
      _refreshBookings();
    } on SupabaseAppException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_supabaseMessage(error))));
    } finally {
      _setBookingUpdating(booking.id, false);
    }
  }

  Future<void> _rejectBooking(BookingData booking) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
                    trailing: const Icon(Icons.chevron_right_rounded),
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

    _setBookingUpdating(booking.id, true);
    try {
      await SupabaseService.instance.updateBookingStatus(
        booking: booking,
        status: 'Dibatalkan',
        cancelReason: reason,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking dibatalkan: $reason')));
      _refreshBookings();
    } on SupabaseAppException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_supabaseMessage(error))));
    } finally {
      _setBookingUpdating(booking.id, false);
    }
  }

  void _refreshBookings() {
    final user = SupabaseAuth.instance.currentUser;
    if (!mounted || user == null) {
      return;
    }
    setState(() {
      _bookingsStream = SupabaseService.instance.ownerBookingsStream(user.id);
    });
  }

  void _setBookingUpdating(String bookingId, bool isUpdating) {
    if (!mounted) {
      return;
    }
    setState(() {
      if (isUpdating) {
        _updatingBookingIds.add(bookingId);
      } else {
        _updatingBookingIds.remove(bookingId);
      }
    });
  }
}
