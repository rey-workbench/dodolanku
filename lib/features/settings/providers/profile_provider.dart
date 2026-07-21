import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/features/scanner/providers/scanner_provider.dart';

@immutable
class ProfileState {
  final String storeName;
  final String storeAddress;
  final bool isLoading;

  const ProfileState({
    required this.storeName,
    required this.storeAddress,
    this.isLoading = false,
  });

  ProfileState copyWith({
    String? storeName,
    String? storeAddress,
    bool? isLoading,
  }) {
    return ProfileState(
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    Future.microtask(() => loadProfile());
    return const ProfileState(
      storeName: 'dodolanku',
      storeAddress: 'Jl. Raya dodolanku No. 1',
      isLoading: true,
    );
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    final db = ref.read(databaseServiceProvider);
    await db.initDb();
    final config = await db.getReceiptConfig();
    state = ProfileState(
      storeName: config['store_name'] ?? 'dodolanku',
      storeAddress: config['store_address'] ?? 'Jl. Raya dodolanku No. 1',
      isLoading: false,
    );
  }

  Future<void> updateProfile({
    required String name,
    required String address,
  }) async {
    state = state.copyWith(isLoading: true);
    final db = ref.read(databaseServiceProvider);
    final config = await db.getReceiptConfig();

    await db.updateReceiptConfig(
      storeName: name,
      storeAddress: address,
      storePhone: config['store_phone'],
      qrisData: config['qris_data'],
      headerMsg: config['header_msg'] ?? '',
      footerMsg: config['footer_msg'] ?? 'Terima Kasih',
    );

    state = ProfileState(
      storeName: name,
      storeAddress: address,
      isLoading: false,
    );
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
