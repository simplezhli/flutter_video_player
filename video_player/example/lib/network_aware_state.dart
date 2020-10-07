import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// https://medium.com/@ducduy.dev/flutter-implement-network-aware-in-your-flutter-app-1db6bc66430a
mixin NetworkAwareState<T extends StatefulWidget> on State<T> {

  bool _isDisconnected = true;

  StreamSubscription<ConnectivityResult> _networkSubscription;
  final Connectivity _connectivity = Connectivity();

  void onReconnected(ConnectivityResult result);

  void onDisconnected();

  Future<void> _initConnectivity() async {
    ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }


  @override
  void initState() {
    super.initState();
    //listen to network changes
    _initConnectivity();
    _networkSubscription =
        _connectivity.onConnectivityChanged.listen((result) {
          _updateConnectionStatus(result);
        });
  }

  _updateConnectionStatus(ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      if (_isDisconnected) {
        onReconnected(result);
        _isDisconnected = false;
      }
    } else {
      _isDisconnected = true;
      onDisconnected();
    }
  }

  @override
  void dispose() {
    _cancelSubscription();
    super.dispose();
  }

  void _cancelSubscription() {
    try {
      _networkSubscription?.cancel();
    } catch (e) {
      print(e);
    }
  }
}