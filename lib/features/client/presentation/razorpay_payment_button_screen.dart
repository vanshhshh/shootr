import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_constants.dart';
import '../../../shared/widgets/primary_glow_button.dart';

class RazorpayPaymentButtonScreen extends StatefulWidget {
  const RazorpayPaymentButtonScreen({
    required this.amountLabel,
    required this.paymentButtonId,
    super.key,
  });

  final String amountLabel;
  final String paymentButtonId;

  @override
  State<RazorpayPaymentButtonScreen> createState() =>
      _RazorpayPaymentButtonScreenState();
}

class _RazorpayPaymentButtonScreenState
    extends State<RazorpayPaymentButtonScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _loadError = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _isLoading = false;
                _loadError =
                    'Razorpay could not load. Check your connection and try again.';
              });
            }
          },
        ),
      )
      ..loadHtmlString(
        _paymentButtonHtml(widget.paymentButtonId),
        baseUrl: 'https://shootr.app',
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Razorpay Payment'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppConstants.radius),
                border: Border.all(color: AppColors.glass),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Amount due',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.amountLabel,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                if (_loadError != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.glass),
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radius),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: PrimaryGlowButton(
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _paymentButtonHtml(String paymentButtonId) {
  return '''
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <style>
      html, body {
        margin: 0;
        min-height: 100%;
        background: #0A0A0A;
        color: #FFFFFF;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      }
      main {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 24px;
        box-sizing: border-box;
      }
      section {
        width: 100%;
        max-width: 420px;
        text-align: center;
      }
      h1 {
        margin: 0 0 10px;
        font-size: 24px;
        line-height: 1.2;
      }
      p {
        margin: 0 0 22px;
        color: #9E9E9E;
        font-size: 15px;
        line-height: 1.5;
      }
      form {
        display: flex;
        justify-content: center;
      }
      .razorpay-payment-button {
        min-width: 220px;
        min-height: 52px;
        border: 0;
        border-radius: 16px;
        background: #00FF85;
        color: #000000;
        font-size: 16px;
        font-weight: 700;
      }
    </style>
  </head>
  <body>
    <main>
      <section>
        <h1>Complete payment</h1>
        <p>Use Razorpay checkout, then return to Shootr when the payment succeeds.</p>
        <form>
          <script src="https://checkout.razorpay.com/v1/payment-button.js" data-payment_button_id="$paymentButtonId" async></script>
        </form>
      </section>
    </main>
  </body>
</html>
''';
}
