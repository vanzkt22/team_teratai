import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  String? imageUrl;
  Uint8List? imageBytes;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    nameController.text = p['name'] ?? '';
    priceController.text = (p['price'] ?? '').toString();
    descriptionController.text = p['description'] ?? '';
    imageUrl = p['image_url'];
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() => imageBytes = result.files.single.bytes);

      final uploadedUrl = await uploadToSupabase(imageBytes!);
      if (uploadedUrl != null) {
        setState(() => imageUrl = uploadedUrl);
        _showSnackBar('✅ Gambar berhasil diupload');
      } else {
        _showSnackBar('❌ Gagal upload gambar');
      }
    }
  }

  Future<String?> uploadToSupabase(Uint8List bytes) async {
    try {
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'products/$fileName';

      await supabase.storage
          .from('product-images')
          .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

      return supabase.storage.from('product-images').getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> updateProduct() async {
    final name = nameController.text.trim();
    final priceText = priceController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty || priceText.isEmpty) {
      _showSnackBar('⚠️ Nama dan harga wajib diisi');
      return;
    }

    final price = int.tryParse(priceText);
    if (price == null) {
      _showSnackBar('⚠️ Harga harus berupa angka');
      return;
    }

    setState(() => isLoading = true);
    try {
      await supabase.from('products').update({
        'name': name,
        'price': price,
        'description': description,
        'image_url': imageUrl ?? '',
      }).eq('id', widget.product['id']);

      _showSnackBar('✅ Produk berhasil diperbarui');
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Update error: $e');
      _showSnackBar('❌ Gagal memperbarui produk');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Produk'),
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
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
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.upload),
              label: const Text('Upload Gambar Baru'),
            ),
            const SizedBox(height: 10),
            if (imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(imageBytes!, height: 150, width: 150, fit: BoxFit.cover),
              )
            else if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl!, height: 150, width: 150, fit: BoxFit.cover),
              ),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: updateProduct,
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan Perubahan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
