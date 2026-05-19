part of '../../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onOpenChat,
    required this.onOpenBookings,
  });

  final VoidCallback onOpenChat;
  final VoidCallback onOpenBookings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 20,
        title: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Color(0xFF006A6A)),
            const SizedBox(width: 6),
            Text(
              'KosHub',
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF006A6A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: widget.onOpenChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<KosData>>(
        stream: FirestoreService.instance.kosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen(label: 'Memuat data kos...');
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Gagal memuat daftar kos',
                subtitle: _streamErrorMessage(snapshot.error),
              ),
            );
          }

          final items = snapshot.data ?? const <KosData>[];
          final filtered = items.where((kos) {
            final query = _searchQuery.toLowerCase();
            final matchesSearch =
                query.isEmpty ||
                kos.name.toLowerCase().contains(query) ||
                kos.area.toLowerCase().contains(query) ||
                kos.address.toLowerCase().contains(query);
            final matchesCategory =
                _selectedCategory == null || kos.category == _selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeHero(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    onSubmitted: (_) {},
                  ),
                  const SizedBox(height: 24),
                  _CategorySection(
                    selectedCategory: _selectedCategory,
                    onSelected: (category) {
                      setState(() {
                        _selectedCategory = _selectedCategory == category
                            ? null
                            : category;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: _selectedCategory == null
                        ? 'Kos Tersedia'
                        : 'Kos $_selectedCategory',
                    actionLabel: 'Seed Data Demo',
                    onTap: _seedDemoData,
                  ),
                  const SizedBox(height: 14),
                  if (filtered.isEmpty)
                    _EmptyStateCard(
                      title: items.isEmpty
                          ? 'Belum ada data kos di Firestore'
                          : 'Tidak ada hasil yang cocok',
                      subtitle: items.isEmpty
                          ? 'Tekan "Seed Data Demo" untuk membuat contoh data kos, pemilik, dan chat awal.'
                          : 'Coba ubah kata kunci atau kategori pencarianmu.',
                      buttonLabel: items.isEmpty ? 'Buat Data Demo' : null,
                      onPressed: items.isEmpty ? _seedDemoData : null,
                    )
                  else
                    ListView.separated(
                      itemCount: filtered.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final kos = filtered[index];
                        return _KosCard(
                          kos: kos,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => KosDetailPage(kos: kos),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 28),
                  Text(
                    'Promo Menarik',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _PromoBanner(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _seedDemoData() async {
    try {
      await FirestoreService.instance.seedSampleData();
      if (mounted) {
        _showLightDialog(
          context,
          title: 'Data demo siap',
          message: 'Contoh data kos berhasil dimuat ke aplikasi.',
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        _showLightDialog(
          context,
          title: 'Data demo gagal dimuat',
          message: _firebaseMessage(error),
        );
      }
    } catch (_) {
      if (mounted) {
        _showLightDialog(
          context,
          title: 'Data demo gagal',
          message: 'Coba lagi dalam beberapa saat.',
        );
      }
    }
  }
}
