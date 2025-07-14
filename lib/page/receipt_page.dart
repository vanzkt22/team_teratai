import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key});

  String formatCurrency(num number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
        .format(number);
  }

  String formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(date);
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final transaction = args?['transaction'] as Map?;
    final items = args?['items'] as List? ?? [];
    final alamat = args?['alamat'] as String? ?? '-';
    final ongkir = args?['ongkir'] as int? ?? 0;

    if (transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Struk Pembelian")),
        body: const Center(child: Text("Data transaksi tidak ditemukan.")),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Struk Pembelian"),
        backgroundColor: Colors.brown,
        elevation: 0,
      ),
      bottomNavigationBar: _navBar(2, context),
      body: Stack(
        children: [
          Image.asset(
            'assets/bg.jpeg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: Center(
              child: Card(
                color: Colors.white.withOpacity(0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 48),
                        const SizedBox(height: 12),
                        const Text("Terima Kasih!",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text("Pembayaran Anda berhasil."),
                        const SizedBox(height: 16),
                        Text(formatDate(transaction['created_at'] ?? ''),
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        const Divider(),
                        const Text("Detail Pembelian",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),

                        // Daftar produk
                        ...items.map((item) {
                          final product = item['product'] ?? {};
                          final name = product['name'] ?? 'Produk';
                          final price = product['price'] ?? 0;
                          final qty = item['quantity'] ?? 0;

                          return Column(
                            children: [
                              ListTile(
                                dense: true,
                                title: Text(name),
                                subtitle: Text("Qty: $qty"),
                                trailing: Text(formatCurrency(price)),
                              ),
                              const Divider(),
                            ],
                          );
                        }).toList(),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Subtotal",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(formatCurrency(transaction['total_price'] - ongkir)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Ongkir", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(formatCurrency(ongkir)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(formatCurrency(transaction['total_price'])),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Pembayaran",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(transaction['payment_method']),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Alamat", style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(alamat, textAlign: TextAlign.right)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/buyer', (route) => false);
                          },
                          icon: const Icon(Icons.home),
                          label: const Text("Kembali ke Beranda"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _navBar(int selectedIndex, BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      backgroundColor: Colors.brown[400],
      selectedItemColor: Colors.white,
      onTap: (index) {
        if (index == 0) Navigator.pushNamed(context, '/buyer');
        if (index == 1) Navigator.pushNamed(context, '/cart');
        if (index == 2) Navigator.pushNamed(context, '/history');
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.coffee), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: ''),
      ],
    );
  }
}
