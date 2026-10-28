import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The app name lives here. Change it in one place.
const String kAppName = 'SoulBeads';
const int kMalaSize = 108;
const List<String> kCats = ['Names', 'Mantras', 'My own'];

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

class AppThemeData {
  final String name;
  final Color seed;
  final Brightness brightness;
  final Color background;
  const AppThemeData(this.name, this.seed, this.brightness, this.background);
}

const List<AppThemeData> kThemes = [
  AppThemeData(
      'Saffron', Colors.deepOrange, Brightness.light, Color(0xFFFFF8F0)),
  AppThemeData('Dark gold', Colors.amber, Brightness.dark, Color(0xFF14110C)),
  AppThemeData('White', Colors.indigo, Brightness.light, Colors.white),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(SoulBeadsApp(prefs: prefs));
}

class SoulBeadsApp extends StatefulWidget {
  final SharedPreferences prefs;
  const SoulBeadsApp({super.key, required this.prefs});

  @override
  State<SoulBeadsApp> createState() => _SoulBeadsAppState();
}

class _SoulBeadsAppState extends State<SoulBeadsApp> {
  late int _themeIndex = _safeTheme(widget.prefs.getInt('theme'));

  int _safeTheme(int? i) => (i != null && i >= 0 && i < kThemes.length) ? i : 0;

  void _setTheme(int i) {
    setState(() => _themeIndex = i);
    widget.prefs.setInt('theme', i);
  }

  @override
  Widget build(BuildContext context) {
    final t = kThemes[_themeIndex];
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: t.seed,
        brightness: t.brightness,
        scaffoldBackgroundColor: t.background,
        useMaterial3: true,
      ),
      home: JapPage(prefs: widget.prefs, onTheme: _setTheme),
    );
  }
}

class JapPage extends StatefulWidget {
  final SharedPreferences prefs;
  final void Function(int) onTheme;
  const JapPage({super.key, required this.prefs, required this.onTheme});

  @override
  State<JapPage> createState() => _JapPageState();
}

class _JapPageState extends State<JapPage> {
  late JapItem _item;
  List<JapItem> _custom = [];
  int _cat = 0;
  bool _groupMode = false;
  int _count = 0;
  int _target = 108;
  bool _vibrate = true;

  @override
  void initState() {
    super.initState();
    final p = widget.prefs;
    _custom = _loadCustom(p);
    _count = p.getInt('count') ?? 0;
    _target = p.getInt('target') ?? 108;
    _vibrate = p.getBool('vibrate') ?? true;
    _groupMode = p.getBool('group') ?? false;
    _item = _findByTitle(p.getString('item')) ?? kNames[1];
    _cat = kMantras.contains(_item) ? 1 : (_custom.contains(_item) ? 2 : 0);
  }

  JapItem _fromJson(Map<String, dynamic> m) =>
      JapItem(m['t'] as String, m['x'] as String?);

  List<JapItem> _loadCustom(SharedPreferences p) {
    final raw = p.getString('custom');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [for (final e in list) _fromJson(e as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  JapItem? _findByTitle(String? t) {
    if (t == null) return null;
    for (final it in [...kNames, ...kMantras, ..._custom]) {
      if (it.title == t) return it;
    }
    return null;
  }

  void _persist() {
    final p = widget.prefs;
    p.setInt('count', _count);
    p.setInt('target', _target);
    p.setBool('vibrate', _vibrate);
    p.setBool('group', _groupMode);
    p.setString('item', _item.title);
  }

  void _persistCustom() {
    widget.prefs.setString(
      'custom',
      jsonEncode([
        for (final c in _custom) {'t': c.title, 'x': c.text}
      ]),
    );
  }

  JapItem get _shown => _groupMode ? kNames[_count % kNames.length] : _item;

  List<JapItem> _itemsFor(int cat) {
    if (cat == 0) return kNames;
    if (cat == 1) return kMantras;
    return _custom;
  }

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
    _persist();
  }

  void _reset() {
    setState(() => _count = 0);
    _persist();
  }

  void _select(JapItem item) {
    setState(() {
      _item = item;
      _groupMode = false;
      _count = 0;
    });
    _persist();
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
      _persist();
    }
  }

  Future<void> _addCustom() async {
    final titleC = TextEditingController();
    final textC = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add your own'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleC,
                autofocus: true,
                decoration:
                    const InputDecoration(labelText: 'Name or mantra title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textC,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: 'Mantra text (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final title = titleC.text.trim();
    if (ok == true && title.isNotEmpty) {
      final text = textC.text.trim();
      final item = JapItem(title, text.isEmpty ? null : text);
      setState(() {
        _custom = [..._custom, item];
        _cat = 2;
      });
      _persistCustom();
      _select(item);
    }
  }

  Future<void> _confirmDelete(JapItem it) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${it.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _custom = _custom.where((c) => !identical(c, it)).toList();
        if (identical(_item, it)) {
          _item = kNames[1];
          _groupMode = false;
          _count = 0;
        }
      });
      _persistCustom();
      _persist();
    }
  }

  Widget _card(JapItem item, {VoidCallback? onLong}) {
    final cs = Theme.of(context).colorScheme;
    final selected = identical(item, _shown);
    return GestureDetector(
      onTap: () => _select(item),
      onLongPress: onLong,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          item.title,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _addCard() {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _addCustom,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.add), Text('Add own')],
        ),
      ),
    );
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
            onSelected: (_) {
              setState(() => _target = t);
              _persist();
            },
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
          PopupMenuButton<int>(
            tooltip: 'Theme',
            icon: const Icon(Icons.palette_outlined),
            onSelected: widget.onTheme,
            itemBuilder: (_) => [
              for (int i = 0; i < kThemes.length; i++)
                PopupMenuItem(value: i, child: Text(kThemes[i].name)),
            ],
          ),
          IconButton(
            tooltip: 'Vibration',
            icon: Icon(_vibrate ? Icons.vibration : Icons.mobile_off),
            onPressed: () {
              setState(() => _vibrate = !_vibrate);
              _persist();
            },
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
                onSelectionChanged: (s) {
                  setState(() {
                    _groupMode = s.first;
                    _count = 0;
                  });
                  _persist();
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (int i = 0; i < kCats.length; i++)
                    ChoiceChip(
                      label: Text(kCats[i]),
                      selected: _cat == i,
                      onSelected: (_) => setState(() => _cat = i),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_cat == 2) _addCard(),
                    for (final it in _itemsFor(_cat))
                      _card(it,
                          onLong: _cat == 2 ? () => _confirmDelete(it) : null),
                  ],
                ),
              ),
              if (_cat == 2 && _custom.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Long-press a card to delete',
                      style: TextStyle(fontSize: 12)),
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
