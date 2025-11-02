// ignore_for_file: depend_on_referenced_packages
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riff/core/networks/api_error_model.dart';
part 'signup_state.freezed.dart';


@freezed
class SignupState<T> with _$SignupState<T> {
  const factory SignupState.initial() = _Initial;
  const factory SignupState.loading() = Loading;
  const factory SignupState.success(T data) = Success<T>;
  const factory SignupState.failure(ApiErrorModel apiErrorModel) = Error;
}