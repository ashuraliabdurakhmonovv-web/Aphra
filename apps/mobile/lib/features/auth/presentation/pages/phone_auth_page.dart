import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/validation/uzbek_phone_validator.dart';
import '../../domain/entities/registration_profile.dart';
import '../bloc/auth_onboarding_bloc.dart';
import '../widgets/auth_header.dart';

class PhoneAuthPage extends StatelessWidget {
  const PhoneAuthPage({
    required this.onSkip,
    required this.onCompleted,
    super.key,
  });
  final VoidCallback onSkip;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<AuthOnboardingBloc>(),
    child: _AuthFlow(onSkip: onSkip, onCompleted: onCompleted),
  );
}

class _AuthFlow extends StatelessWidget {
  const _AuthFlow({required this.onSkip, required this.onCompleted});
  final VoidCallback onSkip;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) =>
      BlocListener<AuthOnboardingBloc, AuthOnboardingState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == AuthSubmissionStatus.success) {
            onCompleted();
          } else if (state.status == AuthSubmissionStatus.failure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('auth.save_error'.tr())));
          }
        },
        child: BlocBuilder<AuthOnboardingBloc, AuthOnboardingState>(
          builder: (context, state) => Scaffold(
            backgroundColor: const Color(0xFFFFFBFD),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthHeader(
                      step: state.step,
                      onBack: state.step == 0
                          ? onSkip
                          : () => context.read<AuthOnboardingBloc>().add(
                              const AuthBackPressed(),
                            ),
                      onSkip: onSkip,
                    ),
                    const SizedBox(height: 38),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: switch (state.step) {
                          0 => _PhoneStep(key: const ValueKey('phone')),
                          1 => _OtpStep(
                            phone: state.phone,
                            key: const ValueKey('otp'),
                          ),
                          _ => _ProfileStep(
                            phone: state.phone,
                            isLoading:
                                state.status == AuthSubmissionStatus.loading,
                            key: const ValueKey('profile'),
                          ),
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _PhoneStep extends StatefulWidget {
  const _PhoneStep({super.key});
  @override
  State<_PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<_PhoneStep> {
  final controller = TextEditingController();
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void next() {
    if (!UzbekPhoneValidator.isValid(controller.text)) {
      setState(() => error = 'auth.invalid_phone');
      return;
    }
    final bloc = context.read<AuthOnboardingBloc>();
    bloc
      ..add(AuthPhoneChanged(controller.text))
      ..add(const AuthNextPressed());
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('auth.phone_title'.tr(), style: _titleStyle),
      const SizedBox(height: 10),
      Text('auth.phone_subtitle'.tr(), style: _subtitleStyle),
      const SizedBox(height: 34),
      Container(
        height: 66,
        decoration: _fieldDecoration,
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('🇺🇿', style: TextStyle(fontSize: 25)),
            ),
            const SizedBox(width: 9),
            const Text(
              '+998',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const VerticalDivider(
              width: 26,
              indent: 1,
              endIndent: 1,
              color: AppColors.border,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: false,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: const InputDecoration(
                  hintText: '90 123 45 67',
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 17),
                onSubmitted: (_) => next(),
              ),
            ),
          ],
        ),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(
            error!.tr(),
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ),
      const SizedBox(height: 24),
      _PinkButton(label: 'auth.continue'.tr(), onPressed: next),
      const SizedBox(height: 46),
      Center(child: Text('auth.or_sign_in'.tr(), style: _subtitleStyle)),
      const SizedBox(height: 24),
      Row(
        children: [
          const Expanded(
            child: _SocialButton(
              child: Text(
                'G',
                style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: _SocialButton(
              child: Text(
                '',
                style: TextStyle(color: Colors.black, fontSize: 32, height: 1),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: _SocialButton(
              child: Icon(
                Icons.send_rounded,
                color: Color(0xFF2AABEE),
                size: 30,
              ),
            ),
          ),
        ],
      ),
      const Spacer(),
      Center(
        child: Text.rich(
          TextSpan(
            text: '${'auth.agreement_prefix'.tr()}\n',
            children: [
              TextSpan(
                text: 'auth.terms_link'.tr(),
                style: const TextStyle(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(text: ' ${'auth.and'.tr()} '),
              TextSpan(
                text: 'auth.privacy_link'.tr(),
                style: const TextStyle(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.45,
            fontSize: 13,
          ),
        ),
      ),
    ],
  );
}

class _OtpStep extends StatefulWidget {
  const _OtpStep({required this.phone, super.key});
  final String phone;
  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  Timer? timer;
  int secondsRemaining = 45;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    timer?.cancel();
    setState(() => secondsRemaining = 45);
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining <= 1) {
        timer.cancel();
        setState(() => secondsRemaining = 0);
      } else {
        setState(() => secondsRemaining--);
      }
    });
  }

  void _resend() {
    controller.clear();
    context.read<AuthOnboardingBloc>().add(const AuthOtpChanged(''));
    focusNode.requestFocus();
    _startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('auth.otp_title'.tr(), style: _titleStyle),
      const SizedBox(height: 10),
      Text(
        '${'auth.otp_subtitle'.tr()}\n+998 ${widget.phone}',
        style: _subtitleStyle,
      ),
      const SizedBox(height: 34),
      GestureDetector(
        onTap: focusNode.requestFocus,
        child: Stack(
          children: [
            Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (value) {
                  setState(() {});
                  context.read<AuthOnboardingBloc>().add(AuthOtpChanged(value));
                  if (value.length == 6) {
                    context.read<AuthOnboardingBloc>().add(
                      const AuthNextPressed(),
                    );
                  }
                },
              ),
            ),
            Row(
              children: List.generate(6, (index) {
                final value = index < controller.text.length
                    ? controller.text[index]
                    : '';
                return Expanded(
                  child: Container(
                    height: 58,
                    margin: EdgeInsets.only(right: index == 5 ? 0 : 8),
                    alignment: Alignment.center,
                    decoration: _fieldDecoration,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      const SizedBox(height: 30),
      Center(
        child: secondsRemaining > 0
            ? Text.rich(
                TextSpan(
                  text: 'auth.resend'.tr(),
                  children: [
                    TextSpan(
                      text:
                          ' 00:${secondsRemaining.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                style: _subtitleStyle,
              )
            : TextButton(
                onPressed: _resend,
                child: Text('auth.resend_now'.tr()),
              ),
      ),
    ],
  );
}

class _ProfileStep extends StatefulWidget {
  const _ProfileStep({required this.phone, required this.isLoading, super.key});

  final String phone;
  final bool isLoading;
  @override
  State<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<_ProfileStep> {
  bool female = true;
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final birthDateController = TextEditingController();
  DateTime? birthDate;
  bool showErrors = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
    );
    if (selectedDate == null || !mounted) return;
    setState(() {
      birthDate = selectedDate;
      birthDateController.text = DateFormat('dd.MM.yyyy').format(selectedDate);
    });
  }

  void _submit() {
    final isValid =
        firstNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty &&
        birthDate != null;
    if (!isValid) {
      setState(() => showErrors = true);
      return;
    }
    context.read<AuthOnboardingBloc>().add(
      AuthRegistrationSubmitted(
        RegistrationProfile(
          phone: '+998${widget.phone}',
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          birthDate: birthDate!,
          gender: female ? UserGender.female : UserGender.male,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('auth.profile_title'.tr(), style: _titleStyle),
        const SizedBox(height: 8),
        Text('auth.profile_subtitle'.tr(), style: _subtitleStyle),
        const SizedBox(height: 18),
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.softPink,
                child: Icon(
                  Icons.person_outline,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
              Positioned(
                right: -4,
                bottom: 3,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _LabeledField(
          label: 'auth.first_name'.tr(),
          controller: firstNameController,
          errorText: showErrors && firstNameController.text.trim().isEmpty
              ? 'auth.required_field'.tr()
              : null,
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'auth.last_name'.tr(),
          controller: lastNameController,
          errorText: showErrors && lastNameController.text.trim().isEmpty
              ? 'auth.required_field'.tr()
              : null,
        ),
        const SizedBox(height: 12),
        _LabeledField(
          label: 'auth.birth_date'.tr(),
          controller: birthDateController,
          readOnly: true,
          onTap: _selectBirthDate,
          suffix: const Icon(Icons.calendar_month_outlined),
          errorText: showErrors && birthDate == null
              ? 'auth.required_field'.tr()
              : null,
        ),
        const SizedBox(height: 12),
        Text('auth.gender'.tr(), style: _labelStyle),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _GenderButton(
                label: 'auth.female'.tr(),
                icon: Icons.female,
                selected: female,
                onTap: () => setState(() => female = true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GenderButton(
                label: 'auth.male'.tr(),
                icon: Icons.male,
                selected: !female,
                onTap: () => setState(() => female = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _PinkButton(
          label: 'auth.continue'.tr(),
          onPressed: widget.isLoading ? null : _submit,
          isLoading: widget.isLoading,
        ),
      ],
    ),
  );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.suffix,
    this.errorText,
    this.readOnly = false,
    this.onTap,
  });
  final String label;
  final TextEditingController controller;
  final Widget? suffix;
  final String? errorText;
  final bool readOnly;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: _labelStyle),
      const SizedBox(height: 7),
      TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          suffixIcon: suffix,
          border: _outline,
          enabledBorder: _outline,
          focusedBorder: _outline.copyWith(
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          errorText: errorText,
        ),
      ),
    ],
  );
}

class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      foregroundColor: selected ? AppColors.primary : AppColors.textPrimary,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class _PinkButton extends StatelessWidget {
  const _PinkButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 58,
    child: FilledButton(
      onPressed: onPressed,
      child: isLoading
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
    ),
  );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [BoxShadow(color: Color(0x09000000), blurRadius: 14)],
    ),
    child: child,
  );
}

const _titleStyle = TextStyle(
  color: Color(0xFF111827),
  fontSize: 31,
  height: 1.12,
  fontWeight: FontWeight.w800,
  letterSpacing: -.7,
);
const _subtitleStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 16,
  height: 1.45,
);
const _labelStyle = TextStyle(color: AppColors.textSecondary, fontSize: 13);
final _fieldDecoration = BoxDecoration(
  color: Colors.white,
  border: Border.all(color: AppColors.border),
  borderRadius: BorderRadius.circular(17),
);
const _outline = OutlineInputBorder(
  borderSide: BorderSide(color: AppColors.border),
  borderRadius: BorderRadius.all(Radius.circular(14)),
);
