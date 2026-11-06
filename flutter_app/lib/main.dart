import 'dart:async';
import 'dart:io' show Platform, exit;
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'demo_auth_gate.dart';

const _bg = Color(0xFF05050A);
const _panel = Color(0xFF100D18);
const _purple = Color(0xFF9B35FF);
const _lilac = Color(0xFFC28AFF);
const _white = Color(0xFFF2ECFA);
const _muted = Color(0xFF9A8EAD);
const _successGreen = Color(0xFF4CAF50);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await windowManager.setBackgroundColor(_bg);
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
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
          colorScheme: ColorScheme.fromSeed(
            seedColor: _purple,
            brightness: Brightness.dark,
          ),
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

  bool _isFunctionalArea(Offset point) =>
      _containsPoint(_closeKey, point) ||
      _containsPoint(_serverKey, point) ||
      _containsPoint(_powerKey, point) ||
      _containsPoint(_navKey, point);

  void _onPointerDown(PointerDownEvent event) {
    if (!Platform.isWindows || event.kind != PointerDeviceKind.mouse) return;
    if ((event.buttons & kPrimaryMouseButton) == 0) return;
    _pointerStartPositions[event.pointer] = event.position;
    if (!_isFunctionalArea(event.position)) {
      _draggablePointers.add(event.pointer);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_draggablePointers.contains(event.pointer) ||
        (event.buttons & kPrimaryMouseButton) == 0) {
      return;
    }
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
    }
    SystemNavigator.pop();
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
    );
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
              decoration: BoxDecoration(
                color: _bg,
                border: Border.all(color: _purple, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                    child: Column(
                      children: [
                        _AppHeader(
                          closeKey: _closeKey,
                          onClose: _closeApp,
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: _tab,
                            children: [
                              HomeScreen(
                                serverKey: _serverKey,
                                powerKey: _powerKey,
                              ),
                              ProfileScreen(onLogin: _openLogin),
                            ],
                          ),
                        ),
                        _BottomNav(
                          navKey: _navKey,
                          selected: _tab,
                          onSelect: (value) => setState(() => _tab = value),
                        ),
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
  const _AppHeader({required this.closeKey, required this.onClose});

  final GlobalKey closeKey;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Row(
          children: [
            IconButton(
              key: closeKey,
              tooltip: 'Закрыть приложение',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: _lilac, size: 25),
            ),
            const Spacer(),
            const _SpiderLogo(size: 23),
            const SizedBox(width: 8),
            const Text(
              'Spider VPN',
              style: TextStyle(
                color: _white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
      );
}

class _SpiderLogo extends StatelessWidget {
  const _SpiderLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _SpiderLogoPainter()),
      );
}

class _SpiderLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);

    final stroke = Paint()
      ..color = _purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = _purple;

    for (var i = 0; i < 4; i++) {
      final y = 7.0 + i * 3.2;
      final spread = 5.0 + (i.isOdd ? 1.0 : 0.0);
      for (final side in [-1.0, 1.0]) {
        final leg = Path()
          ..moveTo(12 + side * 2, y)
          ..quadraticBezierTo(12 + side * 6, y - 1, 12 + side * spread, y - 3)
          ..moveTo(12 + side * 2, y)
          ..quadraticBezierTo(12 + side * 6, y + 1, 12 + side * spread, y + 3);
        canvas.drawPath(leg, stroke);
      }
    }

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(12, 12), width: 5.5, height: 8),
      fill,
    );
    canvas.drawCircle(const Offset(12, 6.5), 2.4, fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpiderLogoPainter oldDelegate) => false;
}

class VpnServer {
  const VpnServer({
    required this.country,
    required this.flag,
    required this.city,
  });

  final String country;
  final String flag;
  final String city;
}

const _servers = [
  VpnServer(country: 'США', flag: '🇺🇸', city: 'Нью-Йорк'),
  VpnServer(country: 'Германия', flag: '🇩🇪', city: 'Берлин'),
  VpnServer(country: 'Нидерланды', flag: '🇳🇱', city: 'Амстердам'),
  VpnServer(country: 'Швеция', flag: '🇸🇪', city: 'Стокгольм'),
  VpnServer(country: 'Япония', flag: '🇯🇵', city: 'Токио'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.serverKey,
    required this.powerKey,
  });

  final GlobalKey serverKey;
  final GlobalKey powerKey;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _weave;
  late final AnimationController _statusBlink;
  late final Animation<Color?> _statusColor;

  VpnServer _server = _servers.first;
  bool _connecting = false;
  bool _connected = false;
  Duration _uptime = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _weave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..addStatusListener(_onWeaveStatus);

    _statusBlink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _statusColor = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: _white, end: _successGreen),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: _successGreen, end: _white),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: _white, end: _successGreen),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: _successGreen, end: _white),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Color?>(_white),
        weight: 20,
      ),
    ]).animate(_statusBlink);
  }

  void _onWeaveStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted || !_connecting) return;

    setState(() {
      _connecting = false;
      _connected = true;
    });

    _statusBlink.forward(from: 0);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _connected) {
        setState(() => _uptime += const Duration(seconds: 1));
      }
    });
  }

  Future<void> _chooseServer() async {
    final selected = await showModalBottomSheet<VpnServer>(
      context: context,
      backgroundColor: _panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .62,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: _muted,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Text(
                  'Выберите страну',
                  style: TextStyle(
                    color: _white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: _servers.length,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final server = _servers[index];
                    final isSelected = server.country == _server.country;

                    return Material(
                      color: isSelected
                          ? _purple.withOpacity(.18)
                          : const Color(0xFF1A1720),
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? _purple
                                : const Color(0xFF2A2532),
                          ),
                        ),
                        leading: Text(
                          server.flag,
                          style: const TextStyle(fontSize: 28),
                        ),
                        title: Text(
                          server.country,
                          style: const TextStyle(
                            color: _white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          server.city,
                          style: const TextStyle(color: _muted),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: _lilac,
                              )
                            : const Icon(
                                Icons.chevron_right_rounded,
                                color: _muted,
                              ),
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
    _statusBlink.reset();
    setState(() {
      _server = selected;
      _uptime = Duration.zero;
      _connected = false;
      _connecting = true;
    });

    _weave.forward(from: 0);
  }

  void _toggleVpn() {
    if (_connecting) return;

    if (_connected) {
      _timer?.cancel();
      _statusBlink.reset();
      setState(() {
        _connected = false;
        _uptime = Duration.zero;
      });
      _weave.reverse();
      return;
    }

    setState(() => _connecting = true);
    _weave.forward(from: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _weave.dispose();
    _statusBlink.dispose();
    super.dispose();
  }

  String get _time {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(_uptime.inHours)}:'
        '${two(_uptime.inMinutes.remainder(60))}:'
        '${two(_uptime.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(height: 26),
          _ServerCard(
            key: widget.serverKey,
            server: _server,
            connected: _connected,
            connecting: _connecting,
            onTap: _chooseServer,
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: 320,
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _weave,
                    builder: (context, _) => CustomPaint(
                      painter: WeavingSpiderPainter(
                        progress: _connected ? 1 : _weave.value,
                        showSpider: _connecting,
                      ),
                    ),
                  ),
                ),
                _PowerButton(
                  key: widget.powerKey,
                  connecting: _connecting,
                  connected: _connected,
                  onTap: _toggleVpn,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: AnimatedBuilder(
              key: ValueKey('$_connecting-$_connected'),
              animation: _statusBlink,
              builder: (context, _) => Text(
                _connecting
                    ? 'Подключение…'
                    : (_connected ? 'Подключено' : 'Не подключено'),
                style: TextStyle(
                  color: _connected ? (_statusColor.value ?? _white) : _white,
                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _connected
                ? Text(
                    _time,
                    style: const TextStyle(
                      color: _lilac,
                      fontSize: 19,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
                    _connecting
                        ? 'Паучок плетёт защищённый маршрут'
                        : 'Нажмите кнопку для подключения',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
          ),
          const Spacer(flex: 2),
        ],
      );
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    super.key,
    required this.server,
    required this.connected,
    required this.connecting,
    required this.onTap,
  });

  final VpnServer server;
  final bool connected;
  final bool connecting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF15121B),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _purple.withOpacity(.8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: _lilac, size: 24),
                const SizedBox(width: 12),
                Text(server.flag, style: const TextStyle(fontSize: 25)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${server.country} · ${server.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        connecting
                            ? 'Подключение к серверу…'
                            : connected
                                ? 'Подключено'
                                : 'Нажмите, чтобы выбрать сервер',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _lilac,
                  size: 25,
                ),
              ],
            ),
          ),
        ),
      );
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({
    super.key,
    required this.connecting,
    required this.connected,
    required this.onTap,
  });

  final bool connecting;
  final bool connected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: connected || connecting
                ? const [Color(0xFF32104D), Color(0xFF09070E)]
                : const [Color(0xFF1E1030), Color(0xFF09070E)],
          ),
          border: Border.all(
            color: connected || connecting ? _lilac : _purple,
            width: connected || connecting ? 3.5 : 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(
                connected ? .72 : (connecting ? .55 : .22),
              ),
              blurRadius: connected ? 42 : (connecting ? 34 : 20),
              spreadRadius: connected ? 8 : (connecting ? 5 : 1),
            ),
          ],
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
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 38,
                        height: 38,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _lilac,
                        ),
                      )
                    : Icon(
                        Icons.power_settings_new_rounded,
                        key: ValueKey(connected),
                        size: 38,
                        color: connected ? Colors.white : _white,
                      ),
              ),
            ),
          ),
        ),
      );
}

class WeavingSpiderPainter extends CustomPainter {
  const WeavingSpiderPainter({
    required this.progress,
    required this.showSpider,
  });

  final double progress;
  final bool showSpider;

  static const int _spokes = 12;
  static const int _rings = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .46;
    final p = progress.clamp(0.0, 1.0).toDouble();

    final thread = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round
      ..color = _lilac.withOpacity(.58);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = _purple.withOpacity(.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final spokeProgress = (p / .52).clamp(0.0, 1.0).toDouble();
    for (var i = 0; i < _spokes; i++) {
      final angle = -math.pi / 2 + math.pi * 2 * i / _spokes;
      final end = Offset(
        center.dx + math.cos(angle) * radius * spokeProgress,
        center.dy + math.sin(angle) * radius * spokeProgress,
      );
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(end.dx, end.dy);
      canvas.drawPath(path, glow);
      canvas.drawPath(path, thread);
    }

    final ringProgress = ((p - .34) / .66).clamp(0.0, 1.0).toDouble();
    for (var ring = 1; ring <= _rings; ring++) {
      final reveal =
          (ringProgress * _rings - (ring - 1)).clamp(0.0, 1.0).toDouble();
      if (reveal <= 0) continue;

      final r = radius * ring / _rings;
      final path = Path();

      for (var i = 0; i <= _spokes; i++) {
        final angle = -math.pi / 2 + math.pi * 2 * i / _spokes;
        final point = Offset(
          center.dx + math.cos(angle) * r,
          center.dy + math.sin(angle) * r,
        );

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
          continue;
        }

        final previousAngle = -math.pi / 2 + math.pi * 2 * (i - 1) / _spokes;
        final middleAngle = (previousAngle + angle) / 2;
        final control = Offset(
          center.dx + math.cos(middleAngle) * r * .91,
          center.dy + math.sin(middleAngle) * r * .91,
        );

        path.quadraticBezierTo(control.dx, control.dy, point.dx, point.dy);
      }

      final metrics = path.computeMetrics().toList();
      if (metrics.isEmpty) continue;

      final part = metrics.first.extractPath(
        0,
        metrics.first.length * reveal,
      );
      canvas.drawPath(part, glow);
      canvas.drawPath(part, thread);
    }

    if (p > .9) {
      final alpha = ((p - .9) / .1).clamp(0.0, 1.0).toDouble();
      final bead = Paint()..color = _lilac.withOpacity(.55 * alpha);

      for (var i = 0; i < _spokes; i++) {
        final angle = -math.pi / 2 + math.pi * 2 * i / _spokes;
        canvas.drawCircle(
          Offset(
            center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius,
          ),
          1.5,
          bead,
        );
      }
    }

    if (showSpider && p < 1) {
      final angle = -math.pi / 2 + math.pi * 2 * p;
      final spider = Offset(
        center.dx + math.cos(angle) * radius * .84,
        center.dy + math.sin(angle) * radius * .84,
      );
      _drawSpider(canvas, spider, angle + math.pi / 2);
    }
  }

  void _drawSpider(Canvas canvas, Offset center, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final legs = Paint()
      ..color = _lilac
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    final body = Paint()..color = _purple;

    for (var i = 0; i < 4; i++) {
      final y = (i - 1.5) * 3.2;
      final reach = 10.0 + (i.isOdd ? 2 : 0);

      for (final side in [-1.0, 1.0]) {
        final leg = Path()
          ..moveTo(side * 2.2, y)
          ..quadraticBezierTo(side * 6, y - 1, side * 8, y - 4)
          ..quadraticBezierTo(side * 10, y - 6, side * reach, y - 7)
          ..moveTo(side * 2.2, y)
          ..quadraticBezierTo(side * 6, y + 1, side * 8, y + 4)
          ..quadraticBezierTo(side * 10, y + 6, side * reach, y + 7);
        canvas.drawPath(leg, legs);
      }
    }

    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 7, height: 11),
      body,
    );
    canvas.drawCircle(
      const Offset(0, -7),
      3.2,
      Paint()..color = _lilac,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WeavingSpiderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.showSpider != showSpider;
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Профиль',
            style: TextStyle(
              color: _white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Войти в аккаунт'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: const [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: _panel,
                  child: _SpiderLogo(size: 52),
                ),
                SizedBox(height: 14),
                Center(
                  child: Text(
                    'Spider VPN',
                    style: TextStyle(
                      color: _white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Center(
                  child: Text(
                    'Твой безопасный интернет',
                    style: TextStyle(color: _muted, fontSize: 15),
                  ),
                ),
                SizedBox(height: 22),
                _InfoCard(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Подписка',
                  subtitle: 'Управление подпиской',
                  outlined: true,
                ),
                SizedBox(height: 22),
                Text(
                  'Полезные ссылки',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                _InfoCard(
                  icon: Icons.language_rounded,
                  title: 'Официальный сайт',
                  subtitle: 'spidervpn.com',
                ),
                SizedBox(height: 9),
                _InfoCard(
                  icon: Icons.send_rounded,
                  title: 'Telegram канал',
                  subtitle: 't.me/spidervpn',
                ),
                SizedBox(height: 20),
                Text(
                  'Управление',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                _InfoCard(
                  icon: Icons.add_to_home_screen_rounded,
                  title: 'Добавить устройство',
                  subtitle: 'До 10 устройств',
                ),
                SizedBox(height: 9),
                _InfoCard(
                  icon: Icons.headset_mic_rounded,
                  title: 'Обратиться в поддержку',
                ),
                SizedBox(height: 14),
                _InfoCard(
                  icon: Icons.logout_rounded,
                  title: 'Выйти из аккаунта',
                  outlined: true,
                ),
              ],
            ),
          ),
        ],
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Форма проверена. Сервер авторизации ещё не подключён.',
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, {Widget? suffixIcon}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted),
        filled: true,
        fillColor: _panel,
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF211A2D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _purple),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          foregroundColor: _white,
          title: const Text('Вход в аккаунт'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: _SpiderLogo(size: 56)),
                    const SizedBox(height: 16),
                    const Text(
                      'Spider VPN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Войдите, чтобы продолжить',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(color: _white),
                      decoration: _decoration('Электронная почта'),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) {
                          return 'Введите корректную электронную почту';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      autofillHints: const [AutofillHints.password],
                      style: const TextStyle(color: _white),
                      decoration: _decoration(
                        'Пароль',
                        suffixIcon: IconButton(
                          tooltip: _hidePassword
                              ? 'Показать пароль'
                              : 'Скрыть пароль',
                          onPressed: () {
                            setState(() => _hidePassword = !_hidePassword);
                          },
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: _muted,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return 'Пароль должен содержать не менее 6 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submit,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Войти'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Восстановление пароля пока не подключено.',
                            ),
                          ),
                        );
                      },
                      child: const Text('Забыли пароль?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.outlined = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : _panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: outlined ? _purple.withOpacity(.8) : const Color(0xFF211A2D),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: _lilac, size: 27),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _lilac,
              size: 25,
            ),
          ],
        ),
      );
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.navKey,
    required this.selected,
    required this.onSelect,
  });

  final GlobalKey navKey;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        key: navKey,
        padding: const EdgeInsets.only(top: 7, bottom: 3),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF21172E))),
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_rounded,
                label: 'Главная',
                active: selected == 0,
                onTap: () => onSelect(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.person_rounded,
                label: 'Профиль',
                active: selected == 1,
                onTap: () => onSelect(1),
              ),
            ),
          ],
        ),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? _lilac : _muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.06 : 1,
              duration: const Duration(milliseconds: 240),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: active ? 42 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: _purple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
