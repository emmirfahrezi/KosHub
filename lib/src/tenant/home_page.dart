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
  bool _isGridView = true;
  late final Stream<List<HomeBannerData>> _homeBannersStream;
  late final Stream<List<KosData>> _kosStream;

  @override
  void initState() {
    super.initState();
    _homeBannersStream = SupabaseService.instance.homeBannersStream();
    _kosStream = SupabaseService.instance.kosStream();
  }

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
      body: StreamBuilder<List<HomeBannerData>>(
        stream: _homeBannersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen(label: 'Memuat tampilan beranda...');
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Gagal memuat banner home',
                subtitle: _streamErrorMessage(snapshot.error),
              ),
            );
          }

          final banners = snapshot.data ?? const <HomeBannerData>[];
          final heroItems = banners
              .where((item) => item.isActive && item.placement == 'hero')
              .toList();
          final heroBanner = heroItems.isEmpty ? null : heroItems.first;

          return StreamBuilder<List<KosData>>(
            stream: _kosStream,
            builder: (context, kosSnapshot) {
              if (kosSnapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingScreen(label: 'Memuat data kos...');
              }
              if (kosSnapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: _EmptyStateCard(
                    title: 'Gagal memuat daftar kos',
                    subtitle: _streamErrorMessage(kosSnapshot.error),
                  ),
                );
              }

              final items = kosSnapshot.data ?? const <KosData>[];
              final filtered = items.where((kos) {
                final query = _searchQuery.toLowerCase();
                final matchesSearch =
                    query.isEmpty ||
                    kos.name.toLowerCase().contains(query) ||
                    kos.area.toLowerCase().contains(query) ||
                    kos.address.toLowerCase().contains(query);
                final matchesCategory =
                    _selectedCategory == null ||
                    kos.category == _selectedCategory;
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
                        banner: heroBanner,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedCategory == null
                                  ? 'Kos Tersedia'
                                  : 'Kos $_selectedCategory',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFD9E9F7),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ViewModeButton(
                                  icon: Icons.view_list_rounded,
                                  selected: !_isGridView,
                                  onTap: () {
                                    if (_isGridView) {
                                      setState(() => _isGridView = false);
                                    }
                                  },
                                ),
                                const SizedBox(width: 4),
                                _ViewModeButton(
                                  icon: Icons.grid_view_rounded,
                                  selected: _isGridView,
                                  onTap: () {
                                    if (!_isGridView) {
                                      setState(() => _isGridView = true);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (filtered.isEmpty)
                        _EmptyStateCard(
                          title: items.isEmpty
                              ? 'Belum ada kos yang aktif'
                              : 'Tidak ada hasil yang cocok',
                          subtitle: items.isEmpty
                              ? 'Belum ada listing kos aktif yang tampil saat ini.'
                              : 'Coba ubah kata kunci atau kategori pencarianmu.',
                        )
                      else
                        _isGridView
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  final cardWidth =
                                      (constraints.maxWidth - 12) / 2;
                                  final cardHeight = cardWidth < 190
                                      ? 460.0
                                      : 420.0;

                                  return GridView.builder(
                                    itemCount: filtered.length,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 16,
                                          mainAxisExtent: cardHeight,
                                        ),
                                    itemBuilder: (context, index) {
                                      final kos = filtered[index];
                                      return _KosCard(
                                        kos: kos,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  KosDetailPage(kos: kos),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final kos = filtered[index];
                                  return _KosCard(
                                    kos: kos,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              KosDetailPage(kos: kos),
                                        ),
                                      );
                                    },
                                  );
                                },
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

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF006A6A) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : const Color(0xFF5D6B6B),
        ),
      ),
    );
  }
}
