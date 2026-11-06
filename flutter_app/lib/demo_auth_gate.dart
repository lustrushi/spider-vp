import 'dart:math' as math;

import 'package:flutter/material.dart';

const _demoBg = Color(0xFF05050A);
const _demoPanel = Color(0xFF100D18);
const _demoPurple = Color(0xFF9B35FF);
const _demoLilac = Color(0xFFC28AFF);
const _demoText = Color(0xFFF2ECFA);
const _demoMuted = Color(0xFF9A8EAD);

/// Local-only demo authentication. Credentials are kept in memory and are
/// lost when the app closes. This is not suitable for real accounts.
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

  Future<void> _registered(String username, String password) async {
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
    await _askForEmail();
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
            decoration: const InputDecoration(
              labelText: 'Электронная почта (необязательно)',
              labelStyle: TextStyle(color: _demoMuted),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isNotEmpty && !_isEmail(text)) {
                return 'Введите корректный адрес';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: const Text('Пропустить'),
          ),
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
            validator: (value) => _isEmail(value?.trim() ?? '')
                ? null
                : 'Введите корректную почту',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _demoPanel,
        title: const Text('Демо-восстановление', style: TextStyle(color: _demoText)),
        content: Text(
          'Логин вашего демо-аккаунта: $_username. Письмо не отправляется. '
          'Продолжить и задать новый пароль?',
          style: const TextStyle(color: _demoText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Задать пароль'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _showResetPasswordDialog();
  }

  Future<void> _showResetPasswordDialog() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final password = await showDialog<String>(
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
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: _demoText),
                decoration: const InputDecoration(labelText: 'Новый пароль'),
                validator: (value) => (value ?? '').length < 6
                    ? 'Минимум 6 символов'
                    : null,
              ),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                style: const TextStyle(color: _demoText),
                decoration: const InputDecoration(labelText: 'Повторите пароль'),
                validator: (value) => value != passwordController.text
                    ? 'Пароли не совпадают'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, passwordController.text);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    passwordController.dispose();
    confirmController.dispose();
    if (password != null && mounted) {
      setState(() {
        _password = password;
        _authorized = false;
        _showRegistration = false;
      });
      _message('Пароль изменён. Войдите с новым паролем.');
    }
  }

  bool _isEmail(String value) =>
      value.contains('@') && value.substring(value.indexOf('@') + 1).contains('.');

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
                      onCreateAccount: () => setState(() {
                        _showRegistration = true;
                      }),
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
  final _key = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _login.dispose();
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
            const _SpiderWebMark(size: 112),
            const SizedBox(height: 16),
            const Text(
              'Создать аккаунт',
              textAlign: TextAlign.center,
              style: TextStyle(color: _demoText, fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Придумайте логин и пароль',
              textAlign: TextAlign.center,
              style: TextStyle(color: _demoMuted),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _login,
              style: const TextStyle(color: _demoText),
              decoration: const InputDecoration(labelText: 'Логин'),
              validator: (value) => (value?.trim().length ?? 0) < 3
                  ? 'Логин должен содержать минимум 3 символа'
                  : null,
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
              validator: (value) => (value ?? '').length < 6
                  ? 'Пароль должен содержать минимум 6 символов'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _repeat,
              obscureText: _obscure,
              style: const TextStyle(color: _demoText),
              decoration: const InputDecoration(labelText: 'Повторите пароль'),
              validator: (value) => value != _password.text
                  ? 'Пароли не совпадают'
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (_key.currentState!.validate()) {
                  widget.onRegister(_login.text.trim(), _password.text);
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Text('Зарегистрироваться'),
              ),
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
  final _key = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SpiderWebMark(size: 112),
            const SizedBox(height: 16),
            const Text(
              'Вход в аккаунт',
              textAlign: TextAlign.center,
              style: TextStyle(color: _demoText, fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _login,
              style: const TextStyle(color: _demoText),
              decoration: const InputDecoration(labelText: 'Логин'),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Введите логин'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: true,
              style: const TextStyle(color: _demoText),
              decoration: const InputDecoration(labelText: 'Пароль'),
              validator: (value) => (value?.isEmpty ?? true)
                  ? 'Введите пароль'
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onForgot,
                child: const Text('Забыл логин/пароль?', style: TextStyle(color: _demoMuted, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (_key.currentState!.validate()) {
                  widget.onLogin(_login.text.trim(), _password.text);
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Text('Войти'),
              ),
            ),
            TextButton(onPressed: widget.onCreateAccount, child: const Text('Создать аккаунт')),
          ],
        ),
      );
}

class _SpiderWebMark extends StatelessWidget {
  const _SpiderWebMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _SpiderWebPainter()),
      );
}

class _SpiderWebPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .43;
    final webPaint = Paint()
      ..color = _demoPurple.withOpacity(.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15;
    final spiderPaint = Paint()
      ..color = _demoLilac
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final bodyPaint = Paint()..color = _demoPurple;

    const rays = 8;
    for (var i = 0; i < rays; i++) {
      final angle = -math.pi / 2 + math.pi * 2 * i / rays;
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius),
        webPaint,
      );
    }
    for (var ring = 1; ring <= 4; ring++) {
      final ringRadius = radius * ring / 4;
      final path = Path();
      for (var i = 0; i <= rays; i++) {
        final angle = -math.pi / 2 + math.pi * 2 * i / rays;
        final point = Offset(
          center.dx + math.cos(angle) * ringRadius,
          center.dy + math.sin(angle) * ringRadius,
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          final previousAngle = -math.pi / 2 + math.pi * 2 * (i - 1) / rays;
          final middleAngle = (previousAngle + angle) / 2;
          final control = Offset(
            center.dx + math.cos(middleAngle) * ringRadius * .78,
            center.dy + math.sin(middleAngle) * ringRadius * .78,
          );
          path.quadraticBezierTo(control.dx, control.dy, point.dx, point.dy);
        }
      }
      canvas.drawPath(path, webPaint);
    }

    for (var i = 0; i < 4; i++) {
      final y = (i - 1.5) * size.width * .045;
      for (final side in [-1.0, 1.0]) {
        final leg = Path()
          ..moveTo(center.dx + side * size.width * .025, center.dy + y)
          ..quadraticBezierTo(
            center.dx + side * size.width * .09,
            center.dy + y - size.width * .035,
            center.dx + side * size.width * .14,
            center.dy + y - size.width * .09,
          )
          ..moveTo(center.dx + side * size.width * .025, center.dy + y)
          ..quadraticBezierTo(
            center.dx + side * size.width * .09,
            center.dy + y + size.width * .035,
            center.dx + side * size.width * .14,
            center.dy + y + size.width * .09,
          );
        canvas.drawPath(leg, spiderPaint);
      }
    }
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size.width * .13, height: size.width * .23),
      bodyPaint,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - size.width * .14),
      size.width * .055,
      Paint()..color = _demoLilac,
    );
  }

  @override
  bool shouldRepaint(covariant _SpiderWebPainter oldDelegate) => false;
}
