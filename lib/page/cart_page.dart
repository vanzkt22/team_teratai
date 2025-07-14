import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> cartItems = [];
  bool isLoading = true;

  // Alamat dan ongkir
  String selectedAlamat = 'Klaten';
  final Map<String, int> ongkirMap = {
    'Klaten': 10000,
    'Jogja': 15000,
    'Solo': 12000,
    'Semarang': 20000,
  };

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  Future<void> fetchCart() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('cart')
          .select('id, quantity, product:products(id, name, price, image_url)')
          .eq('user_id', user.id);

      if (response is List) {
        setState(() {
          cartItems = response;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch cart error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> increaseQty(String cartId, int currentQty) async {
    await supabase
        .from('cart')
        .update({'quantity': currentQty + 1})
        .eq('id', cartId);
    fetchCart();
  }

  Future<void> decreaseQty(String cartId, int currentQty) async {
    if (currentQty <= 1) {
      await deleteCartItem(cartId);
    } else {
      await supabase
          .from('cart')
          .update({'quantity': currentQty - 1})
          .eq('id', cartId);
      fetchCart();
    }
  }

  Future<void> deleteCartItem(String cartId) async {
    await supabase.from('cart').delete().eq('id', cartId);
    fetchCart();
  }

  @override
  Widget build(BuildContext context) {
    int totalBelanja = 0;
    for (var item in cartItems) {
      final product = item['product'];
      if (product != null) {
        final price = (product['price'] ?? 0) as int;
        final qty = (item['quantity'] ?? 1) as int;
        totalBelanja += price * qty;
      }
    }

    int ongkir = ongkirMap[selectedAlamat] ?? 0;
    int totalFinal = totalBelanja + ongkir;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Keranjang'),
        backgroundColor: Colors.brown,
        elevation: 0,
      ),
      bottomNavigationBar: _navBar(1),
      body: Stack(
        children: [
          Image.asset(
            'assets/bg.jpeg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Expanded(
                            child: cartItems.isEmpty
                                ? const Center(child: Text('Keranjang kosong'))
                                : ListView.builder(
                                    itemCount: cartItems.length,
                                    itemBuilder: (context, index) {
                                      final item = cartItems[index];
                                      final product = item['product'];
                                      if (product == null) {
                                        return const SizedBox.shrink();
                                      }

                                      return Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        elevation: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  product['image_url'] ?? '',
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(product['name']),
                                                    Text("Rp${product['price']}"),
                                                    Text("Jumlah: ${item['quantity']}"),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.add, color: Colors.green),
                                                    onPressed: () => increaseQty(
                                                      item['id'].toString(),
                                                      item['quantity'] as int,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.remove, color: Colors.orange),
                                                    onPressed: () => decreaseQty(
                                                      item['id'].toString(),
                                                      item['quantity'] as int,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () => deleteCartItem(
                                                      item['id'].toString(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Total Belanja: Rp$totalBelanja",
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  const Text("Alamat: "),
                                  DropdownButton<String>(
                                    value: selectedAlamat,
                                    items: ongkirMap.keys
                                        .map((alamat) => DropdownMenuItem(
                                              value: alamat,
                                              child: Text(alamat),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => selectedAlamat = val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              Text("Ongkir: Rp$ongkir"),
                              Text("Total Bayar: Rp$totalFinal",
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: cartItems.isEmpty
                                      ? null
                                      : () {
                                          Navigator.pushNamed(
                                            context,
                                            '/payment',
                                            arguments: {
                                              'totalBayar': totalFinal,
                                              'alamat': selectedAlamat,
                                              'items': cartItems.map((item) {
                                                final product = item['product'];
                                                return {
                                                  'product_id': product['id'],
                                                  'name': product['name'],
                                                  'price': product['price'],
                                                  'quantity': item['quantity'],
                                                  'subtotal': (product['price'] as int) *
                                                      (item['quantity'] as int),
                                                };
                                              }).toList(),
                                            },
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Pilih Pembayaran'),
                                ),
                              ),
                            ],
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
