part of '../../main.dart';

enum OwnerTransactionFilter { all, thisMonth, unpaid, overdue, paid }

class OwnerTransactionsPage extends StatefulWidget {
  const OwnerTransactionsPage({
    super.key,
    this.initialFilter = OwnerTransactionFilter.all,
    this.initialQuery = '',
  });

  final OwnerTransactionFilter initialFilter;
  final String initialQuery;

  @override
  State<OwnerTransactionsPage> createState() => _OwnerTransactionsPageState();
}

class _OwnerTransactionsPageState extends State<OwnerTransactionsPage> {
  late final TextEditingController _searchController;
  late OwnerTransactionFilter _selectedFilter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Riwayat Transaksi'),
      ),
      body: StreamBuilder<List<BookingData>>(
        stream: FirestoreService.instance.ownerBookingsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen(label: 'Memuat transaksi...');
          }

          final transactions = _filterTransactions(
            snapshot.data ?? const <BookingData>[],
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              Container(
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
                    hintText: 'Cari nama penghuni, kamar, atau metode bayar...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: OwnerTransactionFilter.values.map((filter) {
                    final selected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_transactionFilterLabel(filter)),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedFilter = filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              if (transactions.isEmpty)
                const _EmptyStateCard(
                  title: 'Belum ada transaksi yang cocok',
                  subtitle:
                      'Coba ubah filter atau tunggu pembayaran/booking berikutnya masuk.',
                )
              else
                ...List.generate(transactions.length, (index) {
                  final booking = transactions[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == transactions.length - 1 ? 0 : 14,
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                TransactionDetailPage(booking: booking),
                          ),
                        );
                      },
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
                                Expanded(
                                  child: Text(
                                    booking.userName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                _StatusBadge(label: booking.paymentStatus),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _SummaryRow(
                              label: 'Tanggal pembayaran',
                              value: booking.paymentUpdatedAt == null
                                  ? 'Belum ada'
                                  : _formatLongDate(booking.paymentUpdatedAt!),
                            ),
                            const SizedBox(height: 6),
                            _SummaryRow(
                              label: 'Metode',
                              value: booking.paymentMethod,
                            ),
                            const SizedBox(height: 6),
                            _SummaryRow(
                              label: 'Nominal',
                              value: booking.total,
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  List<BookingData> _filterTransactions(List<BookingData> bookings) {
    final now = DateTime.now();
    return bookings.where((booking) {
      final matchesFilter = switch (_selectedFilter) {
        OwnerTransactionFilter.all => true,
        OwnerTransactionFilter.thisMonth =>
          booking.sortKey.month == now.month &&
              booking.sortKey.year == now.year,
        OwnerTransactionFilter.unpaid =>
          booking.paymentStatus == 'Belum Bayar' ||
              booking.paymentStatus == 'Pending',
        OwnerTransactionFilter.overdue => booking.paymentStatus == 'Overdue',
        OwnerTransactionFilter.paid => booking.paymentStatus == 'Lunas',
      };
      final matchesQuery =
          _query.isEmpty ||
          booking.userName.toLowerCase().contains(_query) ||
          booking.roomLabel.toLowerCase().contains(_query) ||
          booking.paymentMethod.toLowerCase().contains(_query);
      return matchesFilter && matchesQuery;
    }).toList()..sort((a, b) => b.sortKey.compareTo(a.sortKey));
  }
}
