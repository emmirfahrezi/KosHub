-- ============================================================
-- MIGRATION: Tambah kolom lokasi pada tabel kos
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================================

-- 1. Tambah kolom jika belum ada
alter table public.kos
  add column if not exists latitude numeric,
  add column if not exists longitude numeric,
  add column if not exists google_maps_link text;

-- ============================================================
-- 2. Update data kos yang ada dengan koordinat berdasarkan area
--    (Data riil harus diisi pemilik lewat form edit)
-- ============================================================

-- Jakarta Pusat (default: Menteng / Monas area)
update public.kos
set
  latitude        = -6.1919,
  longitude       = 106.8327,
  google_maps_link = 'https://www.google.com/maps/search/?api=1&query=-6.1919,106.8327'
where (latitude is null or latitude = 0)
  and lower(area) like '%jakarta pusat%';

-- Jakarta Selatan (default: Blok M / Kemang area)
update public.kos
set
  latitude        = -6.2515,
  longitude       = 106.8159,
  google_maps_link = 'https://www.google.com/maps/search/?api=1&query=-6.2515,106.8159'
where (latitude is null or latitude = 0)
  and lower(area) like '%jakarta selatan%';

-- Jakarta Barat (default: Grogol area)
update public.kos
set
  latitude        = -6.1671,
  longitude       = 106.7860,
  google_maps_link = 'https://www.google.com/maps/search/?api=1&query=-6.1671,106.7860'
where (latitude is null or latitude = 0)
  and lower(area) like '%jakarta barat%';

-- Jakarta Timur (default: Cawang area)
update public.kos
set
  latitude        = -6.2431,
  longitude       = 106.8716,
  google_maps_link = 'https://www.google.com/maps/search/?api=1&query=-6.2431,106.8716'
where (latitude is null or latitude = 0)
  and lower(area) like '%jakarta timur%';

-- Jakarta Utara (default: Ancol area)
update public.kos
set
  latitude        = -6.1248,
  longitude       = 106.8450,
  google_maps_link = 'https://www.google.com/maps/search/?api=1&query=-6.1248,106.8450'
where (latitude is null or latitude = 0)
  and lower(area) like '%jakarta utara%';

-- Depok (default: UI Depok area)
update public.kos
set
  latitude        = -6.3649,
  longitude       = 106.8274,
  google_maps_link = 'https://www.google.com/maps/search/?api=1&query=-6.3649,106.8274'
where (latitude is null or latitude = 0)
  and lower(area) like '%depok%';

-- Bekasi (default: Bekasi Kota area)
update public.kos
set
  latitude        = -6.2383,
  longitude       = 106.9756,
  google_maps_link = 'https://www.google.com/maps/search/?api=1&query=-6.2383,106.9756'
where (latitude is null or latitude = 0)
  and lower(area) like '%bekasi%';

-- Tangerang (default: Tangerang Kota area)
update public.kos
set
  latitude        = -6.1783,
  longitude       = 106.6308,
  google_maps_link = 'https://www.google.com/maps/search/?api=1&query=-6.1783,106.6308'
where (latitude is null or latitude = 0)
  and lower(area) like '%tangerang%';

-- Bogor (default: Kota Bogor area)
update public.kos
set
  latitude        = -6.5971,
  longitude       = 106.8060,
  google_maps_link = 'https://www.google.com/maps/search/?api=1&query=-6.5971,106.8060'
where (latitude is null or latitude = 0)
  and lower(area) like '%bogor%';

-- Fallback: semua yang masih null → koordinat default Jakarta
update public.kos
set
  latitude        = -6.2000,
  longitude       = 106.8166,
  google_maps_link = 'https://www.google.com/maps/search/?api=1&query=-6.2000,106.8166'
where (latitude is null or latitude = 0);

-- ============================================================
-- 3. Verifikasi hasil
-- ============================================================
select id, nama_kos, area, latitude, longitude, google_maps_link
from public.kos
order by created_at desc
limit 20;
