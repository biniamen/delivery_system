import 'package:creavers_delivery_mobile/app/app_controller.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:creavers_delivery_mobile/shared/widgets/connection_status_card.dart';
import 'package:flutter/material.dart';

final class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.controller,
    required this.apiOrigin,
    super.key,
  });

  final AppController controller;
  final Uri apiOrigin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

final class _LoginPageState extends State<LoginPage> {
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

  void _selectDemoAccount(String email) {
    _emailController.text = email;
    _passwordController.clear();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _BrandMark(),
                  const SizedBox(height: 28),
                  Text(
                    'Delivery in your hands.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customers can browse the catalogue. Drivers can manage assigned deliveries.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 22),
                  ConnectionStatusCard(
                    state: widget.controller.connectionState,
                    message: widget.controller.connectionMessage,
                    apiOrigin: widget.apiOrigin,
                    onRetry: widget.controller.checkConnection,
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: () =>
                            _selectDemoAccount('customer@demo.creavers.local'),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('Customer demo'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _selectDemoAccount('driver@demo.creavers.local'),
                        icon: const Icon(Icons.local_shipping_outlined),
                        label: const Text('Driver demo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (value) => value == null || !value.contains('@')
                        ? 'Enter a valid email address.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _hidePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password.'
                        : null,
                  ),
                  if (widget.controller.errorMessage
                      case final error?) ...<Widget>[
                    const SizedBox(height: 14),
                    _ErrorMessage(message: error),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: widget.controller.isBusy ? null : _submit,
                    icon: widget.controller.isBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(
                      widget.controller.isBusy ? 'Signing in…' : 'Sign in',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

final class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.deepTeal,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const SizedBox.square(
          dimension: 54,
          child: Center(
            child: Text(
              'C',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 14),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Creavers',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text('Supermarket delivery'),
        ],
      ),
    ],
  );
}

final class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
