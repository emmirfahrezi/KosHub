part of '../../main.dart';

class OwnerRegistrationPage extends StatefulWidget {
  const OwnerRegistrationPage({super.key, this.existingKos, this.profile});

  final KosData? existingKos;
  final AppUserData? profile;

  @override
  State<OwnerRegistrationPage> createState() => _OwnerRegistrationPageState();
}

class _OwnerRegistrationPageState extends State<OwnerRegistrationPage> {
  final _picker = ImagePicker();
  final _ownerNameController = TextEditingController();
  final _kosNameController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _roomController = TextEditingController(text: '1');
  final _facilityController = TextEditingController();
  final _photoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ktpController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _paymentProofController = TextEditingController();
  final _voucherController = TextEditingController();
  final _googleMapsLinkController = TextEditingController();
  Uint8List? _selectedKosPhotoBytes;
  String? _selectedKosPhotoName;
  Uint8List? _selectedPaymentProofBytes;
  String? _selectedPaymentProofName;

  String _selectedCategory = 'Campur';
  bool _saving = false;
  int _discountAmount = 0;
  bool _uploadingKosPhoto = false;
  bool _uploadingPaymentProof = false;

  @override
  void initState() {
    super.initState();
    final user = SupabaseAuth.instance.currentUser;
    final existingKos = widget.existingKos;
    final storedBankAccount =
        widget.profile?.bankAccountLabel.trim().isNotEmpty == true &&
            widget.profile?.bankAccountLabel != 'Belum diisi'
        ? widget.profile!.bankAccountLabel
        : existingKos?.ownerBankAccount ?? '';
    _ownerNameController.text =
        existingKos?.ownerName ?? user?.displayName ?? '';
    _kosNameController.text = existingKos?.name ?? '';
    _areaController.text = existingKos?.area ?? '';
    _addressController.text = existingKos?.address ?? '';
    _descriptionController.text = existingKos?.description ?? '';
    _priceController.text = existingKos == null
        ? ''
        : existingKos.price.toString();
    _roomController.text = existingKos == null
        ? '1'
        : existingKos.availableRooms.toString();
    _facilityController.text = existingKos?.facilities.join(', ') ?? '';
    _photoController.text =
        existingKos != null && existingKos.gallery.isNotEmpty
        ? existingKos.gallery.first
        : '';
    _phoneController.text = widget.profile?.phoneNumber == '-'
        ? ''
        : widget.profile?.phoneNumber ?? '';
    _ktpController.text = widget.profile?.ktpNumber == '-'
        ? ''
        : widget.profile?.ktpNumber ?? '';
    _emergencyController.text = widget.profile?.emergencyContact == '-'
        ? ''
        : widget.profile?.emergencyContact ?? '';
    _bankAccountController.text = storedBankAccount;
    _paymentProofController.text =
        widget.profile?.activationPaymentProofUrl ?? '';
    _voucherController.text = widget.profile?.ownerVoucherCode ?? '';
    _discountAmount = widget.profile?.ownerActivationDiscount ?? 0;
    _selectedCategory = existingKos?.category ?? 'Campur';
    // Pre-fill Google Maps link from existing kos
    if (existingKos != null && existingKos.googleMapsLink.isNotEmpty) {
      _googleMapsLinkController.text = existingKos.googleMapsLink;
    } else if (existingKos != null && existingKos.latitude != 0.0) {
      _googleMapsLinkController.text =
          'https://www.google.com/maps/search/?api=1&query=${existingKos.latitude},${existingKos.longitude}';
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _kosNameController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _roomController.dispose();
    _facilityController.dispose();
    _photoController.dispose();
    _phoneController.dispose();
    _ktpController.dispose();
    _emergencyController.dispose();
    _bankAccountController.dispose();
    _paymentProofController.dispose();
    _voucherController.dispose();
    _googleMapsLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingKos != null;
    final isApprovedOwner =
        widget.profile?.canAccessOwnerShell == true ||
        widget.existingKos?.listingStatus == 'active';
    final feeAfterDiscount = math.max(
      0,
      _ownerActivationBaseFee - _discountAmount,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isApprovedOwner
              ? 'Edit Listing Kos'
              : isEditing
              ? 'Edit Pengajuan Pemilik'
              : 'Daftar Pemilik Kos',
        ),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isApprovedOwner
                      ? 'Perbarui data listing kosmu'
                      : isEditing
                      ? 'Perbarui pengajuan owner dan listing awalmu'
                      : 'Lengkapi data kos pertamamu',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isApprovedOwner
                      ? 'Nama kos, harga, fasilitas, dan detail lainnya bisa kamu ubah kapan saja dari sini.'
                      : 'Setelah dikirim, admin akan cek bukti pembayaran aktivasi, verifikasi data, lalu mengaktifkan akun pemilik dan listing kosmu.',
                  style: const TextStyle(
                    color: Color(0xFF5D6B6B),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!isApprovedOwner) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Biaya Aktivasi Owner',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: 'Biaya dasar',
                    value: _currency(_ownerActivationBaseFee),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Potongan voucher',
                    value: _currency(_discountAmount),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Total dibayar',
                    value: _currency(feeAfterDiscount),
                    bold: true,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Upload bukti transfer manual agar admin bisa konfirmasi dan mengaktifkan akun pemilik kos.',
                    style: TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InputField(
              controller: _phoneController,
              label: 'Nomor HP',
              hintText: 'Contoh: 081234567890',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _InputField(
              controller: _ktpController,
              label: 'Nomor KTP',
              hintText: 'Masukkan nomor KTP pemilik',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _InputField(
              controller: _emergencyController,
              label: 'Kontak darurat',
              hintText: 'Nama / nomor kontak darurat',
            ),
            const SizedBox(height: 16),
            _InputField(
              controller: _bankAccountController,
              label: 'Rekening penerima',
              hintText: 'Contoh: BCA 1234567890 a.n Nama Pemilik',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<OwnerVoucherData>>(
              stream: SupabaseService.instance.ownerVouchersStream(),
              builder: (context, snapshot) {
                final vouchers = (snapshot.data ?? const <OwnerVoucherData>[])
                    .where((item) => item.isActive)
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InputField(
                      controller: _voucherController,
                      label: 'Kode voucher owner',
                      hintText: 'Opsional, contoh: OWNERHEMAT',
                    ),
                    if (vouchers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: vouchers
                            .map(
                              (voucher) => ActionChip(
                                label: Text(
                                  '${voucher.code} • ${_currency(voucher.discountAmount)}',
                                ),
                                onPressed: () {
                                  setState(() {
                                    _voucherController.text = voucher.code;
                                    _discountAmount = voucher.discountAmount;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _UploadImageCard(
              label: 'Bukti pembayaran aktivasi',
              hint: 'Upload bukti transfer dari galeri, bukan tempel URL lagi.',
              imageUrl: _paymentProofController.text.trim(),
              imageBytes: _selectedPaymentProofBytes,
              fileName: _selectedPaymentProofName,
              onPick: _pickPaymentProofImage,
              isLoading: _uploadingPaymentProof,
            ),
            const SizedBox(height: 20),
          ],
          _InputField(
            controller: _ownerNameController,
            label: 'Nama pemilik',
            hintText: 'Nama lengkap pemilik kos',
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _kosNameController,
            label: 'Nama kos',
            hintText: 'Contoh: Kos Melati Harmoni',
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _areaController,
            label: 'Area',
            hintText: 'Contoh: Jakarta Selatan',
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _addressController,
            label: 'Alamat lengkap',
            hintText: 'Masukkan alamat kos',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          // ── Lokasi Google Maps ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4ECEC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: Color(0xFF006A6A), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Lokasi di Google Maps',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Buka Google Maps → cari kos → salin link dari tombol "Bagikan" atau "Share".',
                  style: TextStyle(color: Color(0xFF5D6B6B), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _googleMapsLinkController,
                  label: 'Link Google Maps',
                  hintText: 'Paste link dari Google Maps di sini',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Koordinat latitude & longitude akan diekstrak otomatis dari link.',
                  style: TextStyle(color: Color(0xFF7E9090), fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _descriptionController,
            label: 'Deskripsi kos',
            hintText: 'Jelaskan fasilitas dan keunggulan kos',
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _priceController,
            label: 'Harga per bulan',
            hintText: 'Contoh: 1500000',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _roomController,
            label: 'Jumlah kamar tersedia',
            hintText: 'Contoh: 3',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _SelectCard(
            label: 'Kategori kos',
            value: _selectedCategory,
            items: const ['Campur', 'Putra', 'Putri', 'Eksklusif'],
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _facilityController,
            label: 'Fasilitas',
            hintText: 'Pisahkan dengan koma, contoh: WiFi, AC, CCTV',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _UploadImageCard(
            label: 'Foto utama kos',
            hint:
                'Upload gambar utama listing dari galeri agar tampil di aplikasi.',
            imageUrl: _photoController.text.trim(),
            imageBytes: _selectedKosPhotoBytes,
            fileName: _selectedKosPhotoName,
            onPick: _pickKosPhotoImage,
            isLoading: _uploadingKosPhoto,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_saving || _uploadingKosPhoto || _uploadingPaymentProof) ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF006A6A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEditing ? 'Perbarui Listing Kos' : 'Kirim Pendaftaran',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickKosPhotoImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedKosPhotoBytes = bytes;
      _selectedKosPhotoName = file.name;
      _uploadingKosPhoto = true;
    });

    try {
      final user = SupabaseAuth.instance.currentUser!;
      final url = await SupabaseService.instance.uploadOwnerImage(
        user: user,
        bytes: bytes,
        fileName: file.name,
        folder: 'kos-images',
      );
      if (mounted) {
        setState(() {
          _photoController.text = url;
        });
        _showMessage('Foto kos berhasil diunggah.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedKosPhotoBytes = null;
          _selectedKosPhotoName = null;
        });
        _showMessage('Gagal mengunggah foto kos. Silakan coba lagi.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingKosPhoto = false;
        });
      }
    }
  }

  Future<void> _pickPaymentProofImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedPaymentProofBytes = bytes;
      _selectedPaymentProofName = file.name;
      _uploadingPaymentProof = true;
    });

    try {
      final user = SupabaseAuth.instance.currentUser!;
      final url = await SupabaseService.instance.uploadOwnerImage(
        user: user,
        bytes: bytes,
        fileName: file.name,
        folder: 'payment-proofs',
      );
      if (mounted) {
        setState(() {
          _paymentProofController.text = url;
        });
        _showMessage('Bukti pembayaran berhasil diunggah.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedPaymentProofBytes = null;
          _selectedPaymentProofName = null;
        });
        _showMessage('Gagal mengunggah bukti pembayaran. Silakan coba lagi.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPaymentProof = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_uploadingKosPhoto || _uploadingPaymentProof) {
      _showMessage('Mohon tunggu hingga proses upload selesai.');
      return;
    }

    final ownerName = _ownerNameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final ktpNumber = _ktpController.text.trim();
    final emergencyContact = _emergencyController.text.trim();
    final bankAccountInput = _bankAccountController.text.trim();
    final kosName = _kosNameController.text.trim();
    final area = _areaController.text.trim();
    final address = _addressController.text.trim();
    final description = _descriptionController.text.trim();
    final monthlyPrice = int.tryParse(_priceController.text.trim());
    final availableRooms = int.tryParse(_roomController.text.trim());
    var photoUrl = _photoController.text.trim();
    var paymentProofUrl = _paymentProofController.text.trim();
    final voucherCode = _voucherController.text.trim();
    final facilities = _facilityController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final isApprovedOwner =
        widget.profile?.canAccessOwnerShell == true ||
        widget.existingKos?.listingStatus == 'active';
    final storedBankAccount =
        widget.profile?.bankAccountLabel.trim().isNotEmpty == true &&
            widget.profile?.bankAccountLabel != 'Belum diisi'
        ? widget.profile!.bankAccountLabel
        : widget.existingKos?.ownerBankAccount.trim() ?? '';
    final bankAccount = bankAccountInput.isNotEmpty
        ? bankAccountInput
        : storedBankAccount;
    final hasKosPhoto =
        _selectedKosPhotoBytes != null || photoUrl.trim().isNotEmpty;
    final hasPaymentProof =
        _selectedPaymentProofBytes != null || paymentProofUrl.trim().isNotEmpty;

    final googleMapsLinkVal = _googleMapsLinkController.text.trim();
    // Auto-extract lat/lng from the Google Maps URL
    final parsed = _parseLatLngFromUrl(googleMapsLinkVal);
    final latitudeVal = parsed?.$1 ?? 0.0;
    final longitudeVal = parsed?.$2 ?? 0.0;

    if (ownerName.isEmpty ||
        kosName.isEmpty ||
        area.isEmpty ||
        address.isEmpty ||
        description.isEmpty ||
        monthlyPrice == null ||
        availableRooms == null ||
        !hasKosPhoto) {
      _showMessage('Semua data wajib diisi dengan benar.');
      return;
    }

    if (googleMapsLinkVal.isEmpty ||
        (!googleMapsLinkVal.startsWith('http://') &&
            !googleMapsLinkVal.startsWith('https://'))) {
      _showMessage('Link Google Maps tidak valid. Salin dari tombol Share di Google Maps.');
      return;
    }

    if (!isApprovedOwner &&
        (phoneNumber.isEmpty ||
            ktpNumber.isEmpty ||
            emergencyContact.isEmpty ||
            bankAccount.isEmpty ||
            !hasPaymentProof)) {
      _showMessage('Lengkapi identitas owner dan bukti pembayaran aktivasi.');
      return;
    }

    if (facilities.isEmpty) {
      _showMessage('Isi minimal satu fasilitas kos.');
      return;
    }

    setState(() => _saving = true);
    try {
      final user = SupabaseAuth.instance.currentUser!;
      if (widget.existingKos == null) {
        await SupabaseService.instance.registerOwnerKos(
          user: user,
          ownerName: ownerName,
          kosName: kosName,
          area: area,
          address: address,
          description: description,
          monthlyPrice: monthlyPrice,
          availableRooms: availableRooms,
          category: _selectedCategory,
          latitude: latitudeVal,
          longitude: longitudeVal,
          googleMapsLink: googleMapsLinkVal,
          facilities: facilities,
          photoUrl: photoUrl,
          phoneNumber: phoneNumber,
          ktpNumber: ktpNumber,
          emergencyContact: emergencyContact,
          bankAccount: bankAccount,
          paymentProofUrl: paymentProofUrl,
          voucherCode: voucherCode,
        );
      } else {
        await SupabaseService.instance.updateOwnerKos(
          user: user,
          kosId: widget.existingKos!.id,
          ownerName: ownerName,
          kosName: kosName,
          area: area,
          address: address,
          description: description,
          monthlyPrice: monthlyPrice,
          availableRooms: availableRooms,
          category: _selectedCategory,
          latitude: latitudeVal,
          longitude: longitudeVal,
          googleMapsLink: googleMapsLinkVal,
          facilities: facilities,
          photoUrl: photoUrl,
          phoneNumber: phoneNumber,
          ktpNumber: ktpNumber,
          emergencyContact: emergencyContact,
          bankAccount: bankAccount,
          paymentProofUrl: paymentProofUrl,
          voucherCode: voucherCode,
        );
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isApprovedOwner
                ? 'Perubahan listing kos berhasil disimpan.'
                : 'Pengajuan owner berhasil dikirim. Admin akan cek bukti pembayaran dan mengaktifkan akunmu.',
          ),
        ),
      );
      Navigator.pop(context);
    } on SupabaseAppException catch (error) {
      _showMessage(_supabaseMessage(error));
    } catch (_) {
      _showMessage('Pendaftaran pemilik gagal diproses. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Ekstrak (latitude, longitude) dari berbagai format URL Google Maps.
  /// Mendukung: maps.google.com/?q=, /maps/search/?q=, /@lat,lng,zoom,
  /// goo.gl/maps, maps.app.goo.gl, dan format share pendek lainnya.
  (double, double)? _parseLatLngFromUrl(String url) {
    if (url.isEmpty) return null;
    // Pattern 1: ?q=lat,lng atau &q=lat,lng
    final qPattern = RegExp(r'[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)');
    var match = qPattern.firstMatch(url);
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }
    // Pattern 2: /@lat,lng,zoom (Google Maps standard URL)
    final atPattern = RegExp(r'/@(-?\d+\.\d+),(-?\d+\.\d+)');
    match = atPattern.firstMatch(url);
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }
    // Pattern 3: !3d lat !4d lng (embedded Google Maps)
    final embPattern = RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)');
    match = embPattern.firstMatch(url);
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }
    // Pattern 4: ll=lat,lng
    final llPattern = RegExp(r'll=(-?\d+\.\d+),(-?\d+\.\d+)');
    match = llPattern.firstMatch(url);
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }
    return null;
  }
}

class _UploadImageCard extends StatelessWidget {
  const _UploadImageCard({
    required this.label,
    required this.hint,
    required this.imageUrl,
    required this.imageBytes,
    required this.fileName,
    required this.onPick,
    this.isLoading = false,
  });

  final String label;
  final String hint;
  final String imageUrl;
  final Uint8List? imageBytes;
  final String? fileName;
  final Future<void> Function() onPick;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hasPreview = imageBytes != null || imageUrl.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF314040),
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: isLoading ? null : () async => onPick(),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4ECEC)),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasPreview)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: double.infinity,
                            height: 180,
                            child: imageBytes != null
                                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                                : Image.network(imageUrl, fit: BoxFit.cover),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FBFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDDE9E9)),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: Color(0xFF7E9090),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Belum ada gambar dipilih',
                                style: TextStyle(
                                  color: Color(0xFF7E9090),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        fileName?.trim().isNotEmpty == true
                            ? 'File dipilih: $fileName'
                            : hint,
                        style: const TextStyle(
                          color: Color(0xFF5D6B6B),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : () async => onPick(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFB8D7D7)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.upload_rounded),
                          label: Text(
                            hasPreview ? 'Ganti Gambar' : 'Upload Gambar',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF006A6A),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Mengunggah gambar...',
                              style: TextStyle(
                                color: Color(0xFF006A6A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
