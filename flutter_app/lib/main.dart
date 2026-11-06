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
                        _AppHeader(closeKey: _closeKey, onClose: _closeApp),
                        Expanded(
                          child: IndexedStack(
                            index: _tab,
                            children: [
                              HomeScreen(
                                serverKey: _serverKey,
                                powerKey: _powerKey,
                              ),
                              const ProfileScreen(),
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
  const VpnServer({required this.country, required this.flag, required this.city});
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
  const HomeScreen({super.key, required this.serverKey, required this.powerKey});
  final GlobalKey serverKey;
  final GlobalKey powerKey;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _weave;
  late final AnimationController _blink;
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
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  void _onWeaveStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted || !_connecting) return;
    setState(() { _connecting = false; _connected = true; });
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
                    final selectedServer = server.country == _server.country;
                    return Material(
                      color: selectedServer ? _purple.withOpacity(.18) : const Color(0xFF1D1624),
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: selectedServer ? _purple : const Color(0xFF47344D),
                          ),
                        ),
                        leading: Text(server.flag, style: const TextStyle(fontSize: 28)),
                        title: Text(
                          server.country,
                          style: const TextStyle(
                            color: _white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(server.city, style: const TextStyle(color: _muted)),
                        trailing: selectedServer
                            ? const Icon(Icons.check_circle_rounded, color: _lilac)
                            : const Icon(Icons.chevron_right_rounded, color: _muted),
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
      _blink.reset();
      setState(() { _connected = false; _uptime = Duration.zero; });
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
    _blink.dispose();
    super.dispose();
  }

  String get _time {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(_uptime.inHours)}:${two(_uptime.inMinutes.remainder(60))}:${two(_uptime.inSeconds.remainder(60))}';
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
                        showSpider: !_connected,
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
              animation: _blink,
              builder: (context, _) => Text(
                _connecting ? 'Подключение…' : (_connected ? 'Подключено' : 'Не подключено'),
                style: TextStyle(
                  color: _connected && _blink.value < .8 ? _lilac : _white,
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
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
                      fontSize: 21,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Text(
                    _connecting ? 'Паучок плетёт защищённый маршрут' : 'Нажмите кнопку для подключения',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted, fontSize: 15),
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
        color: const Color(0xFF120F1A),
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
                        connecting ? 'Подключение к серверу…' : connected ? 'Подключено' : 'Нажмите, чтобы выбрать сервер',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _lilac, size: 25),
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
                ? const [Color(0xFF381E46), Color(0xFF0E0B12)]
                : const [Color(0xFF1D1622), Color(0xFF0E0B12)],
          ),
          border: Border.all(
            color: connected || connecting ? _lilac : _purple,
            width: connected || connecting ? 3.5 : 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(connected ? .72 : (connecting ? .55 : .22)),
              blurRadius: connected ? 42 : (connecting ? 34 : 20),
              spreadRadius: connected ? 8 : (connecting ? 6 : 3),
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: _lilac),
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
    final thread = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round
      ..color = _lilac.withOpacity(.65);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = _purple.withOpacity(.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final spokeProgress = (p / .52).clamp(0.0, 1.0).toDouble();
    for (var i = 0; i < _spokes; i++) {
      final angle = -math.pi / 2 + math.pi * 2 * i / _spokes;
      final end = Offset(
        center.dx + math.cos(angle) * radius * spokeProgress,
        center.dy + math.sin(angle) * radius * spokeProgress,
      );
      final path = Path()..moveTo(center.dx, center.dy)..lineTo(end.dx, end.dy);
      canvas.drawPath(path, glow);
      canvas.drawPath(path, thread);
    }
    final ringProgress = ((p - .34) / .66).clamp(0.0, 1.0).toDouble();
    for (var ring = 1; ring <= _rings; ring++) {
      final reveal = (ringProgress * _rings - (ring - 1)).clamp(0.0, 1.0).toDouble();
      if (reveal <= 0) continue;
      final radiusForRing = radius * ring / _rings;
      final path = Path();
      for (var i = 0; i <= _spokes; i++) {
        final angle = -math.pi / 2 + math.pi * 2 * i / _spokes;
        final point = Offset(
          center.dx + math.cos(angle) * radiusForRing,
          center.dy + math.sin(angle) * radiusForRing,
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
          continue;
        }
        final prevAngle = -math.pi / 2 + math.pi * 2 * (i - 1) / _spokes;
        final middle = (prevAngle + angle) / 2;
        final control = Offset(
          center.dx + math.cos(middle) * radiusForRing * .91,
          center.dy + math.sin(middle) * radiusForRing * .91,
        );
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
      _drawSpider(
        canvas,
        Offset(
          center.dx + math.cos(angle) * radius * .84,
          center.dy + math.sin(angle) * radius * .84,
        ),
        angle + math.pi / 2,
      );
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
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 7, height: 11), body);
    canvas.drawCircle(const Offset(0, -7), 3.2, Paint()..color = _lilac);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WeavingSpiderPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.showSpider != showSpider;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
  int _selectedPalette = 0;

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)),
      );

  Future<void> _editText({
    required String title,
    required String label,
    required String initial,
    required String? Function(String) validate,
    required ValueChanged<String> save,
    TextInputType keyboard = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initial);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: Text(title, style: const TextStyle(color: _white)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboard,
            style: const TextStyle(color: _white),
            decoration: InputDecoration(labelText: label),
            validator: (value) => validate((value ?? '').trim()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _purple),
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && mounted) save(result);
  }

  Future<void> _changeLogin() => _editText(
        title: 'Изменить логин',
        label: 'Новый логин',
        initial: _login,
        validate: (value) => value.length >= 3 ? null : 'Минимум 3 символа',
        save: (value) {
          setState(() => _login = value);
          _toast('Логин обновлён в демо-профиле.');
        },
      );

  Future<void> _changePassword() async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    final key = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('Изменить пароль', style: TextStyle(color: _white)),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Новый пароль'),
                validator: (value) => (value ?? '').length >= 6 ? null : 'Минимум 6 символов',
              ),
              TextFormField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Повторите пароль'),
                validator: (value) => value == password.text ? null : 'Пароли не совпадают',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _purple),
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(context, password.text);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    password.dispose();
    confirm.dispose();
    if (result != null && mounted) _toast('Пароль обновлён в демо-профиле.');
  }

  Future<void> _bindGmail() => _editText(
        title: 'Привязать Gmail',
        label: 'Адрес @gmail.com',
        initial: _gmail ?? '',
        keyboard: TextInputType.emailAddress,
        validate: (value) =>
            RegExp(r'^[A-Z0-9._%+-]+@gmail\.com$', caseSensitive: false).hasMatch(value)
                ? null
                : 'Разрешён только адрес @gmail.com',
        save: (value) {
          setState(() => _gmail = value);
          _toast('Gmail сохранён в демо-профиле.');
        },
      );

  Future<void> _bindPhone() => _editText(
        title: 'Привязать номер телефона',
        label: 'Номер телефона',
        initial: _phone ?? '',
        keyboard: TextInputType.phone,
        validate: (value) => RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(value)
            ? null
            : 'Введите корректный номер',
        save: (value) {
          setState(() => _phone = value);
          _toast('Номер сохранён в демо-профиле.');
        },
      );

  Future<void> _selectValue({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelect,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _panel,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                title,
                style: const TextStyle(
                  color: _white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(option, style: const TextStyle(color: _white)),
                trailing: const Icon(Icons.chevron_right, color: _lilac),
                onTap: () => Navigator.pop(context, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) onSelect(result);
  }

  Future<void> _openSubscription() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Управление подпиской',
                style: TextStyle(
                  color: _white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Осталось 11 дней 9 часов',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _purple),
                onPressed: () => Navigator.pop(context),
                child: const Text('Продлить подписку'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _white,
                  side: const BorderSide(color: _purple),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Приобрести подписку'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
        children: [
          const Text(
            'Профиль',
            style: TextStyle(
              color: _white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Управление аккаунтом'),
          const SizedBox(height: 8),
          _ProfileAction(
            icon: Icons.workspace_premium_rounded,
            title: 'Управление подпиской',
            subtitle: 'Осталось 11 дней 9 часов',
            onTap: _openSubscription,
          ),
          const SizedBox(height: 8),
          _ProfileAction(
            icon: Icons.privacy_tip_outlined,
            title: 'Конфиденциальность',
            subtitle: 'Логин, пароль, Gmail и номер телефона',
            onTap: _openPrivacy,
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Подписка'),
          const SizedBox(height: 8),
          _ProfileAction(
            icon: Icons.credit_card_rounded,
            title: 'Управление подпиской',
            subtitle: 'Осталось 11 дней 9 часов',
            onTap: _openSubscription,
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Настройки подключения'),
          const SizedBox(height: 8),
          _SettingPicker(
            label: 'Режим подключения',
            value: _mode,
            onTap: () => _selectValue(
              title: 'Режим подключения',
              options: const ['Туннель', 'Автоматический', 'Сплит-туннель'],
              onSelect: (v) => setState(() => _mode = v),
            ),
          ),
          const SizedBox(height: 8),
          _SettingPicker(
            label: 'DNS-сервер',
            value: _dns,
            onTap: () => _selectValue(
              title: 'DNS-сервер',
              options: const ['Cloudflare (1.1.1.1)', 'Google (8.8.8.8)', 'Автоматически'],
              onSelect: (v) => setState(() => _dns = v),
            ),
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Маршрутизация'),
          const SizedBox(height: 8),
          _ProfileAction(
            icon: Icons.alt_route_rounded,
            title: 'Настройки сплит-туннелирования',
            onTap: () => _toast('Настройка доступна в демо-режиме.'),
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Система'),
          const SizedBox(height: 8),
          _SettingPicker(
            label: 'Язык',
            value: _language,
            onTap: () => _selectValue(
              title: 'Язык',
              options: const ['Русский', 'English'],
              onSelect: (v) => setState(() => _language = v),
            ),
          ),
          const SizedBox(height: 8),
          _ProfileAction(
            icon: Icons.tune_rounded,
            title: 'Расширенные настройки',
            onTap: () => _toast('Расширенные настройки'),
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Custom color'),
          const SizedBox(height: 8),
          const _CustomColorPicker(),
          const SizedBox(height: 18),
          const _SectionTitle('Управление'),
          const SizedBox(height: 8),
          const _ProfileAction(
            icon: Icons.add_to_home_screen_rounded,
            title: 'Добавить устройство',
            subtitle: 'До 10 устройств',
          ),
          const SizedBox(height: 8),
          const _ProfileAction(
            icon: Icons.headset_mic_rounded,
            title: 'Обратиться в поддержку',
          ),
          const SizedBox(height: 18),
          const _SectionTitle('Полезные ссылки'),
          const SizedBox(height: 8),
          const _ProfileAction(
            icon: Icons.language_rounded,
            title: 'Официальный сайт',
            subtitle: 'spidervpn.com',
          ),
          const SizedBox(height: 8),
          const _ProfileAction(
            icon: Icons.send_rounded,
            title: 'Telegram канал',
            subtitle: 't.me/spidervpn',
          ),
          const SizedBox(height: 8),
          const _ProfileAction(
            icon: Icons.logout_rounded,
            title: 'Выйти из аккаунта',
          ),
        ],
      );

  Future<void> _openPrivacy() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Конфиденциальность',
                  style: TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Изменение данных в локальном демо-профиле.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                _ProfileAction(
                  icon: Icons.person_outline,
                  title: 'Изменить логин',
                  subtitle: _login,
                  onTap: () async {
                    await _changeLogin();
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 8),
                _ProfileAction(
                  icon: Icons.lock_outline,
                  title: 'Изменить пароль',
                  subtitle: '••••••••',
                  onTap: _changePassword,
                ),
                const SizedBox(height: 8),
                _ProfileAction(
                  icon: Icons.mail_outline,
                  title: _gmail == null ? 'Привязать Gmail' : 'Gmail',
                  subtitle: _gmail ?? 'Только адрес @gmail.com',
                  onTap: () async {
                    await _bindGmail();
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 8),
                _ProfileAction(
                  icon: Icons.phone_outlined,
                  title: _phone == null ? 'Привязать номер телефона' : 'Номер телефона',
                  subtitle: _phone ?? 'Не привязан',
                  onTap: () async {
                    await _bindPhone();
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomColorPicker extends StatefulWidget {
  const _CustomColorPicker();

  @override
  State<_CustomColorPicker> createState() => _CustomColorPickerState();
}

class _CustomColorPickerState extends State<_CustomColorPicker> {
  int _selected = 0;

  static const List<LinearGradient> _gradients = [
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE8E7EE), Color(0xFF2D2D33), Color(0xFFE8E7EE)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7FB3FF), Color(0xFFD9A0FF), Color(0xFF4E96FF)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7DD3FC), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    ),
  ];

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_gradients.length, (index) {
          final selected = index == _selected;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selected = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _gradients[index],
                  border: Border.all(
                    color: selected ? _white : Colors.transparent,
                    width: selected ? 2.5 : 0,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: _white.withOpacity(.22), blurRadius: 12)]
                      : null,
                ),
              ),
            ),
          );
        }),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          color: _white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _SettingPicker extends StatelessWidget {
  const _SettingPicker({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF1C141E),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 11, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: const TextStyle(
                          color: _white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: _white),
              ],
            ),
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
        color: const Color(0xFF1C141E),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: _lilac, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _muted, size: 22),
              ],
            ),
          ),
        ),
      );
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.navKey, required this.selected, required this.onSelect});
  final GlobalKey navKey;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        key: navKey,
        padding: const EdgeInsets.only(top: 7, bottom: 3),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF31212F))),
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
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
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
