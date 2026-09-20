import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import '../services/ticket_service.dart';
import '../services/api_client.dart';

/// Agency staff scan a passenger's boarding QR code here. Pauses itself
/// after the first successful read so the same ticket isn't validated
/// twice in a row, and surfaces the backend's error message directly
/// (already boarded, wrong agency, unknown code) rather than guessing.
class ScanTicketScreen extends StatefulWidget {
  const ScanTicketScreen({super.key});

  @override
  State<ScanTicketScreen> createState() => _ScanTicketScreenState();
}

class _ScanTicketScreenState extends State<ScanTicketScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  String? _error;
  BoardingValidationResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _result != null) return;
    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;

    setState(() {
      _processing = true;
      _error = null;
    });
    await _controller.stop();

    try {
      final result = await TicketService.instance.validateBoarding(code);
      if (mounted) setState(() => _result = result);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
      await _controller.start();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _scanAgain() async {
    setState(() {
      _result = null;
      _error = null;
    });
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ticket'),
        backgroundColor: AppColors.darkOlive,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          _buildOverlayFrame(),
          if (_processing)
            const ColoredBox(
              color: Colors.black45,
              child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
            ),
          if (_error != null) _buildErrorBanner(),
          if (_result != null) _buildResultCard(),
        ],
      ),
    );
  }

  Widget _buildOverlayFrame() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gold, width: 3),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 30,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
            TextButton(
              onPressed: _scanAgain,
              child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final r = _result!;
    return Positioned(
      left: 20,
      right: 20,
      bottom: 30,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 26),
                const SizedBox(width: 10),
                const Text('Boarded', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            Text(r.passengerName, style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text('${r.originCity} → ${r.destinationCity}', style: AppTextStyles.subtitle),
            Text(formatDate(r.departureAt), style: AppTextStyles.subtitle),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Scan next ticket', onPressed: _scanAgain),
          ],
        ),
      ),
    );
  }
}
