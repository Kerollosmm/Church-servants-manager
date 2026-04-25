import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class AIOfflineGate extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AIOfflineGate({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data ?? [ConnectivityResult.none];
        final isOffline =
            results.contains(ConnectivityResult.none) && results.length == 1;

        if (isOffline) {
          return fallback ??
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off, color: Colors.grey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI features are unavailable offline. Connect to the internet to see insights.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              );
        }

        return child;
      },
    );
  }
}
