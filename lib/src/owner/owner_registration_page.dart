part of '../../main.dart';

class OwnerRegistrationPage extends StatefulWidget {
  const OwnerRegistrationPage({super.key, this.existingKos});

  final KosData? existingKos;

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

  String _selectedCategory = 'Campur';
  String _selectedApprovalMode = 'Manual Approval';
  bool _saving = false;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingKos != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Listing Kos' : 'Daftar Pemilik Kos'),
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
                  isEditing
                      ? 'Perbarui data listing kosmu'
                      : 'Lengkapi data kos pertamamu',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEditing
                      ? 'Nama kos, harga, fasilitas, dan detail lainnya bisa kamu ubah kapan saja dari sini.'
                      : 'Setelah dikirim, akunmu akan berubah menjadi pemilik dan listing kos langsung tampil di halaman utama.',
                  style: const TextStyle(
                    color: Color(0xFF5D6B6B),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
    final kosName = _kosNameController.text.trim();
    final area = _areaController.text.trim();
    final address = _addressController.text.trim();
    final description = _descriptionController.text.trim();
    final monthlyPrice = int.tryParse(_priceController.text.trim());
    final availableRooms = int.tryParse(_roomController.text.trim());
    final photoUrl = _photoController.text.trim();
    final facilities = _facilityController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

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
        );
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingKos == null
                ? 'Pendaftaran pemilik berhasil. Listing kos kamu sudah aktif.'
                : 'Perubahan listing kos berhasil disimpan.',
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
