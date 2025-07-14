import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeBuyerPage extends StatefulWidget {
  const HomeBuyerPage({super.key});

  @override
  State<HomeBuyerPage> createState() => _HomeBuyerPageState();
}

class _HomeBuyerPageState extends State<HomeBuyerPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> allProducts = [];
  List<dynamic> filteredProducts = [];
  bool isLoading = true;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final res = await supabase.from('products').select();
      setState(() {
        allProducts = res;
        filteredProducts = res;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Fetch error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> addToCart(dynamic product) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Anda belum login')),
      );
      return;
    }

    try {
      final existing = await supabase
          .from('cart')
          .select()
          .eq('user_id', user.id)
          .eq('product_id', product['id']);

      if (existing != null && existing.isNotEmpty) {
        await supabase.from('cart').update({
          'quantity': existing[0]['quantity'] + 1,
        }).eq('id', existing[0]['id']);
      } else {
        await supabase.from('cart').insert({
          'user_id': user.id,
          'product_id': product['id'],
          'quantity': 1,
        });
      }

      if (context.mounted) {
        final goToCart = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Produk Ditambahkan'),
            content: const Text('Ingin membuka keranjang belanja?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Tetap di sini'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Buka Keranjang'),
              ),
            ],
          ),
        );

        if (goToCart == true) {
          Navigator.pushNamed(context, '/cart');
        }
      }
    } catch (e) {
      debugPrint('Add to cart error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal menambahkan ke keranjang: $e')),
      );
    }
  }

  void filterSearch(String query) {
    final results = allProducts.where((product) {
      final name = product['name'].toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() => filteredProducts = results);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _navBar(0),
      appBar: AppBar(
        title: const Text('Menu Kopi'),
        backgroundColor: Colors.brown,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await supabase.auth.signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
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
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: filterSearch,
                    decoration: InputDecoration(
                      hintText: "Cari Kopi ...",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredProducts.isEmpty
                            ? const Center(
                                child: Text(
                                  'Tidak ada produk ditemukan.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (product['image_url'] != null &&
                                            product['image_url'].toString().isNotEmpty)
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                            child: Image.network(
                                              product['image_url'],
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: Colors.grey[300],
                                                height: 150,
                                                child: const Icon(Icons.broken_image, size: 50),
                                              ),
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product['name'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Rp${product['price']}",
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                product['description'] ?? '-',
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 12),
                                              Center(
                                                child: ElevatedButton(
                                                  onPressed: () => addToCart(product),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.brown,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(
                                                        vertical: 12, horizontal: 24),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                  ),
                                                  child: const Text("Pesan"),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
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
      unselectedItemColor: Colors.white60,
      onTap: (index) {
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
