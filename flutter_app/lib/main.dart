import 'dart:async';
import 'dart:io' show Platform, exit;
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'demo_auth_gate.dart';

const _bg = Color(0xFF05050A); // Keep the app background fixed.
const _panel = Color(0xFF100D18);
const _white = Color(0xFFF2ECFA);
const _muted = Color(0xFF9A8EAD);
const _green = Color(0xFF4CAF50);

const _palettes = <List<Color>>[
  [Color(0xFFE8E7EE), Color(0xFF38383F)],
  [Color(0xFF418BFF), Color(0xFFFF76C8)],
  [Color(0xFF54D7FF), Color(0xFF8A55FF)],
];

String _tr(bool english, String ru, String en) => english ? en : ru;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await windowManager.setBackgroundColor(_bg);
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
    await windowManager.setMinimumSize(const Size(440, 820));
    await windowManager.setSize(const Size(440, 820));
    await windowManager.setAlignment(Alignment.center);
  }
  runApp(const SpiderVpnApp());
}

class SpiderVpnApp extends StatelessWidget {
  const SpiderVpnApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Spider VPN',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _bg,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9B35FF), brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: DemoAuthGate(appBuilder: (_) => const AppShell()),
      );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  bool _english = false;
  int _palette = 0;
  final _closeKey = GlobalKey();
  final _serverKey = GlobalKey();
  final _powerKey = GlobalKey();
  final _navKey = GlobalKey();
  final Map<int, Offset> _dragStarts = {};
  final Set<int> _draggable = {};

  bool _contains(GlobalKey key, Offset point) {
    final object = key.currentContext?.findRenderObject();
    return object is RenderBox && object.hasSize && (object.localToGlobal(Offset.zero) & object.size).contains(point);
  }

  void _down(PointerDownEvent event) {
    if (!Platform.isWindows || event.kind != PointerDeviceKind.mouse || (event.buttons & kPrimaryMouseButton) == 0) return;
    _dragStarts[event.pointer] = event.position;
    if (!_contains(_closeKey, event.position) && !_contains(_serverKey, event.position) && !_contains(_powerKey, event.position) && !_contains(_navKey, event.position)) _draggable.add(event.pointer);
  }

  void _move(PointerMoveEvent event) {
    if (!_draggable.contains(event.pointer) || (event.buttons & kPrimaryMouseButton) == 0) return;
    final start = _dragStarts[event.pointer];
    if (start == null || (event.position - start).distance < 5) return;
    _draggable.remove(event.pointer);
    _dragStarts.remove(event.pointer);
    unawaited(windowManager.startDragging());
  }

  void _clear(int pointer) {
    _dragStarts.remove(pointer);
    _draggable.remove(pointer);
  }

  void _close() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accents = _palettes[_palette];
    return Listener(
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: (event) => _clear(event.pointer),
      onPointerCancel: (event) => _clear(event.pointer),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: accents.first, width: 1.4), borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                child: Column(
                  children: [
                    _AppHeader(closeKey: _closeKey, english: _english, accent: accents.first, onClose: _close, onLanguage: () => setState(() => _english = !_english)),
                    Expanded(
                      child: IndexedStack(
                        index: _tab,
                        children: [
                          HomeScreen(key: const ValueKey('home'), serverKey: _serverKey, powerKey: _powerKey, english: _english, accent: accents.first, glow: accents.last),
                          ProfileScreen(key: const ValueKey('profile'), english: _english, palette: _palette, onPalette: (value) => setState(() => _palette = value), accent: accents.first),
                        ],
                      ),
                    ),
                    _BottomNav(navKey: _navKey, selected: _tab, english: _english, accent: accents.first, onSelect: (value) => setState(() => _tab = value)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.closeKey, required this.english, required this.accent, required this.onClose, required this.onLanguage});
  final GlobalKey closeKey;
  final bool english;
  final Color accent;
  final VoidCallback onClose;
  final VoidCallback onLanguage;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Row(children: [
          IconButton(key: closeKey, tooltip: _tr(english, 'Закрыть приложение', 'Close app'), onPressed: onClose, icon: Icon(Icons.close_rounded, color: accent, size: 25)),
          const Spacer(),
          Icon(Icons.pets_rounded, color: accent, size: 21),
          const SizedBox(width: 8),
          const Text('Spider VPN', style: TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w600)),
          const Spacer(),
          Material(
            color: const Color(0xFF17111D),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onLanguage,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                child: RichText(text: TextSpan(style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800), children: [
                  TextSpan(text: 'EN', style: TextStyle(color: english ? accent : _muted)),
                  const TextSpan(text: ' | ', style: TextStyle(color: _muted)),
                  TextSpan(text: 'RU', style: TextStyle(color: english ? _muted : accent)),
                ])),
              ),
            ),
          ),
        ]),
      );
}

class VpnServer {
  const VpnServer(this.country, this.flag, this.city, this.cityEn);
  final String country;
  final String flag;
  final String city;
  final String cityEn;
}

const _servers = <VpnServer>[
  VpnServer('США', '🇺🇸', 'Нью-Йорк', 'New York'),
  VpnServer('Германия', '🇩🇪', 'Берлин', 'Berlin'),
  VpnServer('Нидерланды', '🇳🇱', 'Амстердам', 'Amsterdam'),
  VpnServer('Швеция', '🇸🇪', 'Стокгольм', 'Stockholm'),
  VpnServer('Япония', '🇯🇵', 'Токио', 'Tokyo'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.serverKey, required this.powerKey, required this.english, required this.accent, required this.glow});
  final GlobalKey serverKey;
  final GlobalKey powerKey;
  final bool english;
  final Color accent;
  final Color glow;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _weave;
  late final AnimationController _blink;
  late final Animation<Color?> _connectedFlash;
  VpnServer _server = _servers.first;
  bool _connecting = false;
  bool _connected = false;
  bool _unstable = false;
  Duration _uptime = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _weave = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..addStatusListener(_onWeaveStatus);
    _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _connectedFlash = TweenSequence<Color?>([
      TweenSequenceItem(tween: ColorTween(begin: _white, end: _green), weight: 10),
      TweenSequenceItem(tween: ColorTween(begin: _green, end: _white), weight: 10),
      TweenSequenceItem(tween: ColorTween(begin: _white, end: _green), weight: 10),
      TweenSequenceItem(tween: ColorTween(begin: _green, end: _white), weight: 10),
      TweenSequenceItem(tween: ColorTween(begin: _white, end: _green), weight: 10),
      TweenSequenceItem(tween: ColorTween(begin: _green, end: _white), weight: 10),
      TweenSequenceItem(tween: ConstantTween<Color?>(_white), weight: 40),
    ]).animate(_blink);
  }

  void _onWeaveStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted || !_connecting) return;
    setState(() { _connecting = false; _connected = true; _unstable = false; });
    _blink.forward(from: 0);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _connected) setState(() => _uptime += const Duration(seconds: 1));
    });
  }

  Future<void> _chooseServer() async {
    final selected = await showModalBottomSheet<VpnServer>(
      context: context,
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          Padding(padding: const EdgeInsets.all(12), child: Text(_tr(widget.english, 'Выберите страну', 'Choose a country'), style: const TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w600))),
          for (final server in _servers) ListTile(
            leading: Text(server.flag, style: const TextStyle(fontSize: 26)),
            title: Text(widget.english ? _countryEn(server.country) : server.country, style: const TextStyle(color: _white)),
            subtitle: Text(widget.english ? server.cityEn : server.city, style: const TextStyle(color: _muted)),
            trailing: server.country == _server.country ? Icon(Icons.check_circle, color: widget.accent) : null,
            onTap: () => Navigator.pop(context, server),
          ),
        ],
      )),
    );
    if (!mounted || selected == null) return;
    _timer?.cancel();
    _blink.reset();
    setState(() { _server = selected; _uptime = Duration.zero; _connected = false; _connecting = true; _unstable = false; });
    _weave.forward(from: 0);
  }

  String _countryEn(String country) => switch (country) {
        'США' => 'United States', 'Германия' => 'Germany', 'Нидерланды' => 'Netherlands', 'Швеция' => 'Sweden', 'Япония' => 'Japan', _ => country,
      };

  void _toggleVpn() {
    if (_connecting) {
      _weave.stop();
      setState(() { _connecting = false; _connected = false; _unstable = true; _uptime = Duration.zero; });
      return;
    }
    if (_connected) {
      _timer?.cancel();
      _blink.reset();
      setState(() { _connected = false; _uptime = Duration.zero; _unstable = false; });
      _weave.reverse();
      return;
    }
    setState(() { _connecting = true; _unstable = false; });
    _weave.forward(from: 0);
  }

  @override
  void dispose() { _timer?.cancel(); _weave.dispose(); _blink.dispose(); super.dispose(); }

  String get _time {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(_uptime.inHours)}:${two(_uptime.inMinutes.remainder(60))}:${two(_uptime.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final status = _connecting
        ? _tr(widget.english, 'Подключение…', 'Connecting…')
        : _unstable
            ? _tr(widget.english, 'Соединение нестабильно', 'Connection unstable')
            : _connected
                ? _tr(widget.english, 'Подключено', 'Connected')
                : _tr(widget.english, 'Не подключено', 'Not connected');
    return Column(children: [
      const SizedBox(height: 22),
      Material(
        color: const Color(0xFF120F1A),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: widget.serverKey,
          onTap: _chooseServer,
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
            Icon(Icons.bolt_rounded, color: widget.accent), const SizedBox(width: 10), Text(_server.flag, style: const TextStyle(fontSize: 24)), const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${widget.english ? _countryEn(_server.country) : _server.country} · ${widget.english ? _server.cityEn : _server.city}', style: const TextStyle(color: _white, fontWeight: FontWeight.w600)),
              Text(_unstable ? _tr(widget.english, 'Соединение нестабильно', 'Connection unstable') : _connecting ? _tr(widget.english, 'Подключение к серверу…', 'Connecting to server…') : _connected ? _tr(widget.english, 'Подключено', 'Connected') : _tr(widget.english, 'Нажмите, чтобы выбрать сервер', 'Tap to select server'), style: const TextStyle(color: _muted, fontSize: 12)),
            ])), const Icon(Icons.chevron_right, color: _muted),
          ])),
        ),
      ),
      const Spacer(),
      SizedBox(width: 320, height: 320, child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: AnimatedBuilder(animation: _weave, builder: (context, _) => CustomPaint(painter: WeavingSpiderPainter(progress: _connected ? 1 : _weave.value, showSpider: _connecting, accent: widget.accent)))),
        _PowerButton(key: widget.powerKey, connecting: _connecting, connected: _connected, unstable: _unstable, accent: widget.accent, glow: widget.glow, onTap: _toggleVpn),
      ])),
      const SizedBox(height: 8),
      AnimatedBuilder(animation: _blink, builder: (context, _) => Text(status, textAlign: TextAlign.center, style: TextStyle(color: _unstable ? const Color(0xFFFF5570) : (_connected ? (_connectedFlash.value ?? _white) : _white), fontSize: 21, fontWeight: FontWeight.w600))),
      const SizedBox(height: 8),
      _connected
          ? Text(_time, style: TextStyle(color: widget.accent, fontSize: 29, letterSpacing: 4, fontWeight: FontWeight.w700))
          : Text(_connecting ? _tr(widget.english, 'Паучок плетёт защищённый маршрут', 'Weaving a secure route') : _unstable ? _tr(widget.english, 'Нажмите кнопку, чтобы повторить', 'Tap to retry') : _tr(widget.english, 'Нажмите кнопку для подключения', 'Tap to connect'), textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13)),
      const Spacer(),
    ]);
  }
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({super.key, required this.connecting, required this.connected, required this.unstable, required this.accent, required this.glow, required this.onTap});
  final bool connecting, connected, unstable;
  final Color accent, glow;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
        width: 160, height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [Color.lerp(glow, const Color(0xFF09070E), .2)!, const Color(0xFF09070E)]),
          border: Border.all(color: unstable ? const Color(0xFFFF5570) : accent, width: connected || connecting || unstable ? 3.5 : 2.5),
          boxShadow: [BoxShadow(color: (unstable ? const Color(0xFFFF5570) : glow).withOpacity(.4), blurRadius: connected ? 38 : 24, spreadRadius: 4)],
        ),
        child: Material(color: Colors.transparent, shape: const CircleBorder(), child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: Center(child: connecting ? CircularProgressIndicator(color: accent) : Icon(unstable ? Icons.close_rounded : Icons.power_settings_new_rounded, color: unstable ? const Color(0xFFFF5570) : _white, size: 40)))),
      );
}

class WeavingSpiderPainter extends CustomPainter {
  const WeavingSpiderPainter({required this.progress, required this.showSpider, required this.accent});
  final double progress;
  final bool showSpider;
  final Color accent;
  static const int _spokes = 12;
  static const int _rings = 7;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .46;
    final p = progress.clamp(0.0, 1.0).toDouble();
    final thread = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.1..strokeCap = StrokeCap.round..color = accent.withOpacity(.72);
    final glow = Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..color = accent.withOpacity(.16)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < _spokes; i++) {
      final a = -math.pi / 2 + math.pi * 2 * i / _spokes;
      final end = Offset(center.dx + math.cos(a) * radius * (p / .52).clamp(0.0, 1.0), center.dy + math.sin(a) * radius * (p / .52).clamp(0.0, 1.0));
      final line = Path()..moveTo(center.dx, center.dy)..lineTo(end.dx, end.dy);
      canvas.drawPath(line, glow); canvas.drawPath(line, thread);
    }
    final ringProgress = ((p - .34) / .66).clamp(0.0, 1.0).toDouble();
    for (var ring = 1; ring <= _rings; ring++) {
      final reveal = (ringProgress * _rings - (ring - 1)).clamp(0.0, 1.0).toDouble();
      if (reveal <= 0) continue;
      final r = radius * ring / _rings;
      final path = Path();
      for (var i = 0; i <= _spokes; i++) {
        final a = -math.pi / 2 + math.pi * 2 * i / _spokes;
        final point = Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
        if (i == 0) { path.moveTo(point.dx, point.dy); continue; }
        final prev = -math.pi / 2 + math.pi * 2 * (i - 1) / _spokes;
        final middle = (prev + a) / 2;
        path.quadraticBezierTo(center.dx + math.cos(middle) * r * .91, center.dy + math.sin(middle) * r * .91, point.dx, point.dy);
      }
      final metrics = path.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final partial = metrics.first.extractPath(0, metrics.first.length * reveal);
        canvas.drawPath(partial, glow); canvas.drawPath(partial, thread);
      }
    }
    if (showSpider && p < 1) {
      final a = -math.pi / 2 + math.pi * 2 * p;
      _drawSpider(canvas, Offset(center.dx + math.cos(a) * radius * .84, center.dy + math.sin(a) * radius * .84), a + math.pi / 2, accent);
    }
  }
  void _drawSpider(Canvas canvas, Offset center, double rotation, Color color) {
    canvas.save(); canvas.translate(center.dx, center.dy); canvas.rotate(rotation);
    final legs = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.7..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = (i - 1.5) * 3.2;
      for (final side in [-1.0, 1.0]) {
        final path = Path()..moveTo(side * 2, y)..quadraticBezierTo(side * 7, y - 2, side * 11, y - 7)..moveTo(side * 2, y)..quadraticBezierTo(side * 7, y + 2, side * 11, y + 7);
        canvas.drawPath(path, legs);
      }
    }
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 7, height: 11), Paint()..color = color);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant WeavingSpiderPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.showSpider != showSpider || oldDelegate.accent != accent;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.english, required this.palette, required this.onPalette, required this.accent});
  final bool english;
  final int palette;
  final ValueChanged<int> onPalette;
  final Color accent;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _login = 'spider_user';
  String? _gmail;
  String? _phone;
  String _dns = 'Cloudflare (1.1.1.1)';
  String _mode = 'Туннель';
  String _language = 'Русский';
  String t(String ru, String en) => _tr(widget.english, ru, en);
  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _editText({required String title, required String label, required String initial, required String? Function(String) validate, required ValueChanged<String> save, TextInputType keyboard = TextInputType.text}) async {
    final controller = TextEditingController(text: initial);
    final key = GlobalKey<FormState>();
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      backgroundColor: _panel,
      title: Text(title, style: const TextStyle(color: _white)),
      content: Form(key: key, child: TextFormField(controller: controller, keyboardType: keyboard, style: const TextStyle(color: _white), decoration: InputDecoration(labelText: label), validator: (value) => validate((value ?? '').trim()))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t('Отмена', 'Cancel'))), FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(context, controller.text.trim()); }, child: Text(t('Сохранить', 'Save'))],
    ));
    controller.dispose();
    if (result != null && mounted) save(result);
  }

  Future<void> _changeLogin() => _editText(title: t('Изменить логин', 'Change username'), label: t('Новый логин', 'New username'), initial: _login, validate: (v) => v.length >= 3 ? null : t('Минимум 3 символа', 'At least 3 characters'), save: (v) { setState(() => _login = v); _toast(t('Логин обновлён в демо-профиле.', 'Username updated in demo profile.')); });

  Future<void> _changePassword() async {
    final pass = TextEditingController(); final confirm = TextEditingController(); final key = GlobalKey<FormState>();
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      backgroundColor: _panel,
      title: Text(t('Изменить пароль', 'Change password'), style: const TextStyle(color: _white)),
      content: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: pass, obscureText: true, decoration: InputDecoration(labelText: t('Новый пароль', 'New password')), validator: (v) => (v ?? '').length >= 6 ? null : t('Минимум 6 символов', 'At least 6 characters')),
        TextFormField(controller: confirm, obscureText: true, decoration: InputDecoration(labelText: t('Повторите пароль', 'Repeat password')), validator: (v) => v == pass.text ? null : t('Пароли не совпадают', 'Passwords do not match')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t('Отмена', 'Cancel'))), FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(context, pass.text); }, child: Text(t('Сохранить', 'Save'))],
    ));
    pass.dispose(); confirm.dispose();
    if (result != null && mounted) _toast(t('Пароль обновлён в демо-профиле.', 'Password updated in demo profile.'));
  }

  Future<void> _bindGmail() => _editText(title: t('Привязать Gmail', 'Link Gmail'), label: t('Адрес @gmail.com', 'Gmail address'), initial: _gmail ?? '', keyboard: TextInputType.emailAddress, validate: (v) => RegExp(r'^[A-Z0-9._%+-]+@gmail\.com$', caseSensitive: false).hasMatch(v) ? null : t('Разрешён только адрес @gmail.com', 'Only @gmail.com addresses are allowed'), save: (v) { setState(() => _gmail = v); _toast(t('Gmail сохранён в демо-профиле.', 'Gmail saved in demo profile.')); });
  Future<void> _bindPhone() => _editText(title: t('Привязать номер телефона', 'Link phone number'), label: t('Номер телефона', 'Phone number'), initial: _phone ?? '', keyboard: TextInputType.phone, validate: (v) => RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(v) ? null : t('Введите корректный номер', 'Enter a valid phone number'), save: (v) { setState(() => _phone = v); _toast(t('Номер сохранён в демо-профиле.', 'Number saved in demo profile.')); });

  Future<void> _selectValue({required String title, required List<String> options, required ValueChanged<String> onSelect}) async {
    final value = await showModalBottomSheet<String>(context: context, backgroundColor: _panel, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: const EdgeInsets.all(18), child: Text(title, style: const TextStyle(color: _white, fontSize: 18, fontWeight: FontWeight.w600))),
      for (final option in options) ListTile(title: Text(option, style: const TextStyle(color: _white)), onTap: () => Navigator.pop(context, option)),
    ])));
    if (value != null) onSelect(value);
  }

  Future<void> _openSubscription() async {
    await showModalBottomSheet<void>(context: context, backgroundColor: _panel, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) => SafeArea(child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t('Управление подпиской', 'Manage subscription'), style: const TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8), Text(t('Осталось 11 дней 9 часов', '11 days 9 hours remaining'), style: const TextStyle(color: _muted)),
        const SizedBox(height: 18),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: widget.accent), onPressed: () => Navigator.pop(context), child: Text(t('Продлить подписку', 'Renew subscription'))),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(t('Приобрести подписку', 'Purchase subscription'))),
      ]),
    )));
  }

  @override
  Widget build(BuildContext context) => ListView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.fromLTRB(0, 10, 0, 16), children: [
    Text(t('Профиль', 'Profile'), style: const TextStyle(color: _white, fontSize: 22, fontWeight: FontWeight.w600)),
    const SizedBox(height: 16),
    _SectionTitle(t('Управление аккаунтом', 'Account management')),
    const SizedBox(height: 8),
    _ProfileAction(icon: Icons.workspace_premium_rounded, title: t('Управление подпиской', 'Manage subscription'), subtitle: t('Осталось 11 дней 9 часов', '11 days 9 hours remaining'), accent: widget.accent, onTap: _openSubscription),
    const SizedBox(height: 8),
    _ProfileAction(icon: Icons.privacy_tip_outlined, title: t('Конфиденциальность', 'Privacy'), subtitle: t('Логин, пароль, Gmail и номер телефона', 'Username, password, Gmail and phone'), accent: widget.accent, onTap: _openPrivacy),
    const SizedBox(height: 18),
    _SectionTitle(t('Настройки подключения', 'Connection settings')),
    const SizedBox(height: 8),
    _SettingPicker(label: t('Режим подключения', 'Connection mode'), value: _languageValue(_mode), accent: widget.accent, onTap: () => _selectValue(title: t('Режим подключения', 'Connection mode'), options: widget.english ? const ['Tunnel', 'Automatic', 'Split tunnel'] : const ['Туннель', 'Автоматический', 'Сплит-туннель'], onSelect: (v) => setState(() => _mode = widget.english ? _modeFromEnglish(v) : v))),
    const SizedBox(height: 8),
    _SettingPicker(label: 'DNS', value: _dns, accent: widget.accent, onTap: () => _selectValue(title: 'DNS', options: const ['Cloudflare (1.1.1.1)', 'Google (8.8.8.8)', 'Automatic'], onSelect: (v) => setState(() => _dns = v))),
    const SizedBox(height: 18),
    _SectionTitle(t('Маршрутизация', 'Routing')),
    const SizedBox(height: 8),
    _ProfileAction(icon: Icons.alt_route_rounded, title: t('Настройки сплит-туннелирования', 'Split tunneling settings'), accent: widget.accent, onTap: () => _toast(t('Настройка доступна в демо-режиме.', 'Demo setting only.'))),
    const SizedBox(height: 18),
    _SectionTitle(t('Система', 'System')),
    const SizedBox(height: 8),
    _SettingPicker(label: t('Язык', 'Language'), value: _language, accent: widget.accent, onTap: () => _selectValue(title: t('Язык', 'Language'), options: const ['Русский', 'English'], onSelect: (v) => setState(() => _language = v))),
    const SizedBox(height: 8),
    _ProfileAction(icon: Icons.tune_rounded, title: t('Расширенные настройки', 'Advanced settings'), accent: widget.accent, onTap: () => _toast(t('Расширенные настройки', 'Advanced settings'))),
    const SizedBox(height: 18),
    _SectionTitle('Custom color'),
    const SizedBox(height: 10),
    _PaletteRow(selected: widget.palette, accent: widget.accent, onSelect: widget.onPalette),
    const SizedBox(height: 18),
    _SectionTitle(t('Управление', 'Management')),
    const SizedBox(height: 8),
    _ProfileAction(icon: Icons.add_to_home_screen_rounded, title: t('Добавить устройство', 'Add device'), subtitle: t('До 10 устройств', 'Up to 10 devices'), accent: widget.accent),
    const SizedBox(height: 8),
    _ProfileAction(icon: Icons.headset_mic_rounded, title: t('Обратиться в поддержку', 'Contact support'), accent: widget.accent),
    const SizedBox(height: 18),
    _SectionTitle(t('Полезные ссылки', 'Useful links')),
    const SizedBox(height: 8),
    _ProfileAction(icon: Icons.language_rounded, title: t('Официальный сайт', 'Official website'), subtitle: 'spidervpn.com', accent: widget.accent),
    const SizedBox(height: 8),
    _ProfileAction(icon: Icons.send_rounded, title: 'Telegram', subtitle: 't.me/spidervpn', accent: widget.accent),
    const SizedBox(height: 8),
    _ProfileAction(icon: Icons.logout_rounded, title: t('Выйти из аккаунта', 'Log out'), accent: widget.accent),
  ]);

  String _languageValue(String value) => widget.english ? _modeFromRussian(value) : value;
  String _modeFromRussian(String value) => switch (value) { 'Туннель' => 'Tunnel', 'Автоматический' => 'Automatic', 'Сплит-туннель' => 'Split tunnel', _ => value };
  String _modeFromEnglish(String value) => switch (value) { 'Tunnel' => 'Туннель', 'Automatic' => 'Автоматический', 'Split tunnel' => 'Сплит-туннель', _ => value };

  Future<void> _openPrivacy() async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: _panel, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) => StatefulBuilder(builder: (context, setSheetState) => SafeArea(child: Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t('Конфиденциальность', 'Privacy'), style: const TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8), Text(t('Изменения сохраняются только в демо-приложении.', 'Changes are only saved in this demo app.'), style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 14),
        _ProfileAction(icon: Icons.person_outline, title: t('Изменить логин', 'Change username'), subtitle: _login, accent: widget.accent, onTap: () async { await _changeLogin(); setSheetState(() {}); }),
        const SizedBox(height: 8),
        _ProfileAction(icon: Icons.lock_outline, title: t('Изменить пароль', 'Change password'), subtitle: '••••••••', accent: widget.accent, onTap: _changePassword),
        const SizedBox(height: 8),
        _ProfileAction(icon: Icons.mail_outline, title: _gmail == null ? t('Привязать Gmail', 'Link Gmail') : 'Gmail', subtitle: _gmail ?? t('Только адрес @gmail.com', 'Only @gmail.com'), accent: widget.accent, onTap: () async { await _bindGmail(); setSheetState(() {}); }),
        const SizedBox(height: 8),
        _ProfileAction(icon: Icons.phone_outlined, title: _phone == null ? t('Привязать номер телефона', 'Link phone number') : t('Номер телефона', 'Phone number'), subtitle: _phone ?? t('Не привязан', 'Not linked'), accent: widget.accent, onTap: () async { await _bindPhone(); setSheetState(() {}); }),
        const SizedBox(height: 8),
      ]),
    ))));
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.selected, required this.accent, required this.onSelect});
  final int selected;
  final Color accent;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_palettes.length, (index) => GestureDetector(
    onTap: () => onSelect(index),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 11), width: 34, height: 34,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _palettes[index]), border: Border.all(color: selected == index ? _white : Colors.transparent, width: selected == index ? 2.5 : 0), boxShadow: selected == index ? [BoxShadow(color: accent.withOpacity(.35), blurRadius: 12)] : null),
    ),
  ))));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(color: _white, fontSize: 17, fontWeight: FontWeight.w700));
}

class _SettingPicker extends StatelessWidget {
  const _SettingPicker({required this.label, required this.value, required this.onTap, required this.accent});
  final String label, value;
  final VoidCallback onTap;
  final Color accent;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF1C141E), borderRadius: BorderRadius.circular(12),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(
      padding: const EdgeInsets.fromLTRB(15, 11, 12, 10),
      child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: _muted, fontSize: 13)), const SizedBox(height: 3), Text(value, style: const TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w600))])), Icon(Icons.keyboard_arrow_down_rounded, color: accent)]),
    )),
  );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({required this.icon, required this.title, this.subtitle, this.onTap, required this.accent});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color accent;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF1C141E), borderRadius: BorderRadius.circular(15),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [Icon(icon, color: accent, size: 22), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w600)), if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12))]])), const Icon(Icons.chevron_right_rounded, color: _muted, size: 22)]),
    )),
  );
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.navKey, required this.selected, required this.english, required this.accent, required this.onSelect});
  final GlobalKey navKey;
  final int selected;
  final bool english;
  final Color accent;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Container(
    key: navKey, padding: const EdgeInsets.only(top: 7, bottom: 3),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF31212F)))),
    child: Row(children: [
      Expanded(child: _NavItem(icon: Icons.home_rounded, label: _tr(english, 'Главная', 'Home'), active: selected == 0, accent: accent, onTap: () => onSelect(0))),
      Expanded(child: _NavItem(icon: Icons.person_rounded, label: _tr(english, 'Профиль', 'Profile'), active: selected == 1, accent: accent, onTap: () => onSelect(1))),
    ]),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.accent, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: active ? accent : _muted, size: 25), const SizedBox(height: 3), Text(label, style: TextStyle(color: active ? accent : _muted, fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400)), const SizedBox(height: 4), AnimatedContainer(duration: const Duration(milliseconds: 240), width: active ? 42 : 0, height: 2, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2)))]),
  ));
}
