// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PostState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PostState()';
}


}

/// @nodoc
class $PostStateCopyWith<$Res>  {
$PostStateCopyWith(PostState _, $Res Function(PostState) __);
}


/// Adds pattern-matching-related methods to [PostState].
extension PostStatePatterns on PostState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Initial value)?  initial,TResult Function( LikeLoading value)?  likeLoading,TResult Function( LikeSuccess value)?  likeSuccess,TResult Function( LikeError value)?  likeError,TResult Function( ShareSuccess value)?  shareSuccess,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Initial() when initial != null:
return initial(_that);case LikeLoading() when likeLoading != null:
return likeLoading(_that);case LikeSuccess() when likeSuccess != null:
return likeSuccess(_that);case LikeError() when likeError != null:
return likeError(_that);case ShareSuccess() when shareSuccess != null:
return shareSuccess(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Initial value)  initial,required TResult Function( LikeLoading value)  likeLoading,required TResult Function( LikeSuccess value)  likeSuccess,required TResult Function( LikeError value)  likeError,required TResult Function( ShareSuccess value)  shareSuccess,}){
final _that = this;
switch (_that) {
case Initial():
return initial(_that);case LikeLoading():
return likeLoading(_that);case LikeSuccess():
return likeSuccess(_that);case LikeError():
return likeError(_that);case ShareSuccess():
return shareSuccess(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Initial value)?  initial,TResult? Function( LikeLoading value)?  likeLoading,TResult? Function( LikeSuccess value)?  likeSuccess,TResult? Function( LikeError value)?  likeError,TResult? Function( ShareSuccess value)?  shareSuccess,}){
final _that = this;
switch (_that) {
case Initial() when initial != null:
return initial(_that);case LikeLoading() when likeLoading != null:
return likeLoading(_that);case LikeSuccess() when likeSuccess != null:
return likeSuccess(_that);case LikeError() when likeError != null:
return likeError(_that);case ShareSuccess() when shareSuccess != null:
return shareSuccess(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( String postId)?  likeLoading,TResult Function( String postId,  bool isLiked,  int likeCount)?  likeSuccess,TResult Function( String message)?  likeError,TResult Function()?  shareSuccess,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Initial() when initial != null:
return initial();case LikeLoading() when likeLoading != null:
return likeLoading(_that.postId);case LikeSuccess() when likeSuccess != null:
return likeSuccess(_that.postId,_that.isLiked,_that.likeCount);case LikeError() when likeError != null:
return likeError(_that.message);case ShareSuccess() when shareSuccess != null:
return shareSuccess();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( String postId)  likeLoading,required TResult Function( String postId,  bool isLiked,  int likeCount)  likeSuccess,required TResult Function( String message)  likeError,required TResult Function()  shareSuccess,}) {final _that = this;
switch (_that) {
case Initial():
return initial();case LikeLoading():
return likeLoading(_that.postId);case LikeSuccess():
return likeSuccess(_that.postId,_that.isLiked,_that.likeCount);case LikeError():
return likeError(_that.message);case ShareSuccess():
return shareSuccess();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( String postId)?  likeLoading,TResult? Function( String postId,  bool isLiked,  int likeCount)?  likeSuccess,TResult? Function( String message)?  likeError,TResult? Function()?  shareSuccess,}) {final _that = this;
switch (_that) {
case Initial() when initial != null:
return initial();case LikeLoading() when likeLoading != null:
return likeLoading(_that.postId);case LikeSuccess() when likeSuccess != null:
return likeSuccess(_that.postId,_that.isLiked,_that.likeCount);case LikeError() when likeError != null:
return likeError(_that.message);case ShareSuccess() when shareSuccess != null:
return shareSuccess();case _:
  return null;

}
}

}

/// @nodoc


class Initial implements PostState {
  const Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PostState.initial()';
}


}




/// @nodoc


class LikeLoading implements PostState {
  const LikeLoading(this.postId);
  

 final  String postId;

/// Create a copy of PostState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LikeLoadingCopyWith<LikeLoading> get copyWith => _$LikeLoadingCopyWithImpl<LikeLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LikeLoading&&(identical(other.postId, postId) || other.postId == postId));
}


@override
int get hashCode => Object.hash(runtimeType,postId);

@override
String toString() {
  return 'PostState.likeLoading(postId: $postId)';
}


}

/// @nodoc
abstract mixin class $LikeLoadingCopyWith<$Res> implements $PostStateCopyWith<$Res> {
  factory $LikeLoadingCopyWith(LikeLoading value, $Res Function(LikeLoading) _then) = _$LikeLoadingCopyWithImpl;
@useResult
$Res call({
 String postId
});




}
/// @nodoc
class _$LikeLoadingCopyWithImpl<$Res>
    implements $LikeLoadingCopyWith<$Res> {
  _$LikeLoadingCopyWithImpl(this._self, this._then);

  final LikeLoading _self;
  final $Res Function(LikeLoading) _then;

/// Create a copy of PostState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? postId = null,}) {
  return _then(LikeLoading(
null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LikeSuccess implements PostState {
  const LikeSuccess(this.postId, this.isLiked, this.likeCount);
  

 final  String postId;
 final  bool isLiked;
 final  int likeCount;

/// Create a copy of PostState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LikeSuccessCopyWith<LikeSuccess> get copyWith => _$LikeSuccessCopyWithImpl<LikeSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LikeSuccess&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount));
}


@override
int get hashCode => Object.hash(runtimeType,postId,isLiked,likeCount);

@override
String toString() {
  return 'PostState.likeSuccess(postId: $postId, isLiked: $isLiked, likeCount: $likeCount)';
}


}

/// @nodoc
abstract mixin class $LikeSuccessCopyWith<$Res> implements $PostStateCopyWith<$Res> {
  factory $LikeSuccessCopyWith(LikeSuccess value, $Res Function(LikeSuccess) _then) = _$LikeSuccessCopyWithImpl;
@useResult
$Res call({
 String postId, bool isLiked, int likeCount
});




}
/// @nodoc
class _$LikeSuccessCopyWithImpl<$Res>
    implements $LikeSuccessCopyWith<$Res> {
  _$LikeSuccessCopyWithImpl(this._self, this._then);

  final LikeSuccess _self;
  final $Res Function(LikeSuccess) _then;

/// Create a copy of PostState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? postId = null,Object? isLiked = null,Object? likeCount = null,}) {
  return _then(LikeSuccess(
null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class LikeError implements PostState {
  const LikeError(this.message);
  

 final  String message;

/// Create a copy of PostState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LikeErrorCopyWith<LikeError> get copyWith => _$LikeErrorCopyWithImpl<LikeError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LikeError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'PostState.likeError(message: $message)';
}


}

/// @nodoc
abstract mixin class $LikeErrorCopyWith<$Res> implements $PostStateCopyWith<$Res> {
  factory $LikeErrorCopyWith(LikeError value, $Res Function(LikeError) _then) = _$LikeErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$LikeErrorCopyWithImpl<$Res>
    implements $LikeErrorCopyWith<$Res> {
  _$LikeErrorCopyWithImpl(this._self, this._then);

  final LikeError _self;
  final $Res Function(LikeError) _then;

/// Create a copy of PostState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(LikeError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ShareSuccess implements PostState {
  const ShareSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShareSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PostState.shareSuccess()';
}


}




// dart format on
