import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------- App basics ----------
const String kAppName = 'SoulBeads'; // change the app name here
const int kMalaSize = 108;

int gLang = 0; // 0 English, 1 Hindi, 2 Gujarati
const List<String> kLangNames = ['English', 'हिन्दी', 'ગુજરાતી'];
const List<String> kCatKeys = ['names', 'mantras', 'mine'];

const Map<String, List<String>> kStr = {
  'names': ['Names', 'नाम', 'નામ'],
  'mantras': ['Mantras', 'मन्त्र', 'મંત્ર'],
  'mine': ['My own', 'मेरे अपने', 'મારા પોતાના'],
  'all_names': [
    'All names, one by one',
    'सभी नाम, एक-एक करके',
    'બધા નામ, એક પછી એક'
  ],
  'add_own': ['Add own', 'अपना जोड़ें', 'પોતાનું ઉમેરો'],
  'add_title': ['Add your own', 'अपना जोड़ें', 'પોતાનું ઉમેરો'],
  'title_hint': [
    'Name or mantra title',
    'नाम या मन्त्र का शीर्षक',
    'નામ અથવા મંત્રનું શીર્ષક'
  ],
  'text_hint': [
    'Mantra text (optional)',
    'मन्त्र का पाठ (वैकल्पिक)',
    'મંત્રનો પાઠ (વૈકલ્પિક)'
  ],
  'long_press': [
    'Long-press a card to delete',
    'हटाने के लिए कार्ड को दबाए रखें',
    'કાઢી નાખવા કાર્ડ દબાવી રાખો'
  ],
  'delete_q': ['Delete this card?', 'यह कार्ड हटाएँ?', 'આ કાર્ડ કાઢી નાખવું?'],
  'delete': ['Delete', 'हटाएँ', 'કાઢી નાખો'],
  'add': ['Add', 'जोड़ें', 'ઉમેરો'],
  'cancel': ['Cancel', 'रद्द करें', 'રદ કરો'],
  'set': ['Set', 'सेट करें', 'સેટ કરો'],
  'custom': ['Custom', 'अन्य', 'અન્ય'],
  'custom_target': ['Custom target', 'अपना लक्ष्य', 'પોતાનું લક્ષ્ય'],
  'target': ['Target', 'लक्ष्य', 'લક્ષ્ય'],
  'done': ['Target complete 🙏', 'लक्ष्य पूरा हुआ 🙏', 'લક્ષ્ય પૂર્ણ થયું 🙏'],
  'malas': ['Malas', 'माला', 'માળા'],
  'today': ['Today', 'आज', 'આજે'],
  'streak_days': ['day streak', 'दिन लगातार', 'દિવસ સળંગ'],
  'all_time': ['Total jap', 'कुल जप', 'કુલ જપ'],
  'history': ['History', 'इतिहास', 'ઇતિહાસ'],
  'no_history': [
    'No jap yet. Open a card to start.',
    'अभी तक कोई जप नहीं। शुरू करने के लिए कार्ड खोलें।',
    'હજુ કોઈ જપ નથી. શરૂ કરવા કાર્ડ ખોલો.'
  ],
  'vibration': ['Vibration', 'कंपन', 'વાઇબ્રેશન'],
  'reset': ['Reset', 'रीसेट', 'રીસેટ'],
  'theme': ['Theme', 'थीम', 'થીમ'],
  'language': ['Language', 'भाषा', 'ભાષા'],
  'th_saffron': ['Saffron', 'केसरिया', 'કેસરી'],
  'th_dark': ['Dark gold', 'डार्क गोल्ड', 'ડાર્ક ગોલ્ડ'],
  'th_white': ['White', 'सफ़ेद', 'સફેદ'],
};

String tr(String key) => kStr[key]?[gLang] ?? key;

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ---------- Data ----------
class JapItem {
  final String title; // English title, also used as the saved id
  final String? text;
  final String? hi;
  final String? gu;
  const JapItem(this.title, {this.text, this.hi, this.gu});

  String get shownTitle {
    if (gLang == 1 && hi != null) return hi!;
    if (gLang == 2 && gu != null) return gu!;
    return title;
  }
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
  JapItem('Ganesh Mantra',
      text: 'ॐ गं गणपतये नमः॥', hi: 'गणेश मन्त्रः', gu: 'ગણેશ મંત્ર'),
  JapItem('Keshav Mantra',
      text: 'ॐ केशवाय नमः॥', hi: 'केशव मन्त्रः', gu: 'કેશવ મંત્ર'),
  JapItem('Maha Mrityunjaya Mantra',
      text:
          'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम्।\nउर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय मामृतात्॥',
      hi: 'महामृत्युञ्जय मन्त्रः',
      gu: 'મહામૃત્યુંજય મંત્ર'),
  JapItem('Krishnaaya Vasudevaya Mantra',
      text:
          'ॐ कृष्णाय वासुदेवाय हरये परमात्मने।\nप्रणतः क्लेशनाशाय गोविन्दाय नमो नमः॥',
      hi: 'कृष्णाय वासुदेवाय मन्त्रः',
      gu: 'કૃષ્ણાય વાસુદેવાય મંત્ર'),
  JapItem('Hare Krishna Mahamantra',
      text:
          'हरे कृष्ण हरे कृष्ण, कृष्ण कृष्ण हरे हरे।\nहरे राम हरे राम, राम राम हरे हरे॥',
      hi: 'हरे कृष्ण महामन्त्रः',
      gu: 'હરે કૃષ્ણ મહામંત્ર'),
  JapItem('Gayatri Mantra',
      text:
          'ॐ भूर्भुवः स्वः।\nतत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि।\nधियो यो नः प्रचोदयात्॥',
      hi: 'गायत्री मन्त्रः',
      gu: 'ગાયત્રી મંત્ર'),
  JapItem('Vasudeva Mantra',
      text: 'ॐ नमो भगवते वासुदेवाय॥',
      hi: 'वासुदेव मन्त्रः',
      gu: 'વાસુદેવ મંત્ર'),
];

class AppThemeData {
  final String key;
  final Color seed;
  final Brightness brightness;
  final Color background;
  const AppThemeData(this.key, this.seed, this.brightness, this.background);
}

const List<AppThemeData> kThemes = [
  AppThemeData(
      'th_saffron', Colors.deepOrange, Brightness.light, Color(0xFFFFF8F0)),
  AppThemeData('th_dark', Colors.amber, Brightness.dark, Color(0xFF14110C)),
  AppThemeData('th_white', Colors.indigo, Brightness.light, Colors.white),
];

// ---------- Saved data ----------
class Store extends ChangeNotifier {
  final SharedPreferences prefs;
  List<JapItem> custom = [];
  Map<String, int> hist = {};
  int target = 108;
  bool vibrate = true;
  int theme = 0;
  int lang = 0;

  Store(this.prefs) {
    target = prefs.getInt('target') ?? 108;
    vibrate = prefs.getBool('vibrate') ?? true;
    final th = prefs.getInt('theme') ?? 0;
    theme = (th >= 0 && th < kThemes.length) ? th : 0;
    final lg = prefs.getInt('lang') ?? 0;
    lang = (lg >= 0 && lg < kLangNames.length) ? lg : 0;
    gLang = lang;
    custom = _loadCustom();
    hist = _loadHist();
  }

  JapItem _itemFromJson(Map<String, dynamic> m) =>
      JapItem(m['t'] as String, text: m['x'] as String?);

  List<JapItem> _loadCustom() {
    final raw = prefs.getString('custom');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [for (final e in list) _itemFromJson(e as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  Map<String, int> _loadHist() {
    final raw = prefs.getString('hist');
    if (raw == null) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return {for (final e in m.entries) e.key: (e.value as num).toInt()};
    } catch (_) {
      return {};
    }
  }

  void _saveCustom() {
    prefs.setString(
      'custom',
      jsonEncode([
        for (final c in custom) {'t': c.title, 'x': c.text}
      ]),
    );
  }

  int countOf(String key) => prefs.getInt('cnt:$key') ?? 0;
  void setCount(String key, int n) => prefs.setInt('cnt:$key', n);

  void setTarget(int n) {
    target = n;
    prefs.setInt('target', n);
  }

  void setVibrate(bool v) {
    vibrate = v;
    prefs.setBool('vibrate', v);
  }

  void setTheme(int i) {
    theme = i;
    prefs.setInt('theme', i);
    notifyListeners();
  }

  void setLang(int i) {
    lang = i;
    gLang = i;
    prefs.setInt('lang', i);
    notifyListeners();
  }

  void addCustom(JapItem it) {
    custom = [...custom, it];
    _saveCustom();
    notifyListeners();
  }

  void removeCustom(JapItem it) {
    custom = custom.where((c) => !identical(c, it)).toList();
    prefs.remove('cnt:${it.title}');
    _saveCustom();
    notifyListeners();
  }

  void addJap() {
    final k = dayKey(DateTime.now());
    hist[k] = (hist[k] ?? 0) + 1;
    prefs.setString('hist', jsonEncode(hist));
  }

  int todayCount() => hist[dayKey(DateTime.now())] ?? 0;

  int totalCount() => hist.values.fold<int>(0, (a, b) => a + b);

  int streak() {
    var d = DateTime.now();
    if ((hist[dayKey(d)] ?? 0) == 0) {
      d = DateTime(d.year, d.month, d.day - 1);
    }
    var n = 0;
    while ((hist[dayKey(d)] ?? 0) > 0) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }
}

// ---------- App ----------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(SoulBeadsApp(store: Store(prefs)));
}

class SoulBeadsApp extends StatelessWidget {
  final Store store;
  const SoulBeadsApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final t = kThemes[store.theme];
        return MaterialApp(
          title: kAppName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: t.seed,
            brightness: t.brightness,
            scaffoldBackgroundColor: t.background,
            useMaterial3: true,
          ),
          home: HomePage(store: store),
        );
      },
    );
  }
}

// ---------- Home page (cards) ----------
class HomePage extends StatefulWidget {
  final Store store;
  const HomePage({super.key, required this.store});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _cat = 0;

  Store get s => widget.store;

  Future<void> _open(JapItem? item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => JapPage(store: s, item: item)),
    );
    if (mounted) setState(() {});
  }

  void _openHistory() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => HistoryPage(store: s)),
    );
  }

  Future<void> _addCustom() async {
    final titleC = TextEditingController();
    final textC = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleC,
                autofocus: true,
                decoration: InputDecoration(labelText: tr('title_hint')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textC,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(labelText: tr('text_hint')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('add')),
          ),
        ],
      ),
    );
    final title = titleC.text.trim();
    final text = textC.text.trim();
    if (ok == true && title.isNotEmpty) {
      s.addCustom(JapItem(title, text: text.isEmpty ? null : text));
      if (mounted) setState(() => _cat = 2);
    }
  }

  Future<void> _confirmDelete(JapItem it) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${tr('delete_q')}\n${it.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
    if (ok == true) s.removeCustom(it);
  }

  Widget _card(String label, VoidCallback onTap,
      {VoidCallback? onLong, IconData? icon, bool outlined = false}) {
    final cs = Theme.of(context).colorScheme;
    final fg = outlined ? cs.onSurface : cs.onPrimaryContainer;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLong,
      child: Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined ? null : cs.primaryContainer,
          borderRadius: BorderRadius.circular(18),
          border: outlined ? Border.all(color: cs.primary, width: 1.5) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, color: cs.primary),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _gridChildren() {
    if (_cat == 0) {
      return [
        _card(tr('all_names'), () => _open(null), icon: Icons.auto_awesome),
        for (final it in kNames) _card(it.shownTitle, () => _open(it)),
      ];
    }
    if (_cat == 1) {
      return [for (final it in kMantras) _card(it.shownTitle, () => _open(it))];
    }
    return [
      _card(tr('add_own'), _addCustom, icon: Icons.add, outlined: true),
      for (final it in s.custom)
        _card(it.shownTitle, () => _open(it),
            onLong: () => _confirmDelete(it)),
    ];
  }

  Widget _banner() {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _openHistory,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🔥 ${s.streak()} ${tr('streak_days')}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '${tr('today')}: ${s.todayCount()}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppName),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: tr('history'),
            icon: const Icon(Icons.history),
            onPressed: _openHistory,
          ),
          PopupMenuButton<int>(
            tooltip: tr('language'),
            icon: const Icon(Icons.language),
            onSelected: s.setLang,
            itemBuilder: (_) => [
              for (int i = 0; i < kLangNames.length; i++)
                PopupMenuItem(value: i, child: Text(kLangNames[i])),
            ],
          ),
          PopupMenuButton<int>(
            tooltip: tr('theme'),
            icon: const Icon(Icons.palette_outlined),
            onSelected: s.setTheme,
            itemBuilder: (_) => [
              for (int i = 0; i < kThemes.length; i++)
                PopupMenuItem(value: i, child: Text(tr(kThemes[i].key))),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              _banner(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (int i = 0; i < kCatKeys.length; i++)
                    ChoiceChip(
                      label: Text(tr(kCatKeys[i])),
                      selected: _cat == i,
                      onSelected: (_) => setState(() => _cat = i),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_cat == 2 && s.custom.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(tr('long_press'),
                      style: const TextStyle(fontSize: 12)),
                ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  children: _gridChildren(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Jap page ----------
class JapPage extends StatefulWidget {
  final Store store;
  final JapItem? item; // null means: all names, one by one
  const JapPage({super.key, required this.store, required this.item});

  @override
  State<JapPage> createState() => _JapPageState();
}

class _JapPageState extends State<JapPage> {
  late int _count;
  late int _target;
  late bool _vibrate;

  Store get s => widget.store;
  bool get _group => widget.item == null;
  String get _key => _group ? 'group' : widget.item!.title;
  JapItem get _shown => _group ? kNames[_count % kNames.length] : widget.item!;

  @override
  void initState() {
    super.initState();
    _count = s.countOf(_key);
    _target = s.target;
    _vibrate = s.vibrate;
  }

  void _tap() {
    setState(() => _count++);
    s.setCount(_key, _count);
    s.addJap();
    if (_vibrate) {
      if (_count == _target) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
    if (_count == _target) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_target  ${tr('done')}')),
      );
    }
  }

  void _reset() {
    setState(() => _count = 0);
    s.setCount(_key, 0);
  }

  void _setTarget(int n) {
    setState(() => _target = n);
    s.setTarget(n);
  }

  Future<void> _customTarget() async {
    final controller = TextEditingController();
    final String? result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('custom_target')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. 1008'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(tr('set')),
          ),
        ],
      ),
    );
    final int? n = int.tryParse(result ?? '');
    if (n != null && n > 0) _setTarget(n);
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
            onSelected: (_) => _setTarget(t),
          ),
        ChoiceChip(
          label: Text(isCustom ? '${tr('custom')}: $_target' : tr('custom')),
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
        title: Text(
          _group ? tr('all_names') : widget.item!.shownTitle,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: tr('vibration'),
            icon: Icon(_vibrate ? Icons.vibration : Icons.mobile_off),
            onPressed: () {
              setState(() => _vibrate = !_vibrate);
              s.setVibrate(_vibrate);
            },
          ),
          IconButton(
            tooltip: tr('reset'),
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
              Text(
                shown.shownTitle,
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
                          Text('${tr('target')}: $_target'),
                          if (malas > 0) Text('${tr('malas')}: $malas'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _targetChips(),
              const SizedBox(height: 16),
              Text(
                '${tr('today')}: ${s.todayCount()}',
                style: const TextStyle(fontSize: 16),
              ),
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

// ---------- History page ----------
class HistoryPage extends StatelessWidget {
  final Store store;
  const HistoryPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [
      for (int i = 0; i < 30; i++) DateTime(now.year, now.month, now.day - i),
    ];
    final counts = [for (final d in days) store.hist[dayKey(d)] ?? 0];
    final maxC = counts.fold<int>(1, (a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text(tr('history'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '🔥 ${store.streak()} ${tr('streak_days')}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('${tr('today')}: ${store.todayCount()}'),
          Text('${tr('all_time')}: ${store.totalCount()}'),
          if (store.totalCount() == 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(tr('no_history')),
            ),
          const SizedBox(height: 16),
          for (int i = 0; i < days.length; i++)
            ListTile(
              dense: true,
              leading: Icon(
                  counts[i] > 0 ? Icons.check_circle : Icons.circle_outlined),
              title: Text(i == 0
                  ? '${tr('today')} (${dayKey(days[i])})'
                  : dayKey(days[i])),
              subtitle: LinearProgressIndicator(value: counts[i] / maxC),
              trailing: Text('${counts[i]}'),
            ),
        ],
      ),
    );
  }
}
      
