// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forgot_password_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ForgotPasswordState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState()';
}


}

/// @nodoc
class $ForgotPasswordStateCopyWith<$Res>  {
$ForgotPasswordStateCopyWith(ForgotPasswordState _, $Res Function(ForgotPasswordState) __);
}


/// Adds pattern-matching-related methods to [ForgotPasswordState].
extension ForgotPasswordStatePatterns on ForgotPasswordState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( Loading value)?  loading,TResult Function( Success value)?  success,TResult Function( Error value)?  failure,TResult Function( OtpVerificationLoading value)?  otpVerificationLoading,TResult Function( OtpVerified value)?  otpVerified,TResult Function( OtpVerificationFailed value)?  otpVerificationFailed,TResult Function( ResetPasswordLoading value)?  resetPasswordLoading,TResult Function( ResetPasswordSuccess value)?  resetPasswordSuccess,TResult Function( ResetPasswordFailed value)?  resetPasswordFailed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case Loading() when loading != null:
return loading(_that);case Success() when success != null:
return success(_that);case Error() when failure != null:
return failure(_that);case OtpVerificationLoading() when otpVerificationLoading != null:
return otpVerificationLoading(_that);case OtpVerified() when otpVerified != null:
return otpVerified(_that);case OtpVerificationFailed() when otpVerificationFailed != null:
return otpVerificationFailed(_that);case ResetPasswordLoading() when resetPasswordLoading != null:
return resetPasswordLoading(_that);case ResetPasswordSuccess() when resetPasswordSuccess != null:
return resetPasswordSuccess(_that);case ResetPasswordFailed() when resetPasswordFailed != null:
return resetPasswordFailed(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( Loading value)  loading,required TResult Function( Success value)  success,required TResult Function( Error value)  failure,required TResult Function( OtpVerificationLoading value)  otpVerificationLoading,required TResult Function( OtpVerified value)  otpVerified,required TResult Function( OtpVerificationFailed value)  otpVerificationFailed,required TResult Function( ResetPasswordLoading value)  resetPasswordLoading,required TResult Function( ResetPasswordSuccess value)  resetPasswordSuccess,required TResult Function( ResetPasswordFailed value)  resetPasswordFailed,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case Loading():
return loading(_that);case Success():
return success(_that);case Error():
return failure(_that);case OtpVerificationLoading():
return otpVerificationLoading(_that);case OtpVerified():
return otpVerified(_that);case OtpVerificationFailed():
return otpVerificationFailed(_that);case ResetPasswordLoading():
return resetPasswordLoading(_that);case ResetPasswordSuccess():
return resetPasswordSuccess(_that);case ResetPasswordFailed():
return resetPasswordFailed(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( Loading value)?  loading,TResult? Function( Success value)?  success,TResult? Function( Error value)?  failure,TResult? Function( OtpVerificationLoading value)?  otpVerificationLoading,TResult? Function( OtpVerified value)?  otpVerified,TResult? Function( OtpVerificationFailed value)?  otpVerificationFailed,TResult? Function( ResetPasswordLoading value)?  resetPasswordLoading,TResult? Function( ResetPasswordSuccess value)?  resetPasswordSuccess,TResult? Function( ResetPasswordFailed value)?  resetPasswordFailed,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case Loading() when loading != null:
return loading(_that);case Success() when success != null:
return success(_that);case Error() when failure != null:
return failure(_that);case OtpVerificationLoading() when otpVerificationLoading != null:
return otpVerificationLoading(_that);case OtpVerified() when otpVerified != null:
return otpVerified(_that);case OtpVerificationFailed() when otpVerificationFailed != null:
return otpVerificationFailed(_that);case ResetPasswordLoading() when resetPasswordLoading != null:
return resetPasswordLoading(_that);case ResetPasswordSuccess() when resetPasswordSuccess != null:
return resetPasswordSuccess(_that);case ResetPasswordFailed() when resetPasswordFailed != null:
return resetPasswordFailed(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String data)?  success,TResult Function( ApiErrorModel apiErrorModel)?  failure,TResult Function()?  otpVerificationLoading,TResult Function( String data)?  otpVerified,TResult Function( ApiErrorModel apiErrorModel)?  otpVerificationFailed,TResult Function()?  resetPasswordLoading,TResult Function( String data)?  resetPasswordSuccess,TResult Function( ApiErrorModel apiErrorModel)?  resetPasswordFailed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case Loading() when loading != null:
return loading();case Success() when success != null:
return success(_that.data);case Error() when failure != null:
return failure(_that.apiErrorModel);case OtpVerificationLoading() when otpVerificationLoading != null:
return otpVerificationLoading();case OtpVerified() when otpVerified != null:
return otpVerified(_that.data);case OtpVerificationFailed() when otpVerificationFailed != null:
return otpVerificationFailed(_that.apiErrorModel);case ResetPasswordLoading() when resetPasswordLoading != null:
return resetPasswordLoading();case ResetPasswordSuccess() when resetPasswordSuccess != null:
return resetPasswordSuccess(_that.data);case ResetPasswordFailed() when resetPasswordFailed != null:
return resetPasswordFailed(_that.apiErrorModel);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String data)  success,required TResult Function( ApiErrorModel apiErrorModel)  failure,required TResult Function()  otpVerificationLoading,required TResult Function( String data)  otpVerified,required TResult Function( ApiErrorModel apiErrorModel)  otpVerificationFailed,required TResult Function()  resetPasswordLoading,required TResult Function( String data)  resetPasswordSuccess,required TResult Function( ApiErrorModel apiErrorModel)  resetPasswordFailed,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case Loading():
return loading();case Success():
return success(_that.data);case Error():
return failure(_that.apiErrorModel);case OtpVerificationLoading():
return otpVerificationLoading();case OtpVerified():
return otpVerified(_that.data);case OtpVerificationFailed():
return otpVerificationFailed(_that.apiErrorModel);case ResetPasswordLoading():
return resetPasswordLoading();case ResetPasswordSuccess():
return resetPasswordSuccess(_that.data);case ResetPasswordFailed():
return resetPasswordFailed(_that.apiErrorModel);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String data)?  success,TResult? Function( ApiErrorModel apiErrorModel)?  failure,TResult? Function()?  otpVerificationLoading,TResult? Function( String data)?  otpVerified,TResult? Function( ApiErrorModel apiErrorModel)?  otpVerificationFailed,TResult? Function()?  resetPasswordLoading,TResult? Function( String data)?  resetPasswordSuccess,TResult? Function( ApiErrorModel apiErrorModel)?  resetPasswordFailed,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case Loading() when loading != null:
return loading();case Success() when success != null:
return success(_that.data);case Error() when failure != null:
return failure(_that.apiErrorModel);case OtpVerificationLoading() when otpVerificationLoading != null:
return otpVerificationLoading();case OtpVerified() when otpVerified != null:
return otpVerified(_that.data);case OtpVerificationFailed() when otpVerificationFailed != null:
return otpVerificationFailed(_that.apiErrorModel);case ResetPasswordLoading() when resetPasswordLoading != null:
return resetPasswordLoading();case ResetPasswordSuccess() when resetPasswordSuccess != null:
return resetPasswordSuccess(_that.data);case ResetPasswordFailed() when resetPasswordFailed != null:
return resetPasswordFailed(_that.apiErrorModel);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements ForgotPasswordState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState.initial()';
}


}




/// @nodoc


class Loading implements ForgotPasswordState {
  const Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState.loading()';
}


}




/// @nodoc


class Success implements ForgotPasswordState {
  const Success(this.data);
  

 final  String data;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SuccessCopyWith<Success> get copyWith => _$SuccessCopyWithImpl<Success>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Success&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'ForgotPasswordState.success(data: $data)';
}


}

/// @nodoc
abstract mixin class $SuccessCopyWith<$Res> implements $ForgotPasswordStateCopyWith<$Res> {
  factory $SuccessCopyWith(Success value, $Res Function(Success) _then) = _$SuccessCopyWithImpl;
@useResult
$Res call({
 String data
});




}
/// @nodoc
class _$SuccessCopyWithImpl<$Res>
    implements $SuccessCopyWith<$Res> {
  _$SuccessCopyWithImpl(this._self, this._then);

  final Success _self;
  final $Res Function(Success) _then;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(Success(
null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class Error implements ForgotPasswordState {
  const Error(this.apiErrorModel);
  

 final  ApiErrorModel apiErrorModel;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorCopyWith<Error> get copyWith => _$ErrorCopyWithImpl<Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Error&&(identical(other.apiErrorModel, apiErrorModel) || other.apiErrorModel == apiErrorModel));
}


@override
int get hashCode => Object.hash(runtimeType,apiErrorModel);

@override
String toString() {
  return 'ForgotPasswordState.failure(apiErrorModel: $apiErrorModel)';
}


}

/// @nodoc
abstract mixin class $ErrorCopyWith<$Res> implements $ForgotPasswordStateCopyWith<$Res> {
  factory $ErrorCopyWith(Error value, $Res Function(Error) _then) = _$ErrorCopyWithImpl;
@useResult
$Res call({
 ApiErrorModel apiErrorModel
});




}
/// @nodoc
class _$ErrorCopyWithImpl<$Res>
    implements $ErrorCopyWith<$Res> {
  _$ErrorCopyWithImpl(this._self, this._then);

  final Error _self;
  final $Res Function(Error) _then;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? apiErrorModel = null,}) {
  return _then(Error(
null == apiErrorModel ? _self.apiErrorModel : apiErrorModel // ignore: cast_nullable_to_non_nullable
as ApiErrorModel,
  ));
}


}

/// @nodoc


class OtpVerificationLoading implements ForgotPasswordState {
  const OtpVerificationLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpVerificationLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState.otpVerificationLoading()';
}


}




/// @nodoc


class OtpVerified implements ForgotPasswordState {
  const OtpVerified(this.data);
  

 final  String data;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpVerifiedCopyWith<OtpVerified> get copyWith => _$OtpVerifiedCopyWithImpl<OtpVerified>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpVerified&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'ForgotPasswordState.otpVerified(data: $data)';
}


}

/// @nodoc
abstract mixin class $OtpVerifiedCopyWith<$Res> implements $ForgotPasswordStateCopyWith<$Res> {
  factory $OtpVerifiedCopyWith(OtpVerified value, $Res Function(OtpVerified) _then) = _$OtpVerifiedCopyWithImpl;
@useResult
$Res call({
 String data
});




}
/// @nodoc
class _$OtpVerifiedCopyWithImpl<$Res>
    implements $OtpVerifiedCopyWith<$Res> {
  _$OtpVerifiedCopyWithImpl(this._self, this._then);

  final OtpVerified _self;
  final $Res Function(OtpVerified) _then;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(OtpVerified(
null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class OtpVerificationFailed implements ForgotPasswordState {
  const OtpVerificationFailed(this.apiErrorModel);
  

 final  ApiErrorModel apiErrorModel;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpVerificationFailedCopyWith<OtpVerificationFailed> get copyWith => _$OtpVerificationFailedCopyWithImpl<OtpVerificationFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpVerificationFailed&&(identical(other.apiErrorModel, apiErrorModel) || other.apiErrorModel == apiErrorModel));
}


@override
int get hashCode => Object.hash(runtimeType,apiErrorModel);

@override
String toString() {
  return 'ForgotPasswordState.otpVerificationFailed(apiErrorModel: $apiErrorModel)';
}


}

/// @nodoc
abstract mixin class $OtpVerificationFailedCopyWith<$Res> implements $ForgotPasswordStateCopyWith<$Res> {
  factory $OtpVerificationFailedCopyWith(OtpVerificationFailed value, $Res Function(OtpVerificationFailed) _then) = _$OtpVerificationFailedCopyWithImpl;
@useResult
$Res call({
 ApiErrorModel apiErrorModel
});




}
/// @nodoc
class _$OtpVerificationFailedCopyWithImpl<$Res>
    implements $OtpVerificationFailedCopyWith<$Res> {
  _$OtpVerificationFailedCopyWithImpl(this._self, this._then);

  final OtpVerificationFailed _self;
  final $Res Function(OtpVerificationFailed) _then;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? apiErrorModel = null,}) {
  return _then(OtpVerificationFailed(
null == apiErrorModel ? _self.apiErrorModel : apiErrorModel // ignore: cast_nullable_to_non_nullable
as ApiErrorModel,
  ));
}


}

/// @nodoc


class ResetPasswordLoading implements ForgotPasswordState {
  const ResetPasswordLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPasswordLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordState.resetPasswordLoading()';
}


}




/// @nodoc


class ResetPasswordSuccess implements ForgotPasswordState {
  const ResetPasswordSuccess(this.data);
  

 final  String data;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResetPasswordSuccessCopyWith<ResetPasswordSuccess> get copyWith => _$ResetPasswordSuccessCopyWithImpl<ResetPasswordSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPasswordSuccess&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'ForgotPasswordState.resetPasswordSuccess(data: $data)';
}


}

/// @nodoc
abstract mixin class $ResetPasswordSuccessCopyWith<$Res> implements $ForgotPasswordStateCopyWith<$Res> {
  factory $ResetPasswordSuccessCopyWith(ResetPasswordSuccess value, $Res Function(ResetPasswordSuccess) _then) = _$ResetPasswordSuccessCopyWithImpl;
@useResult
$Res call({
 String data
});




}
/// @nodoc
class _$ResetPasswordSuccessCopyWithImpl<$Res>
    implements $ResetPasswordSuccessCopyWith<$Res> {
  _$ResetPasswordSuccessCopyWithImpl(this._self, this._then);

  final ResetPasswordSuccess _self;
  final $Res Function(ResetPasswordSuccess) _then;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(ResetPasswordSuccess(
null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ResetPasswordFailed implements ForgotPasswordState {
  const ResetPasswordFailed(this.apiErrorModel);
  

 final  ApiErrorModel apiErrorModel;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResetPasswordFailedCopyWith<ResetPasswordFailed> get copyWith => _$ResetPasswordFailedCopyWithImpl<ResetPasswordFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPasswordFailed&&(identical(other.apiErrorModel, apiErrorModel) || other.apiErrorModel == apiErrorModel));
}


@override
int get hashCode => Object.hash(runtimeType,apiErrorModel);

@override
String toString() {
  return 'ForgotPasswordState.resetPasswordFailed(apiErrorModel: $apiErrorModel)';
}


}

/// @nodoc
abstract mixin class $ResetPasswordFailedCopyWith<$Res> implements $ForgotPasswordStateCopyWith<$Res> {
  factory $ResetPasswordFailedCopyWith(ResetPasswordFailed value, $Res Function(ResetPasswordFailed) _then) = _$ResetPasswordFailedCopyWithImpl;
@useResult
$Res call({
 ApiErrorModel apiErrorModel
});




}
/// @nodoc
class _$ResetPasswordFailedCopyWithImpl<$Res>
    implements $ResetPasswordFailedCopyWith<$Res> {
  _$ResetPasswordFailedCopyWithImpl(this._self, this._then);

  final ResetPasswordFailed _self;
  final $Res Function(ResetPasswordFailed) _then;

/// Create a copy of ForgotPasswordState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? apiErrorModel = null,}) {
  return _then(ResetPasswordFailed(
null == apiErrorModel ? _self.apiErrorModel : apiErrorModel // ignore: cast_nullable_to_non_nullable
as ApiErrorModel,
  ));
}


}

// dart format on
