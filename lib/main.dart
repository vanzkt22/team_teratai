import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'page/splash_page.dart';
import 'page/login_page.dart';
import 'page/register_page.dart';
import 'page/home_admin_page.dart';
import 'page/home_buyer_page.dart';
import 'page/cart_page.dart';
import 'page/payment_page.dart';
import 'page/receipt_page.dart';
import 'page/purchase_history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://binumueljghvffzussir.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJpbnVtdWVsamdodmZmenVzc2lyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4OTM4NjgsImV4cCI6MjA2NzQ2OTg2OH0.aOiuLYG3XT4KXvm-qPsNiD1drL1ktevTP7xLra4T8cw',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Djatayu Coffee',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/admin': (context) => const AdminHomePage(),
        '/buyer': (context) => const HomeBuyerPage(),
        '/cart': (context) => const CartPage(),
        '/history': (context) => const PurchaseHistoryPage(),
        '/receipt': (context) => const ReceiptPage(),
      },
      // 💡 Gunakan onGenerateRoute untuk route dengan arguments kompleks
      onGenerateRoute: (settings) {
        if (settings.name == '/payment') {
          final args = settings.arguments as Map;
          return MaterialPageRoute(
            builder: (context) => PaymentPage(
              totalBayar: args['totalBayar'],
              alamat: args['alamat'],
              items: args['items'],
            ),
          );
        }
        return null;
      },
    );
  }
}
