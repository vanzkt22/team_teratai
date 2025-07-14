import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchaseHistoryPage extends StatefulWidget {
  const PurchaseHistoryPage({super.key});

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Anda belum login')),
        );
        return;
      }

      final response = await supabase
          .from('transactions')
          .select('''
            id,
            created_at,
            total_price,
            payment_method,
            status,
            transaction_items (
              quantity,
              price,
              product:products (
                name,
                price
              )
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        history = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal memuat riwayat: $e')),
      );
    }
  }

  String formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(date);
    } catch (_) {
      return '-';
    }
  }

  String formatCurrency(num number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
        .format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Riwayat Pembelian'),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Pembelian',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : history.isEmpty
                              ? const Center(child: Text('Belum ada transaksi.'))
                              : ListView.builder(
                                  itemCount: history.length,
                                  itemBuilder: (context, index) {
                                    final transaction = history[index];

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/receipt',
                                          arguments: {
                                            'transaction': transaction,
                                            'items': transaction['transaction_items'],
                                            'alamat': '-', // optional
                                            'ongkir': 0,   // optional
                                          },
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              formatCurrency(transaction['total_price']),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Metode: ${transaction['payment_method']}'),
                                                Text(
                                                  transaction['status'],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: transaction['status'] == 'selesai'
                                                        ? Colors.green
                                                        : Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              formatDate(transaction['created_at']),
                                              style: const TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
