// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/auth/user-prefrences/genres_screen.dart'
    show genres, instruments;
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/profile/UI/profile_screen.dart';
import 'package:riff/features/home/profile_settings/logic/profile_settings_cubit.dart';
import 'package:riff/generated/l10n.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final UserProfile profile;
  const ProfileSettingsScreen({super.key, required this.profile});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(text: widget.profile.fullName);
    _usernameCtrl = TextEditingController(text: widget.profile.username);
    _emailCtrl = TextEditingController(text: widget.profile.email);
    context.read<ProfileSettingsCubit>().init(widget.profile);
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<ProfileSettingsCubit, ProfileSettingsState>(
      listenWhen: (p, c) => p.saveSuccess != c.saveSuccess,
      listener: (context, state) {
        if (state.saveSuccess == true) {
          // Refresh the profile in HomeCubit so changes appear immediately
          // without restarting the app.
          try {
            context.read<HomeCubit>().refreshProfile();
          } catch (_) {
            // HomeCubit may not be in tree if navigated from outside home
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.profileSavedSuccess),
              backgroundColor: const Color(0xFF30D158),
            ),
          );
          Navigator.pop(context, true);
        } else if (state.saveSuccess == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? s.profileSavedFailure),
              backgroundColor: ColorManager.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.profileSettingsTitle),
          centerTitle: true,
        ),
        body: BlocBuilder<ProfileSettingsCubit, ProfileSettingsState>(
          builder: (context, state) {
            final cubit = context.read<ProfileSettingsCubit>();
            final isGoogle = widget.profile.provider == 'google';

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Subtitle ─────────────────────────────────────────
                    Text(
                      s.profileSettingsSubtitle,
                      style: TextStyles.font14Medium.copyWith(
                        color: isDark
                            ? const Color(0xFF888888)
                            : const Color(0xFF666666),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // ── Full Name ────────────────────────────────────────
                    _SectionLabel(label: s.fullName, isDark: isDark),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _fullNameCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      onChanged: cubit.onFullNameChanged,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                      decoration: _inputDecoration(
                        context: context,
                        isDark: isDark,
                        hint: 'e.g. John Doe',
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // ── Username ─────────────────────────────────────────
                    _SectionLabel(label: s.usernameLabel, isDark: isDark),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _usernameCtrl,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      onChanged: cubit.onUsernameChanged,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return s.usernameRequired;
                        }
                        if (state.usernameStatus == UsernameStatus.taken) {
                          return s.usernameTaken;
                        }
                        return null;
                      },
                      decoration: _inputDecoration(
                        context: context,
                        isDark: isDark,
                        hint: s.usernameHint,
                        suffix: _UsernameSuffix(status: state.usernameStatus, s: s),
                      ),
                    ),
                    _UsernameHelperText(status: state.usernameStatus, s: s),
                    SizedBox(height: 20.h),

                    // ── Email ────────────────────────────────────────────
                    _SectionLabel(label: s.emailSettingsLabel, isDark: isDark),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _emailCtrl,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enabled: !isGoogle,
                      onChanged: cubit.onEmailChanged,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return s.emailRequired;
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                          return s.emailInvalid;
                        }
                        return null;
                      },
                      decoration: _inputDecoration(
                        context: context,
                        isDark: isDark,
                        hint: s.emailSettingsHint,
                      ).copyWith(
                        helperText: isGoogle ? s.googleAccountEmailNote : null,
                        helperStyle: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF888888)
                              : const Color(0xFF999999),
                        ),
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // ── Genres ───────────────────────────────────────────
                    _SectionLabel(label: s.genresSettingsLabel, isDark: isDark),
                    SizedBox(height: 4.h),
                    Text(
                      s.genresSettingsSubtitle,
                      style: TextStyles.font12Medium.copyWith(
                        color: isDark
                            ? const Color(0xFF888888)
                            : const Color(0xFF999999),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    _GenrePicker(
                      selected: state.genres,
                      isDark: isDark,
                      onToggle: cubit.toggleGenre,
                    ),
                    SizedBox(height: 28.h),

                    // ── Instruments ───────────────────────────────────────
                    _SectionLabel(label: 'Instruments', isDark: isDark),
                    SizedBox(height: 4.h),
                    Text(
                      'Select the instruments you play',
                      style: TextStyles.font12Medium.copyWith(
                        color: isDark
                            ? const Color(0xFF888888)
                            : const Color(0xFF999999),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    _InstrumentPicker(
                      selected: state.instruments,
                      isDark: isDark,
                      onToggle: cubit.toggleInstrument,
                    ),
                    SizedBox(height: 36.h),

                    // ── Save button ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: state.isSaving ||
                                state.usernameStatus == UsernameStatus.checking ||
                                state.usernameStatus == UsernameStatus.taken
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  cubit.save();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.accent,
                          foregroundColor: ColorManager.black,
                          disabledBackgroundColor:
                              ColorManager.accent.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          elevation: 0,
                        ),
                        child: state.isSaving
                            ? SizedBox(
                                width: 22.r,
                                height: 22.r,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: ColorManager.black,
                                ),
                              )
                            : Text(
                                s.saveProfileBtn,
                                style: TextStyles.font16Medium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: ColorManager.black,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required bool isDark,
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF555555) : const Color(0xFFBBBBBB),
        fontSize: 14,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F4F4),
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: ColorManager.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: ColorManager.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: ColorManager.red, width: 1.5),
      ),
    );
  }
}

// ─── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyles.font14Medium.copyWith(
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }
}

// ─── Username suffix icon ──────────────────────────────────────────────────────

class _UsernameSuffix extends StatelessWidget {
  final UsernameStatus status;
  final S s;
  const _UsernameSuffix({required this.status, required this.s});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case UsernameStatus.checking:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ColorManager.accent,
            ),
          ),
        );
      case UsernameStatus.available:
        return const Icon(Icons.check_circle_rounded,
            color: Color(0xFF30D158), size: 22);
      case UsernameStatus.taken:
        return Icon(Icons.cancel_rounded, color: ColorManager.red, size: 22);
      case UsernameStatus.unchanged:
        return const Icon(Icons.check_circle_outline_rounded,
            color: Color(0xFF888888), size: 22);
      case UsernameStatus.idle:
        return const SizedBox.shrink();
    }
  }
}

// ─── Username helper text ─────────────────────────────────────────────────────

class _UsernameHelperText extends StatelessWidget {
  final UsernameStatus status;
  final S s;
  const _UsernameHelperText({required this.status, required this.s});

  @override
  Widget build(BuildContext context) {
    String? text;
    Color color = const Color(0xFF888888);

    switch (status) {
      case UsernameStatus.available:
        text = s.usernameAvailable;
        color = const Color(0xFF30D158);
        break;
      case UsernameStatus.taken:
        text = s.usernameTaken;
        color = ColorManager.red;
        break;
      case UsernameStatus.unchanged:
        text = s.usernameUnchanged;
        break;
      case UsernameStatus.checking:
      case UsernameStatus.idle:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 6.h, left: 4.w),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }
}

// ─── Instrument picker ────────────────────────────────────────────────────────

class _InstrumentPicker extends StatelessWidget {
  final List<String> selected;
  final bool isDark;
  final void Function(String) onToggle;

  const _InstrumentPicker({
    required this.selected,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: instruments.map((ins) {
        final isSelected = selected.contains(ins.name);
        return GestureDetector(
          onTap: () => onToggle(ins.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorManager.accent
                  : (isDark
                      ? const Color(0xFF252525)
                      : const Color(0xFFF0F0F0)),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isSelected
                    ? ColorManager.accent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  ins.image,
                  width: 20.r,
                  height: 20.r,
                  color: isSelected
                      ? ColorManager.black
                      : (isDark
                          ? const Color(0xFF888888)
                          : const Color(0xFF666666)),
                ),
                SizedBox(width: 8.w),
                Text(
                  ins.name,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? ColorManager.black
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Genre picker ─────────────────────────────────────────────────────────────

class _GenrePicker extends StatelessWidget {
  final List<String> selected;
  final bool isDark;
  final void Function(String) onToggle;

  const _GenrePicker({
    required this.selected,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: genres.map((g) {
        final isSelected = selected.contains(g.name);
        return GestureDetector(
          onTap: () => onToggle(g.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorManager.accent
                  : (isDark
                      ? const Color(0xFF252525)
                      : const Color(0xFFF0F0F0)),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isSelected
                    ? ColorManager.accent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  g.image,
                  width: 20.r,
                  height: 20.r,
                  color: isSelected
                      ? ColorManager.black
                      : (isDark
                          ? const Color(0xFF888888)
                          : const Color(0xFF666666)),
                ),
                SizedBox(width: 8.w),
                Text(
                  g.name,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? ColorManager.black
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
