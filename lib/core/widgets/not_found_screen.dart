import 'package:flutter/material.dart';

/// Shown when the router encounters an unregistered route name.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الصفحة غير موجودة')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'هذه الصفحة غير موجودة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (_) => false),
                icon: const Icon(Icons.home),
                label: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
