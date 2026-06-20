part of '../../main.dart';
class DemoTenantAccount {
  const DemoTenantAccount({
    required this.name,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.ktpNumber,
    required this.emergencyContact,
    required this.bankAccount,
    required this.photoUrl,
    required this.accountStatus,
    required this.verificationStatus,
    required this.loginActivity,
    required this.notes,
  });

  final String name;
  final String email;
  final String password;
  final String phoneNumber;
  final String ktpNumber;
  final String emergencyContact;
  final String bankAccount;
  final String photoUrl;
  final String accountStatus;
  final String verificationStatus;
  final String loginActivity;
  final String notes;
}

const List<DemoTenantAccount> _demoTenantAccounts = [
  DemoTenantAccount(
    name: 'Alya Putri Maheswari',
    email: 'demo.penyewa1@koshub.app',
    password: 'DemoKosHub#2026',
    phoneNumber: '081290001001',
    ktpNumber: '3174011201990001',
    emergencyContact: 'Ibu Santi - 081290009001',
    bankAccount: 'BCA 7012345601 a.n. Alya Putri Maheswari',
    photoUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
    accountStatus: 'Aktif',
    verificationStatus: 'Terverifikasi',
    loginActivity: 'Demo login 20 Juni 2026',
    notes: 'Mahasiswi tingkat akhir, suka kos dekat kampus dan akses TransJakarta.',
  ),
  DemoTenantAccount(
    name: 'Rizky Ananda Pratama',
    email: 'demo.penyewa2@koshub.app',
    password: 'DemoKosHub#2026',
    phoneNumber: '081290001002',
    ktpNumber: '3174021502980002',
    emergencyContact: 'Ayah Budi - 081290009002',
    bankAccount: 'Mandiri 1320019988221 a.n. Rizky Ananda Pratama',
    photoUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    accountStatus: 'Aktif',
    verificationStatus: 'Terverifikasi',
    loginActivity: 'Demo login 20 Juni 2026',
    notes: 'Karyawan hybrid di area Sudirman, prefer kamar dengan WiFi cepat dan laundry.',
  ),
  DemoTenantAccount(
    name: 'Nabila Salsabila Rahma',
    email: 'demo.penyewa3@koshub.app',
    password: 'DemoKosHub#2026',
    phoneNumber: '081290001003',
    ktpNumber: '3174032303990003',
    emergencyContact: 'Kak Rani - 081290009003',
    bankAccount: 'BNI 0987654321 a.n. Nabila Salsabila Rahma',
    photoUrl:
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=400&q=80',
    accountStatus: 'Aktif',
    verificationStatus: 'Terverifikasi',
    loginActivity: 'Demo login 20 Juni 2026',
    notes: 'Freelancer desain, mencari kos estetik dengan ruang komunal nyaman.',
  ),
  DemoTenantAccount(
    name: 'Dimas Saputra Nugraha',
    email: 'demo.penyewa4@koshub.app',
    password: 'DemoKosHub#2026',
    phoneNumber: '081290001004',
    ktpNumber: '3174041104970004',
    emergencyContact: 'Istri Fina - 081290009004',
    bankAccount: 'BRI 6601888999 a.n. Dimas Saputra Nugraha',
    photoUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80',
    accountStatus: 'Aktif',
    verificationStatus: 'Terverifikasi',
    loginActivity: 'Demo login 20 Juni 2026',
    notes: 'Staff sales lapangan, butuh parkir motor aman dan akses jalan utama.',
  ),
  DemoTenantAccount(
    name: 'Citra Lestari Handayani',
    email: 'demo.penyewa5@koshub.app',
    password: 'DemoKosHub#2026',
    phoneNumber: '081290001005',
    ktpNumber: '3174050101000005',
    emergencyContact: 'Suami Yoga - 081290009005',
    bankAccount: 'CIMB Niaga 800123456700 a.n. Citra Lestari Handayani',
    photoUrl:
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80',
    accountStatus: 'Aktif',
    verificationStatus: 'Terverifikasi',
    loginActivity: 'Demo login 20 Juni 2026',
    notes: 'Admin klinik, suka kos putri yang tenang dengan kamar mandi dalam.',
  ),
  DemoTenantAccount(
    name: 'Fajar Maulana Hidayat',
    email: 'demo.penyewa6@koshub.app',
    password: 'DemoKosHub#2026',
    phoneNumber: '081290001006',
    ktpNumber: '3174060909950006',
    emergencyContact: 'Ibu Rina - 081290009006',
    bankAccount: 'Permata 899001223344 a.n. Fajar Maulana Hidayat',
    photoUrl:
        'https://images.unsplash.com/photo-1504593811423-6dd665756598?auto=format&fit=crop&w=400&q=80',
    accountStatus: 'Aktif',
    verificationStatus: 'Terverifikasi',
    loginActivity: 'Demo login 20 Juni 2026',
    notes: 'Programmer remote, prioritas AC dingin, meja kerja, dan internet stabil.',
  ),
  DemoTenantAccount(
    name: 'Intan Permata Sari',
    email: 'demo.penyewa7@koshub.app',
    password: 'DemoKosHub#2026',
    phoneNumber: '081290001007',
    ktpNumber: '3174071707010007',
    emergencyContact: 'Ayah Herman - 081290009007',
    bankAccount: 'BSI 7112233445 a.n. Intan Permata Sari',
    photoUrl:
        'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&w=400&q=80',
    accountStatus: 'Aktif',
    verificationStatus: 'Terverifikasi',
    loginActivity: 'Demo login 20 Juni 2026',
    notes: 'Mahasiswi S2, mencari kos syariah dekat perpustakaan dan tempat makan.',
  ),
  DemoTenantAccount(
    name: 'Yusuf Kurniawan Aditya',
    email: 'demo.penyewa8@koshub.app',
    password: 'DemoKosHub#2026',
    phoneNumber: '081290001008',
    ktpNumber: '3174082108940008',
    emergencyContact: 'Kak Aldi - 081290009008',
    bankAccount: 'Danamon 001778899221 a.n. Yusuf Kurniawan Aditya',
    photoUrl:
        'https://images.unsplash.com/photo-1504257432389-52343af06ae3?auto=format&fit=crop&w=400&q=80',
    accountStatus: 'Aktif',
    verificationStatus: 'Terverifikasi',
    loginActivity: 'Demo login 20 Juni 2026',
    notes: 'Supervisor retail, cocok untuk demo booking, chat, dan histori transaksi.',
  ),
];

const Map<String, dynamic> _sampleKosMap1 = {
  'owner_id': 'demo-owner-rina',
  'owner_name': 'Bu Rina',
  'owner_status': 'Online',
  'owner_photo':
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80',
  'nama_kos': 'Kos Menteng Syariah',
  'area': 'Jakarta Pusat',
  'alamat': 'Jl. HOS Cokroaminoto No. 18, Menteng, Jakarta Pusat',
  'deskripsi':
      'Kos nyaman untuk mahasiswi dan karyawan dengan lingkungan tenang, akses mudah ke transportasi umum, serta keamanan 24 jam.',
  'harga_mulai': 1500000,
  'fasilitas': ['WiFi Gratis', 'AC', 'CCTV', 'Dapur Bersama', 'Parkir Motor'],
  'gender': 'Putri',
  'foto_urls': [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuC2D57JOt6UVKCAyyDeDdptmIBGYgck1Ue48jjfJQb3kIU95FQdBMD6VCxfQbBp0YPh8V-jOCjqg__tiHnXkfZTf48h5dD9p0umsCPvfz10JYJ10Wep4WWe8XCZRp40gokF-HLXaCSdn2A-w4Muc8igEC42zgaGYzcSsoxXZIDcZxToKULKyVarbgerAjGTDPDsrRTglAx_GheZmLCJIbjbxUqBPYseBCZ1quwgl5BnTKS-O7mC0pCq82MJECLzhJ9cqfDV5ea9',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDn4tW5bdE8f1lqK3t3lYIgcPfwHcKHMo5tQfvpjQluS7BD0zV_3tvTgIKGeqyB5reZIeue7h3ixhunQli9uywMlzXvFSd4-oBKv340V8O5yHvYohZ8WLjiXZa1wnuLuSdGvdY-nTX3IkZkewXkfOrXOpqLKt8Vw9dfjzwxUCrExOjOjdJlJ7cK386R-Lcnym2wiSAE-o7ovXu4qZLndSqqn0I9IXgZpuo5H4h75guKvOTzPm7QgwQzRff7CGdfpez5BJGIjCnA',
  ],
  'rating': 4.8,
  'total_review': 120,
  'available_rooms': 3,
  'status': 'active',
};

const Map<String, dynamic> _sampleKosMap2 = {
  'owner_id': 'demo-owner-dimas',
  'owner_name': 'Pak Dimas',
  'owner_status': 'Terakhir aktif 5 menit lalu',
  'owner_photo':
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
  'nama_kos': 'Griya Urban Kemang',
  'area': 'Jakarta Selatan',
  'alamat': 'Jl. Kemang Utara No. 7, Mampang, Jakarta Selatan',
  'deskripsi':
      'Kos eksklusif dengan desain modern, kamar mandi dalam, laundry, dan lokasi strategis dekat area perkantoran.',
  'harga_mulai': 3200000,
  'fasilitas': ['KM Dalam', 'Laundry', 'WiFi', 'CCTV', 'Dapur Mini'],
  'gender': 'Eksklusif',
  'foto_urls': [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAogmMwDw1tdNckktoBtTIzdjTITVdLL8ZGZqMyKgS2nPXQZi3dXnNiH5YmQUGLXt7ao_eVWqhEXBUMe6U8edaHSCbbS1bXulHzgc6Cys3Mvf9rm7tjQk4nCl6zH5x_L0GcWFLaV-gQcQca4PVv2p9s8bP9jXLeojMuls_q5WFMlhWbjOVCxI5frkyRp5FYRRimGmNwIuIAK17wmpnOBPWg31wTuAQyIv1m09lAM5cLhF3LFzI4TIpgLDG6mx_kKjz8q6YElb7f',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBTtRX9PGRevp8GKF9nCE-UV8z1Tkj1c21GYZGl6QBU6eg39HNS01x779ls19eCLmTN7VFTHP4KRdzl8g-EkvSEuzLgb7_zyUlX4jrbQmlkPoLDWp11R_VXIsEgZOsyf-G9gDe3JXJ02CXYVIq_siC_2uItA6M81wUMveDwySY74XjW6bwc_4E1FvyyVFBtw6f7kkq8o94d0WwzjazE13X5Bm9Hljj6JKUw5SRMVriA5ppgKmxLph9qaoXqf14dEa_p2JCWQ7x6',
  ],
  'rating': 4.9,
  'total_review': 85,
  'available_rooms': 2,
  'status': 'active',
};

