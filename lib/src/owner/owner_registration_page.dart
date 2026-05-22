part of '../../main.dart';

class OwnerRegistrationPage extends StatefulWidget {
  const OwnerRegistrationPage({super.key, this.existingKos, this.profile});

  final KosData? existingKos;
  final AppUserData? profile;

  @override
  State<OwnerRegistrationPage> createState() => _OwnerRegistrationPageState();
}

class _OwnerRegistrationPageState extends State<OwnerRegistrationPage> {
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

  String _selectedCategory = 'Campur';
  String _selectedApprovalMode = 'Manual Approval';
  bool _saving = false;
  int _discountAmount = 0;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final existingKos = widget.existingKos;
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
        : _sampleKosMap1['foto_urls'][0] as String;
    _phoneController.text = widget.profile?.phoneNumber == '-'
        ? ''
        : widget.profile?.phoneNumber ?? '';
    _ktpController.text = widget.profile?.ktpNumber == '-'
        ? ''
        : widget.profile?.ktpNumber ?? '';
    _emergencyController.text = widget.profile?.emergencyContact == '-'
        ? ''
        : widget.profile?.emergencyContact ?? '';
    _bankAccountController.text =
        widget.profile?.bankAccountLabel == 'Belum diisi'
        ? ''
        : widget.profile?.bankAccountLabel ?? '';
    _paymentProofController.text =
        widget.profile?.activationPaymentProofUrl ?? '';
    _voucherController.text = widget.profile?.ownerVoucherCode ?? '';
    _discountAmount = widget.profile?.ownerActivationDiscount ?? 0;
    _selectedCategory = existingKos?.category ?? 'Campur';
    _selectedApprovalMode = existingKos?.approvalMode ?? 'Manual Approval';
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
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
              stream: FirestoreService.instance.ownerVouchersStream(),
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
            _InputField(
              controller: _paymentProofController,
              label: 'URL bukti pembayaran',
              hintText: 'Tempel link bukti transfer manual',
              keyboardType: TextInputType.url,
              maxLines: 2,
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
          _SelectCard(
            label: 'Persetujuan booking',
            value: _selectedApprovalMode,
            items: const ['Manual Approval', 'Auto Approval'],
            onChanged: (value) => setState(() => _selectedApprovalMode = value),
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _facilityController,
            label: 'Fasilitas',
            hintText: 'Pisahkan dengan koma, contoh: WiFi, AC, CCTV',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _photoController,
            label: 'URL foto kos',
            hintText: 'Tempel link foto utama kos',
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF006A6A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
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
              : Text(isEditing ? 'Simpan Perubahan' : 'Kirim Pendaftaran'),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final ownerName = _ownerNameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final ktpNumber = _ktpController.text.trim();
    final emergencyContact = _emergencyController.text.trim();
    final bankAccount = _bankAccountController.text.trim();
    final kosName = _kosNameController.text.trim();
    final area = _areaController.text.trim();
    final address = _addressController.text.trim();
    final description = _descriptionController.text.trim();
    final monthlyPrice = int.tryParse(_priceController.text.trim());
    final availableRooms = int.tryParse(_roomController.text.trim());
    final photoUrl = _photoController.text.trim();
    final paymentProofUrl = _paymentProofController.text.trim();
    final voucherCode = _voucherController.text.trim();
    final facilities = _facilityController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final isApprovedOwner =
        widget.profile?.canAccessOwnerShell == true ||
        widget.existingKos?.listingStatus == 'active';

    if (ownerName.isEmpty ||
        kosName.isEmpty ||
        area.isEmpty ||
        address.isEmpty ||
        description.isEmpty ||
        monthlyPrice == null ||
        availableRooms == null ||
        photoUrl.isEmpty) {
      _showMessage('Semua data wajib diisi dengan benar.');
      return;
    }

    if (!isApprovedOwner &&
        (phoneNumber.isEmpty ||
            ktpNumber.isEmpty ||
            emergencyContact.isEmpty ||
            bankAccount.isEmpty ||
            paymentProofUrl.isEmpty)) {
      _showMessage('Lengkapi identitas owner dan bukti pembayaran aktivasi.');
      return;
    }

    if (facilities.isEmpty) {
      _showMessage('Isi minimal satu fasilitas kos.');
      return;
    }

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      if (widget.existingKos == null) {
        await FirestoreService.instance.registerOwnerKos(
          user: user,
          ownerName: ownerName,
          kosName: kosName,
          area: area,
          address: address,
          description: description,
          monthlyPrice: monthlyPrice,
          availableRooms: availableRooms,
          category: _selectedCategory,
          approvalMode: _selectedApprovalMode,
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
        await FirestoreService.instance.updateOwnerKos(
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
          approvalMode: _selectedApprovalMode,
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
    } on FirebaseException catch (error) {
      _showMessage(_firebaseMessage(error));
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
}
