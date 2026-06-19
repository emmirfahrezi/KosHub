part of '../../main.dart';

class OwnerReviewsPage extends StatelessWidget {
  const OwnerReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Ulasan Penyewa'),
      ),
      body: StreamBuilder<List<ReviewData>>(
        stream: SupabaseService.instance.ownerReviewsStream(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen(label: 'Memuat ulasan penyewa...');
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Ulasan gagal dimuat',
                subtitle: _streamErrorMessage(snapshot.error),
              ),
            );
          }

          final reviews = snapshot.data ?? const <ReviewData>[];
          if (reviews.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Belum ada ulasan',
                subtitle:
                    'Rating dan komentar dari penyewa akan tampil di sini setelah masa sewa selesai.',
              ),
            );
          }

          final average =
              reviews.fold<int>(0, (total, review) => total + review.rating) /
              reviews.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 42,
                      color: Color(0xFFB78103),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          average.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${reviews.length} ulasan penyewa',
                          style: const TextStyle(color: Color(0xFF5D6B6B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFFE8EFEF),
                              backgroundImage: review.userPhoto.isEmpty
                                  ? null
                                  : NetworkImage(review.userPhoto),
                              child: review.userPhoto.isEmpty
                                  ? const Icon(
                                      Icons.person_rounded,
                                      color: Color(0xFF5D6B6B),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _formatLongDate(review.updatedAt),
                                    style: const TextStyle(
                                      color: Color(0xFF7B8A8A),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${review.rating}/5',
                              style: const TextStyle(
                                color: Color(0xFFB78103),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
