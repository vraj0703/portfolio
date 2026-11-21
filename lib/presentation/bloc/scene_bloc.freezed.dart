// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scene_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SceneEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SceneEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent()';
}


}

/// @nodoc
class $SceneEventCopyWith<$Res>  {
$SceneEventCopyWith(SceneEvent _, $Res Function(SceneEvent) __);
}


/// Adds pattern-matching-related methods to [SceneEvent].
extension SceneEventPatterns on SceneEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Initialize value)?  initialize,TResult Function( LoadingProgressed value)?  loadingProgressed,TResult Function( LogoEntranceCompleted value)?  logoEntranceCompleted,TResult Function( Tapped value)?  tapped,TResult Function( LogoHoverLapsed value)?  logoHoverLapsed,TResult Function( LogoExitCompleted value)?  logoExitCompleted,TResult Function( TitleEntranceCompleted value)?  titleEntranceCompleted,TResult Function( AdvanceRequested value)?  advanceRequested,TResult Function( BoldTextCompleted value)?  boldTextCompleted,TResult Function( GalleryExited value)?  galleryExited,TResult Function( GalleryExitRequested value)?  galleryExitRequested,TResult Function( ContactRequested value)?  contactRequested,TResult Function( GalleryRequested value)?  galleryRequested,TResult Function( HomeRequested value)?  homeRequested,TResult Function( FlagsChanged value)?  flagsChanged,TResult Function( MuteToggled value)?  muteToggled,TResult Function( RadioToggled value)?  radioToggled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize(_that);case LoadingProgressed() when loadingProgressed != null:
return loadingProgressed(_that);case LogoEntranceCompleted() when logoEntranceCompleted != null:
return logoEntranceCompleted(_that);case Tapped() when tapped != null:
return tapped(_that);case LogoHoverLapsed() when logoHoverLapsed != null:
return logoHoverLapsed(_that);case LogoExitCompleted() when logoExitCompleted != null:
return logoExitCompleted(_that);case TitleEntranceCompleted() when titleEntranceCompleted != null:
return titleEntranceCompleted(_that);case AdvanceRequested() when advanceRequested != null:
return advanceRequested(_that);case BoldTextCompleted() when boldTextCompleted != null:
return boldTextCompleted(_that);case GalleryExited() when galleryExited != null:
return galleryExited(_that);case GalleryExitRequested() when galleryExitRequested != null:
return galleryExitRequested(_that);case ContactRequested() when contactRequested != null:
return contactRequested(_that);case GalleryRequested() when galleryRequested != null:
return galleryRequested(_that);case HomeRequested() when homeRequested != null:
return homeRequested(_that);case FlagsChanged() when flagsChanged != null:
return flagsChanged(_that);case MuteToggled() when muteToggled != null:
return muteToggled(_that);case RadioToggled() when radioToggled != null:
return radioToggled(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Initialize value)  initialize,required TResult Function( LoadingProgressed value)  loadingProgressed,required TResult Function( LogoEntranceCompleted value)  logoEntranceCompleted,required TResult Function( Tapped value)  tapped,required TResult Function( LogoHoverLapsed value)  logoHoverLapsed,required TResult Function( LogoExitCompleted value)  logoExitCompleted,required TResult Function( TitleEntranceCompleted value)  titleEntranceCompleted,required TResult Function( AdvanceRequested value)  advanceRequested,required TResult Function( BoldTextCompleted value)  boldTextCompleted,required TResult Function( GalleryExited value)  galleryExited,required TResult Function( GalleryExitRequested value)  galleryExitRequested,required TResult Function( ContactRequested value)  contactRequested,required TResult Function( GalleryRequested value)  galleryRequested,required TResult Function( HomeRequested value)  homeRequested,required TResult Function( FlagsChanged value)  flagsChanged,required TResult Function( MuteToggled value)  muteToggled,required TResult Function( RadioToggled value)  radioToggled,}){
final _that = this;
switch (_that) {
case Initialize():
return initialize(_that);case LoadingProgressed():
return loadingProgressed(_that);case LogoEntranceCompleted():
return logoEntranceCompleted(_that);case Tapped():
return tapped(_that);case LogoHoverLapsed():
return logoHoverLapsed(_that);case LogoExitCompleted():
return logoExitCompleted(_that);case TitleEntranceCompleted():
return titleEntranceCompleted(_that);case AdvanceRequested():
return advanceRequested(_that);case BoldTextCompleted():
return boldTextCompleted(_that);case GalleryExited():
return galleryExited(_that);case GalleryExitRequested():
return galleryExitRequested(_that);case ContactRequested():
return contactRequested(_that);case GalleryRequested():
return galleryRequested(_that);case HomeRequested():
return homeRequested(_that);case FlagsChanged():
return flagsChanged(_that);case MuteToggled():
return muteToggled(_that);case RadioToggled():
return radioToggled(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Initialize value)?  initialize,TResult? Function( LoadingProgressed value)?  loadingProgressed,TResult? Function( LogoEntranceCompleted value)?  logoEntranceCompleted,TResult? Function( Tapped value)?  tapped,TResult? Function( LogoHoverLapsed value)?  logoHoverLapsed,TResult? Function( LogoExitCompleted value)?  logoExitCompleted,TResult? Function( TitleEntranceCompleted value)?  titleEntranceCompleted,TResult? Function( AdvanceRequested value)?  advanceRequested,TResult? Function( BoldTextCompleted value)?  boldTextCompleted,TResult? Function( GalleryExited value)?  galleryExited,TResult? Function( GalleryExitRequested value)?  galleryExitRequested,TResult? Function( ContactRequested value)?  contactRequested,TResult? Function( GalleryRequested value)?  galleryRequested,TResult? Function( HomeRequested value)?  homeRequested,TResult? Function( FlagsChanged value)?  flagsChanged,TResult? Function( MuteToggled value)?  muteToggled,TResult? Function( RadioToggled value)?  radioToggled,}){
final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize(_that);case LoadingProgressed() when loadingProgressed != null:
return loadingProgressed(_that);case LogoEntranceCompleted() when logoEntranceCompleted != null:
return logoEntranceCompleted(_that);case Tapped() when tapped != null:
return tapped(_that);case LogoHoverLapsed() when logoHoverLapsed != null:
return logoHoverLapsed(_that);case LogoExitCompleted() when logoExitCompleted != null:
return logoExitCompleted(_that);case TitleEntranceCompleted() when titleEntranceCompleted != null:
return titleEntranceCompleted(_that);case AdvanceRequested() when advanceRequested != null:
return advanceRequested(_that);case BoldTextCompleted() when boldTextCompleted != null:
return boldTextCompleted(_that);case GalleryExited() when galleryExited != null:
return galleryExited(_that);case GalleryExitRequested() when galleryExitRequested != null:
return galleryExitRequested(_that);case ContactRequested() when contactRequested != null:
return contactRequested(_that);case GalleryRequested() when galleryRequested != null:
return galleryRequested(_that);case HomeRequested() when homeRequested != null:
return homeRequested(_that);case FlagsChanged() when flagsChanged != null:
return flagsChanged(_that);case MuteToggled() when muteToggled != null:
return muteToggled(_that);case RadioToggled() when radioToggled != null:
return radioToggled(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initialize,TResult Function( LoadingPhase phase,  double value)?  loadingProgressed,TResult Function()?  logoEntranceCompleted,TResult Function( bool touch)?  tapped,TResult Function()?  logoHoverLapsed,TResult Function()?  logoExitCompleted,TResult Function()?  titleEntranceCompleted,TResult Function()?  advanceRequested,TResult Function()?  boldTextCompleted,TResult Function()?  galleryExited,TResult Function( GalleryExit to)?  galleryExitRequested,TResult Function()?  contactRequested,TResult Function()?  galleryRequested,TResult Function()?  homeRequested,TResult Function( ButtonFlags flags)?  flagsChanged,TResult Function()?  muteToggled,TResult Function()?  radioToggled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize();case LoadingProgressed() when loadingProgressed != null:
return loadingProgressed(_that.phase,_that.value);case LogoEntranceCompleted() when logoEntranceCompleted != null:
return logoEntranceCompleted();case Tapped() when tapped != null:
return tapped(_that.touch);case LogoHoverLapsed() when logoHoverLapsed != null:
return logoHoverLapsed();case LogoExitCompleted() when logoExitCompleted != null:
return logoExitCompleted();case TitleEntranceCompleted() when titleEntranceCompleted != null:
return titleEntranceCompleted();case AdvanceRequested() when advanceRequested != null:
return advanceRequested();case BoldTextCompleted() when boldTextCompleted != null:
return boldTextCompleted();case GalleryExited() when galleryExited != null:
return galleryExited();case GalleryExitRequested() when galleryExitRequested != null:
return galleryExitRequested(_that.to);case ContactRequested() when contactRequested != null:
return contactRequested();case GalleryRequested() when galleryRequested != null:
return galleryRequested();case HomeRequested() when homeRequested != null:
return homeRequested();case FlagsChanged() when flagsChanged != null:
return flagsChanged(_that.flags);case MuteToggled() when muteToggled != null:
return muteToggled();case RadioToggled() when radioToggled != null:
return radioToggled();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initialize,required TResult Function( LoadingPhase phase,  double value)  loadingProgressed,required TResult Function()  logoEntranceCompleted,required TResult Function( bool touch)  tapped,required TResult Function()  logoHoverLapsed,required TResult Function()  logoExitCompleted,required TResult Function()  titleEntranceCompleted,required TResult Function()  advanceRequested,required TResult Function()  boldTextCompleted,required TResult Function()  galleryExited,required TResult Function( GalleryExit to)  galleryExitRequested,required TResult Function()  contactRequested,required TResult Function()  galleryRequested,required TResult Function()  homeRequested,required TResult Function( ButtonFlags flags)  flagsChanged,required TResult Function()  muteToggled,required TResult Function()  radioToggled,}) {final _that = this;
switch (_that) {
case Initialize():
return initialize();case LoadingProgressed():
return loadingProgressed(_that.phase,_that.value);case LogoEntranceCompleted():
return logoEntranceCompleted();case Tapped():
return tapped(_that.touch);case LogoHoverLapsed():
return logoHoverLapsed();case LogoExitCompleted():
return logoExitCompleted();case TitleEntranceCompleted():
return titleEntranceCompleted();case AdvanceRequested():
return advanceRequested();case BoldTextCompleted():
return boldTextCompleted();case GalleryExited():
return galleryExited();case GalleryExitRequested():
return galleryExitRequested(_that.to);case ContactRequested():
return contactRequested();case GalleryRequested():
return galleryRequested();case HomeRequested():
return homeRequested();case FlagsChanged():
return flagsChanged(_that.flags);case MuteToggled():
return muteToggled();case RadioToggled():
return radioToggled();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initialize,TResult? Function( LoadingPhase phase,  double value)?  loadingProgressed,TResult? Function()?  logoEntranceCompleted,TResult? Function( bool touch)?  tapped,TResult? Function()?  logoHoverLapsed,TResult? Function()?  logoExitCompleted,TResult? Function()?  titleEntranceCompleted,TResult? Function()?  advanceRequested,TResult? Function()?  boldTextCompleted,TResult? Function()?  galleryExited,TResult? Function( GalleryExit to)?  galleryExitRequested,TResult? Function()?  contactRequested,TResult? Function()?  galleryRequested,TResult? Function()?  homeRequested,TResult? Function( ButtonFlags flags)?  flagsChanged,TResult? Function()?  muteToggled,TResult? Function()?  radioToggled,}) {final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize();case LoadingProgressed() when loadingProgressed != null:
return loadingProgressed(_that.phase,_that.value);case LogoEntranceCompleted() when logoEntranceCompleted != null:
return logoEntranceCompleted();case Tapped() when tapped != null:
return tapped(_that.touch);case LogoHoverLapsed() when logoHoverLapsed != null:
return logoHoverLapsed();case LogoExitCompleted() when logoExitCompleted != null:
return logoExitCompleted();case TitleEntranceCompleted() when titleEntranceCompleted != null:
return titleEntranceCompleted();case AdvanceRequested() when advanceRequested != null:
return advanceRequested();case BoldTextCompleted() when boldTextCompleted != null:
return boldTextCompleted();case GalleryExited() when galleryExited != null:
return galleryExited();case GalleryExitRequested() when galleryExitRequested != null:
return galleryExitRequested(_that.to);case ContactRequested() when contactRequested != null:
return contactRequested();case GalleryRequested() when galleryRequested != null:
return galleryRequested();case HomeRequested() when homeRequested != null:
return homeRequested();case FlagsChanged() when flagsChanged != null:
return flagsChanged(_that.flags);case MuteToggled() when muteToggled != null:
return muteToggled();case RadioToggled() when radioToggled != null:
return radioToggled();case _:
  return null;

}
}

}

/// @nodoc


class Initialize implements SceneEvent {
  const Initialize();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Initialize);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.initialize()';
}


}




/// @nodoc


class LoadingProgressed implements SceneEvent {
  const LoadingProgressed({required this.phase, required this.value});
  

 final  LoadingPhase phase;
 final  double value;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadingProgressedCopyWith<LoadingProgressed> get copyWith => _$LoadingProgressedCopyWithImpl<LoadingProgressed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadingProgressed&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,phase,value);

@override
String toString() {
  return 'SceneEvent.loadingProgressed(phase: $phase, value: $value)';
}


}

/// @nodoc
abstract mixin class $LoadingProgressedCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $LoadingProgressedCopyWith(LoadingProgressed value, $Res Function(LoadingProgressed) _then) = _$LoadingProgressedCopyWithImpl;
@useResult
$Res call({
 LoadingPhase phase, double value
});




}
/// @nodoc
class _$LoadingProgressedCopyWithImpl<$Res>
    implements $LoadingProgressedCopyWith<$Res> {
  _$LoadingProgressedCopyWithImpl(this._self, this._then);

  final LoadingProgressed _self;
  final $Res Function(LoadingProgressed) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? value = null,}) {
  return _then(LoadingProgressed(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LoadingPhase,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class LogoEntranceCompleted implements SceneEvent {
  const LogoEntranceCompleted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoEntranceCompleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.logoEntranceCompleted()';
}


}




/// @nodoc


class Tapped implements SceneEvent {
  const Tapped({this.touch = false});
  

@JsonKey() final  bool touch;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TappedCopyWith<Tapped> get copyWith => _$TappedCopyWithImpl<Tapped>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tapped&&(identical(other.touch, touch) || other.touch == touch));
}


@override
int get hashCode => Object.hash(runtimeType,touch);

@override
String toString() {
  return 'SceneEvent.tapped(touch: $touch)';
}


}

/// @nodoc
abstract mixin class $TappedCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $TappedCopyWith(Tapped value, $Res Function(Tapped) _then) = _$TappedCopyWithImpl;
@useResult
$Res call({
 bool touch
});




}
/// @nodoc
class _$TappedCopyWithImpl<$Res>
    implements $TappedCopyWith<$Res> {
  _$TappedCopyWithImpl(this._self, this._then);

  final Tapped _self;
  final $Res Function(Tapped) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? touch = null,}) {
  return _then(Tapped(
touch: null == touch ? _self.touch : touch // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class LogoHoverLapsed implements SceneEvent {
  const LogoHoverLapsed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoHoverLapsed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.logoHoverLapsed()';
}


}




/// @nodoc


class LogoExitCompleted implements SceneEvent {
  const LogoExitCompleted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoExitCompleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.logoExitCompleted()';
}


}




/// @nodoc


class TitleEntranceCompleted implements SceneEvent {
  const TitleEntranceCompleted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TitleEntranceCompleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.titleEntranceCompleted()';
}


}




/// @nodoc


class AdvanceRequested implements SceneEvent {
  const AdvanceRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdvanceRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.advanceRequested()';
}


}




/// @nodoc


class BoldTextCompleted implements SceneEvent {
  const BoldTextCompleted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoldTextCompleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.boldTextCompleted()';
}


}




/// @nodoc


class GalleryExited implements SceneEvent {
  const GalleryExited();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryExited);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.galleryExited()';
}


}




/// @nodoc


class GalleryExitRequested implements SceneEvent {
  const GalleryExitRequested({required this.to});
  

 final  GalleryExit to;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GalleryExitRequestedCopyWith<GalleryExitRequested> get copyWith => _$GalleryExitRequestedCopyWithImpl<GalleryExitRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryExitRequested&&(identical(other.to, to) || other.to == to));
}


@override
int get hashCode => Object.hash(runtimeType,to);

@override
String toString() {
  return 'SceneEvent.galleryExitRequested(to: $to)';
}


}

/// @nodoc
abstract mixin class $GalleryExitRequestedCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $GalleryExitRequestedCopyWith(GalleryExitRequested value, $Res Function(GalleryExitRequested) _then) = _$GalleryExitRequestedCopyWithImpl;
@useResult
$Res call({
 GalleryExit to
});




}
/// @nodoc
class _$GalleryExitRequestedCopyWithImpl<$Res>
    implements $GalleryExitRequestedCopyWith<$Res> {
  _$GalleryExitRequestedCopyWithImpl(this._self, this._then);

  final GalleryExitRequested _self;
  final $Res Function(GalleryExitRequested) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? to = null,}) {
  return _then(GalleryExitRequested(
to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as GalleryExit,
  ));
}


}

/// @nodoc


class ContactRequested implements SceneEvent {
  const ContactRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContactRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.contactRequested()';
}


}




/// @nodoc


class GalleryRequested implements SceneEvent {
  const GalleryRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.galleryRequested()';
}


}




/// @nodoc


class HomeRequested implements SceneEvent {
  const HomeRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.homeRequested()';
}


}




/// @nodoc


class FlagsChanged implements SceneEvent {
  const FlagsChanged({required this.flags});
  

 final  ButtonFlags flags;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlagsChangedCopyWith<FlagsChanged> get copyWith => _$FlagsChangedCopyWithImpl<FlagsChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FlagsChanged&&(identical(other.flags, flags) || other.flags == flags));
}


@override
int get hashCode => Object.hash(runtimeType,flags);

@override
String toString() {
  return 'SceneEvent.flagsChanged(flags: $flags)';
}


}

/// @nodoc
abstract mixin class $FlagsChangedCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $FlagsChangedCopyWith(FlagsChanged value, $Res Function(FlagsChanged) _then) = _$FlagsChangedCopyWithImpl;
@useResult
$Res call({
 ButtonFlags flags
});




}
/// @nodoc
class _$FlagsChangedCopyWithImpl<$Res>
    implements $FlagsChangedCopyWith<$Res> {
  _$FlagsChangedCopyWithImpl(this._self, this._then);

  final FlagsChanged _self;
  final $Res Function(FlagsChanged) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? flags = null,}) {
  return _then(FlagsChanged(
flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as ButtonFlags,
  ));
}


}

/// @nodoc


class MuteToggled implements SceneEvent {
  const MuteToggled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MuteToggled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.muteToggled()';
}


}




/// @nodoc


class RadioToggled implements SceneEvent {
  const RadioToggled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadioToggled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.radioToggled()';
}


}




/// @nodoc
mixin _$SceneState {

 ButtonFlags get flags; bool get muted;
/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SceneStateCopyWith<SceneState> get copyWith => _$SceneStateCopyWithImpl<SceneState>(this as SceneState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SceneState&&(identical(other.flags, flags) || other.flags == flags)&&(identical(other.muted, muted) || other.muted == muted));
}


@override
int get hashCode => Object.hash(runtimeType,flags,muted);

@override
String toString() {
  return 'SceneState(flags: $flags, muted: $muted)';
}


}

/// @nodoc
abstract mixin class $SceneStateCopyWith<$Res>  {
  factory $SceneStateCopyWith(SceneState value, $Res Function(SceneState) _then) = _$SceneStateCopyWithImpl;
@useResult
$Res call({
 ButtonFlags flags, bool muted
});




}
/// @nodoc
class _$SceneStateCopyWithImpl<$Res>
    implements $SceneStateCopyWith<$Res> {
  _$SceneStateCopyWithImpl(this._self, this._then);

  final SceneState _self;
  final $Res Function(SceneState) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? flags = null,Object? muted = null,}) {
  return _then(_self.copyWith(
flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as ButtonFlags,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SceneState].
extension SceneStatePatterns on SceneState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Loading value)?  loading,TResult Function( Logo value)?  logo,TResult Function( LogoOverlayRemoving value)?  logoOverlayRemoving,TResult Function( TitleLoading value)?  titleLoading,TResult Function( Title value)?  title,TResult Function( Active value)?  active,TResult Function( Gallery value)?  gallery,TResult Function( Contact value)?  contact,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that);case Logo() when logo != null:
return logo(_that);case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving(_that);case TitleLoading() when titleLoading != null:
return titleLoading(_that);case Title() when title != null:
return title(_that);case Active() when active != null:
return active(_that);case Gallery() when gallery != null:
return gallery(_that);case Contact() when contact != null:
return contact(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Loading value)  loading,required TResult Function( Logo value)  logo,required TResult Function( LogoOverlayRemoving value)  logoOverlayRemoving,required TResult Function( TitleLoading value)  titleLoading,required TResult Function( Title value)  title,required TResult Function( Active value)  active,required TResult Function( Gallery value)  gallery,required TResult Function( Contact value)  contact,}){
final _that = this;
switch (_that) {
case Loading():
return loading(_that);case Logo():
return logo(_that);case LogoOverlayRemoving():
return logoOverlayRemoving(_that);case TitleLoading():
return titleLoading(_that);case Title():
return title(_that);case Active():
return active(_that);case Gallery():
return gallery(_that);case Contact():
return contact(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Loading value)?  loading,TResult? Function( Logo value)?  logo,TResult? Function( LogoOverlayRemoving value)?  logoOverlayRemoving,TResult? Function( TitleLoading value)?  titleLoading,TResult? Function( Title value)?  title,TResult? Function( Active value)?  active,TResult? Function( Gallery value)?  gallery,TResult? Function( Contact value)?  contact,}){
final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that);case Logo() when logo != null:
return logo(_that);case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving(_that);case TitleLoading() when titleLoading != null:
return titleLoading(_that);case Title() when title != null:
return title(_that);case Active() when active != null:
return active(_that);case Gallery() when gallery != null:
return gallery(_that);case Contact() when contact != null:
return contact(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( LoadingProgress progress,  ButtonFlags flags,  bool muted)?  loading,TResult Function( bool isInteractive,  bool touchHovered,  ButtonFlags flags,  bool muted)?  logo,TResult Function( ButtonFlags flags,  bool muted)?  logoOverlayRemoving,TResult Function( ButtonFlags flags,  bool muted)?  titleLoading,TResult Function( ButtonFlags flags,  bool muted)?  title,TResult Function( double uiOpacity,  bool isArrowVisible,  ButtonFlags flags,  bool muted)?  active,TResult Function( ButtonFlags flags,  bool muted,  GalleryExit? leavingFor)?  gallery,TResult Function( ButtonFlags flags,  bool muted)?  contact,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that.progress,_that.flags,_that.muted);case Logo() when logo != null:
return logo(_that.isInteractive,_that.touchHovered,_that.flags,_that.muted);case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving(_that.flags,_that.muted);case TitleLoading() when titleLoading != null:
return titleLoading(_that.flags,_that.muted);case Title() when title != null:
return title(_that.flags,_that.muted);case Active() when active != null:
return active(_that.uiOpacity,_that.isArrowVisible,_that.flags,_that.muted);case Gallery() when gallery != null:
return gallery(_that.flags,_that.muted,_that.leavingFor);case Contact() when contact != null:
return contact(_that.flags,_that.muted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( LoadingProgress progress,  ButtonFlags flags,  bool muted)  loading,required TResult Function( bool isInteractive,  bool touchHovered,  ButtonFlags flags,  bool muted)  logo,required TResult Function( ButtonFlags flags,  bool muted)  logoOverlayRemoving,required TResult Function( ButtonFlags flags,  bool muted)  titleLoading,required TResult Function( ButtonFlags flags,  bool muted)  title,required TResult Function( double uiOpacity,  bool isArrowVisible,  ButtonFlags flags,  bool muted)  active,required TResult Function( ButtonFlags flags,  bool muted,  GalleryExit? leavingFor)  gallery,required TResult Function( ButtonFlags flags,  bool muted)  contact,}) {final _that = this;
switch (_that) {
case Loading():
return loading(_that.progress,_that.flags,_that.muted);case Logo():
return logo(_that.isInteractive,_that.touchHovered,_that.flags,_that.muted);case LogoOverlayRemoving():
return logoOverlayRemoving(_that.flags,_that.muted);case TitleLoading():
return titleLoading(_that.flags,_that.muted);case Title():
return title(_that.flags,_that.muted);case Active():
return active(_that.uiOpacity,_that.isArrowVisible,_that.flags,_that.muted);case Gallery():
return gallery(_that.flags,_that.muted,_that.leavingFor);case Contact():
return contact(_that.flags,_that.muted);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( LoadingProgress progress,  ButtonFlags flags,  bool muted)?  loading,TResult? Function( bool isInteractive,  bool touchHovered,  ButtonFlags flags,  bool muted)?  logo,TResult? Function( ButtonFlags flags,  bool muted)?  logoOverlayRemoving,TResult? Function( ButtonFlags flags,  bool muted)?  titleLoading,TResult? Function( ButtonFlags flags,  bool muted)?  title,TResult? Function( double uiOpacity,  bool isArrowVisible,  ButtonFlags flags,  bool muted)?  active,TResult? Function( ButtonFlags flags,  bool muted,  GalleryExit? leavingFor)?  gallery,TResult? Function( ButtonFlags flags,  bool muted)?  contact,}) {final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that.progress,_that.flags,_that.muted);case Logo() when logo != null:
return logo(_that.isInteractive,_that.touchHovered,_that.flags,_that.muted);case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving(_that.flags,_that.muted);case TitleLoading() when titleLoading != null:
return titleLoading(_that.flags,_that.muted);case Title() when title != null:
return title(_that.flags,_that.muted);case Active() when active != null:
return active(_that.uiOpacity,_that.isArrowVisible,_that.flags,_that.muted);case Gallery() when gallery != null:
return gallery(_that.flags,_that.muted,_that.leavingFor);case Contact() when contact != null:
return contact(_that.flags,_that.muted);case _:
  return null;

}
}

}

/// @nodoc


class Loading extends SceneState {
  const Loading({this.progress = LoadingProgress.empty, this.flags = const ButtonFlags(), this.muted = false}): super._();
  

@JsonKey() final  LoadingProgress progress;
@override@JsonKey() final  ButtonFlags flags;
@override@JsonKey() final  bool muted;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadingCopyWith<Loading> get copyWith => _$LoadingCopyWithImpl<Loading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Loading&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.flags, flags) || other.flags == flags)&&(identical(other.muted, muted) || other.muted == muted));
}


@override
int get hashCode => Object.hash(runtimeType,progress,flags,muted);

@override
String toString() {
  return 'SceneState.loading(progress: $progress, flags: $flags, muted: $muted)';
}


}

/// @nodoc
abstract mixin class $LoadingCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $LoadingCopyWith(Loading value, $Res Function(Loading) _then) = _$LoadingCopyWithImpl;
@override @useResult
$Res call({
 LoadingProgress progress, ButtonFlags flags, bool muted
});




}
/// @nodoc
class _$LoadingCopyWithImpl<$Res>
    implements $LoadingCopyWith<$Res> {
  _$LoadingCopyWithImpl(this._self, this._then);

  final Loading _self;
  final $Res Function(Loading) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? progress = null,Object? flags = null,Object? muted = null,}) {
  return _then(Loading(
progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as LoadingProgress,flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as ButtonFlags,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class Logo extends SceneState {
  const Logo({this.isInteractive = false, this.touchHovered = false, this.flags = const ButtonFlags(), this.muted = false}): super._();
  

@JsonKey() final  bool isInteractive;
@JsonKey() final  bool touchHovered;
@override@JsonKey() final  ButtonFlags flags;
@override@JsonKey() final  bool muted;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogoCopyWith<Logo> get copyWith => _$LogoCopyWithImpl<Logo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Logo&&(identical(other.isInteractive, isInteractive) || other.isInteractive == isInteractive)&&(identical(other.touchHovered, touchHovered) || other.touchHovered == touchHovered)&&(identical(other.flags, flags) || other.flags == flags)&&(identical(other.muted, muted) || other.muted == muted));
}


@override
int get hashCode => Object.hash(runtimeType,isInteractive,touchHovered,flags,muted);

@override
String toString() {
  return 'SceneState.logo(isInteractive: $isInteractive, touchHovered: $touchHovered, flags: $flags, muted: $muted)';
}


}

/// @nodoc
abstract mixin class $LogoCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $LogoCopyWith(Logo value, $Res Function(Logo) _then) = _$LogoCopyWithImpl;
@override @useResult
$Res call({
 bool isInteractive, bool touchHovered, ButtonFlags flags, bool muted
});




}
/// @nodoc
class _$LogoCopyWithImpl<$Res>
    implements $LogoCopyWith<$Res> {
  _$LogoCopyWithImpl(this._self, this._then);

  final Logo _self;
  final $Res Function(Logo) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isInteractive = null,Object? touchHovered = null,Object? flags = null,Object? muted = null,}) {
  return _then(Logo(
isInteractive: null == isInteractive ? _self.isInteractive : isInteractive // ignore: cast_nullable_to_non_nullable
as bool,touchHovered: null == touchHovered ? _self.touchHovered : touchHovered // ignore: cast_nullable_to_non_nullable
as bool,flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as ButtonFlags,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class LogoOverlayRemoving extends SceneState {
  const LogoOverlayRemoving({this.flags = const ButtonFlags(), this.muted = false}): super._();
  

@override@JsonKey() final  ButtonFlags flags;
@override@JsonKey() final  bool muted;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogoOverlayRemovingCopyWith<LogoOverlayRemoving> get copyWith => _$LogoOverlayRemovingCopyWithImpl<LogoOverlayRemoving>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoOverlayRemoving&&(identical(other.flags, flags) || other.flags == flags)&&(identical(other.muted, muted) || other.muted == muted));
}


@override
int get hashCode => Object.hash(runtimeType,flags,muted);

@override
String toString() {
  return 'SceneState.logoOverlayRemoving(flags: $flags, muted: $muted)';
}


}

/// @nodoc
abstract mixin class $LogoOverlayRemovingCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $LogoOverlayRemovingCopyWith(LogoOverlayRemoving value, $Res Function(LogoOverlayRemoving) _then) = _$LogoOverlayRemovingCopyWithImpl;
@override @useResult
$Res call({
 ButtonFlags flags, bool muted
});




}
/// @nodoc
class _$LogoOverlayRemovingCopyWithImpl<$Res>
    implements $LogoOverlayRemovingCopyWith<$Res> {
  _$LogoOverlayRemovingCopyWithImpl(this._self, this._then);

  final LogoOverlayRemoving _self;
  final $Res Function(LogoOverlayRemoving) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? flags = null,Object? muted = null,}) {
  return _then(LogoOverlayRemoving(
flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as ButtonFlags,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class TitleLoading extends SceneState {
  const TitleLoading({this.flags = const ButtonFlags(), this.muted = false}): super._();
  

@override@JsonKey() final  ButtonFlags flags;
@override@JsonKey() final  bool muted;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TitleLoadingCopyWith<TitleLoading> get copyWith => _$TitleLoadingCopyWithImpl<TitleLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TitleLoading&&(identical(other.flags, flags) || other.flags == flags)&&(identical(other.muted, muted) || other.muted == muted));
}


@override
int get hashCode => Object.hash(runtimeType,flags,muted);

@override
String toString() {
  return 'SceneState.titleLoading(flags: $flags, muted: $muted)';
}


}

/// @nodoc
abstract mixin class $TitleLoadingCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $TitleLoadingCopyWith(TitleLoading value, $Res Function(TitleLoading) _then) = _$TitleLoadingCopyWithImpl;
@override @useResult
$Res call({
 ButtonFlags flags, bool muted
});




}
/// @nodoc
class _$TitleLoadingCopyWithImpl<$Res>
    implements $TitleLoadingCopyWith<$Res> {
  _$TitleLoadingCopyWithImpl(this._self, this._then);

  final TitleLoading _self;
  final $Res Function(TitleLoading) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? flags = null,Object? muted = null,}) {
  return _then(TitleLoading(
flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as ButtonFlags,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class Title extends SceneState {
  const Title({this.flags = const ButtonFlags(), this.muted = false}): super._();
  

@override@JsonKey() final  ButtonFlags flags;
@override@JsonKey() final  bool muted;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TitleCopyWith<Title> get copyWith => _$TitleCopyWithImpl<Title>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Title&&(identical(other.flags, flags) || other.flags == flags)&&(identical(other.muted, muted) || other.muted == muted));
}


@override
int get hashCode => Object.hash(runtimeType,flags,muted);

@override
String toString() {
  return 'SceneState.title(flags: $flags, muted: $muted)';
}


}

/// @nodoc
abstract mixin class $TitleCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $TitleCopyWith(Title value, $Res Function(Title) _then) = _$TitleCopyWithImpl;
@override @useResult
$Res call({
 ButtonFlags flags, bool muted
});




}
/// @nodoc
class _$TitleCopyWithImpl<$Res>
    implements $TitleCopyWith<$Res> {
  _$TitleCopyWithImpl(this._self, this._then);

  final Title _self;
  final $Res Function(Title) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? flags = null,Object? muted = null,}) {
  return _then(Title(
flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as ButtonFlags,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class Active extends SceneState {
  const Active({this.uiOpacity = 1.0, this.isArrowVisible = true, this.flags = const ButtonFlags(), this.muted = false}): super._();
  

@JsonKey() final  double uiOpacity;
@JsonKey() final  bool isArrowVisible;
@override@JsonKey() final  ButtonFlags flags;
@override@JsonKey() final  bool muted;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveCopyWith<Active> get copyWith => _$ActiveCopyWithImpl<Active>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Active&&(identical(other.uiOpacity, uiOpacity) || other.uiOpacity == uiOpacity)&&(identical(other.isArrowVisible, isArrowVisible) || other.isArrowVisible == isArrowVisible)&&(identical(other.flags, flags) || other.flags == flags)&&(identical(other.muted, muted) || other.muted == muted));
}


@override
int get hashCode => Object.hash(runtimeType,uiOpacity,isArrowVisible,flags,muted);

@override
String toString() {
  return 'SceneState.active(uiOpacity: $uiOpacity, isArrowVisible: $isArrowVisible, flags: $flags, muted: $muted)';
}


}

/// @nodoc
abstract mixin class $ActiveCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $ActiveCopyWith(Active value, $Res Function(Active) _then) = _$ActiveCopyWithImpl;
@override @useResult
$Res call({
 double uiOpacity, bool isArrowVisible, ButtonFlags flags, bool muted
});




}
/// @nodoc
class _$ActiveCopyWithImpl<$Res>
    implements $ActiveCopyWith<$Res> {
  _$ActiveCopyWithImpl(this._self, this._then);

  final Active _self;
  final $Res Function(Active) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uiOpacity = null,Object? isArrowVisible = null,Object? flags = null,Object? muted = null,}) {
  return _then(Active(
uiOpacity: null == uiOpacity ? _self.uiOpacity : uiOpacity // ignore: cast_nullable_to_non_nullable
as double,isArrowVisible: null == isArrowVisible ? _self.isArrowVisible : isArrowVisible // ignore: cast_nullable_to_non_nullable
as bool,flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as ButtonFlags,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class Gallery extends SceneState {
  const Gallery({this.flags = const ButtonFlags(), this.muted = false, this.leavingFor}): super._();
  

@override@JsonKey() final  ButtonFlags flags;
@override@JsonKey() final  bool muted;
 final  GalleryExit? leavingFor;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GalleryCopyWith<Gallery> get copyWith => _$GalleryCopyWithImpl<Gallery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Gallery&&(identical(other.flags, flags) || other.flags == flags)&&(identical(other.muted, muted) || other.muted == muted)&&(identical(other.leavingFor, leavingFor) || other.leavingFor == leavingFor));
}


@override
int get hashCode => Object.hash(runtimeType,flags,muted,leavingFor);

@override
String toString() {
  return 'SceneState.gallery(flags: $flags, muted: $muted, leavingFor: $leavingFor)';
}


}

/// @nodoc
abstract mixin class $GalleryCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $GalleryCopyWith(Gallery value, $Res Function(Gallery) _then) = _$GalleryCopyWithImpl;
@override @useResult
$Res call({
 ButtonFlags flags, bool muted, GalleryExit? leavingFor
});




}
/// @nodoc
class _$GalleryCopyWithImpl<$Res>
    implements $GalleryCopyWith<$Res> {
  _$GalleryCopyWithImpl(this._self, this._then);

  final Gallery _self;
  final $Res Function(Gallery) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? flags = null,Object? muted = null,Object? leavingFor = freezed,}) {
  return _then(Gallery(
flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as ButtonFlags,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,leavingFor: freezed == leavingFor ? _self.leavingFor : leavingFor // ignore: cast_nullable_to_non_nullable
as GalleryExit?,
  ));
}


}

/// @nodoc


class Contact extends SceneState {
  const Contact({this.flags = const ButtonFlags(), this.muted = false}): super._();
  

@override@JsonKey() final  ButtonFlags flags;
@override@JsonKey() final  bool muted;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContactCopyWith<Contact> get copyWith => _$ContactCopyWithImpl<Contact>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Contact&&(identical(other.flags, flags) || other.flags == flags)&&(identical(other.muted, muted) || other.muted == muted));
}


@override
int get hashCode => Object.hash(runtimeType,flags,muted);

@override
String toString() {
  return 'SceneState.contact(flags: $flags, muted: $muted)';
}


}

/// @nodoc
abstract mixin class $ContactCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $ContactCopyWith(Contact value, $Res Function(Contact) _then) = _$ContactCopyWithImpl;
@override @useResult
$Res call({
 ButtonFlags flags, bool muted
});




}
/// @nodoc
class _$ContactCopyWithImpl<$Res>
    implements $ContactCopyWith<$Res> {
  _$ContactCopyWithImpl(this._self, this._then);

  final Contact _self;
  final $Res Function(Contact) _then;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? flags = null,Object? muted = null,}) {
  return _then(Contact(
flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as ButtonFlags,muted: null == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
