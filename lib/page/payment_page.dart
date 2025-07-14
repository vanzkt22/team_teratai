import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentPage extends StatefulWidget {
  final int totalBayar;
  final String alamat;
  final List<dynamic> items;

  const PaymentPage({
    super.key,
    required this.totalBayar,
    required this.alamat,
    required this.items,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final supabase = Supabase.instance.client;
  String metodePembayaran = 'Dana';
  bool isProcessing = false;

  // Controller input nomor pembayaran
  final TextEditingController accountNumberController = TextEditingController();

  Future<void> handlePayment() async {
    final user = supabase.auth.currentUser;
    if (user == null || isProcessing) return;

    // Validasi nomor akun
    if (accountNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗ Masukkan nomor pembayaran terlebih dahulu")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      // Simpan transaksi utama
      final transaksiRes = await supabase
          .from('transactions')
          .insert({
            'user_id': user.id,
            'total_price': widget.totalBayar,
            'payment_method': metodePembayaran,
            'payment_number': accountNumberController.text.trim(),
            'status': 'selesai',
            'alamat': widget.alamat,
          })
          .select()
          .single();

      final transactionId = transaksiRes['id'];

      // Simpan detail item transaksi
      for (final item in widget.items) {
        final isNested = item['product'] != null;
        final productId = isNested ? item['product']['id'] : item['product_id'];
        final quantity = item['quantity'];
        final price = isNested ? item['product']['price'] : item['price'];

        await supabase.from('transaction_items').insert({
          'transaction_id': transactionId,
          'product_id': productId,
          'quantity': quantity,
          'price': price,
        });
      }

      // Hapus cart user
      await supabase.from('cart').delete().eq('user_id', user.id);

      // Navigasi ke struk
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/receipt',
          (route) => false,
          arguments: {
            'transaction': transaksiRes,
            'items': widget.items,
          },
        );
      }
    } catch (e, stack) {
  debugPrint("Payment error: $e");
  debugPrint("Stack trace: $stack");
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("❌ $e")),
  );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _navBar(1),
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: Colors.brown,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Image.asset(
            'assets/bg.jpeg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Metode Pembayaran",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile(
                      title: const Text("Kartu Debit"),
                      value: 'Kartu',
                      groupValue: metodePembayaran,
                      onChanged: (val) => setState(() {
                        metodePembayaran = val!;
                        accountNumberController.clear();
                      }),
                    ),
                    RadioListTile(
                      title: const Text("Dana"),
                      value: 'Dana',
                      groupValue: metodePembayaran,
                      onChanged: (val) => setState(() {
                        metodePembayaran = val!;
                        accountNumberController.clear();
                      }),
                    ),
                    const SizedBox(height: 12),

                    // Input nomor rekening sesuai metode
                    if (metodePembayaran == 'Dana' || metodePembayaran == 'Kartu')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextField(
                          controller: accountNumberController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: metodePembayaran == 'Dana'
                                ? 'Nomor Dana'
                                : 'Nomor Kartu Debit',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),

                    Divider(color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    const Text(
                      "Detail Pesanan",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        final isNested = item['product'] != null;
                        final name =
                            isNested ? item['product']['name'] : item['name'];
                        final quantity = item['quantity'];
                        final price =
                            isNested ? item['product']['price'] : item['price'];
                        final subtotal = (price as int) * (quantity as int);
                        return ListTile(
                          dense: true,
                          title: Text(name),
                          subtitle: Text("Jumlah: $quantity"),
                          trailing: Text("Rp$subtotal"),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Alamat Pengiriman",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(widget.alamat),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Pembayaran",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Rp${widget.totalBayar}",
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: isProcessing ? null : handlePayment,
                        icon: isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.payment),
                        label: Text(isProcessing
                            ? "Memproses..."
                            : "Bayar Sekarang"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _navBar(int selectedIndex) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      backgroundColor: Colors.brown[400],
      selectedItemColor: Colors.white,
      onTap: (index) {
        if (index == 0) Navigator.pushReplacementNamed(context, '/buyer');
        if (index == 1) Navigator.pushReplacementNamed(context, '/cart');
        if (index == 2) Navigator.pushReplacementNamed(context, '/history');
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.coffee), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: ''),
      ],
    );
  }
}
