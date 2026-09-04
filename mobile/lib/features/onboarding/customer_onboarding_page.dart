import 'package:creavers_delivery_mobile/app/app_controller.dart';
import 'package:creavers_delivery_mobile/core/models/customer_onboarding.dart';
import 'package:creavers_delivery_mobile/core/network/api_exception.dart';
import 'package:creavers_delivery_mobile/core/services/customer_onboarding_service.dart';
import 'package:creavers_delivery_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum _OnboardingStep { phone, otp, profile }

final class CustomerOnboardingPage extends StatefulWidget {
  const CustomerOnboardingPage({
    required this.controller,
    required this.onboardingService,
    super.key,
  });

  final AppController controller;
  final CustomerOnboardingService onboardingService;

  @override
  State<CustomerOnboardingPage> createState() => _CustomerOnboardingPageState();
}

final class _CustomerOnboardingPageState extends State<CustomerOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+251');
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  _OnboardingStep _step = _OnboardingStep.phone;
  CustomerOtpChallenge? _challenge;
  String? _verifiedChallengeId;
  DateTime? _dateOfBirth;
  String? _errorMessage;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;
    await _perform(() async {
      final challenge = await widget.onboardingService.requestOtp(
        _phoneController.text,
      );
      setState(() {
        _challenge = challenge;
        _step = _OnboardingStep.otp;
      });
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      setState(() => _errorMessage = 'Enter the six-digit verification code.');
      return;
    }
    final challenge = _challenge;
    if (challenge == null) return;
    await _perform(() async {
      final verification = await widget.onboardingService.verifyOtp(
        challengeId: challenge.challengeId,
        phoneNumber: _phoneController.text,
        otpCode: _otpController.text,
      );
      if (verification.session case final session?) {
        widget.controller.acceptOnboardingSession(session);
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      setState(() {
        _verifiedChallengeId = verification.verifiedChallengeId;
        _step = _OnboardingStep.profile;
      });
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      setState(() => _errorMessage = 'Select your date of birth.');
      return;
    }
    final verifiedChallengeId = _verifiedChallengeId;
    if (verifiedChallengeId == null) return;
    await _perform(() async {
      final session = await widget.onboardingService.register(
        verifiedChallengeId: verifiedChallengeId,
        phoneNumber: _phoneController.text,
        fullName: _nameController.text,
        dateOfBirth: _dateOfBirth!,
      );
      widget.controller.acceptOnboardingSession(session);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  Future<void> _perform(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      await action();
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Unable to continue. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Select date of birth',
    );
    if (selected != null) setState(() => _dateOfBirth = selected);
  }

  void _backStep() {
    setState(() {
      _errorMessage = null;
      _step = switch (_step) {
        _OnboardingStep.phone => _OnboardingStep.phone,
        _OnboardingStep.otp => _OnboardingStep.phone,
        _OnboardingStep.profile => _OnboardingStep.otp,
      };
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back',
        onPressed: _step == _OnboardingStep.phone
            ? () => Navigator.of(context).pop()
            : _backStep,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text('Create account'),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _OnboardingHero(step: _step),
                  const SizedBox(height: 18),
                  _Progress(step: _step),
                  const SizedBox(height: 22),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: switch (_step) {
                      _OnboardingStep.phone => _PhoneStep(
                        key: const ValueKey('phone'),
                        controller: _phoneController,
                      ),
                      _OnboardingStep.otp => _OtpStep(
                        key: const ValueKey('otp'),
                        controller: _otpController,
                        challenge: _challenge!,
                      ),
                      _OnboardingStep.profile => _ProfileStep(
                        key: const ValueKey('profile'),
                        nameController: _nameController,
                        dateOfBirth: _dateOfBirth,
                        onSelectDate: _selectDateOfBirth,
                      ),
                    },
                  ),
                  if (_errorMessage case final message?) ...<Widget>[
                    const SizedBox(height: 14),
                    _InlineError(message: message),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : switch (_step) {
                            _OnboardingStep.phone => _requestOtp,
                            _OnboardingStep.otp => _verifyOtp,
                            _OnboardingStep.profile => _register,
                          },
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _step == _OnboardingStep.profile
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                          ),
                    label: Text(
                      _busy
                          ? 'Please wait…'
                          : switch (_step) {
                              _OnboardingStep.phone => 'Send verification code',
                              _OnboardingStep.otp => 'Verify phone',
                              _OnboardingStep.profile =>
                                'Create account & shop',
                            },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'By continuing, you confirm that the information belongs to you. Development OTP is temporary and must be replaced before production.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.inkSoft,
                      fontSize: 11,
                      height: 1.4,
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

final class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF064F53), AppTheme.teal],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x29075E62),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      children: <Widget>[
        const Positioned(
          right: -22,
          bottom: -30,
          child: Icon(
            Icons.shopping_bag_rounded,
            size: 130,
            color: Color(0x16FFFFFF),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'CREAVERS MEMBERSHIP',
                style: TextStyle(
                  color: AppTheme.warmGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                switch (step) {
                  _OnboardingStep.phone => 'Start with your phone.',
                  _OnboardingStep.otp => 'Make sure it is you.',
                  _OnboardingStep.profile => 'One last detail.',
                },
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(switch (step) {
                _OnboardingStep.phone => 'A verified number keeps your orders and delivery updates connected.',
                _OnboardingStep.otp =>
                  'Enter the short code sent for this development session.',
                _OnboardingStep.profile => 'Tell us what to call you, then your fresh catalogue is ready.',
              }, style: const TextStyle(color: Color(0xFFE0F1EF), height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _Progress extends StatelessWidget {
  const _Progress({required this.step});
  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) => Row(
    children: _OnboardingStep.values
        .map((item) {
          final index = item.index;
          final active = index <= step.index;
          return Expanded(
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: active ? AppTheme.deepTeal : Colors.white,
                    border: Border.all(
                      color: active ? AppTheme.deepTeal : AppTheme.border,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: active && index < step.index
                        ? const Icon(Icons.check, size: 15, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: active ? Colors.white : AppTheme.inkSoft,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
                if (index < _OnboardingStep.values.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < step.index
                          ? AppTheme.deepTeal
                          : AppTheme.border,
                    ),
                  ),
              ],
            ),
          );
        })
        .toList(growable: false),
  );
}

final class _PhoneStep extends StatelessWidget {
  const _PhoneStep({required this.controller, super.key});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        'Mobile number',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 6),
      const Text(
        'Use an Ethiopian mobile number for this prototype.',
        style: TextStyle(color: AppTheme.inkSoft),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        autofillHints: const <String>[AutofillHints.telephoneNumber],
        decoration: const InputDecoration(
          labelText: 'Phone number',
          hintText: '+251 911 234 567',
          prefixIcon: Icon(Icons.phone_outlined),
        ),
        validator: (value) {
          final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
          return digits.length < 9 ? 'Enter a valid mobile number.' : null;
        },
      ),
    ],
  );
}

final class _OtpStep extends StatelessWidget {
  const _OtpStep({
    required this.controller,
    required this.challenge,
    super.key,
  });
  final TextEditingController controller;
  final CustomerOtpChallenge challenge;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        'Verification code',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 6),
      Text(
        'Code requested for ${challenge.maskedPhoneNumber}.',
        style: const TextStyle(color: AppTheme.inkSoft),
      ),
      if (challenge.developmentCode case final code?) ...<Widget>[
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5DA),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFF1D591)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                const Icon(Icons.science_outlined, color: Color(0xFF8A5A00)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Development code',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      TextFormField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 8,
        ),
        decoration: const InputDecoration(counterText: '', hintText: '••••••'),
      ),
    ],
  );
}

final class _ProfileStep extends StatelessWidget {
  const _ProfileStep({
    required this.nameController,
    required this.dateOfBirth,
    required this.onSelectDate,
    super.key,
  });
  final TextEditingController nameController;
  final DateTime? dateOfBirth;
  final VoidCallback onSelectDate;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        'Your profile',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 6),
      const Text(
        'These details help personalize delivery communication.',
        style: TextStyle(color: AppTheme.inkSoft),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: nameController,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        autofillHints: const <String>[AutofillHints.name],
        decoration: const InputDecoration(
          labelText: 'Full name',
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
        validator: (value) => value == null || value.trim().length < 2
            ? 'Enter your full name.'
            : null,
      ),
      const SizedBox(height: 14),
      InkWell(
        onTap: onSelectDate,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Date of birth',
            prefixIcon: Icon(Icons.cake_outlined),
            suffixIcon: Icon(Icons.calendar_month_outlined),
          ),
          child: Text(
            dateOfBirth == null
                ? 'Select date'
                : '${dateOfBirth!.day.toString().padLeft(2, '0')} / ${dateOfBirth!.month.toString().padLeft(2, '0')} / ${dateOfBirth!.year}',
            style: TextStyle(
              color: dateOfBirth == null ? AppTheme.inkSoft : AppTheme.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );
}

final class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}
