import 'dart:math' as math;

import 'package:flutter/material.dart';

const _bg = Color(0xFF08060B);
const _panel = Color(0xFF151019);
const _pink = Color(0xFFFF4FA3);
const _rose = Color(0xFFFFB4D4);
const _text = Color(0xFFF7F1F7);
const _muted = Color(0xFFAA9EAE);

/// Local demo authentication only: credentials are held in memory and lost
/// when the application closes. This is not production authentication.
class DemoAuthGate extends StatefulWidget {
  const DemoAuthGate({super.key, required this.appBuilder});
  final WidgetBuilder appBuilder;

  @override
  State<DemoAuthGate> createState() => _DemoAuthGateState();
}

class _DemoAuthGateState extends State<DemoAuthGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;
  String? _username;
  String? _password;
  bool _authorized = false;
  bool _registering = true;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  void _register(String username, String password) {
    if (_username != null) {
      setState(() => _registering = false);
      _message('Демо-аккаунт уже создан. Войдите в него.');
      return;
    }
    setState(() {
      _username = username.trim();
      _password = password;
      _registering = false;
    });
    _message('Аккаунт создан. Теперь войдите.');
  }

  void _login(String username, String password) {
    if (_username == null ||
        username.trim().toLowerCase() != _username!.toLowerCase() ||
        password != _password) {
      _message('Неверный логин или пароль.');
      return;
    }
    setState(() => _authorized = true);
  }

  Future<void> _recover() async {
    if (_username == null) {
      _message('Сначала создайте демо-аккаунт.');
      return;
    }
    final userController = TextEditingController();
    final userKey = GlobalKey<FormState>();
    final enteredUser = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('Восстановление пароля', style: TextStyle(color: _text)),
        content: Form(
          key: userKey,
          child: TextFormField(
            controller: userController,
            style: const TextStyle(color: _text),
            decoration: const InputDecoration(labelText: 'Логин аккаунта'),
            validator: (value) => (value?.trim().isNotEmpty ?? false) ? null : 'Введите логин',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (userKey.currentState!.validate()) Navigator.pop(dialogContext, userController.text.trim());
            },
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    userController.dispose();
    if (!mounted || enteredUser == null) return;
    if (enteredUser.toLowerCase() != _username!.toLowerCase()) {
      _message('Демо-аккаунт с таким логином не найден.');
      return;
    }

    final passwordController = TextEditingController();
    final repeatController = TextEditingController();
    final passwordKey = GlobalKey<FormState>();
    final newPassword = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('Новый пароль', style: TextStyle(color: _text)),
        content: Form(
          key: passwordKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Локальное демо-восстановление: письмо не отправляется.', style: TextStyle(color: _muted)),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Новый пароль'),
                validator: (value) => (value ?? '').length >= 6 ? null : 'Минимум 6 символов',
              ),
              TextFormField(
                controller: repeatController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Повторите пароль'),
                validator: (value) => value == passwordController.text ? null : 'Пароли не совпадают',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (passwordKey.currentState!.validate()) Navigator.pop(dialogContext, passwordController.text);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    passwordController.dispose();
    repeatController.dispose();
    if (newPassword != null && mounted) {
      setState(() {
        _password = newPassword;
        _registering = false;
      });
      _message('Пароль изменён. Войдите с новым паролем.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authorized) return widget.appBuilder(context);
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _shine,
        builder: (context, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _shine.value, -1),
              end: Alignment(1 - 2 * _shine.value, 1),
              colors: const [Color(0xFF08060B), Color(0xFF1D101A), Color(0xFF100B13), Color(0xFF08060B)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: _registering
                      ? _RegistrationForm(shine: _shine, onRegister: _register, onLogin: () => setState(() => _registering = false))
                      : _LoginForm(shine: _shine, onLogin: _login, onForgot: _recover, onRegister: () => setState(() => _registering = true)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrationForm extends StatefulWidget {
  const _RegistrationForm({required this.shine, required this.onRegister, required this.onLogin});
  final Animation<double> shine;
  final void Function(String, String) onRegister;
  final VoidCallback onLogin;
  @override
  State<_RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<_RegistrationForm> {
  final _key = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Brand(shine: widget.shine),
            const SizedBox(height: 25),
            const Text('Создать аккаунт', textAlign: TextAlign.center, style: TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Придумайте логин и пароль', textAlign: TextAlign.center, style: TextStyle(color: _muted)),
            const SizedBox(height: 26),
            TextFormField(controller: _username, style: const TextStyle(color: _text), decoration: const InputDecoration(labelText: 'Логин'), validator: (v) => (v?.trim().length ?? 0) >= 3 ? null : 'Минимум 3 символа'),
            const SizedBox(height: 14),
            TextFormField(controller: _password, obscureText: _obscure, style: const TextStyle(color: _text), decoration: InputDecoration(labelText: 'Пароль', suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off))), validator: (v) => (v ?? '').length >= 6 ? null : 'Минимум 6 символов'),
            const SizedBox(height: 14),
            TextFormField(controller: _repeat, obscureText: _obscure, style: const TextStyle(color: _text), decoration: const InputDecoration(labelText: 'Повторите пароль'), validator: (v) => v == _password.text ? null : 'Пароли не совпадают'),
            const SizedBox(height: 22),
            _GlowButton(shine: widget.shine, label: 'Зарегистрироваться', onPressed: () { if (_key.currentState!.validate()) widget.onRegister(_username.text.trim(), _password.text); }),
            TextButton(onPressed: widget.onLogin, child: const Text('Уже есть аккаунт? Войти')),
          ],
        ),
      );
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.shine, required this.onLogin, required this.onForgot, required this.onRegister});
  final Animation<double> shine;
  final void Function(String, String) onLogin;
  final VoidCallback onForgot;
  final VoidCallback onRegister;
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _key = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  @override
  void dispose() { _username.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Form(
        key: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Brand(shine: widget.shine),
            const SizedBox(height: 25),
            const Text('Вход в аккаунт', textAlign: TextAlign.center, style: TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 26),
            TextFormField(controller: _username, style: const TextStyle(color: _text), decoration: const InputDecoration(labelText: 'Логин'), validator: (v) => (v?.trim().isNotEmpty ?? false) ? null : 'Введите логин'),
            const SizedBox(height: 14),
            TextFormField(controller: _password, obscureText: true, style: const TextStyle(color: _text), decoration: const InputDecoration(labelText: 'Пароль'), validator: (v) => (v?.isNotEmpty ?? false) ? null : 'Введите пароль'),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: widget.onForgot, child: const Text('Забыл логин/пароль?', style: TextStyle(color: _muted, fontSize: 12)))),
            const SizedBox(height: 10),
            _GlowButton(shine: widget.shine, label: 'Войти', onPressed: () { if (_key.currentState!.validate()) widget.onLogin(_username.text.trim(), _password.text); }),
            TextButton(onPressed: widget.onRegister, child: const Text('Создать аккаунт')),
          ],
        ),
      );
}

class _Brand extends StatelessWidget {
  const _Brand({required this.shine});
  final Animation<double> shine;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 190, height: 190, child: CustomPaint(painter: _SpiderPainter(shine))),
          const SizedBox(height: 7),
          AnimatedBuilder(
            animation: shine,
            builder: (context, _) => ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-1 + 2 * shine.value, 0),
                end: Alignment(1 - 2 * shine.value, 0),
                colors: const [_text, Color(0xFFFFB4D4), _text],
              ).createShader(bounds),
              child: const Text('SPIDER VPN', style: TextStyle(color: Colors.white, fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 4.5)),
            ),
          ),
        ],
      );
}

class _SpiderPainter extends CustomPainter {
  _SpiderPainter(this.animation) : super(repaint: animation);
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.shortestSide / 300;
    final phase = animation.value;
    final gradient = LinearGradient(
      begin: Alignment(-1 + 2 * phase, -1),
      end: Alignment(1 - 2 * phase, 1),
      colors: [const Color(0x884A172E), Color.lerp(_pink, _rose, (math.sin(phase * math.pi * 2) + 1) / 2)!, const Color(0xFFFFE0ED), _pink],
      stops: const [0, .35, .58, 1],
    ).createShader(Offset.zero & size);
    final legsPaint = Paint()..shader = gradient..style = PaintingStyle.stroke..strokeWidth = 9..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final bodyPaint = Paint()..shader = gradient;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    final paths = <Path>[
      Path()..moveTo(-9,-25)..cubicTo(-42,-53,-54,-83,-60,-111)..cubicTo(-66,-137,-66,-166,-82,-191),
      Path()..moveTo(9,-25)..cubicTo(42,-53,54,-83,60,-111)..cubicTo(66,-137,66,-166,82,-191),
      Path()..moveTo(-16,-19)..cubicTo(-56,-39,-92,-44,-120,-72)..cubicTo(-137,-89,-143,-108,-159,-124),
      Path()..moveTo(16,-19)..cubicTo(56,-39,92,-44,120,-72)..cubicTo(137,-89,143,-108,159,-124),
      Path()..moveTo(-17,-2)..cubicTo(-60,-2,-100,4,-128,24)..cubicTo(-151,40,-160,61,-178,76),
      Path()..moveTo(17,-2)..cubicTo(60,-2,100,4,128,24)..cubicTo(151,40,160,61,178,76),
      Path()..moveTo(-12,17)..cubicTo(-48,39,-78,58,-83,95)..cubicTo(-87,132,-67,164,-52,190),
      Path()..moveTo(12,17)..cubicTo(48,39,78,58,83,95)..cubicTo(87,132,67,164,52,190),
    ];
    for (final path in paths) { canvas.drawPath(path, legsPaint); }
    canvas.drawOval(const Rect.fromCenter(center: Offset(0, 9), width: 61, height: 83), bodyPaint);
    canvas.drawOval(const Rect.fromCenter(center: Offset(0, -34), width: 51, height: 48), bodyPaint);
    final feelers = Path()
      ..moveTo(-10, -52)..quadraticBezierTo(-31, -76, -17, -91)
      ..moveTo(10, -52)..quadraticBezierTo(31, -76, 17, -91);
    canvas.drawPath(feelers, legsPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpiderPainter oldDelegate) => oldDelegate.animation != animation;
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({required this.shine, required this.label, required this.onPressed});
  final Animation<double> shine;
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: shine,
        builder: (context, _) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(begin: Alignment(-1 + 2 * shine.value, 0), end: Alignment(1 - 2 * shine.value, 0), colors: const [Color(0xFF6D254B), Color(0xFFE95A9D), Color(0xFF6D254B)]),
            boxShadow: [BoxShadow(color: _pink.withOpacity(.2), blurRadius: 18)],
          ),
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 13), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .5))),
          ),
        ),
      );
}
