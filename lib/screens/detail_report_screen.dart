// screens/detail_report_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/report_model.dart';
import '../providers/report_provider.dart';

class DetailReportScreen extends ConsumerStatefulWidget {
  final ReportModel report;

  const DetailReportScreen({Key? key, required this.report}) : super(key: key);

  @override
  ConsumerState<DetailReportScreen> createState() => _DetailReportScreenState();
}

class _DetailReportScreenState extends ConsumerState<DetailReportScreen> {
  final _completionController = TextEditingController();
  File? _completionImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _completionController.dispose();
    super.dispose();
  }

  Future<void> _pickCompletionImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _completionImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil foto: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Sumber Foto Hasil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.green.shade700),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickCompletionImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.green.shade700),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickCompletionImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsCompleted() async {
    if (widget.report.status == 'selesai') {
      _showSnackBar('Laporan sudah ditandai selesai');
      return;
    }

    // Dialog untuk input deskripsi dan foto penyelesaian
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tandai Selesai'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _completionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Pekerjaan',
                  hintText: 'Jelaskan pekerjaan yang telah dilakukan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showImageSourceDialog();
                },
                icon: Icon(Icons.add_a_photo),
                label: Text(_completionImage != null
                    ? 'Foto Terpilih'
                    : 'Tambah Foto Hasil'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                ),
              ),
              if (_completionImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _completionImage!,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performMarkAsCompleted();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _performMarkAsCompleted() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(reportProvider.notifier).markAsCompleted(
        widget.report.id!,
        _completionController.text,
        _completionImage,
      );

      if (mounted) {
        _showSnackBar('Laporan berhasil ditandai selesai!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Gagal menandai selesai: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReport() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus laporan ini? '
              'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(reportProvider.notifier).deleteReport(widget.report.id!);

      if (mounted) {
        _showSnackBar('Laporan berhasil dihapus');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Gagal menghapus laporan: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.report.status == 'selesai';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteReport,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Foto Utama
            _buildMainPhoto(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.pending,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCompleted ? 'SELESAI' : 'PENDING',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Judul
                  Text(
                    widget.report.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Deskripsi
                  _buildInfoCard(
                    icon: Icons.description,
                    title: 'Deskripsi',
                    content: widget.report.description,
                  ),
                  const SizedBox(height: 12),

                  // Lokasi
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: 'Lokasi',
                    content:
                    'Lat: ${widget.report.latitude.toStringAsFixed(6)}\n'
                        'Long: ${widget.report.longitude.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 12),

                  // Tanggal
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    title: 'Tanggal Laporan',
                    content: _formatDate(widget.report.createdAt),
                  ),

                  // Jika sudah selesai, tampilkan info penyelesaian
                  if (isCompleted) ...[
                    const SizedBox(height: 20),
                    Divider(thickness: 2),
                    const SizedBox(height: 12),
                    Text(
                      'Info Penyelesaian',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (widget.report.completionDescription != null)
                      _buildInfoCard(
                        icon: Icons.done,
                        title: 'Deskripsi Pekerjaan',
                        content: widget.report.completionDescription!,
                      ),

                    if (widget.report.completionPhotoUrl != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Foto Hasil Pengerjaan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.report.completionPhotoUrl!.startsWith('http')
                            ? Image.network(
                          widget.report.completionPhotoUrl!,
                          fit: BoxFit.cover,
                        )
                            : Image.file(
                          File(widget.report.completionPhotoUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),

                  // Tombol Aksi
                  if (!isCompleted)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _markAsCompleted,
                        icon: Icon(Icons.check_circle),
                        label: const Text(
                          'TANDAI SELESAI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPhoto() {
    return Hero(
      tag: 'photo_${widget.report.id}',
      child: Container(
        height: 300,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: widget.report.photoUrl.startsWith('http')
            ? Image.network(
          widget.report.photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImageError(),
        )
            : Image.file(
          File(widget.report.photoUrl),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImageError(),
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 60, color: Colors.grey),
          const SizedBox(height: 8),
          Text('Foto tidak dapat dimuat'),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}