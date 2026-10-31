import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

/// Modal dialog simulating the official Cashfree Payment Gateway v3 checkout experience.
/// Supports UPI (QR & VPA), Cards (Credit/Debit with test card prefill), and Net Banking.
class CashfreeGatewayModal extends ConsumerStatefulWidget {
  final String orderId;
  final String paymentSessionId;
  final double amount;
  final String plan;
  final String companyCode;
  final String companyName;
  final bool stubMode;
  final VoidCallback? onSuccess;

  const CashfreeGatewayModal({
    super.key,
    required this.orderId,
    required this.paymentSessionId,
    required this.amount,
    required this.plan,
    required this.companyCode,
    required this.companyName,
    this.stubMode = false,
    this.onSuccess,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String orderId,
    required String paymentSessionId,
    required double amount,
    required String plan,
    required String companyCode,
    required String companyName,
    bool stubMode = false,
    VoidCallback? onSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: CashfreeGatewayModal(
          orderId: orderId,
          paymentSessionId: paymentSessionId,
          amount: amount,
          plan: plan,
          companyCode: companyCode,
          companyName: companyName,
          stubMode: stubMode,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  @override
  ConsumerState<CashfreeGatewayModal> createState() => _CashfreeGatewayModalState();
}

class _CashfreeGatewayModalState extends ConsumerState<CashfreeGatewayModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Processing state
  bool _isProcessing = false;
  String _processingStep = '';
  bool _isSuccess = false;
  String? _errorMessage;
  String _paymentRef = '';

  // Timer for QR code
  Timer? _qrTimer;
  int _qrCountdown = 899; // 14 mins 59 secs

  // UPI Form
  final _upiController = TextEditingController(text: 'admin@okaxis');

  // Card Form
  final _cardNumberController = TextEditingController(text: '4111 1111 1111 1111');
  final _cardExpiryController = TextEditingController(text: '12/28');
  final _cardCvvController = TextEditingController(text: '888');
  final _cardHolderController = TextEditingController(text: 'Operations Manager');

  // Netbanking
  String _selectedBank = 'HDFC';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startQrTimer();
  }

  void _startQrTimer() {
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_qrCountdown > 0) {
        if (mounted) setState(() => _qrCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qrTimer?.cancel();
    _upiController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _handlePaymentSubmit(String method) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _processingStep = 'Connecting to Cashfree Payments Gateway...';
    });

    try {
      // Step 1: Simulate connection
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _processingStep = 'Authenticating $method transaction...');

      // Step 2: Bank processing
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _processingStep = 'Receiving bank authorization...');

      // Step 3: Call backend verify
      final success = await ref.read(subscriptionProvider.notifier).verifyAndActivatePayment(
            orderId: widget.orderId,
            plan: widget.plan,
            stubMode: widget.stubMode,
          );

      if (!mounted) return;

      if (success) {
        final refNum = 'CF${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
          _paymentRef = refNum;
        });
        widget.onSuccess?.call();
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Payment verification could not be confirmed by bank.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Cashfree PG error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header Bar
            _buildCashfreeHeader(),

            // Order Summary Strip
            _buildOrderSummaryStrip(),

            // Body Area
            Expanded(
              child: _isProcessing
                  ? _buildProcessingView()
                  : _isSuccess
                      ? _buildSuccessView()
                      : _buildMainCheckoutView(),
            ),

            // Footer Security Bar
            _buildCashfreeFooter(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Cashfree Header
  // ===========================================================================
  Widget _buildCashfreeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF090D1A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          // Cashfree stylized logo badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              'C',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'cashfree',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'payments',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF059669)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34D399),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'SANDBOX',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF34D399),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                const Text(
                  'PCI-DSS Level 1 • 256-bit Encrypted Checkout',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!_isProcessing && !_isSuccess)
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
              onPressed: () => Navigator.of(context).pop(false),
              tooltip: 'Cancel Payment',
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Order Summary Strip
  // ===========================================================================
  Widget _buildOrderSummaryStrip() {
    final amountFormatted = '₹${widget.amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'),
          (m) => '${m[1]},',
        )}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF131D31),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.companyName} (${widget.companyCode})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Plan: ${widget.plan == 'PRO_ANNUAL' ? 'Pro Annual (365 Days)' : 'Pro Monthly (30 Days)'} • Order ID: ${widget.orderId}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'AMOUNT DUE',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                amountFormatted,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Main Checkout View (Tabs)
  // ===========================================================================
  Widget _buildMainCheckoutView() {
    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF7F1D1D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDC2626)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFFCA5A5), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF090D1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF0284C7),
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF94A3B8),
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
            tabs: const [
              Tab(
                icon: Icon(Icons.qr_code_2_rounded, size: 18),
                text: 'UPI / QR',
              ),
              Tab(
                icon: Icon(Icons.credit_card_rounded, size: 18),
                text: 'Cards',
              ),
              Tab(
                icon: Icon(Icons.account_balance_rounded, size: 18),
                text: 'Net Banking',
              ),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUpiTab(),
              _buildCardsTab(),
              _buildNetBankingTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Tab 1: UPI & QR Code
  // ===========================================================================
  Widget _buildUpiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // QR Code card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131D31),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              children: [
                // Simulated authentic QR Code block
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0284C7), width: 2),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // QR Pattern Grid
                      CustomPaint(
                        size: const Size(98, 98),
                        painter: _QrPatternPainter(),
                      ),
                      // Cashfree Center Logo
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0284C7),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan & Pay with Any App',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildAppChip('GPay', const Color(0xFF34A853)),
                          const SizedBox(width: 4),
                          _buildAppChip('PhonePe', const Color(0xFF5F259F)),
                          const SizedBox(width: 4),
                          _buildAppChip('Paytm', const Color(0xFF002E6E)),
                          const SizedBox(width: 4),
                          _buildAppChip('BHIM', const Color(0xFFFF9933)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(
                            'Expires in ${_formatTimer(_qrCountdown)}',
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Divider with "OR"
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFF1E293B))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'OR ENTER UPI ID / VPA',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 12),

          // VPA Field
          TextField(
            controller: _upiController,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'UPI ID / Mobile Number',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              hintText: 'mobile@upi or username@bank',
              hintStyle: const TextStyle(color: Color(0xFF475569)),
              prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF0284C7), size: 18),
              filled: true,
              fillColor: const Color(0xFF131D31),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E293B))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
            ),
          ),
          const SizedBox(height: 8),

          // Quick VPA handles
          Row(
            children: [
              _buildVpaHandleChip('@okaxis'),
              const SizedBox(width: 6),
              _buildVpaHandleChip('@okhdfcbank'),
              const SizedBox(width: 6),
              _buildVpaHandleChip('@paytm'),
              const SizedBox(width: 6),
              _buildVpaHandleChip('@ybl'),
            ],
          ),
          const SizedBox(height: 16),

          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.lock_rounded, size: 16),
              label: Text(
                'Pay with UPI (₹${widget.amount.toInt()})',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              onPressed: () => _handlePaymentSubmit('UPI'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color.withValues(alpha: 0.9),
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildVpaHandleChip(String handle) {
    return GestureDetector(
      onTap: () {
        final current = _upiController.text.split('@').first;
        _upiController.text = '${current.isNotEmpty ? current : 'user'}$handle';
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          handle,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ===========================================================================
  // Tab 2: Cards
  // ===========================================================================
  Widget _buildCardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Visual Card Mockup
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.nfc_rounded, color: Colors.white70, size: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'VISA / TEST',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _cardNumberController.text.isNotEmpty ? _cardNumberController.text : '•••• •••• •••• ••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _cardHolderController.text.toUpperCase(),
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _cardExpiryController.text,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Helper: Fill Cashfree Test Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CARD DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _cardNumberController.text = '4111 1111 1111 1111';
                    _cardExpiryController.text = '12/28';
                    _cardCvvController.text = '888';
                    _cardHolderController.text = 'Operations Admin';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF059669)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_fix_high_rounded, size: 12, color: Color(0xFF34D399)),
                      SizedBox(width: 4),
                      Text(
                        'Use Cashfree Test Card',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF34D399)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Card Number Field
          TextField(
            controller: _cardNumberController,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Card Number',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              prefixIcon: const Icon(Icons.credit_card, color: Color(0xFF0284C7), size: 18),
              filled: true,
              fillColor: const Color(0xFF131D31),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7))),
            ),
          ),
          const SizedBox(height: 8),

          // Expiry & CVV Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cardExpiryController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF131D31),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _cardCvvController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF131D31),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Cardholder Name
          TextField(
            controller: _cardHolderController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Name on Card',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF131D31),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E293B))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0284C7))),
            ),
          ),
          const SizedBox(height: 14),

          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.shield_outlined, size: 16),
              label: Text(
                'Pay with Card (₹${widget.amount.toInt()})',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              onPressed: () => _handlePaymentSubmit('Card'),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Tab 3: Net Banking
  // ===========================================================================
  Widget _buildNetBankingTab() {
    final popularBanks = [
      {'code': 'HDFC', 'name': 'HDFC Bank', 'color': const Color(0xFF004C8F)},
      {'code': 'ICICI', 'name': 'ICICI Bank', 'color': const Color(0xFFB82818)},
      {'code': 'SBI', 'name': 'State Bank of India', 'color': const Color(0xFF280071)},
      {'code': 'AXIS', 'name': 'Axis Bank', 'color': const Color(0xFF97144D)},
      {'code': 'KOTAK', 'name': 'Kotak Mahindra', 'color': const Color(0xFFED1C24)},
      {'code': 'PNB', 'name': 'Punjab National', 'color': const Color(0xFFA20C30)},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POPULAR BANKS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 10),

          // Bank grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.8,
            ),
            itemCount: popularBanks.length,
            itemBuilder: (ctx, idx) {
              final bank = popularBanks[idx];
              final isSelected = _selectedBank == bank['code'];
              final color = bank['color'] as Color;

              return GestureDetector(
                onTap: () => setState(() => _selectedBank = bank['code'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.2) : const Color(0xFF131D31),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          (bank['code'] as String).substring(0, 1),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bank['name'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Proceed Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.account_balance_rounded, size: 16),
              label: Text(
                'Pay via $_selectedBank (₹${widget.amount.toInt()})',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              onPressed: () => _handlePaymentSubmit('$_selectedBank Net Banking'),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Processing Animation View
  // ===========================================================================
  Widget _buildProcessingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0284C7), width: 2),
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: Color(0xFF38BDF8),
                  strokeWidth: 3.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Communicating with Cashfree PG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _processingStep,
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Please do not refresh or close this window',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Success Celebration View
  // ===========================================================================
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    blurRadius: 20,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 18),
            const Text(
              'Payment Received via Cashfree!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bank Reference / UTR: $_paymentRef',
              style: const TextStyle(
                color: Color(0xFF34D399),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF131D31),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                children: [
                  _buildSuccessRow('Company', '${widget.companyName} (${widget.companyCode})'),
                  const SizedBox(height: 6),
                  _buildSuccessRow('Subscription', widget.plan == 'PRO_ANNUAL' ? 'Pro Annual (365 Days)' : 'Pro Monthly (30 Days)'),
                  const SizedBox(height: 6),
                  _buildSuccessRow('Amount Paid', '₹${widget.amount.toInt()}'),
                  const SizedBox(height: 6),
                  _buildSuccessRow('Status', 'ACTIVE PRO • ALL FEATURES UNLOCKED'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text(
                  'Access Manufacturing Floor',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // ===========================================================================
  // Cashfree Footer
  // ===========================================================================
  Widget _buildCashfreeFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF090D1A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 14, color: Color(0xFF10B981)),
              SizedBox(width: 6),
              Text(
                'Secured by Cashfree Payments India',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            'ISO 27001 Certified',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for dynamic realistic QR matrix
class _QrPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    const blockSize = 6.0;
    final cols = (size.width / blockSize).floor();
    final rows = (size.height / blockSize).floor();

    // Corner Finder Patterns
    void drawFinder(double x, double y) {
      final outer = Rect.fromLTWH(x, y, 24, 24);
      final inner = Rect.fromLTWH(x + 4, y + 4, 16, 16);
      final center = Rect.fromLTWH(x + 8, y + 8, 8, 8);

      canvas.drawRect(outer, paint);
      canvas.drawRect(inner, Paint()..color = Colors.white);
      canvas.drawRect(center, paint);
    }

    drawFinder(2, 2);
    drawFinder(size.width - 26, 2);
    drawFinder(2, size.height - 26);

    // Matrix pseudo-pattern
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Skip corner finders
        if ((r < 5 && c < 5) || (r < 5 && c > cols - 6) || (r > rows - 6 && c < 5)) {
          continue;
        }
        // Center area skip for Cashfree C logo
        if (r > rows / 2 - 3 && r < rows / 2 + 3 && c > cols / 2 - 3 && c < cols / 2 + 3) {
          continue;
        }

        // Pseudo-random pseudo pattern based on coordinates
        if ((r * 7 + c * 13) % 3 == 0 || (r * c) % 5 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(c * blockSize + 1, r * blockSize + 1, blockSize - 1.5, blockSize - 1.5),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
