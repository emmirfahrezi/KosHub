create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '-',
  email text not null default '-',
  role text not null default 'penyewa',
  requested_role text not null default '',
  is_active boolean not null default true,
  photo_url text not null default '',
  phone_number text not null default '',
  ktp_number text not null default '',
  emergency_contact text not null default '',
  bank_account text not null default '',
  account_status text not null default 'Aktif',
  verification_status text not null default 'Belum Verifikasi',
  login_activity text not null default '',
  activation_payment_method text not null default 'Transfer Manual',
  activation_payment_status text not null default 'Belum Bayar',
  activation_payment_proof_url text not null default '',
  owner_activation_fee integer not null default 250000,
  owner_activation_discount integer not null default 0,
  owner_voucher_code text not null default '',
  owner_application_submitted_at timestamptz,
  owner_status text not null default '',
  admin_notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.kos (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  owner_name text not null default 'Pemilik Kos',
  owner_status text not null default 'Online',
  owner_photo text not null default '',
  nama_kos text not null,
  area text not null default '-',
  alamat text not null default '-',
  deskripsi text not null default '-',
  harga_mulai integer not null default 0,
  fasilitas text[] not null default '{}',
  gender text not null default '-',
  approval_mode text not null default 'Manual Approval',
  foto_urls text[] not null default '{}',
  rating numeric not null default 0,
  total_review integer not null default 0,
  total_rooms integer not null default 0,
  available_rooms integer not null default 0,
  status text not null default 'pending_review',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  kos_id uuid not null references public.kos(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  owner_name text not null default '',
  owner_photo text not null default '',
  penyewa_id uuid not null references public.profiles(id) on delete cascade,
  penyewa_name text not null default '',
  penyewa_photo text not null default '',
  participant_ids uuid[] not null default '{}',
  kos_snapshot jsonb not null default '{}'::jsonb,
  last_message text not null default '',
  last_message_time timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (kos_id, penyewa_id)
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  sender_name text not null default '',
  text text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  kos_id uuid not null references public.kos(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  user_name text not null default 'Penyewa',
  user_email text not null default '-',
  user_phone text not null default '-',
  user_photo text not null default '',
  emergency_contact text not null default '-',
  kos_snapshot jsonb not null default '{}'::jsonb,
  room_label text not null default '-',
  note text not null default '',
  payment_proof_url text not null default '',
  start_date date not null,
  start_date_label text not null default '',
  end_date date not null,
  end_date_label text not null default '',
  duration_label text not null default '1 bulan',
  monthly_price integer not null default 0,
  payment_method text not null default '-',
  payment_status text not null default 'Pending',
  status text not null default 'Menunggu Konfirmasi',
  cancel_reason text,
  total_price integer not null default 0,
  payment_updated_at timestamptz,
  owner_notes text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cms_home_banners (
  id uuid primary key default gen_random_uuid(),
  title text not null default '',
  subtitle text not null default '',
  image_url text not null default '',
  placement text not null default 'hero',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.owner_vouchers (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title text not null default '',
  description text not null default '',
  discount_amount integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role in (
        'admin',
        'super_admin',
        'moderator',
        'finance_admin',
        'customer_service'
      )
  );
$$;

create or replace function public.current_profile_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role
  from public.profiles
  where id = auth.uid();
$$;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

drop trigger if exists kos_touch_updated_at on public.kos;
create trigger kos_touch_updated_at
before update on public.kos
for each row execute function public.touch_updated_at();

drop trigger if exists chats_touch_updated_at on public.chats;
create trigger chats_touch_updated_at
before update on public.chats
for each row execute function public.touch_updated_at();

drop trigger if exists bookings_touch_updated_at on public.bookings;
create trigger bookings_touch_updated_at
before update on public.bookings
for each row execute function public.touch_updated_at();

drop trigger if exists cms_home_banners_touch_updated_at on public.cms_home_banners;
create trigger cms_home_banners_touch_updated_at
before update on public.cms_home_banners
for each row execute function public.touch_updated_at();

drop trigger if exists owner_vouchers_touch_updated_at on public.owner_vouchers;
create trigger owner_vouchers_touch_updated_at
before update on public.owner_vouchers
for each row execute function public.touch_updated_at();

create or replace function public.create_booking_and_decrement_room(
  p_kos_id uuid,
  p_room_label text,
  p_note text,
  p_payment_proof_url text,
  p_start_date date,
  p_start_date_label text,
  p_end_date date,
  p_end_date_label text,
  p_duration_label text,
  p_monthly_price integer,
  p_payment_method text,
  p_total_price integer
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_kos public.kos%rowtype;
  v_profile public.profiles%rowtype;
  v_booking_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Sesi login tidak valid.';
  end if;

  select * into v_kos
  from public.kos
  where id = p_kos_id
  for update;

  if not found then
    raise exception 'Data kos tidak ditemukan.';
  end if;

  if v_kos.available_rooms <= 0 then
    raise exception 'Kamar sudah penuh.';
  end if;

  if v_kos.owner_id = auth.uid() then
    raise exception 'Pemilik kos tidak bisa booking kos sendiri.';
  end if;

  select * into v_profile
  from public.profiles
  where id = auth.uid();

  if not found then
    raise exception 'Profil user belum tersedia.';
  end if;

  insert into public.bookings (
    kos_id,
    owner_id,
    user_id,
    user_name,
    user_email,
    user_phone,
    user_photo,
    emergency_contact,
    kos_snapshot,
    room_label,
    note,
    payment_proof_url,
    start_date,
    start_date_label,
    end_date,
    end_date_label,
    duration_label,
    monthly_price,
    payment_method,
    payment_status,
    total_price
  )
  values (
    v_kos.id,
    v_kos.owner_id,
    auth.uid(),
    v_profile.name,
    v_profile.email,
    v_profile.phone_number,
    v_profile.photo_url,
    v_profile.emergency_contact,
    to_jsonb(v_kos),
    p_room_label,
    p_note,
    p_payment_proof_url,
    p_start_date,
    p_start_date_label,
    p_end_date,
    p_end_date_label,
    p_duration_label,
    p_monthly_price,
    p_payment_method,
    case when p_payment_proof_url = '' then 'Belum Bayar' else 'Menunggu Konfirmasi' end,
    p_total_price
  )
  returning id into v_booking_id;

  update public.kos
  set available_rooms = greatest(available_rooms - 1, 0)
  where id = v_kos.id;

  return v_booking_id;
end;
$$;

alter table public.profiles enable row level security;
alter table public.kos enable row level security;
alter table public.chats enable row level security;
alter table public.chat_messages enable row level security;
alter table public.bookings enable row level security;
alter table public.cms_home_banners enable row level security;
alter table public.owner_vouchers enable row level security;

drop policy if exists profiles_select_self_or_admin on public.profiles;
create policy profiles_select_self_or_admin on public.profiles
for select using (id = auth.uid() or public.is_admin());

drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles
for insert with check (id = auth.uid() and role = 'penyewa');

drop policy if exists profiles_update_self_or_admin on public.profiles;
create policy profiles_update_self_or_admin on public.profiles
for update using (id = auth.uid() or public.is_admin())
with check (
  public.is_admin()
  or (
    id = auth.uid()
    and (
      role = public.current_profile_role()
      or (
        lower(email) in (
          'emmir.fahrezi1@gmail.com',
          'faizkhairan6@gmail.com'
        )
        and role = 'super_admin'
      )
    )
  )
);

drop policy if exists kos_select_signed_in on public.kos;
create policy kos_select_signed_in on public.kos
for select using (auth.uid() is not null);

drop policy if exists kos_insert_owner on public.kos;
create policy kos_insert_owner on public.kos
for insert with check (owner_id = auth.uid());

drop policy if exists kos_update_owner_or_admin on public.kos;
create policy kos_update_owner_or_admin on public.kos
for update using (owner_id = auth.uid() or public.is_admin())
with check (owner_id = auth.uid() or public.is_admin());

drop policy if exists chats_select_participant on public.chats;
create policy chats_select_participant on public.chats
for select using (auth.uid() = any(participant_ids));

drop policy if exists chats_insert_participant on public.chats;
create policy chats_insert_participant on public.chats
for insert with check (auth.uid() = any(participant_ids));

drop policy if exists chats_update_participant on public.chats;
create policy chats_update_participant on public.chats
for update using (auth.uid() = any(participant_ids))
with check (auth.uid() = any(participant_ids));

drop policy if exists chat_messages_select_participant on public.chat_messages;
create policy chat_messages_select_participant on public.chat_messages
for select using (
  exists (
    select 1 from public.chats
    where chats.id = chat_messages.chat_id
      and auth.uid() = any(chats.participant_ids)
  )
);

drop policy if exists chat_messages_insert_sender on public.chat_messages;
create policy chat_messages_insert_sender on public.chat_messages
for insert with check (
  sender_id = auth.uid()
  and exists (
    select 1 from public.chats
    where chats.id = chat_messages.chat_id
      and auth.uid() = any(chats.participant_ids)
  )
);

drop policy if exists bookings_select_related_or_admin on public.bookings;
create policy bookings_select_related_or_admin on public.bookings
for select using (
  public.is_admin()
  or user_id = auth.uid()
  or owner_id = auth.uid()
);

drop policy if exists bookings_insert_self on public.bookings;
create policy bookings_insert_self on public.bookings
for insert with check (user_id = auth.uid());

drop policy if exists bookings_update_related_or_admin on public.bookings;
create policy bookings_update_related_or_admin on public.bookings
for update using (
  public.is_admin()
  or user_id = auth.uid()
  or owner_id = auth.uid()
)
with check (
  public.is_admin()
  or user_id = auth.uid()
  or owner_id = auth.uid()
);

drop policy if exists home_banners_select_signed_in on public.cms_home_banners;
create policy home_banners_select_signed_in on public.cms_home_banners
for select using (auth.uid() is not null);

drop policy if exists home_banners_admin_write on public.cms_home_banners;
create policy home_banners_admin_write on public.cms_home_banners
for all using (public.is_admin())
with check (public.is_admin());

drop policy if exists owner_vouchers_select_signed_in on public.owner_vouchers;
create policy owner_vouchers_select_signed_in on public.owner_vouchers
for select using (auth.uid() is not null);

drop policy if exists owner_vouchers_admin_write on public.owner_vouchers;
create policy owner_vouchers_admin_write on public.owner_vouchers
for all using (public.is_admin())
with check (public.is_admin());
