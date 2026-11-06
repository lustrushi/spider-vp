import 'dart:async';
import 'dart:io' show Platform, exit;
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'demo_auth_gate.dart';

const _bg = Color(0xFF08060B);
const _panel = Color(0xFF151019);
const _pink = Color(0xFFFF4FA3);
const _rose = Color(0xFFFFB4D4);
const _white = Color(0xFFF7F1F7);
const _muted = Color(0xFFAA9EAE);
const _green = Color(0xFF39F27A);
const _red = Color(0xFFFF5570);

String _tr(bool en, String ru, String english) => en ? english : ru;

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
          colorScheme: ColorScheme.fromSeed(seedColor: _pink, brightness: Brightness.dark),
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
  final GlobalKey _closeKey = GlobalKey();
  final GlobalKey _serverKey = GlobalKey();
  final GlobalKey _powerKey = GlobalKey();
  final GlobalKey _navKey = GlobalKey();
  final Map<int, Offset> _pointerStartPositions = {};
  final Set<int> _draggablePointers = {};

  bool _containsPoint(GlobalKey key, Offset point) {
    final object = key.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return false;
    return (object.localToGlobal(Offset.zero) & object.size).contains(point);
  }

  bool _isFunctionalArea(Offset point) => _containsPoint(_closeKey, point) ||
      _containsPoint(_serverKey, point) || _containsPoint(_powerKey, point) || _containsPoint(_navKey, point);

  void _onPointerDown(PointerDownEvent event) {
    if (!Platform.isWindows || event.kind != PointerDeviceKind.mouse || (event.buttons & kPrimaryMouseButton) == 0) return;
    _pointerStartPositions[event.pointer] = event.position;
    if (!_isFunctionalArea(event.position)) _draggablePointers.add(event.pointer);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_draggablePointers.contains(event.pointer) || (event.buttons & kPrimaryMouseButton) == 0) return;
    final start = _pointerStartPositions[event.pointer];
    if (start == null || (event.position - start).distance < 5) return;
    _draggablePointers.remove(event.pointer);
    _pointerStartPositions.remove(event.pointer);
    unawaited(windowManager.startDragging());
  }

  void _clearPointer(int pointer) {
    _pointerStartPositions.remove(pointer);
    _draggablePointers.remove(pointer);
  }

  void _closeApp() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: (event) => _clearPointer(event.pointer),
        onPointerCancel: (event) => _clearPointer(event.pointer),
        child: Scaffold(
          backgroundColor: _bg,
          body: SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(color: _bg, border: Border.all(color: _pink, width: 1.5), borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                    child: Column(
                      children: [
                        _AppHeader(
                          closeKey: _closeKey,
                          english: _english,
                          onClose: _closeApp,
                          onToggleLanguage: () => setState(() => _english = !_english),
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: _tab,
                            children: [
                              HomeScreen(key: const ValueKey('home'), serverKey: _serverKey, powerKey: _powerKey, english: _english),
                              ProfileScreen(key: const ValueKey('profile'), english: _english),
                            ],
                          ),
                        ),
                        _BottomNav(navKey: _navKey, selected: _tab, english: _english, onSelect: (value) => setState(() => _tab = value)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.closeKey, required this.english, required this.onClose, required this.onToggleLanguage});
  final GlobalKey closeKey;
  final bool english;
  final VoidCallback onClose;
  final VoidCallback onToggleLanguage;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Row(
          children: [
            IconButton(key: closeKey, tooltip: _tr(english, 'Закрыть приложение', 'Close app'), onPressed: onClose, icon: const Icon(Icons.close_rounded, color: _rose, size: 25)),
            const Spacer(),
            const _SpiderLogo(size: 23),
            const SizedBox(width: 8),
            const Text('Spider VPN', style: TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w600)),
            const Spacer(),
            Material(
              color: const Color(0xFF21131B),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onToggleLanguage,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      children: [
                        TextSpan(text: 'EN', style: TextStyle(color: english ? _rose : _muted)),
                        const TextSpan(text: ' | ', style: TextStyle(color: _muted)),
                        TextSpan(text: 'RU', style: TextStyle(color: english ? _muted : _rose)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _SpiderLogo extends StatelessWidget {
  const _SpiderLogo({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _SpiderLogoPainter()));
}

class _SpiderLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);
    final stroke = Paint()..color = _pink..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    final fill = Paint()..color = _pink;
    for (var i = 0; i < 4; i++) {
      final y = 7.0 + i * 3.2;
      final spread = 5.0 + (i.isOdd ? 1.0 : 0.0);
      for (final side in [-1.0, 1.0]) {
        final leg = Path()..moveTo(12 + side * 2, y)..quadraticBezierTo(12 + side * 6, y - 1, 12 + side * spread, y - 3)..moveTo(12 + side * 2, y)..quadraticBezierTo(12 + side * 6, y + 1, 12 + side * spread, y + 3);
        canvas.drawPath(leg, stroke);
      }
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(12, 12), width: 5.5, height: 8), fill);
    canvas.drawCircle(const Offset(12, 6.5), 2.4, fill);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _SpiderLogoPainter oldDelegate) => false;
}

class VpnServer {
  const VpnServer({required this.country, required this.flag, required this.city, required this.cityEn});
  final String country;
  final String flag;
  final String city;
  final String cityEn;
}

const _servers = [
  VpnServer(country: 'США', flag: '🇺🇸', city: 'Нью-Йорк', cityEn: 'New York'),
  VpnServer(country: 'Германия', flag: '🇩🇪', city: 'Берлин', cityEn: 'Berlin'),
  VpnServer(country: 'Нидерланды', flag: '🇳🇱', city: 'Амстердам', cityEn: 'Amsterdam'),
  VpnServer(country: 'Швеция', flag: '🇸🇪', city: 'Стокгольм', cityEn: 'Stockholm'),
  VpnServer(country: 'Япония', flag: '🇯🇵', city: 'Токио', cityEn: 'Tokyo'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.serverKey, required this.powerKey, required this.english});
  final GlobalKey serverKey;
  final GlobalKey powerKey;
  final bool english;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _weave;
  late final AnimationController _blink;
  late final Animation<Color?> _statusColor;
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
    _statusColor = TweenSequence<Color?>([
      TweenSequenceItem(tween: ColorTween(begin: _white, end: _green), weight: 10),
      TweenSequenceItem(tween: ColorTween(begin: _green, end: _white), weight: 10),
      TweenSequenceItem(tween: ColorTween(begin: _white, end: _green), weight: 10),
      TweenSequenceItem(tween: ColorTween(begin: _green, end: _white), weight: 10),
      TweenSequenceItem(tween: ColorTween(begin: _white, end: _green), weight: 10),
      TweenSequenceItem(tween: ColorTween(begin: _green, end: _white), weight: 10),
      TweenSequenceItem(tween: ConstantTween<Color?>(_white), weight: 40),
    ]).animate(CurvedAnimation(parent: _blink, curve: Curves.linear));
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .62,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 38, height: 4, decoration: BoxDecoration(color: _muted, borderRadius: BorderRadius.circular(4))),
              Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 14), child: Text(_tr(widget.english, 'Выберите страну', 'Choose a country'), style: const TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w600))),
              Expanded(
                child: ListView.separated(
                  itemCount: _servers.length,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final server = _servers[index];
                    final selected = server.country == _server.country;
                    return Material(
                      color: selected ? _pink.withOpacity(.18) : const Color(0xFF21131B),
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: selected ? _pink : const Color(0xFF4A2035))),
                        leading: Text(server.flag, style: const TextStyle(fontSize: 28)),
                        title: Text(widget.english ? _countryEn(server.country) : server.country, style: const TextStyle(color: _white, fontWeight: FontWeight.w600)),
                        subtitle: Text(widget.english ? server.cityEn : server.city, style: const TextStyle(color: _muted)),
                        trailing: selected ? const Icon(Icons.check_circle_rounded, color: _rose) : const Icon(Icons.chevron_right_rounded, color: _muted),
                        onTap: () => Navigator.pop(context, server),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    _timer?.cancel();
    _blink.reset();
    setState(() { _server = selected; _uptime = Duration.zero; _connected = false; _connecting = true; _unstable = false; });
    _weave.forward(from: 0);
  }

  String _countryEn(String country) => switch (country) {
        'США' => 'United States',
        'Германия' => 'Germany',
        'Нидерланды' => 'Netherlands',
        'Швеция' => 'Sweden',
        'Япония' => 'Japan',
        _ => country,
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
    return Column(
      children: [
        const SizedBox(height: 26),
        _ServerCard(server: _server, connected: _connected, connecting: _connecting, unstable: _unstable, english: widget.english, onTap: _chooseServer),
        const Spacer(flex: 2),
        SizedBox(
          width: 320,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: AnimatedBuilder(animation: _weave, builder: (context, _) => CustomPaint(painter: WeavingSpiderPainter(progress: _connected ? 1 : _weave.value, showSpider: _connecting)))),
              _PowerButton(key: widget.powerKey, connecting: _connecting, connected: _connected, unstable: _unstable, onTap: _toggleVpn),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: AnimatedBuilder(
            key: ValueKey('$_connecting-$_connected-$_unstable'),
            animation: _blink,
            builder: (context, _) => Text(status, textAlign: TextAlign.center, style: TextStyle(color: _unstable ? _red : (_connected ? (_statusColor.value ?? _white) : _white), fontSize: 21, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 9),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: _connected
              ? Text(_time, style: const TextStyle(color: _rose, fontSize: 29, letterSpacing: 4, fontWeight: FontWeight.w700))
              : Text(_connecting ? _tr(widget.english, 'Паучок плетёт защищённый маршрут', 'Weaving a secure route') : _unstable ? _tr(widget.english, 'Нажмите кнопку, чтобы повторить', 'Tap to retry') : _tr(widget.english, 'Нажмите кнопку для подключения', 'Tap to connect'), textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13)),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.server, required this.connected, required this.connecting, required this.unstable, required this.english, required this.onTap});
  final VpnServer server;
  final bool connected;
  final bool connecting;
  final bool unstable;
  final bool english;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF151019),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: _pink.withOpacity(.8))),
            child: Row(
              children: [
                Icon(unstable ? Icons.warning_amber_rounded : Icons.bolt_rounded, color: unstable ? _red : _rose, size: 24),
                const SizedBox(width: 12),
                Text(server.flag, style: const TextStyle(fontSize: 25)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${english ? (server.country == 'США' ? 'United States' : server.country) : server.country} · ${english ? server.cityEn : server.city}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(unstable ? _tr(english, 'Соединение нестабильно', 'Connection unstable') : connecting ? _tr(english, 'Подключение к серверу…', 'Connecting to server…') : connected ? _tr(english, 'Подключено', 'Connected') : _tr(english, 'Нажмите, чтобы выбрать сервер', 'Tap to choose a server'), style: TextStyle(color: unstable ? _red : _muted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _rose, size: 25),
              ],
            ),
          ),
        ),
      );
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({super.key, required this.connecting, required this.connected, required this.unstable, required this.onTap});
  final bool connecting;
  final bool connected;
  final bool unstable;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: connected || connecting ? const [Color(0xFF4A1730), Color(0xFF0D0910)] : const [Color(0xFF28121E), Color(0xFF0D0910)]),
          border: Border.all(color: unstable ? _red : (connected || connecting ? _rose : _pink), width: connected || connecting || unstable ? 3.5 : 2.5),
          boxShadow: [BoxShadow(color: (unstable ? _red : _pink).withOpacity(connected ? .72 : (connecting ? .55 : .22)), blurRadius: connected ? 42 : (connecting ? 34 : 20), spreadRadius: connected ? 8 : (connecting ? 5 : 1))],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: connecting
                    ? const SizedBox(key: ValueKey('loading'), width: 38, height: 38, child: CircularProgressIndicator(strokeWidth: 2, color: _rose))
                    : Icon(unstable ? Icons.close_rounded : Icons.power_settings_new_rounded, key: ValueKey('$connected-$unstable'), size: 38, color: unstable ? _red : (connected ? Colors.white : _white)),
              ),
            ),
          ),
        ),
      );
}

class WeavingSpiderPainter extends CustomPainter {
  const WeavingSpiderPainter({required this.progress, required this.showSpider});
  final double progress;
  final bool showSpider;
  static const int _spokes = 12;
  static const int _rings = 7;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .46;
    final p = progress.clamp(0.0, 1.0).toDouble();
    final thread = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.05..strokeCap = StrokeCap.round..color = _rose.withOpacity(.65);
    final glow = Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..color = _pink.withOpacity(.14)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final spokeProgress = (p / .52).clamp(0.0, 1.0).toDouble();
    for (var i = 0; i < _spokes; i++) {
      final angle = -math.pi / 2 + math.pi * 2 * i / _spokes;
      final end = Offset(center.dx + math.cos(angle) * radius * spokeProgress, center.dy + math.sin(angle) * radius * spokeProgress);
      final path = Path()..moveTo(center.dx, center.dy)..lineTo(end.dx, end.dy);
      canvas.drawPath(path, glow);
      canvas.drawPath(path, thread);
    }
    final ringProgress = ((p - .34) / .66).clamp(0.0, 1.0).toDouble();
    for (var ring = 1; ring <= _rings; ring++) {
      final reveal = (ringProgress * _rings - (ring - 1)).clamp(0.0, 1.0).toDouble();
      if (reveal <= 0) continue;
      final ringRadius = radius * ring / _rings;
      final path = Path();
      for (var i = 0; i <= _spokes; i++) {
        final angle = -math.pi / 2 + math.pi * 2 * i / _spokes;
        final point = Offset(center.dx + math.cos(angle) * ringRadius, center.dy + math.sin(angle) * ringRadius);
        if (i == 0) { path.moveTo(point.dx, point.dy); continue; }
        final prevAngle = -math.pi / 2 + math.pi * 2 * (i - 1) / _spokes;
        final middle = (prevAngle + angle) / 2;
        final control = Offset(center.dx + math.cos(middle) * ringRadius * .91, center.dy + math.sin(middle) * ringRadius * .91);
        path.quadraticBezierTo(control.dx, control.dy, point.dx, point.dy);
      }
      final metrics = path.computeMetrics().toList();
      if (metrics.isEmpty) continue;
      final partial = metrics.first.extractPath(0, metrics.first.length * reveal);
      canvas.drawPath(partial, glow);
      canvas.drawPath(partial, thread);
    }
    if (showSpider && p < 1) {
      final angle = -math.pi / 2 + math.pi * 2 * p;
      _drawSpider(canvas, Offset(center.dx + math.cos(angle) * radius * .84, center.dy + math.sin(angle) * radius * .84), angle + math.pi / 2);
    }
  }
  void _drawSpider(Canvas canvas, Offset center, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final legs = Paint()..color = _rose..style = PaintingStyle.stroke..strokeWidth = 1.7..strokeCap = StrokeCap.round;
    final body = Paint()..color = _pink;
    for (var i = 0; i < 4; i++) {
      final y = (i - 1.5) * 3.2;
      final reach = 10.0 + (i.isOdd ? 2 : 0);
      for (final side in [-1.0, 1.0]) {
        final leg = Path()..moveTo(side * 2.2, y)..quadraticBezierTo(side * 6, y - 1, side * 8, y - 4)..quadraticBezierTo(side * 10, y - 6, side * reach, y - 7)..moveTo(side * 2.2, y)..quadraticBezierTo(side * 6, y + 1, side * 8, y + 4)..quadraticBezierTo(side * 10, y + 6, side * reach, y + 7);
        canvas.drawPath(leg, legs);
      }
    }
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 7, height: 11), body);
    canvas.drawCircle(const Offset(0, -7), 3.2, Paint()..color = _rose);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant WeavingSpiderPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.showSpider != showSpider;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.english});
  final bool english;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _login = 'spider_user';
  String? _gmail;
  String? _phone;
  String _dns = 'Cloudflare (1.1.1.1)';
  String _mode = 'Туннель';

  String t(String ru, String en) => _tr(widget.english, ru, en);
  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _editText({required String title, required String label, required String initial, required String? Function(String) validate, required ValueChanged<String> save, TextInputType keyboard = TextInputType.text}) async {
    final controller = TextEditingController(text: initial);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: Text(title, style: const TextStyle(color: _white)),
        content: Form(key: formKey, child: TextFormField(controller: controller, keyboardType: keyboard, style: const TextStyle(color: _white), decoration: InputDecoration(labelText: label), validator: (value) => validate((value ?? '').trim()))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('Отмена', 'Cancel'))),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: _pink), onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(context, controller.text.trim()); }, child: Text(t('Сохранить', 'Save'))),
        ],
      ),
    );
    controller.dispose();
    if (result != null && mounted) save(result);
  }

  Future<void> _changeLogin() => _editText(
        title: t('Изменить логин', 'Change username'),
        label: t('Новый логин', 'New username'),
        initial: _login,
        validate: (value) => value.length >= 3 ? null : t('Минимум 3 символа', 'At least 3 characters'),
        save: (value) { setState(() => _login = value); _toast(t('Логин обновлён в демо-профиле.', 'Username updated in demo profile.')); },
      );

  Future<void> _changePassword() async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    final key = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: Text(t('Изменить пароль', 'Change password'), style: const TextStyle(color: _white)),
        content: Form(
          key: key,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: password, obscureText: true, decoration: InputDecoration(labelText: t('Новый пароль', 'New password')), validator: (value) => (value ?? '').length >= 6 ? null : t('Минимум 6 символов', 'At least 6 characters')),
            TextFormField(controller: confirm, obscureText: true, decoration: InputDecoration(labelText: t('Повторите пароль', 'Repeat password')), validator: (value) => value == password.text ? null : t('Пароли не совпадают', 'Passwords do not match')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('Отмена', 'Cancel'))),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: _pink), onPressed: () { if (key.currentState!.validate()) Navigator.pop(context, password.text); }, child: Text(t('Сохранить', 'Save'))),
        ],
      ),
    );
    password.dispose();
    confirm.dispose();
    if (result != null && mounted) _toast(t('Пароль обновлён в демо-профиле.', 'Password updated in demo profile.'));
  }

  Future<void> _bindGmail() => _editText(
        title: t('Привязать Gmail', 'Link Gmail'),
        label: t('Адрес @gmail.com', 'Gmail address'),
        initial: _gmail ?? '',
        keyboard: TextInputType.emailAddress,
        validate: (value) => RegExp(r'^[A-Z0-9._%+-]+@gmail\.com$', caseSensitive: false).hasMatch(value) ? null : t('Разрешён только адрес @gmail.com', 'Only @gmail.com addresses are allowed'),
        save: (value) { setState(() => _gmail = value); _toast(t('Gmail сохранён в демо-профиле.', 'Gmail saved in demo profile.')); },
      );

  Future<void> _bindPhone() => _editText(
        title: t('Привязать номер телефона', 'Link phone number'),
        label: t('Номер телефона', 'Phone number'),
        initial: _phone ?? '',
        keyboard: TextInputType.phone,
        validate: (value) => RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(value) ? null : t('Введите корректный номер', 'Enter a valid phone number'),
        save: (value) { setState(() => _phone = value); _toast(t('Номер сохранён в демо-профиле.', 'Number saved in demo profile.')); },
      );

  Future<void> _selectValue({required String title, required List<String> options, required ValueChanged<String> onSelect}) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _panel,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(18), child: Text(title, style: const TextStyle(color: _white, fontSize: 18, fontWeight: FontWeight.w600))),
          for (final option in options) ListTile(title: Text(option, style: const TextStyle(color: _white)), trailing: const Icon(Icons.chevron_right, color: _rose), onTap: () => Navigator.pop(context, option)),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (result != null) onSelect(result);
  }

  @override
  Widget build(BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
        children: [
          Text(t('Профиль', 'Profile'), style: const TextStyle(color: _white, fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _SectionTitle(t('Управление аккаунтом', 'Account management')),
          const SizedBox(height: 8),
          _ProfileAction(icon: Icons.key_rounded, title: t('ID аккаунта', 'Account ID'), subtitle: 'a0926bbc-d784-444b-9cdd-5dcf13…', onTap: () => _toast(t('ID демо-аккаунта', 'Demo account ID'))),
          const SizedBox(height: 18),
          _SectionTitle(t('Подписка', 'Subscription')),
          const SizedBox(height: 8),
          _ProfileAction(icon: Icons.workspace_premium_rounded, title: t('Управление подпиской', 'Manage subscription'), subtitle: t('Осталось 11 дней 9 часов', '11 days 9 hours remaining')),
          const SizedBox(height: 12),
          _ProfileAction(icon: Icons.privacy_tip_outlined, title: t('Конфиденциальность', 'Privacy'), subtitle: t('Логин, пароль, Gmail и номер телефона', 'Username, password, Gmail and phone'), onTap: _openPrivacy),
          const SizedBox(height: 18),
          _SectionTitle(t('Настройки подключения', 'Connection settings')),
          const SizedBox(height: 8),
          _SettingPicker(label: t('Режим подключения', 'Connection mode'), value: widget.english ? 'Tunnel' : _mode, onTap: () => _selectValue(title: t('Режим подключения', 'Connection mode'), options: widget.english ? const ['Tunnel', 'Automatic'] : const ['Туннель', 'Автоматический'], onSelect: (value) => setState(() => _mode = value))),
          const SizedBox(height: 8),
          _SettingPicker(label: 'DNS', value: _dns, onTap: () => _selectValue(title: 'DNS', options: const ['Cloudflare (1.1.1.1)', 'Google (8.8.8.8)', 'Automatic'], onSelect: (value) => setState(() => _dns = value))),
          const SizedBox(height: 18),
          _SectionTitle(t('Маршрутизация', 'Routing')),
          const SizedBox(height: 8),
          _ProfileAction(icon: Icons.alt_route_rounded, title: t('Настройки сплит-туннелирования', 'Split tunneling settings'), onTap: () => _toast(t('Настройка доступна в демо-режиме', 'Setting is a demo only'))),
          const SizedBox(height: 18),
          _SectionTitle(t('Система', 'System')),
          const SizedBox(height: 8),
          _ProfileAction(icon: Icons.tune_rounded, title: t('Расширенные настройки', 'Advanced settings'), onTap: () => _toast(t('Расширенные настройки', 'Advanced settings'))),
          const SizedBox(height: 18),
          _SectionTitle(t('Управление', 'Management')),
          const SizedBox(height: 8),
          _ProfileAction(icon: Icons.add_to_home_screen_rounded, title: t('Добавить устройство', 'Add device'), subtitle: t('До 10 устройств', 'Up to 10 devices')),
          const SizedBox(height: 8),
          _ProfileAction(icon: Icons.headset_mic_rounded, title: t('Обратиться в поддержку', 'Contact support')),
          const SizedBox(height: 18),
          _SectionTitle(t('Полезные ссылки', 'Useful links')),
          const SizedBox(height: 8),
          _ProfileAction(icon: Icons.language_rounded, title: t('Официальный сайт', 'Official website'), subtitle: 'spidervpn.com'),
          const SizedBox(height: 8),
          _ProfileAction(icon: Icons.send_rounded, title: 'Telegram', subtitle: 't.me/spidervpn'),
          const SizedBox(height: 8),
          _ProfileAction(icon: Icons.logout_rounded, title: t('Выйти из аккаунта', 'Log out')),
        ],
      );

  Future<void> _openPrivacy() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(t('Конфиденциальность', 'Privacy'), style: const TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(t('Изменение данных в локальном демо-профиле.', 'Changes are stored only in this local demo.'), style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 14),
              _ProfileAction(icon: Icons.person_outline, title: t('Изменить логин', 'Change username'), subtitle: _login, onTap: () async { await _changeLogin(); setSheetState(() {}); }),
              const SizedBox(height: 8),
              _ProfileAction(icon: Icons.lock_outline, title: t('Изменить пароль', 'Change password'), subtitle: '••••••••', onTap: _changePassword),
              const SizedBox(height: 8),
              _ProfileAction(icon: Icons.mail_outline, title: _gmail == null ? t('Привязать Gmail', 'Link Gmail') : 'Gmail', subtitle: _gmail ?? t('Только адрес @gmail.com', 'Only @gmail.com'), onTap: () async { await _bindGmail(); setSheetState(() {}); }),
              const SizedBox(height: 8),
              _ProfileAction(icon: Icons.phone_outlined, title: _phone == null ? t('Привязать номер телефона', 'Link phone number') : t('Номер телефона', 'Phone number'), subtitle: _phone ?? t('Не привязан', 'Not linked'), onTap: () async { await _bindPhone(); setSheetState(() {}); }),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(color: _white, fontSize: 17, fontWeight: FontWeight.w700));
}

class _SettingPicker extends StatelessWidget {
  const _SettingPicker({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF211A20),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 11, 12, 10),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: _muted, fontSize: 13)), const SizedBox(height: 3), Text(value, style: const TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w600))])),
              const Icon(Icons.keyboard_arrow_down_rounded, color: _white),
            ]),
          ),
        ),
      );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({required this.icon, required this.title, this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF211A20),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(children: [
              Icon(icon, color: _rose, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w600)), if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12))]])),
              const Icon(Icons.chevron_right_rounded, color: _muted, size: 22),
            ]),
          ),
        ),
      );
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.navKey, required this.selected, required this.english, required this.onSelect});
  final GlobalKey navKey;
  final int selected;
  final bool english;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Container(
        key: navKey,
        padding: const EdgeInsets.only(top: 7, bottom: 3),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF35202B)))),
        child: Row(children: [
          Expanded(child: _NavItem(icon: Icons.home_rounded, label: _tr(english, 'Главная', 'Home'), active: selected == 0, onTap: () => onSelect(0))),
          Expanded(child: _NavItem(icon: Icons.person_rounded, label: _tr(english, 'Профиль', 'Profile'), active: selected == 1, onTap: () => onSelect(1))),
        ]),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = active ? _rose : _muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedScale(scale: active ? 1.06 : 1, duration: const Duration(milliseconds: 240), child: Icon(icon, color: color, size: 25)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          const SizedBox(height: 4),
          AnimatedContainer(duration: const Duration(milliseconds: 240), width: active ? 42 : 0, height: 2, decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(2))),
        ]),
      ),
    );
  }
}
