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
  final _bankAccountController = TextEditingController();
  final _paymentProofController = TextEditingController();
  final _voucherController = TextEditingController();
  final _googleMapsLinkController = TextEditingController();
  final List<String> _kosPhotoUrls = [];
  Uint8List? _selectedPaymentProofBytes;
  String? _selectedPaymentProofName;

  String _selectedCategory = 'Campur';
  bool _saving = false;
  int _discountAmount = 0;
  bool _uploadingKosPhoto = false;
  bool _uploadingPaymentProof = false;
  bool _checkingVoucher = false;
  String? _appliedVoucherCode;
  String? _voucherFeedback;

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
        : _formatNumericInput(existingKos.price.toString());
    _priceController.addListener(_handlePriceChanged);
    _roomController.text = existingKos == null
        ? '1'
        : existingKos.availableRooms.toString();
    _facilityController.text = existingKos?.facilities.join(', ') ?? '';
    _kosPhotoUrls
      ..clear()
      ..addAll(existingKos?.gallery ?? const <String>[]);
    _photoController.text = _kosPhotoUrls.isEmpty ? '' : _kosPhotoUrls.first;
    _phoneController.text = widget.profile?.phoneNumber == '-'
        ? ''
        : widget.profile?.phoneNumber ?? '';
    _ktpController.text = widget.profile?.ktpNumber == '-'
        ? ''
        : widget.profile?.ktpNumber ?? '';
    _bankAccountController.text = storedBankAccount;
    _paymentProofController.text =
        widget.profile?.activationPaymentProofUrl ?? '';
    _voucherController.text = widget.profile?.ownerVoucherCode ?? '';
    _voucherController.addListener(_handleVoucherCodeChanged);
    _discountAmount = widget.profile?.ownerActivationDiscount ?? 0;
    if (_isFreeOwnerActivationVoucherCode(_voucherController.text)) {
      _discountAmount = _ownerActivationBaseFee;
    }
    if (_voucherController.text.trim().isNotEmpty && _discountAmount > 0) {
      _appliedVoucherCode = _voucherController.text.trim().toUpperCase();
      _voucherFeedback = 'Voucher sudah digunakan.';
    }
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
    _priceController.removeListener(_handlePriceChanged);
    _priceController.dispose();
    _roomController.dispose();
    _facilityController.dispose();
    _photoController.dispose();
    _phoneController.dispose();
    _ktpController.dispose();
    _bankAccountController.dispose();
    _paymentProofController.dispose();
    _voucherController.removeListener(_handleVoucherCodeChanged);
    _voucherController.dispose();
    _googleMapsLinkController.dispose();
    super.dispose();
  }

  void _handleVoucherCodeChanged() {
    final normalizedCode = _voucherController.text.trim().toUpperCase();
    if (normalizedCode != (_appliedVoucherCode ?? '') &&
        (_appliedVoucherCode != null ||
            _discountAmount != 0 ||
            _voucherFeedback != null)) {
      setState(() {
        _appliedVoucherCode = null;
        _discountAmount = 0;
        _voucherFeedback = null;
      });
    }
  }

  void _handlePriceChanged() {
    final formatted = _formatNumericInput(_priceController.text);
    if (formatted == _priceController.text) {
      return;
    }
    _priceController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
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
    final isFreeActivation = !isApprovedOwner && feeAfterDiscount == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isApprovedOwner
              ? 'Edit Kos'
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
                  Text(
                    isFreeActivation
                        ? 'Voucher menanggung biaya aktivasi. Admin tetap akan mengecek data owner dan listing sebelum akun diaktifkan.'
                        : 'Upload bukti transfer manual agar admin bisa konfirmasi dan mengaktifkan akun pemilik kos.',
                    style: const TextStyle(
                      color: Color(0xFF5D6B6B),
                      height: 1.45,
                    ),
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
                      hintText: 'Opsional, contoh: KOSHUB99',
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _checkingVoucher ? null : _applyVoucher,
                        icon: _checkingVoucher
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.local_offer_rounded),
                        label: Text(
                          _checkingVoucher
                              ? 'Mengecek Voucher...'
                              : 'Gunakan Voucher',
                        ),
                      ),
                    ),
                    if (_voucherFeedback != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _voucherFeedback!,
                        style: TextStyle(
                          color: _discountAmount > 0
                              ? const Color(0xFF006A6A)
                              : const Color(0xFF9F4035),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
            if (!isFreeActivation) ...[
              _UploadImageCard(
                label: 'Bukti pembayaran aktivasi',
                hint:
                    'Upload bukti transfer dari galeri, bukan tempel URL lagi.',
                imageUrl: _paymentProofController.text.trim(),
                imageBytes: _selectedPaymentProofBytes,
                fileName: _selectedPaymentProofName,
                onPick: _pickPaymentProofImage,
                isLoading: _uploadingPaymentProof,
              ),
              const SizedBox(height: 20),
            ],
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
                  'Link pendek maps.app.goo.gl tetap bisa dipakai. Koordinat hanya terbaca otomatis dari link Google Maps panjang.',
                  style: TextStyle(
                    color: Color(0xFF7E9090),
                    fontSize: 11,
                    height: 1.4,
                  ),
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
            label: 'Harga per bulan (Rp)',
            hintText: 'Contoh: 1.500.000',
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
          _KosGalleryUploadCard(
            imageUrls: _kosPhotoUrls,
            onPick: _pickKosPhotoImages,
            onRemove: _removeKosPhoto,
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

  Future<void> _pickKosPhotoImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 88);
    if (files.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => _uploadingKosPhoto = true);

    try {
      final user = SupabaseAuth.instance.currentUser!;
      final uploadedUrls = <String>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final url = await SupabaseService.instance.uploadOwnerImage(
          user: user,
          bytes: bytes,
          fileName: file.name,
          folder: 'kos-images',
        );
        uploadedUrls.add(url);
      }
      if (mounted) {
        setState(() {
          _kosPhotoUrls.addAll(uploadedUrls);
          _photoController.text = _kosPhotoUrls.isEmpty
              ? ''
              : _kosPhotoUrls.first;
        });
        _showMessage('${uploadedUrls.length} foto kos berhasil diunggah.');
      }
    } catch (e) {
      if (mounted) {
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

  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _appliedVoucherCode = null;
        _discountAmount = 0;
        _voucherFeedback = 'Masukkan kode voucher dulu.';
      });
      return;
    }

    setState(() => _checkingVoucher = true);
    try {
      final voucher = await SupabaseService.instance.activeOwnerVoucherForCode(
        code,
      );
      if (!mounted) {
        return;
      }
      if (voucher == null) {
        setState(() {
          _appliedVoucherCode = null;
          _discountAmount = 0;
          _voucherFeedback = 'Voucher tidak ditemukan atau sudah nonaktif.';
        });
        return;
      }

      final discount = _ownerActivationDiscountFromVoucher(voucher);
      setState(() {
        _appliedVoucherCode = voucher.code.trim().toUpperCase();
        _voucherController.text = voucher.code;
        _discountAmount = discount;
        _voucherFeedback = discount > 0
            ? 'Voucher ${voucher.code} berhasil digunakan.'
            : 'Voucher valid, tapi belum memiliki potongan.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _voucherFeedback = 'Voucher belum bisa dicek. Coba lagi sebentar.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _checkingVoucher = false);
      }
    }
  }

  void _removeKosPhoto(String imageUrl) {
    setState(() {
      _kosPhotoUrls.remove(imageUrl);
      _photoController.text = _kosPhotoUrls.isEmpty ? '' : _kosPhotoUrls.first;
    });
  }

  Future<void> _submit() async {
    if (_uploadingKosPhoto || _uploadingPaymentProof) {
      _showMessage('Mohon tunggu hingga proses upload selesai.');
      return;
    }

    final ownerName = _ownerNameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final ktpNumber = _ktpController.text.trim();
    const emergencyContact = '';
    final bankAccountInput = _bankAccountController.text.trim();
    final kosName = _kosNameController.text.trim();
    final area = _areaController.text.trim();
    final address = _addressController.text.trim();
    final description = _descriptionController.text.trim();
    final monthlyPrice = _parseNumericInput(_priceController.text);
    final availableRooms = int.tryParse(_roomController.text.trim());
    final photoUrls = List<String>.from(_kosPhotoUrls);
    final photoUrl = photoUrls.isEmpty ? '' : photoUrls.first;
    var paymentProofUrl = _paymentProofController.text.trim();
    final enteredVoucherCode = _voucherController.text.trim();
    final normalizedEnteredVoucherCode = enteredVoucherCode.toUpperCase();
    final hasAppliedVoucher =
        _appliedVoucherCode != null &&
        _appliedVoucherCode == normalizedEnteredVoucherCode;
    final voucherCode = hasAppliedVoucher ? enteredVoucherCode : '';
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
    final resolvedDiscountAmount = hasAppliedVoucher ? _discountAmount : 0;
    final isFreeActivation =
        !isApprovedOwner &&
        math.max(0, _ownerActivationBaseFee - resolvedDiscountAmount) == 0;
    final hasKosPhoto = photoUrls.isNotEmpty;
    final hasPaymentProof =
        _selectedPaymentProofBytes != null || paymentProofUrl.trim().isNotEmpty;

    final googleMapsLinkVal = _googleMapsLinkController.text.trim();
    final parsed = _parseLatLngFromUrl(googleMapsLinkVal);
    final latitudeVal = parsed?.$1 ?? widget.existingKos?.latitude ?? 0.0;
    final longitudeVal = parsed?.$2 ?? widget.existingKos?.longitude ?? 0.0;
    final normalizedPhoneNumber = _normalizeIndonesianMobileNumber(
      phoneNumber,
    );

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

    if (phoneNumber.isNotEmpty && normalizedPhoneNumber == null) {
      _showMessage(_indonesianMobileNumberHint('Nomor HP'));
      return;
    }

    if (googleMapsLinkVal.isEmpty || !_isGoogleMapsUrl(googleMapsLinkVal)) {
      _showMessage(
        'Link lokasi harus dari Google Maps. Salin dari tombol Share di Google Maps.',
      );
      return;
    }

    if (!isApprovedOwner &&
        (phoneNumber.isEmpty ||
            ktpNumber.isEmpty ||
            bankAccount.isEmpty ||
            (!isFreeActivation && !hasPaymentProof))) {
      _showMessage(
        enteredVoucherCode.isNotEmpty && !hasAppliedVoucher && !hasPaymentProof
            ? 'Klik Gunakan Voucher dulu atau upload bukti pembayaran aktivasi.'
            : isFreeActivation
            ? 'Lengkapi identitas owner sebelum mengirim pengajuan.'
            : 'Lengkapi identitas owner dan bukti pembayaran aktivasi.',
      );
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
          photoUrls: photoUrls,
          phoneNumber: normalizedPhoneNumber ?? phoneNumber,
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
          photoUrls: photoUrls,
          phoneNumber: normalizedPhoneNumber ?? phoneNumber,
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
    } catch (error) {
      _showMessage(
        widget.existingKos == null
            ? 'Pendaftaran pemilik gagal diproses. ${_unknownSaveErrorMessage(error)}'
            : 'Perubahan listing gagal disimpan. ${_unknownSaveErrorMessage(error)}',
      );
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
                                : Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFF7FBFB),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.broken_image_rounded,
                                        size: 40,
                                        color: Color(0xFFB8D7D7),
                                      ),
                                    ),
                                  ),
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
                          color: Colors.white.withValues(alpha: 0.85),
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

class _KosGalleryUploadCard extends StatelessWidget {
  const _KosGalleryUploadCard({
    required this.imageUrls,
    required this.onPick,
    required this.onRemove,
    required this.isLoading,
  });

  final List<String> imageUrls;
  final Future<void> Function() onPick;
  final ValueChanged<String> onRemove;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto kos',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF314040),
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4ECEC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrls.isEmpty)
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FBFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDE9E9)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 36,
                        color: Color(0xFF7E9090),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Belum ada foto kos',
                        style: TextStyle(
                          color: Color(0xFF7E9090),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final imageUrl = imageUrls[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 132,
                              height: 112,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 8,
                            child: _TagChip(
                              label: index == 0 ? 'Utama' : '${index + 1}',
                              color: index == 0
                                  ? const Color(0xFF006A6A)
                                  : const Color(0xFF35589F),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: isLoading
                                    ? null
                                    : () => onRemove(imageUrl),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'Foto pertama akan menjadi cover. Foto lainnya tampil sebagai galeri di detail kos.',
                style: TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
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
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_rounded),
                  label: Text(isLoading ? 'Mengunggah...' : 'Tambah Foto'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
