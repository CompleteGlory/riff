abstract class PhoneVerifyState {}

class PhoneVerifyInitial extends PhoneVerifyState {}

class PhoneVerifyLoading extends PhoneVerifyState {}

class PhoneVerifyOtpSent extends PhoneVerifyState {
  final String phoneNumber;
  PhoneVerifyOtpSent(this.phoneNumber);
}

class PhoneVerifySuccess extends PhoneVerifyState {}

class PhoneVerifyError extends PhoneVerifyState {
  final String message;
  PhoneVerifyError(this.message);
}
