import 'dart:async';  
import 'package:connectivity_plus/connectivity_plus.dart';  
  
class NetworkService {  
  static final NetworkService instance = NetworkService._internal();  
  NetworkService._internal();  
  
  final Connectivity _connectivity = Connectivity();  
  StreamSubscription<List<ConnectivityResult>>? _subscription;  
  
  Future<bool> hasInternetConnection() async {  
    final results = await _connectivity.checkConnectivity();  
    return results.any((r) => r != ConnectivityResult.none);  
  }  
  
  void listenConnectionChange(Function(bool hasConnection) onChange) {  
    _subscription?.cancel();  
    _subscription = _connectivity.onConnectivityChanged.listen((results) {  
      final hasConnection = results.any((r) => r != ConnectivityResult.none);  
      onChange(hasConnection);  
    });  
  }  
  
  void dispose() {  
    _subscription?.cancel();  
  }  
} 
