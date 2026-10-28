import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// The app name lives here. Change it in one place.
const String kAppName = 'SoulBeads';
const int kMalaSize = 108;

class JapItem {
  final String title;
  final String? text;
  const JapItem(this.title, [this.text]);
}

const List<JapItem> kNames = [
  JapItem('श्री गणेश'),
  JapItem('राधे राधे'),
  JapItem('राधा कृष्ण'),
  JapItem('जय खोडियार माँ'),
  JapItem('जय दशा माँ'),
  JapItem('जय आद्यशक्ति माँ'),
  JapItem('साम्ब सदाशिव'),
  JapItem('राम राम'),
  JapItem('सीताराम'),
  JapItem('आञ्जनेय'),
  JapItem('नारायण'),
];

const List<JapItem> kMantras = [
  JapItem('Ganesh Mantra', 'ॐ गं गणपतये नमः॥'),
  JapItem('Keshav Mantra', 'ॐ केशवाय नमः॥'),
  JapItem('Maha Mrityunjaya Mantra',
      'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम्।\nउर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय मामृतात्॥'),
  JapItem('Krishnaaya Vasudevaya Mantra',
      'ॐ कृष्णाय वासुदेवाय हरये परमात्मने।\nप्रणतः क्लेशनाशाय गोविन्दाय नमो नमः॥'),
  JapItem('Hare Krishna Mahamantra',
      'हरे कृष्ण हरे कृष्ण, कृष्ण कृष्ण हरे हरे।\nहरे राम हरे राम, राम राम हरे हरे॥'),
  JapItem('Gayatri Mantra',
      'ॐ भूर्भुवः स्वः।\nतत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि।\nधियो यो नः प्रचोदयात्॥'),
  JapItem('Vasudeva Mantra', 'ॐ नमो भगवते वासुदेवाय॥'),
];

void main() => runApp(const SoulBeadsApp());

class SoulBeadsApp extends StatelessWidget {
  const SoulBeadsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        scaffoldBackgroundColor: const Color(0xFFFFF8F0),
        useMaterial3: true,
      ),
      home: const JapPage(),
    );
  }
}

class JapPage extends StatefulWidget {
  const JapPage({super.key});

  @override
  State<JapPage> createState() => _JapPageState();
}

class _JapPageState extends State<JapPage> {
  JapItem _item = kNames[1];
  bool _groupMode = false;
  int _count = 0;
  int _target = 108;
  bool _vibrate = true;

  JapItem get _shown => _groupMode ? kNames[_count % kNames.length] : _item;

  void _tap() {
    setState(() => _count++);
    if (_vibrate) {
      if (_count == _target) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
    if (_count == _target) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Target of $_target complete 🙏')),
      );
    }
  }

  void _reset() => setState(() => _count = 0);

  Future<void> _openList() async {
    final JapItem? picked = await Navigator.of(context).push<JapItem>(
      MaterialPageRoute<JapItem>(builder: (_) => const ListPage()),
    );
    if (picked != null) {
      setState(() {
        _item = picked;
        _groupMode = false;
        _count = 0;
      });
    }
  }

  Future<void> _customTarget() async {
    final controller = TextEditingController();
    final String? result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. 1008'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    final int? n = int.tryParse(result ?? '');
    if (n != null && n > 0) {
      setState(() => _target = n);
    }
  }

  Widget _targetChips() {
    const presets = [11, 21, 51, 108];
    final isCustom = !presets.contains(_target);
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final t in presets)
          ChoiceChip(
            label: Text('$t'),
            selected: _target == t,
            onSelected: (_) => setState(() => _target = t),
          ),
        ChoiceChip(
          label: Text(isCustom ? 'Custom: $_target' : 'Custom'),
          selected: isCustom,
          onSelected: (_) => _customTarget(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shown = _shown;
    final lit = _count == 0 ? 0 : ((_count - 1) % kMalaSize) + 1;
    final malas = _count ~/ kMalaSize;
    final side = math.min(MediaQuery.of(context).size.width - 32, 340.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppName),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Vibration',
            icon: Icon(_vibrate ? Icons.vibration : Icons.mobile_off),
            onPressed: () => setState(() => _vibrate = !_vibrate),
          ),
          IconButton(
            tooltip: 'Names and mantras',
            icon: const Icon(Icons.list_alt),
            onPressed: _openList,
          ),
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Single')),
                  ButtonSegment(value: true, label: Text('Name group')),
                ],
                selected: {_groupMode},
                onSelectionChanged: (s) => setState(() {
                  _groupMode = s.first;
                  _count = 0;
                }),
              ),
              const SizedBox(height: 20),
              Text(
                shown.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: shown.text == null ? 34 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (shown.text != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    shown.text!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, height: 1.5),
                  ),
                ),
              const SizedBox(height: 20),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _tap,
                child: SizedBox(
                  width: side,
                  height: side,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(side, side),
                        painter: MalaPainter(
                            lit, cs.primary, cs.primaryContainer),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_count',
                            style: const TextStyle(
                                fontSize: 64, fontWeight: FontWeight.bold),
                          ),
                          Text('of $_target'),
                          if (malas > 0) Text('Malas: $malas'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _targetChips(),
            ],
          ),
        ),
      ),
    );
  }
}

class MalaPainter extends CustomPainter {
  final int lit;
  final Color litColor;
  final Color dimColor;

  MalaPainter(this.lit, this.litColor, this.dimColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final beadR = (2 * math.pi * radius / kMalaSize) / 2 * 0.8;
    for (int i = 0; i < kMalaSize; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / kMalaSize;
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final paint = Paint()..color = i < lit ? litColor : dimColor;
      canvas.drawCircle(pos, beadR, paint);
    }
  }

  @override
  bool shouldRepaint(MalaPainter old) =>
      old.lit != lit ||
      old.litColor != litColor ||
      old.dimColor != dimColor;
}

class ListPage extends StatelessWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Names and mantras')),
      body: ListView(
        children: [
          const _Header('Divine Names'),
          for (final n in kNames)
            ListTile(
              title: Text(n.title, style: const TextStyle(fontSize: 20)),
              onTap: () => Navigator.pop(context, n),
            ),
          const _Header('Mantras'),
          for (final m in kMantras)
            ListTile(
              title: Text(m.title),
              subtitle: Text(m.text!, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(context, m),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String label;
  const _Header(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
