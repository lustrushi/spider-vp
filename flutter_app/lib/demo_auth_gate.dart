import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const _demoBg = Color(0xFF05050A);
const _demoPanel = Color(0xFF100D18);
const _demoPurple = Color(0xFF9B35FF);
const _demoLilac = Color(0xFFC28AFF);
const _demoText = Color(0xFFF2ECFA);
const _demoMuted = Color(0xFF9A8EAD);

/// Local-only demo authentication. Account data is lost when the app closes.
class DemoAuthGate extends StatefulWidget {
  const DemoAuthGate({super.key, required this.appBuilder});

  final WidgetBuilder appBuilder;

  @override
  State<DemoAuthGate> createState() => _DemoAuthGateState();
}

class _DemoAuthGateState extends State<DemoAuthGate> {
  String? _username;
  String? _password;
  String? _email;
  bool _authorized = false;
  bool _showRegistration = true;

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void _registered(String username, String password) {
    if (_username != null) {
      setState(() => _showRegistration = false);
      _message('Демо-аккаунт уже создан. Войдите в него.');
      return;
    }
    setState(() {
      _username = username.trim();
      _password = password;
      _showRegistration = false;
    });
    unawaited(_askForEmail());
  }

  Future<void> _askForEmail() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final email = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _demoPanel,
        title: const Text('Привязать почту?', style: TextStyle(color: _demoText)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: _demoText),
            decoration: const InputDecoration(labelText: 'Электронная почта (необязательно)'),
            validator: (value) {
              final text = value?.trim() ?? '';
              return text.isEmpty || _isEmail(text) ? null : 'Введите корректный адрес';
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, ''), child: const Text('Пропустить')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted) return;
    setState(() {
      _email = email?.isNotEmpty == true ? email : null;
      _authorized = false;
      _showRegistration = false;
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

  Future<void> _showRecovery() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _demoPanel,
        title: const Text('Восстановление аккаунта', style: TextStyle(color: _demoText)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: _demoText),
            decoration: const InputDecoration(labelText: 'Привязанная почта'),
            validator: (value) => _isEmail(value?.trim() ?? '') ? null : 'Введите корректную почту',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || email == null) return;
    if (_email == null || email.toLowerCase() != _email!.toLowerCase()) {
      _message('Аккаунт с такой привязанной почтой не найден.');
      return;
    }
    final reset = await _showResetPasswordDialog();
    if (reset != null && mounted) {
      setState(() {
        _password = reset;
        _authorized = false;
        _showRegistration = false;
      });
      _message('Пароль изменён. Войдите с новым паролем.');
    }
  }

  Future<String?> _showResetPasswordDialog() async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _demoPanel,
        title: const Text('Новый пароль', style: TextStyle(color: _demoText)),
        content: Form(
          key: formKey,
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
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(dialogContext, password.text);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    password.dispose();
    confirm.dispose();
    return result;
  }

  bool _isEmail(String value) {
    final at = value.indexOf('@');
    return at > 0 && value.indexOf('.', at) > at + 1 && value.indexOf('.', at) < value.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_authorized) return widget.appBuilder(context);
    return Scaffold(
      backgroundColor: _demoBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: _showRegistration
                  ? _RegistrationForm(onRegister: _registered)
                  : _LoginForm(
                      onLogin: _login,
                      onForgot: _showRecovery,
                      onCreateAccount: () => setState(() => _showRegistration = true),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrationForm extends StatefulWidget {
  const _RegistrationForm({required this.onRegister});
  final void Function(String username, String password) onRegister;

  @override
  State<_RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<_RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
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
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SpiderVpnBrand(),
            const SizedBox(height: 22),
            const Text('Создать аккаунт', textAlign: TextAlign.center, style: TextStyle(color: _demoText, fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Придумайте логин и пароль', textAlign: TextAlign.center, style: TextStyle(color: _demoMuted)),
            const SizedBox(height: 28),
            TextFormField(
              controller: _username,
              style: const TextStyle(color: _demoText),
              decoration: const InputDecoration(labelText: 'Логин'),
              validator: (value) => (value?.trim().length ?? 0) >= 3 ? null : 'Минимум 3 символа',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              style: const TextStyle(color: _demoText),
              decoration: InputDecoration(
                labelText: 'Пароль',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: (value) => (value ?? '').length >= 6 ? null : 'Минимум 6 символов',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _repeat,
              obscureText: _obscure,
              style: const TextStyle(color: _demoText),
              decoration: const InputDecoration(labelText: 'Повторите пароль'),
              validator: (value) => value == _password.text ? null : 'Пароли не совпадают',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onRegister(_username.text.trim(), _password.text);
                }
              },
              child: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('Зарегистрироваться')),
            ),
          ],
        ),
      );
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.onLogin, required this.onForgot, required this.onCreateAccount});
  final void Function(String username, String password) onLogin;
  final VoidCallback onForgot;
  final VoidCallback onCreateAccount;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SpiderVpnBrand(),
            const SizedBox(height: 22),
            const Text('Вход в аккаунт', textAlign: TextAlign.center, style: TextStyle(color: _demoText, fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 28),
            TextFormField(
              controller: _username,
              style: const TextStyle(color: _demoText),
              decoration: const InputDecoration(labelText: 'Логин'),
              validator: (value) => (value?.trim().isNotEmpty ?? false) ? null : 'Введите логин',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: true,
              style: const TextStyle(color: _demoText),
              decoration: const InputDecoration(labelText: 'Пароль'),
              validator: (value) => (value?.isNotEmpty ?? false) ? null : 'Введите пароль',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: widget.onForgot, child: const Text('Забыл логин/пароль?', style: TextStyle(color: _demoMuted, fontSize: 12))),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onLogin(_username.text.trim(), _password.text);
                }
              },
              child: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('Войти')),
            ),
            TextButton(onPressed: widget.onCreateAccount, child: const Text('Создать аккаунт')),
          ],
        ),
      );
}

/// Animated wordmark using a custom-drawn spider and web, inspired by the
/// supplied reference image. No external image assets or packages required.
class _SpiderVpnBrand extends StatefulWidget {
  const _SpiderVpnBrand();

  @override
  State<_SpiderVpnBrand> createState() => _SpiderVpnBrandState();
}

class _SpiderVpnBrandState extends State<_SpiderVpnBrand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;

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

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 178,
            height: 150,
            child: CustomPaint(painter: _SpiderWebPainter(_shine)),
          ),
          const SizedBox(height: 7),
          const Text(
            'spider vpn',
            style: TextStyle(
              color: _demoText,
              fontSize: 15,
              letterSpacing: 3.2,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      );
}

class _SpiderWebPainter extends CustomPainter {
  _SpiderWebPainter(this.animation) : super(repaint: animation);
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final phase = animation.value;
    final shimmer = LinearGradient(
      begin: Alignment(-1 + 2 * phase, -1),
      end: Alignment(1 - 2 * phase, 1),
      colors: const [
        Color(0x66FFFFFF),
        Color(0xFFE6E8EC),
        Color(0x553F4650),
        Color(0xCCFFFFFF),
      ],
      stops: const [0, .38, .68, 1],
    ).createShader(rect);
    final thread = Paint()
      ..shader = shimmer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Fan-shaped web with eight radial strands and curved cross strands.
    const rays = 8;
    final top = Offset(size.width * .51, size.height * .04);
    final webWidth = size.width * .88;
    final webHeight = size.height * .77;
    final bottom = Offset(top.dx, top.dy + webHeight);
    for (var i = 0; i < rays; i++) {
      final x = size.width * (.07 + .86 * i / (rays - 1));
      final endY = top.dy + webHeight * (i == 0 || i == rays - 1 ? .72 : 1);
      canvas.drawLine(top, Offset(x, endY), thread);
    }
    for (var row = 1; row <= 5; row++) {
      final t = row / 6;
      final y = top.dy + webHeight * t;
      final half = webWidth * .5 * t;
      final path = Path()
        ..moveTo(top.dx - half, y - 2)
        ..quadraticBezierTo(top.dx, y + webHeight * .11, top.dx + half, y - 2);
      canvas.drawPath(path, thread);
    }

    // Spider hangs from the lower-right web strand, like the supplied logo.
    final spiderCenter = Offset(size.width * .79, size.height * .81);
    final legPaint = Paint()
      ..shader = shimmer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final bodyPaint = Paint()
      ..shader = shimmer
      ..style = PaintingStyle.fill;
    canvas.drawLine(
      Offset(size.width * .93, top.dy + webHeight * .72),
      Offset(size.width * .93, spiderCenter.dy - 10),
      thread,
    );
    for (var i = 0; i < 4; i++) {
      final y = spiderCenter.dy + (i - 1.5) * 4;
      for (final side in [-1.0, 1.0]) {
        final leg = Path()
          ..moveTo(spiderCenter.dx + side * 3, y)
          ..quadraticBezierTo(spiderCenter.dx + side * 11, y - 8, spiderCenter.dx + side * 16, y - 2)
          ..quadraticBezierTo(spiderCenter.dx + side * 19, y + 3, spiderCenter.dx + side * 16, y + 8);
        canvas.drawPath(leg, legPaint);
      }
    }
    canvas.drawOval(
      Rect.fromCenter(center: spiderCenter, width: 12, height: 19),
      bodyPaint,
    );
    canvas.drawCircle(Offset(spiderCenter.dx, spiderCenter.dy - 10), 5, bodyPaint);
  }

  @override
  bool shouldRepaint(covariant _SpiderWebPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
