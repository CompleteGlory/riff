import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/services/session_manager.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/account_settings/logic/delete_account_cubit.dart';
import 'package:riff/generated/l10n.dart';

/// Permanent account deletion, reached from Account settings.
///
/// App Store guideline 5.1.1(v) requires this to exist inside the app for any
/// app that lets people create an account — a support email or a web page does
/// not satisfy it.
class DeleteAccountScreen extends StatefulWidget {
  /// The signed-in user's username, typed back as confirmation by accounts
  /// that have no password.
  final String username;

  /// The auth provider from `GET /users/me` — null for email/password
  /// accounts, `google` for accounts created through Google sign-in.
  final String? provider;

  const DeleteAccountScreen({
    super.key,
    required this.username,
    this.provider,
  });

  /// Whether this account confirms with a password or by typing its username.
  /// Accounts created through an OAuth provider never had a password to check.
  bool get usesPassword => provider == null || provider!.isEmpty;

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final confirmed = await _confirm();
    if (!confirmed || !mounted) return;

    final value = _controller.text.trim();
    await context.read<DeleteAccountCubit>().deleteAccount(
          password: widget.usesPassword ? value : null,
          confirmUsername: widget.usesPassword ? null : value,
        );
  }

  /// Last chance to back out. Deliberately a second, explicit step: the form
  /// alone is too easy to submit by reflex for something irreversible.
  Future<bool> _confirm() async {
    final s = S.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.deleteAccountConfirmTitle),
        content: Text(s.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(s.deleteAccountCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              s.deleteAccountConfirmAction,
              style: const TextStyle(color: ColorManager.red),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onDeleted() async {
    final s = S.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.deleteAccountSuccess)),
    );
    // The same teardown as a manual sign-out: clears stored credentials, runs
    // the hooks that reset the app-lifetime singletons and wipe the per-user
    // offline cache, and lands on login with an empty stack. Leaving any of
    // that behind would show the next person the deleted account's cached feed.
    await SessionManager.instance.endSession();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : ColorManager.primaryBlack;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        title: Text(s.deleteAccountTitle),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
        listener: (context, state) {
          if (state.status == DeleteAccountStatus.success) {
            _onDeleted();
          } else if (state.status == DeleteAccountStatus.failure &&
              !state.wrongCredential) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.deleteAccountFailed)),
            );
          }
        },
        builder: (context, state) {
          final busy = state.status == DeleteAccountStatus.loading;

          return AbsorbPointer(
            absorbing: busy,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  // ── Warning ────────────────────────────────────────────────
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: ColorManager.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: ColorManager.red.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: ColorManager.red, size: 22),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              s.deleteAccountHeadline,
                              style: TextStyles.font14semiBold
                                  .copyWith(color: ColorManager.red),
                            ),
                          ),
                        ]),
                        SizedBox(height: 10.h),
                        Text(
                          s.deleteAccountWarning,
                          style: TextStyles.font12Medium.copyWith(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // ── What goes ──────────────────────────────────────────────
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.deleteAccountRemovedIntro,
                            style:
                                TextStyles.font14semiBold.copyWith(color: textColor)),
                        SizedBox(height: 10.h),
                        _Bullet(s.deleteAccountRemovedProfile),
                        _Bullet(s.deleteAccountRemovedContent),
                        _Bullet(s.deleteAccountRemovedMessages),
                        _Bullet(s.deleteAccountRemovedSocial),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // ── Confirmation ───────────────────────────────────────────
                  Text(
                    widget.usesPassword
                        ? s.deleteAccountPasswordLabel
                        : s.deleteAccountUsernameLabel(widget.username),
                    style: TextStyles.font14Medium.copyWith(color: textColor),
                  ),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _controller,
                    obscureText: widget.usesPassword && _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      errorText: state.wrongCredential
                          ? (widget.usesPassword
                              ? s.deleteAccountWrongPassword
                              : s.deleteAccountUsernameMismatch)
                          : null,
                      suffixIcon: widget.usesPassword
                          ? IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            )
                          : null,
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (widget.usesPassword) {
                        return text.isEmpty
                            ? s.deleteAccountPasswordRequired
                            : null;
                      }
                      // Checked here for a quick answer and again on the
                      // server, which is the one that decides.
                      return text.toLowerCase() ==
                              widget.username.trim().toLowerCase()
                          ? null
                          : s.deleteAccountUsernameMismatch;
                    },
                  ),

                  SizedBox(height: 28.h),

                  SizedBox(
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: busy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              s.deleteAccountButton,
                              style: TextStyles.font14semiBold
                                  .copyWith(color: Colors.white),
                            ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  TextButton(
                    onPressed: busy ? null : () => Navigator.pop(context),
                    child: Text(s.deleteAccountCancel),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6.h, right: 8.w, left: 2.w),
            child: Container(
              width: 4.r,
              height: 4.r,
              decoration: const BoxDecoration(
                color: ColorManager.normalGrey,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyles.font12Medium
                  .copyWith(color: ColorManager.normalGrey),
            ),
          ),
        ],
      ),
    );
  }
}
