import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/features/settings/repositories/settings_repository.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:dodolanku/core/services/print_service.dart';
import 'package:dodolanku/core/widgets/app_widgets.dart';

class PrinterSettingsPage extends ConsumerStatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  ConsumerState<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends ConsumerState<PrinterSettingsPage> {
  final PrintService _printService = PrintService.instance;
  List<BluetoothInfo> _devices = [];
  bool _isScanning = false;
  bool _isConnected = false;
  String _connectedDeviceMac = '';
  String _connectedDeviceName = '';
  bool _autoPrint = true;

  @override
  void initState() {
    super.initState();
    _autoPrint = ref.read(settingsRepositoryProvider).getIsAutoPrint();
    _checkConnectionStatus();
    _scanDevices();
  }

  Future<void> _checkConnectionStatus() async {
    final connected = await _printService.isConnected();
    setState(() {
      _isConnected = connected;
    });
  }

  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
      _devices = [];
    });
    final devs = await _printService.getPairedDevices();
    setState(() {
      _devices = devs;
      _isScanning = false;
    });
  }

  Future<void> _connectPrinter(BluetoothInfo device) async {
    AppToast.show(context, message: 'Menghubungkan ke ${device.name}...', icon: Icons.bluetooth_searching);
    final success = await _printService.connect(device.macAdress);
    if (!mounted) return;
    if (success) {
      setState(() {
        _isConnected = true;
        _connectedDeviceMac = device.macAdress;
        _connectedDeviceName = device.name;
      });
      AppToast.show(context, message: 'Berhasil terhubung ke ${device.name}!');
    } else {
      AppToast.show(context, message: 'Gagal terhubung ke printer', isError: true);
    }
  }

  Future<void> _disconnectPrinter() async {
    await _printService.disconnect();
    if (!mounted) return;
    setState(() {
      _isConnected = false;
      _connectedDeviceMac = '';
      _connectedDeviceName = '';
    });
    AppToast.show(context, message: 'Koneksi printer terputus', icon: Icons.bluetooth_disabled);
  }

  Future<void> _testPrint() async {
    final success = await _printService.printTest();
    if (!mounted) return;
    if (!success) {
      AppToast.show(context, message: 'Gagal mencetak. Pastikan printer terhubung.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _scanDevices,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Auto print toggle
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cetak Struk Otomatis',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Cetak otomatis setelah transaksi sukses',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                Switch(
                  value: _autoPrint,
                  activeThumbColor: primary,
                  onChanged: (val) {
                    setState(() {
                      _autoPrint = val;
                    });
                    ref.read(settingsRepositoryProvider).setAutoPrint(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Connection status
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Printer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.print : Icons.print_disabled,
                      color: _isConnected ? Colors.green : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isConnected ? 'Terhubung' : 'Terputus',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isConnected ? Colors.green : Colors.grey,
                            ),
                          ),
                          if (_isConnected && _connectedDeviceName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              '$_connectedDeviceName ($_connectedDeviceMac)',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_isConnected) ...[
                      ElevatedButton(
                        onPressed: _testPrint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: const Text('Test', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _disconnectPrinter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Putuskan', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Printer Bluetooth List Header
          const Text(
            'Printer Tersedia (Paired)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          // Devices list
          if (_isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_devices.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.bluetooth, size: 36, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    const Text(
                      'Tidak ada printer Bluetooth terpasang',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pasangkan printer Anda di pengaturan Bluetooth HP dulu.',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Builder(
              builder: (context) {
                final audioKeywords = [
                  'speaker', 'airpods', 'buds', 'headset', 'audio', 'soundcore',
                  'tws', 'galaxy', 'watch', 'earbuds', 'bose', 'sony', 'jbl',
                  'earphone', 'headphone', 'tv', 'mac', 'iphone', 'ipad', 'pc', 'laptop'
                ];
                final likelyPrinters = <BluetoothInfo>[];
                final otherDevices = <BluetoothInfo>[];
                
                for (final d in _devices) {
                  final lowerName = d.name.toLowerCase();
                  if (audioKeywords.any((kw) => lowerName.contains(kw))) {
                    otherDevices.add(d);
                  } else {
                    likelyPrinters.add(d);
                  }
                }

                Widget buildDeviceCard(BluetoothInfo device) {
                  final isCurrent = _connectedDeviceMac == device.macAdress;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.all(12),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isCurrent ? primary.withValues(alpha: 0.1) : Colors.grey[100],
                          child: Icon(Icons.print, color: isCurrent ? primary : Colors.grey),
                        ),
                        title: Text(
                          device.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(device.macAdress, style: const TextStyle(fontSize: 11)),
                        trailing: isCurrent
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Aktif',
                                  style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () => _connectPrinter(device),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Hubungkan', style: TextStyle(fontSize: 12)),
                              ),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (likelyPrinters.isNotEmpty)
                      ...likelyPrinters.map(buildDeviceCard),
                    if (otherDevices.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 12),
                        child: Text(
                          'Perangkat Lainnya (Bukan Printer)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      ...otherDevices.map(buildDeviceCard),
                    ],
                  ],
                );
              }
            ),
        ],
      ),
    );
  }
}
