import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/phone_verify/data/repos/phone_verify_repo.dart';
import 'phone_verify_state.dart';

class PhoneVerifyCubit extends Cubit<PhoneVerifyState> {
  final PhoneVerifyRepo _repo;
  String? _phoneNumber;

  PhoneVerifyCubit(this._repo) : super(PhoneVerifyInitial());

  String? get phoneNumber => _phoneNumber;

  String _normalizePhoneNumber(String phoneNumber) =>
      phoneNumber.replaceAll(RegExp(r'\D'), '');

  Future<void> sendOtp(String phoneNumber) async {
    emit(PhoneVerifyLoading());
    final normalizedPhoneNumber = _normalizePhoneNumber(phoneNumber);
    _phoneNumber = normalizedPhoneNumber;
    final result = await _repo.sendOtp(normalizedPhoneNumber);
    result.when(
      success: (_) => emit(PhoneVerifyOtpSent(normalizedPhoneNumber)),
      failure: (err) =>
          emit(PhoneVerifyError(err.message ?? 'Failed to send OTP')),
    );
  }

  Future<void> verifyOtp(String otp) async {
    if (state is PhoneVerifyLoading) return;
    if (_phoneNumber == null) return;
    emit(PhoneVerifyLoading());
    final result = await _repo.verifyOtp(_phoneNumber!, otp);
    result.when(
      success: (_) => emit(PhoneVerifySuccess()),
      failure: (err) => emit(PhoneVerifyError(err.message ?? 'Invalid OTP')),
    );
  }

  void resetToInitial() => emit(PhoneVerifyInitial());
}
