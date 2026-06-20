param(
  [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Stop"

function Get-EnvMap {
  param([string]$Path)

  if (-not (Test-Path $Path)) {
    throw "File env tidak ditemukan: $Path"
  }

  $result = @{}
  foreach ($line in Get-Content $Path) {
    $trimmed = $line.Trim()
    if (-not $trimmed -or $trimmed.StartsWith('#')) {
      continue
    }
    $parts = $trimmed -split '=', 2
    if ($parts.Count -ne 2) {
      continue
    }
    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    if (
      ($value.StartsWith('"') -and $value.EndsWith('"')) -or
      ($value.StartsWith("'") -and $value.EndsWith("'"))
    ) {
      $value = $value.Substring(1, $value.Length - 2)
    }
    $result[$key] = $value
  }

  return $result
}

function Invoke-SupabaseJson {
  param(
    [string]$Method,
    [string]$Url,
    [hashtable]$Headers,
    [object]$Body = $null
  )

  $arguments = @(
    '-sS',
    '-L',
    '-X', $Method,
    $Url
  )

  foreach ($key in $Headers.Keys) {
    $arguments += '-H'
    $arguments += ('{0}: {1}' -f $key, $Headers[$key])
  }

  $tempFile = $null
  if ($null -ne $Body) {
    $tempFile = [System.IO.Path]::GetTempFileName()
    $jsonBody = $Body | ConvertTo-Json -Depth 10
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($tempFile, $jsonBody, $utf8NoBom)
    $arguments += '-H'
    $arguments += 'Content-Type: application/json'
    $arguments += '--data-binary'
    $arguments += "@$tempFile"
  }

  try {
    $raw = & curl.exe @arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
      throw "curl gagal dengan exit code $exitCode untuk $Method $Url"
    }
    if (-not $raw) {
      return $null
    }
    return $raw | ConvertFrom-Json
  } finally {
    if ($tempFile -and (Test-Path $tempFile)) {
      Remove-Item -LiteralPath $tempFile -Force
    }
  }
}

$envMap = Get-EnvMap -Path $EnvFile
$supabaseUrl = $envMap['SUPABASE_URL']
$serviceRoleKey = $envMap['SUPABASE_SERVICE_ROLE_KEY']

if (-not $supabaseUrl) {
  throw "SUPABASE_URL belum diisi di $EnvFile"
}

if (-not $serviceRoleKey) {
  throw "SUPABASE_SERVICE_ROLE_KEY belum diisi di $EnvFile"
}

$adminHeaders = @{
  apikey        = $serviceRoleKey
  Authorization = "Bearer $serviceRoleKey"
}

$restHeaders = @{
  apikey        = $serviceRoleKey
  Authorization = "Bearer $serviceRoleKey"
  Prefer        = 'resolution=merge-duplicates,return=representation'
}

$accounts = @(
  @{
    name = 'Alya Putri Maheswari'
    email = 'demo.penyewa1@koshub.app'
    password = 'DemoKosHub#2026'
    phone_number = '081290001001'
    ktp_number = '3174011201990001'
    emergency_contact = 'Ibu Santi - 081290009001'
    bank_account = 'BCA 7012345601 a.n. Alya Putri Maheswari'
    photo_url = 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80'
    account_status = 'Aktif'
    verification_status = 'Terverifikasi'
    login_activity = 'Login 20 Juni 2026'
    kos = @{
      nama_kos = 'Alya Residence Tebet'
      area = 'Jakarta Selatan'
      alamat = 'Jl. Tebet Barat Dalam VIII No. 12, Tebet, Jakarta Selatan'
      deskripsi = 'Kos putri modern dekat kuliner Tebet dengan kamar full furnished, WiFi cepat, dan area komunal nyaman.'
      harga_mulai = 2350000
      fasilitas = @('WiFi 100 Mbps', 'AC', 'Kamar Mandi Dalam', 'Laundry', 'Dapur Bersama', 'CCTV', 'Akses 24 Jam')
      gender = 'Putri'
      approval_mode = 'Manual Approval'
      foto_urls = @(
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80'
      )
      rating = 4.8
      total_review = 31
      total_rooms = 14
      available_rooms = 5
      status = 'active'
    }
  }
  @{
    name = 'Rizky Ananda Pratama'
    email = 'demo.penyewa2@koshub.app'
    password = 'DemoKosHub#2026'
    phone_number = '081290001002'
    ktp_number = '3174021502980002'
    emergency_contact = 'Ayah Budi - 081290009002'
    bank_account = 'Mandiri 1320019988221 a.n. Rizky Ananda Pratama'
    photo_url = 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80'
    account_status = 'Aktif'
    verification_status = 'Terverifikasi'
    login_activity = 'Login 20 Juni 2026'
    kos = @{
      nama_kos = 'Rizky Loft Sudirman'
      area = 'Jakarta Pusat'
      alamat = 'Jl. Bendungan Hilir Raya No. 18, Tanah Abang, Jakarta Pusat'
      deskripsi = 'Kos eksekutif untuk profesional muda dengan interior loft, pantry pribadi, dan akses cepat ke MRT.'
      harga_mulai = 3250000
      fasilitas = @('WiFi 150 Mbps', 'AC', 'Smart TV', 'Kamar Mandi Dalam', 'Cleaning Service', 'Lift', 'CCTV')
      gender = 'Eksklusif'
      approval_mode = 'Auto Approval'
      foto_urls = @(
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80'
      )
      rating = 4.9
      total_review = 44
      total_rooms = 10
      available_rooms = 3
      status = 'active'
    }
  }
  @{
    name = 'Nabila Salsabila Rahma'
    email = 'demo.penyewa3@koshub.app'
    password = 'DemoKosHub#2026'
    phone_number = '081290001003'
    ktp_number = '3174032303990003'
    emergency_contact = 'Kak Rani - 081290009003'
    bank_account = 'BNI 0987654321 a.n. Nabila Salsabila Rahma'
    photo_url = 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=400&q=80'
    account_status = 'Aktif'
    verification_status = 'Terverifikasi'
    login_activity = 'Login 20 Juni 2026'
    kos = @{
      nama_kos = 'Nabila Corner Depok'
      area = 'Depok'
      alamat = 'Jl. Margonda Raya Gg. Kamboja No. 9, Beji, Depok'
      deskripsi = 'Kos estetik dekat kampus dan stasiun, cocok untuk mahasiswi dengan ruang belajar dan balkon santai.'
      harga_mulai = 1850000
      fasilitas = @('WiFi', 'AC', 'Balkon', 'Dapur Bersama', 'Parkir Motor', 'Mesin Cuci', 'Penjaga Kos')
      gender = 'Putri'
      approval_mode = 'Manual Approval'
      foto_urls = @(
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80&sat=-100'
      )
      rating = 4.7
      total_review = 27
      total_rooms = 18
      available_rooms = 6
      status = 'active'
    }
  }
  @{
    name = 'Dimas Saputra Nugraha'
    email = 'demo.penyewa4@koshub.app'
    password = 'DemoKosHub#2026'
    phone_number = '081290001004'
    ktp_number = '3174041104970004'
    emergency_contact = 'Istri Fina - 081290009004'
    bank_account = 'BRI 6601888999 a.n. Dimas Saputra Nugraha'
    photo_url = 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80'
    account_status = 'Aktif'
    verification_status = 'Terverifikasi'
    login_activity = 'Login 20 Juni 2026'
    kos = @{
      nama_kos = 'Dimas Hub Cawang'
      area = 'Jakarta Timur'
      alamat = 'Jl. Dewi Sartika No. 55, Cawang, Jakarta Timur'
      deskripsi = 'Kos campur strategis dekat halte dan tol, ideal untuk pekerja mobile dengan parkir luas dan keamanan baik.'
      harga_mulai = 2100000
      fasilitas = @('WiFi', 'AC', 'Parkir Motor', 'CCTV', 'Dapur Bersama', 'Rooftop', 'Kulkas Bersama')
      gender = 'Campur'
      approval_mode = 'Manual Approval'
      foto_urls = @(
        'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80'
      )
      rating = 4.6
      total_review = 19
      total_rooms = 20
      available_rooms = 8
      status = 'active'
    }
  }
  @{
    name = 'Citra Lestari Handayani'
    email = 'demo.penyewa5@koshub.app'
    password = 'DemoKosHub#2026'
    phone_number = '081290001005'
    ktp_number = '3174050101000005'
    emergency_contact = 'Suami Yoga - 081290009005'
    bank_account = 'CIMB Niaga 800123456700 a.n. Citra Lestari Handayani'
    photo_url = 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80'
    account_status = 'Aktif'
    verification_status = 'Terverifikasi'
    login_activity = 'Login 20 Juni 2026'
    kos = @{
      nama_kos = 'Citra Ladies House'
      area = 'Bandung'
      alamat = 'Jl. Cisitu Lama No. 23, Coblong, Bandung'
      deskripsi = 'Kos putri nyaman dekat kampus ITB dengan nuansa hangat, kamar mandi dalam, dan area jemur tertata.'
      harga_mulai = 1950000
      fasilitas = @('WiFi', 'Kamar Mandi Dalam', 'AC', 'Laundry', 'Dapur Bersama', 'Water Heater', 'Akses Fingerprint')
      gender = 'Putri'
      approval_mode = 'Auto Approval'
      foto_urls = @(
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80'
      )
      rating = 4.8
      total_review = 36
      total_rooms = 12
      available_rooms = 4
      status = 'active'
    }
  }
  @{
    name = 'Fajar Maulana Hidayat'
    email = 'demo.penyewa6@koshub.app'
    password = 'DemoKosHub#2026'
    phone_number = '081290001006'
    ktp_number = '3174060909950006'
    emergency_contact = 'Ibu Rina - 081290009006'
    bank_account = 'Permata 899001223344 a.n. Fajar Maulana Hidayat'
    photo_url = 'https://images.unsplash.com/photo-1504593811423-6dd665756598?auto=format&fit=crop&w=400&q=80'
    account_status = 'Aktif'
    verification_status = 'Terverifikasi'
    login_activity = 'Login 20 Juni 2026'
    kos = @{
      nama_kos = 'Fajar Tech Living BSD'
      area = 'Tangerang Selatan'
      alamat = 'Jl. Letnan Sutopo No. 7, Serpong, Tangerang Selatan'
      deskripsi = 'Kos modern untuk pekerja digital dengan meja kerja ergonomis, internet cepat, dan lounge santai.'
      harga_mulai = 3450000
      fasilitas = @('WiFi 200 Mbps', 'AC', 'Smart Lock', 'Kamar Mandi Dalam', 'Co-working Corner', 'Laundry', 'CCTV')
      gender = 'Eksklusif'
      approval_mode = 'Auto Approval'
      foto_urls = @(
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80&h=800',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80&h=800'
      )
      rating = 4.9
      total_review = 52
      total_rooms = 16
      available_rooms = 2
      status = 'active'
    }
  }
  @{
    name = 'Intan Permata Sari'
    email = 'demo.penyewa7@koshub.app'
    password = 'DemoKosHub#2026'
    phone_number = '081290001007'
    ktp_number = '3174071707010007'
    emergency_contact = 'Ayah Herman - 081290009007'
    bank_account = 'BSI 7112233445 a.n. Intan Permata Sari'
    photo_url = 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&w=400&q=80'
    account_status = 'Aktif'
    verification_status = 'Terverifikasi'
    login_activity = 'Login 20 Juni 2026'
    kos = @{
      nama_kos = 'Intan Syariah Residence'
      area = 'Yogyakarta'
      alamat = 'Jl. Kaliurang Km 5 No. 21, Depok, Sleman'
      deskripsi = 'Kos syariah putri dengan suasana tenang, mushola, dapur bersih, dan lokasi dekat kampus.'
      harga_mulai = 1750000
      fasilitas = @('WiFi', 'AC', 'Mushola', 'Dapur Bersama', 'CCTV', 'Parkir Motor', 'Lemari Besar')
      gender = 'Putri'
      approval_mode = 'Manual Approval'
      foto_urls = @(
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80&h=900',
        'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80&h=900'
      )
      rating = 4.7
      total_review = 29
      total_rooms = 15
      available_rooms = 5
      status = 'active'
    }
  }
  @{
    name = 'Yusuf Kurniawan Aditya'
    email = 'demo.penyewa8@koshub.app'
    password = 'DemoKosHub#2026'
    phone_number = '081290001008'
    ktp_number = '3174082108940008'
    emergency_contact = 'Kak Aldi - 081290009008'
    bank_account = 'Danamon 001778899221 a.n. Yusuf Kurniawan Aditya'
    photo_url = 'https://images.unsplash.com/photo-1504257432389-52343af06ae3?auto=format&fit=crop&w=400&q=80'
    account_status = 'Aktif'
    verification_status = 'Terverifikasi'
    login_activity = 'Login 20 Juni 2026'
    kos = @{
      nama_kos = 'Yusuf Urban Stay Surabaya'
      area = 'Surabaya'
      alamat = 'Jl. Dharmahusada Indah No. 31, Gubeng, Surabaya'
      deskripsi = 'Kos eksklusif dekat pusat kota Surabaya dengan interior clean, pantry bersama, dan kamar luas.'
      harga_mulai = 2550000
      fasilitas = @('WiFi', 'AC', 'Kamar Mandi Dalam', 'Laundry', 'Pantry', 'CCTV', 'Parkir Mobil')
      gender = 'Campur'
      approval_mode = 'Auto Approval'
      foto_urls = @(
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80&h=850',
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80&h=850'
      )
      rating = 4.8
      total_review = 41
      total_rooms = 11
      available_rooms = 3
      status = 'active'
    }
  }
  @{
    name = 'Salsa Nur Aini'
    email = 'demo.penyewa9@koshub.app'
    password = 'DemoKosHub#2026'
    phone_number = '081290001009'
    ktp_number = '3273011101010009'
    emergency_contact = 'Ibu Nani - 081290009009'
    bank_account = 'BCA 7012345609 a.n. Salsa Nur Aini'
    photo_url = 'https://images.unsplash.com/photo-1542204625-de293a2f8ff8?auto=format&fit=crop&w=400&q=80'
    account_status = 'Aktif'
    verification_status = 'Terverifikasi'
    login_activity = 'Login 20 Juni 2026'
    kos = @{
      nama_kos = 'Setiabudi Asri 9'
      area = 'Bandung'
      alamat = 'Jl. Setiabudi Gg. Haji Umar No. 9, Setiabudi, Bandung'
      deskripsi = 'Kos putri hemat di Setiabudi dengan suasana tenang, cocok untuk mahasiswi dan karyawan baru.'
      harga_mulai = 800000
      fasilitas = @('WiFi', 'Kasur', 'Lemari', 'Dapur Bersama', 'Parkir Motor')
      gender = 'Putri'
      approval_mode = 'Manual Approval'
      foto_urls = @(
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80'
      )
      rating = 4.5
      total_review = 12
      total_rooms = 10
      available_rooms = 4
      status = 'active'
    }
  }
  @{
    name = 'Bagas Firmansyah'
    email = 'demo.penyewa10@koshub.app'
    password = 'DemoKosHub#2026'
    phone_number = '081290001010'
    ktp_number = '3273011202020010'
    emergency_contact = 'Ayah Toni - 081290009010'
    bank_account = 'Mandiri 1320019988210 a.n. Bagas Firmansyah'
    photo_url = 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80'
    account_status = 'Aktif'
    verification_status = 'Terverifikasi'
    login_activity = 'Login 20 Juni 2026'
    kos = @{
      nama_kos = 'Setiabudi Harmoni'
      area = 'Bandung'
      alamat = 'Jl. Setiabudi No. 121, Setiabudi, Bandung'
      deskripsi = 'Kos campur strategis dekat kampus dan kuliner, harga ramah dengan fasilitas lengkap.'
      harga_mulai = 950000
      fasilitas = @('WiFi', 'AC', 'Kasur', 'Laundry Koin', 'CCTV', 'Parkir Motor')
      gender = 'Campur'
      approval_mode = 'Auto Approval'
      foto_urls = @(
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80'
      )
      rating = 4.6
      total_review = 18
      total_rooms = 14
      available_rooms = 5
      status = 'active'
    }
  }
  @{
    name = 'Meylani Kartika'
    email = 'demo.penyewa11@koshub.app'
    password = 'DemoKosHub#2026'
    phone_number = '081290001011'
    ktp_number = '3273011303030011'
    emergency_contact = 'Kak Dita - 081290009011'
    bank_account = 'BNI 0987654311 a.n. Meylani Kartika'
    photo_url = 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80'
    account_status = 'Aktif'
    verification_status = 'Terverifikasi'
    login_activity = 'Login 20 Juni 2026'
    kos = @{
      nama_kos = 'Pondok Setiabudi Putri'
      area = 'Bandung'
      alamat = 'Jl. Setiabudi Gg. Sukamaju No. 14, Setiabudi, Bandung'
      deskripsi = 'Kos putri nyaman dengan dapur bersih, water heater, dan lingkungan aman di area Setiabudi.'
      harga_mulai = 1100000
      fasilitas = @('WiFi', 'Kamar Mandi Dalam', 'Water Heater', 'Dapur Bersama', 'CCTV', 'Akses 24 Jam')
      gender = 'Putri'
      approval_mode = 'Manual Approval'
      foto_urls = @(
        'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80&h=850',
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80&h=850'
      )
      rating = 4.7
      total_review = 22
      total_rooms = 12
      available_rooms = 3
      status = 'active'
    }
  }
  @{
    name = 'Rendra Maulana'
    email = 'demo.penyewa12@koshub.app'
    password = 'DemoKosHub#2026'
    phone_number = '081290001012'
    ktp_number = '3273011404040012'
    emergency_contact = 'Ibu Mira - 081290009012'
    bank_account = 'BRI 6601888912 a.n. Rendra Maulana'
    photo_url = 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80'
    account_status = 'Aktif'
    verification_status = 'Terverifikasi'
    login_activity = 'Login 20 Juni 2026'
    kos = @{
      nama_kos = 'Setiabudi Transit House'
      area = 'Bandung'
      alamat = 'Jl. Setiabudi Atas No. 27, Setiabudi, Bandung'
      deskripsi = 'Kos praktis untuk pekerja dan mahasiswa dengan akses angkot mudah dan kamar tertata rapi.'
      harga_mulai = 1200000
      fasilitas = @('WiFi', 'AC', 'Kasur', 'Lemari', 'Dapur Bersama', 'Parkir Motor', 'CCTV')
      gender = 'Campur'
      approval_mode = 'Auto Approval'
      foto_urls = @(
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80&h=840',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80&h=840'
      )
      rating = 4.7
      total_review = 25
      total_rooms = 13
      available_rooms = 4
      status = 'active'
    }
  }
  @{
    name = 'Tiara Aprilia'
    email = 'demo.penyewa13@koshub.app'
    password = 'DemoKosHub#2026'
    phone_number = '081290001013'
    ktp_number = '3273011505050013'
    emergency_contact = 'Ayah Rudi - 081290009013'
    bank_account = 'CIMB Niaga 800123456713 a.n. Tiara Aprilia'
    photo_url = 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&w=400&q=80'
    account_status = 'Aktif'
    verification_status = 'Terverifikasi'
    login_activity = 'Login 20 Juni 2026'
    kos = @{
      nama_kos = 'Setiabudi Green Living'
      area = 'Bandung'
      alamat = 'Jl. Dr. Setiabudi No. 88, Setiabudi, Bandung'
      deskripsi = 'Kos putri premium ekonomis dengan ruang jemur, pantry, dan area yang adem di Setiabudi.'
      harga_mulai = 1300000
      fasilitas = @('WiFi', 'AC', 'Kamar Mandi Dalam', 'Pantry', 'Laundry', 'CCTV', 'Akses Fingerprint')
      gender = 'Putri'
      approval_mode = 'Manual Approval'
      foto_urls = @(
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80&h=830',
        'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80&h=830'
      )
      rating = 4.8
      total_review = 28
      total_rooms = 11
      available_rooms = 2
      status = 'active'
    }
  }
)

$listUrl = "$supabaseUrl/auth/v1/admin/users?page=1&per_page=1000"
$existingUsers = Invoke-SupabaseJson -Method 'GET' -Url $listUrl -Headers $adminHeaders
$existingByEmail = @{}

foreach ($user in ($existingUsers.users | Where-Object { $_.email })) {
  $existingByEmail[$user.email.ToLowerInvariant()] = $user
}

$results = @()

foreach ($account in $accounts) {
  $emailKey = $account.email.ToLowerInvariant()
  $user = $existingByEmail[$emailKey]
  $wasCreated = $false

  if (-not $user) {
    $createBody = @{
      email = $account.email
      password = $account.password
      email_confirm = $true
      user_metadata = @{
        name = $account.name
        photo_url = $account.photo_url
      }
    }

    $user = Invoke-SupabaseJson `
      -Method 'POST' `
      -Url "$supabaseUrl/auth/v1/admin/users" `
      -Headers $adminHeaders `
      -Body $createBody

    $existingByEmail[$emailKey] = $user
    $wasCreated = $true
  }

  $profileBody = @(
    @{
      id = $user.id
      name = $account.name
      email = $account.email
      role = 'pemilik'
      requested_role = 'pemilik'
      is_active = $true
      photo_url = $account.photo_url
      phone_number = $account.phone_number
      ktp_number = $account.ktp_number
      emergency_contact = $account.emergency_contact
      bank_account = $account.bank_account
      account_status = $account.account_status
      verification_status = $account.verification_status
      login_activity = $account.login_activity
      activation_payment_status = 'Lunas'
      activation_payment_method = 'Transfer Manual'
      owner_activation_fee = 250000
      owner_activation_discount = 0
      owner_voucher_code = ''
      owner_status = 'Online'
      admin_notes = 'Akun demo pemilik otomatis'
    }
  )

  $null = Invoke-SupabaseJson `
    -Method 'POST' `
    -Url "$supabaseUrl/rest/v1/profiles?on_conflict=id" `
    -Headers $restHeaders `
    -Body $profileBody

  $existingKos = Invoke-SupabaseJson `
    -Method 'GET' `
    -Url "$supabaseUrl/rest/v1/kos?select=id&owner_id=eq.$($user.id)&limit=1" `
    -Headers $restHeaders

  $kosPayload = @{
    owner_id = $user.id
    owner_name = $account.name
    owner_status = 'Online'
    owner_photo = $account.photo_url
    bank_account = $account.bank_account
    nama_kos = $account.kos.nama_kos
    area = $account.kos.area
    alamat = $account.kos.alamat
    deskripsi = $account.kos.deskripsi
    harga_mulai = $account.kos.harga_mulai
    fasilitas = $account.kos.fasilitas
    gender = $account.kos.gender
    approval_mode = $account.kos.approval_mode
    foto_urls = $account.kos.foto_urls
    rating = $account.kos.rating
    total_review = $account.kos.total_review
    total_rooms = $account.kos.total_rooms
    available_rooms = $account.kos.available_rooms
    status = $account.kos.status
  }

  if ($existingKos -and $existingKos.Count -gt 0) {
    $null = Invoke-SupabaseJson `
      -Method 'PATCH' `
      -Url "$supabaseUrl/rest/v1/kos?id=eq.$($existingKos[0].id)" `
      -Headers $restHeaders `
      -Body $kosPayload
    $listingStatus = 'updated'
  } else {
    $null = Invoke-SupabaseJson `
      -Method 'POST' `
      -Url "$supabaseUrl/rest/v1/kos" `
      -Headers $restHeaders `
      -Body @($kosPayload)
    $listingStatus = 'created'
  }

  $results += [pscustomobject]@{
    Email = $account.email
    Name = $account.name
    Password = $account.password
    Status = if ($wasCreated) { 'created' } else { 'updated' }
    Listing = $listingStatus
    UserId = $user.id
  }
}

$results | Format-Table -AutoSize
