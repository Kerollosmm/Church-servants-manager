import 'dart:async';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:flutter/material.dart';

/// A wrapper widget that triggers a sync when the app returns to the foreground.
class LifecycleSyncManager extends StatefulWidget {
  final Widget child;

  const LifecycleSyncManager({super.key, required this.child});

  @override
  State<LifecycleSyncManager> createState() => _LifecycleSyncManagerState();
}

class _LifecycleSyncManagerState extends State<LifecycleSyncManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger sync when app returns to foreground
      unawaited(getIt<SyncService>().processQueue());
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
