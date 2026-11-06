import 'package:flutter/material.dart';

const _demoBg = Color(0xFF05050A);
const _demoPanel = Color(0xFF100D18);
const _demoPurple = Color(0xFF9B35FF);
const _demoText = Color(0xFFF2ECFA);
const _demoMuted = Color(0xFF9A8EAD);

/// Demo-only authentication gate. Account data lives in memory and is lost
/// when the application process exits; this is intentionally not production auth.
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

  void _registered(String username, String password) {
    setState(() {
      _username = username;
      _password = password;
      _showRegistration = false;
    });
    _showLinkEmailDialog();
  }

  Future<void> _showLinkEmailDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final linkedEmail = await showDialog<String>(
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
              final email = value?.trim() ?? '';
              if (email.isNotEmpty && !email.contains('@')) {
                return 'Введите корректный адрес';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: const Text('Позже'),
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
      _email = linkedEmail?.isNotEmpty == true ? linkedEmail : null;
      _authorized = true;
    });
  }

  void _login(String username, String password) {
    if (username.trim() != _username || password != _password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный логин или пароль.')),
      );
      return;
    }
    setState(() => _authorized = true);
  }

  void _recover(String email) {
    if (_email == null || email.trim().toLowerCase() != _email!.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('К этой почте аккаунт не привязан.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _demoPanel,
        title: const Text('Демо-восстановление', style: TextStyle(color: _demoText)),
        content: Text(
          'Логин: $_username\n\nВ демо-режиме письмо не отправляется. '
          'Можно задать новый пароль на следующем шаге.',
          style: const TextStyle(color: _demoText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showResetPasswordDialog();
            },
            child: const Text('Задать пароль'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetPasswordDialog() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
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
    if (result != null && mounted) {
      setState(() => _password = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароль изменён в демо-аккаунте.')),
      );
    }
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
                      onForgot: () => _showRecovery(context),
                      onCreateAccount: () => setState(() => _showRegistration = true),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRecovery(BuildContext context) async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _demoPanel,
        title: const Text('Восстановление аккаунта', style: TextStyle(color: _demoText)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: _demoText),
            decoration: const InputDecoration(labelText: 'Привязанная почта'),
            validator: (value) => (value?.trim().contains('@') ?? false)
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
                Navigator.pop(dialogContext, emailController.text.trim());
              }
            },
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    emailController.dispose();
    if (email != null && mounted) _recover(email);
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
            const Icon(Icons.shield_rounded, color: _demoPurple, size: 54),
            const SizedBox(height: 16),
            const Text('Создать аккаунт', textAlign: TextAlign.center,
                style: TextStyle(color: _demoText, fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Придумайте логин и пароль', textAlign: TextAlign.center,
                style: TextStyle(color: _demoMuted)),
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
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Демо: продолжить к входу'),
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
            const Icon(Icons.shield_rounded, color: _demoPurple, size: 54),
            const SizedBox(height: 16),
            const Text('Вход в аккаунт', textAlign: TextAlign.center,
                style: TextStyle(color: _demoText, fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 28),
            TextFormField(
              controller: _login,
              style: const TextStyle(color: _demoText),
              decoration: const InputDecoration(labelText: 'Логин'),
              validator: (value) => (value?.trim().isEmpty ?? true) ? 'Введите логин' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: true,
              style: const TextStyle(color: _demoText),
              decoration: const InputDecoration(labelText: 'Пароль'),
              validator: (value) => (value?.isEmpty ?? true) ? 'Введите пароль' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onForgot,
                child: const Text('Забыл логин/пароль?',
                    style: TextStyle(color: _demoMuted, fontSize: 12)),
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
            TextButton(
              onPressed: widget.onCreateAccount,
              child: const Text('Создать аккаунт'),
            ),
          ],
        ),
      );
}
