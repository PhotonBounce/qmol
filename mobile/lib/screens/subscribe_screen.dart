import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../billing.dart';
import '../main.dart' show kPricingUrl;

/// Subscribe tab: lists Play subscription products and starts a Play Billing
/// purchase. On success the backend verifies the token and returns the key.
///
/// Where Play Billing can't run (Flutter web, or a device without Google Play)
/// it degrades to a "manage on the web" panel instead of crashing.
class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({
    super.key,
    required this.api,
    required this.billing,
    required this.onKey,
  });

  final QmolApi api;
  final Billing billing;
  final void Function(String?) onKey;

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  List<ProductDetails> _products = const [];
  bool _loading = true;
  bool _billingAvailable = false;
  String? _msg;

  @override
  void initState() {
    super.initState();
    widget.billing.start(
      onKey: (k) {
        widget.onKey(k);
        if (mounted) {
          setState(() => _msg = 'Subscription active — your key is saved.');
        }
      },
      onError: (e) {
        if (mounted) setState(() => _msg = e);
      },
    );
    _load();
  }

  Future<void> _load() async {
    try {
      final available = await widget.billing.available();
      if (!mounted) return;
      if (!available) {
        setState(() {
          _billingAvailable = false;
          _loading = false;
        });
        return;
      }
      final p = await widget.billing.products();
      if (!mounted) return;
      setState(() {
        _billingAvailable = true;
        _products = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _msg = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openWeb() =>
      launchUrl(Uri.parse(kPricingUrl), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Subscribe',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
            'Higher quotas + all endpoints. Billed securely via Google Play.'),
        const SizedBox(height: 16),
        if (_billingAvailable) ..._playSection() else _webSection(context),
        if (_msg != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(_msg!),
          ),
      ],
    );
  }

  List<Widget> _playSection() => [
        for (final p in _products)
          Card(
            child: ListTile(
              title: Text(p.title.isEmpty ? p.id : p.title),
              subtitle: Text(p.description),
              trailing: FilledButton(
                  onPressed: () => widget.billing.buy(p),
                  child: Text(p.price)),
            ),
          ),
        if (_products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
                'No subscription products found. Create them in Play Console '
                'with ids qmol_research_monthly / qmol_commercial_monthly.'),
          ),
      ];

  Widget _webSection(BuildContext context) {
    // Static plan summary so this tab is useful even where Play Billing can't
    // run (web preview, devices without Google Play). Purchases still complete
    // via the website checkout.
    const plans = [
      ('Research', '\$49 / mo', '10k SMILES/mo · all endpoints'),
      ('Commercial', '\$299 / mo', '100k SMILES/mo · redistribution + teams'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, size: 20),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'In-app purchase runs in the Android app via Google Play. '
                        'You can also subscribe on the web.')),
              ],
            ),
            const SizedBox(height: 12),
            for (final (name, price, blurb) in plans)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(blurb,
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    Text(price,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openWeb,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Subscribe on the web'),
            ),
          ],
        ),
      ),
    );
  }
}
