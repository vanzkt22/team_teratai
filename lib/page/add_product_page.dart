import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  Uint8List? imageBytes;
  String? imageUrl;
  bool isLoading = false;
  bool isUploadingImage = false;

  Future<void> pickImage() async {
    FocusScope.of(context).unfocus(); // Tutup keyboard

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      setState(() {
        imageBytes = bytes;
        isUploadingImage = true;
      });

      final uploadedUrl = await uploadToSupabase(bytes);

      await Future.delayed(const Duration(milliseconds: 300)); // delay kecil

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        setState(() {
          imageUrl = uploadedUrl;
          isUploadingImage = false;
        });
        print('✅ imageUrl = $imageUrl');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Gambar berhasil diupload')),
          );
        }
      } else {
        setState(() => isUploadingImage = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Gagal upload gambar')),
          );
        }
      }
    }
  }

  Future<String?> uploadToSupabase(Uint8List bytes) async {
    try {
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'products/$fileName';

      final bucket = supabase.storage.from('product-images');
      await bucket.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = bucket.getPublicUrl(path);
      debugPrint('📷 Uploaded to: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> addProduct() async {
    final name = nameController.text.trim();
    final priceText = priceController.text.trim();
    final description = descriptionController.text.trim();

    print('🧪 imageUrl on submit: $imageUrl');

    if (name.isEmpty || priceText.isEmpty || description.isEmpty || imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Semua field dan gambar wajib diisi')),
      );
      return;
    }

    final price = int.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Harga harus berupa angka')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await supabase.from('products').insert({
        'name': name,
        'price': price,
        'description': description,
        'image_url': imageUrl,
      });

      debugPrint('Insert response: $response');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Produk berhasil ditambahkan')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Insert error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal menambahkan produk: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Tambah Produk'),
        backgroundColor: Colors.brown,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Image.asset(
            'assets/bg.jpeg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Produk'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: isUploadingImage ? null : pickImage,
                      icon: const Icon(Icons.upload),
                      label: Text(isUploadingImage ? 'Uploading...' : 'Upload Gambar'),
                    ),
                    const SizedBox(height: 10),
                    if (imageBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          imageBytes!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: isUploadingImage ? null : addProduct,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'SIMPAN',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
