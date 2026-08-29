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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Initialize value)?  initialize,TResult Function( LoadingProgressed value)?  loadingProgressed,TResult Function( LogoEntranceCompleted value)?  logoEntranceCompleted,TResult Function( Tapped value)?  tapped,TResult Function( LogoExitCompleted value)?  logoExitCompleted,TResult Function( TitleEntranceCompleted value)?  titleEntranceCompleted,TResult Function( AdvanceRequested value)?  advanceRequested,TResult Function( BoldTextCompleted value)?  boldTextCompleted,TResult Function( GalleryExited value)?  galleryExited,TResult Function( ContactRequested value)?  contactRequested,TResult Function( GalleryRequested value)?  galleryRequested,TResult Function( HomeRequested value)?  homeRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize(_that);case LoadingProgressed() when loadingProgressed != null:
return loadingProgressed(_that);case LogoEntranceCompleted() when logoEntranceCompleted != null:
return logoEntranceCompleted(_that);case Tapped() when tapped != null:
return tapped(_that);case LogoExitCompleted() when logoExitCompleted != null:
return logoExitCompleted(_that);case TitleEntranceCompleted() when titleEntranceCompleted != null:
return titleEntranceCompleted(_that);case AdvanceRequested() when advanceRequested != null:
return advanceRequested(_that);case BoldTextCompleted() when boldTextCompleted != null:
return boldTextCompleted(_that);case GalleryExited() when galleryExited != null:
return galleryExited(_that);case ContactRequested() when contactRequested != null:
return contactRequested(_that);case GalleryRequested() when galleryRequested != null:
return galleryRequested(_that);case HomeRequested() when homeRequested != null:
return homeRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Initialize value)  initialize,required TResult Function( LoadingProgressed value)  loadingProgressed,required TResult Function( LogoEntranceCompleted value)  logoEntranceCompleted,required TResult Function( Tapped value)  tapped,required TResult Function( LogoExitCompleted value)  logoExitCompleted,required TResult Function( TitleEntranceCompleted value)  titleEntranceCompleted,required TResult Function( AdvanceRequested value)  advanceRequested,required TResult Function( BoldTextCompleted value)  boldTextCompleted,required TResult Function( GalleryExited value)  galleryExited,required TResult Function( ContactRequested value)  contactRequested,required TResult Function( GalleryRequested value)  galleryRequested,required TResult Function( HomeRequested value)  homeRequested,}){
final _that = this;
switch (_that) {
case Initialize():
return initialize(_that);case LoadingProgressed():
return loadingProgressed(_that);case LogoEntranceCompleted():
return logoEntranceCompleted(_that);case Tapped():
return tapped(_that);case LogoExitCompleted():
return logoExitCompleted(_that);case TitleEntranceCompleted():
return titleEntranceCompleted(_that);case AdvanceRequested():
return advanceRequested(_that);case BoldTextCompleted():
return boldTextCompleted(_that);case GalleryExited():
return galleryExited(_that);case ContactRequested():
return contactRequested(_that);case GalleryRequested():
return galleryRequested(_that);case HomeRequested():
return homeRequested(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Initialize value)?  initialize,TResult? Function( LoadingProgressed value)?  loadingProgressed,TResult? Function( LogoEntranceCompleted value)?  logoEntranceCompleted,TResult? Function( Tapped value)?  tapped,TResult? Function( LogoExitCompleted value)?  logoExitCompleted,TResult? Function( TitleEntranceCompleted value)?  titleEntranceCompleted,TResult? Function( AdvanceRequested value)?  advanceRequested,TResult? Function( BoldTextCompleted value)?  boldTextCompleted,TResult? Function( GalleryExited value)?  galleryExited,TResult? Function( ContactRequested value)?  contactRequested,TResult? Function( GalleryRequested value)?  galleryRequested,TResult? Function( HomeRequested value)?  homeRequested,}){
final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize(_that);case LoadingProgressed() when loadingProgressed != null:
return loadingProgressed(_that);case LogoEntranceCompleted() when logoEntranceCompleted != null:
return logoEntranceCompleted(_that);case Tapped() when tapped != null:
return tapped(_that);case LogoExitCompleted() when logoExitCompleted != null:
return logoExitCompleted(_that);case TitleEntranceCompleted() when titleEntranceCompleted != null:
return titleEntranceCompleted(_that);case AdvanceRequested() when advanceRequested != null:
return advanceRequested(_that);case BoldTextCompleted() when boldTextCompleted != null:
return boldTextCompleted(_that);case GalleryExited() when galleryExited != null:
return galleryExited(_that);case ContactRequested() when contactRequested != null:
return contactRequested(_that);case GalleryRequested() when galleryRequested != null:
return galleryRequested(_that);case HomeRequested() when homeRequested != null:
return homeRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initialize,TResult Function( LoadingPhase phase,  double value)?  loadingProgressed,TResult Function()?  logoEntranceCompleted,TResult Function()?  tapped,TResult Function()?  logoExitCompleted,TResult Function()?  titleEntranceCompleted,TResult Function()?  advanceRequested,TResult Function()?  boldTextCompleted,TResult Function()?  galleryExited,TResult Function()?  contactRequested,TResult Function()?  galleryRequested,TResult Function()?  homeRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize();case LoadingProgressed() when loadingProgressed != null:
return loadingProgressed(_that.phase,_that.value);case LogoEntranceCompleted() when logoEntranceCompleted != null:
return logoEntranceCompleted();case Tapped() when tapped != null:
return tapped();case LogoExitCompleted() when logoExitCompleted != null:
return logoExitCompleted();case TitleEntranceCompleted() when titleEntranceCompleted != null:
return titleEntranceCompleted();case AdvanceRequested() when advanceRequested != null:
return advanceRequested();case BoldTextCompleted() when boldTextCompleted != null:
return boldTextCompleted();case GalleryExited() when galleryExited != null:
return galleryExited();case ContactRequested() when contactRequested != null:
return contactRequested();case GalleryRequested() when galleryRequested != null:
return galleryRequested();case HomeRequested() when homeRequested != null:
return homeRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initialize,required TResult Function( LoadingPhase phase,  double value)  loadingProgressed,required TResult Function()  logoEntranceCompleted,required TResult Function()  tapped,required TResult Function()  logoExitCompleted,required TResult Function()  titleEntranceCompleted,required TResult Function()  advanceRequested,required TResult Function()  boldTextCompleted,required TResult Function()  galleryExited,required TResult Function()  contactRequested,required TResult Function()  galleryRequested,required TResult Function()  homeRequested,}) {final _that = this;
switch (_that) {
case Initialize():
return initialize();case LoadingProgressed():
return loadingProgressed(_that.phase,_that.value);case LogoEntranceCompleted():
return logoEntranceCompleted();case Tapped():
return tapped();case LogoExitCompleted():
return logoExitCompleted();case TitleEntranceCompleted():
return titleEntranceCompleted();case AdvanceRequested():
return advanceRequested();case BoldTextCompleted():
return boldTextCompleted();case GalleryExited():
return galleryExited();case ContactRequested():
return contactRequested();case GalleryRequested():
return galleryRequested();case HomeRequested():
return homeRequested();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initialize,TResult? Function( LoadingPhase phase,  double value)?  loadingProgressed,TResult? Function()?  logoEntranceCompleted,TResult? Function()?  tapped,TResult? Function()?  logoExitCompleted,TResult? Function()?  titleEntranceCompleted,TResult? Function()?  advanceRequested,TResult? Function()?  boldTextCompleted,TResult? Function()?  galleryExited,TResult? Function()?  contactRequested,TResult? Function()?  galleryRequested,TResult? Function()?  homeRequested,}) {final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize();case LoadingProgressed() when loadingProgressed != null:
return loadingProgressed(_that.phase,_that.value);case LogoEntranceCompleted() when logoEntranceCompleted != null:
return logoEntranceCompleted();case Tapped() when tapped != null:
return tapped();case LogoExitCompleted() when logoExitCompleted != null:
return logoExitCompleted();case TitleEntranceCompleted() when titleEntranceCompleted != null:
return titleEntranceCompleted();case AdvanceRequested() when advanceRequested != null:
return advanceRequested();case BoldTextCompleted() when boldTextCompleted != null:
return boldTextCompleted();case GalleryExited() when galleryExited != null:
return galleryExited();case ContactRequested() when contactRequested != null:
return contactRequested();case GalleryRequested() when galleryRequested != null:
return galleryRequested();case HomeRequested() when homeRequested != null:
return homeRequested();case _:
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
  const Tapped();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tapped);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.tapped()';
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
mixin _$SceneState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SceneState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneState()';
}


}

/// @nodoc
class $SceneStateCopyWith<$Res>  {
$SceneStateCopyWith(SceneState _, $Res Function(SceneState) __);
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
return contact(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( LoadingProgress progress)?  loading,TResult Function( bool isInteractive)?  logo,TResult Function()?  logoOverlayRemoving,TResult Function()?  titleLoading,TResult Function()?  title,TResult Function( double uiOpacity,  bool isArrowVisible)?  active,TResult Function()?  gallery,TResult Function()?  contact,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that.progress);case Logo() when logo != null:
return logo(_that.isInteractive);case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving();case TitleLoading() when titleLoading != null:
return titleLoading();case Title() when title != null:
return title();case Active() when active != null:
return active(_that.uiOpacity,_that.isArrowVisible);case Gallery() when gallery != null:
return gallery();case Contact() when contact != null:
return contact();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( LoadingProgress progress)  loading,required TResult Function( bool isInteractive)  logo,required TResult Function()  logoOverlayRemoving,required TResult Function()  titleLoading,required TResult Function()  title,required TResult Function( double uiOpacity,  bool isArrowVisible)  active,required TResult Function()  gallery,required TResult Function()  contact,}) {final _that = this;
switch (_that) {
case Loading():
return loading(_that.progress);case Logo():
return logo(_that.isInteractive);case LogoOverlayRemoving():
return logoOverlayRemoving();case TitleLoading():
return titleLoading();case Title():
return title();case Active():
return active(_that.uiOpacity,_that.isArrowVisible);case Gallery():
return gallery();case Contact():
return contact();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( LoadingProgress progress)?  loading,TResult? Function( bool isInteractive)?  logo,TResult? Function()?  logoOverlayRemoving,TResult? Function()?  titleLoading,TResult? Function()?  title,TResult? Function( double uiOpacity,  bool isArrowVisible)?  active,TResult? Function()?  gallery,TResult? Function()?  contact,}) {final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that.progress);case Logo() when logo != null:
return logo(_that.isInteractive);case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving();case TitleLoading() when titleLoading != null:
return titleLoading();case Title() when title != null:
return title();case Active() when active != null:
return active(_that.uiOpacity,_that.isArrowVisible);case Gallery() when gallery != null:
return gallery();case Contact() when contact != null:
return contact();case _:
  return null;

}
}

}

/// @nodoc


class Loading extends SceneState {
  const Loading({this.progress = LoadingProgress.empty}): super._();
  

@JsonKey() final  LoadingProgress progress;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadingCopyWith<Loading> get copyWith => _$LoadingCopyWithImpl<Loading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Loading&&(identical(other.progress, progress) || other.progress == progress));
}


@override
int get hashCode => Object.hash(runtimeType,progress);

@override
String toString() {
  return 'SceneState.loading(progress: $progress)';
}


}

/// @nodoc
abstract mixin class $LoadingCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $LoadingCopyWith(Loading value, $Res Function(Loading) _then) = _$LoadingCopyWithImpl;
@useResult
$Res call({
 LoadingProgress progress
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
@pragma('vm:prefer-inline') $Res call({Object? progress = null,}) {
  return _then(Loading(
progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as LoadingProgress,
  ));
}


}

/// @nodoc


class Logo extends SceneState {
  const Logo({this.isInteractive = false}): super._();
  

@JsonKey() final  bool isInteractive;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogoCopyWith<Logo> get copyWith => _$LogoCopyWithImpl<Logo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Logo&&(identical(other.isInteractive, isInteractive) || other.isInteractive == isInteractive));
}


@override
int get hashCode => Object.hash(runtimeType,isInteractive);

@override
String toString() {
  return 'SceneState.logo(isInteractive: $isInteractive)';
}


}

/// @nodoc
abstract mixin class $LogoCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $LogoCopyWith(Logo value, $Res Function(Logo) _then) = _$LogoCopyWithImpl;
@useResult
$Res call({
 bool isInteractive
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
@pragma('vm:prefer-inline') $Res call({Object? isInteractive = null,}) {
  return _then(Logo(
isInteractive: null == isInteractive ? _self.isInteractive : isInteractive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class LogoOverlayRemoving extends SceneState {
  const LogoOverlayRemoving(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoOverlayRemoving);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneState.logoOverlayRemoving()';
}


}




/// @nodoc


class TitleLoading extends SceneState {
  const TitleLoading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TitleLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneState.titleLoading()';
}


}




/// @nodoc


class Title extends SceneState {
  const Title(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Title);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneState.title()';
}


}




/// @nodoc


class Active extends SceneState {
  const Active({this.uiOpacity = 1.0, this.isArrowVisible = true}): super._();
  

@JsonKey() final  double uiOpacity;
@JsonKey() final  bool isArrowVisible;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveCopyWith<Active> get copyWith => _$ActiveCopyWithImpl<Active>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Active&&(identical(other.uiOpacity, uiOpacity) || other.uiOpacity == uiOpacity)&&(identical(other.isArrowVisible, isArrowVisible) || other.isArrowVisible == isArrowVisible));
}


@override
int get hashCode => Object.hash(runtimeType,uiOpacity,isArrowVisible);

@override
String toString() {
  return 'SceneState.active(uiOpacity: $uiOpacity, isArrowVisible: $isArrowVisible)';
}


}

/// @nodoc
abstract mixin class $ActiveCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $ActiveCopyWith(Active value, $Res Function(Active) _then) = _$ActiveCopyWithImpl;
@useResult
$Res call({
 double uiOpacity, bool isArrowVisible
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
@pragma('vm:prefer-inline') $Res call({Object? uiOpacity = null,Object? isArrowVisible = null,}) {
  return _then(Active(
uiOpacity: null == uiOpacity ? _self.uiOpacity : uiOpacity // ignore: cast_nullable_to_non_nullable
as double,isArrowVisible: null == isArrowVisible ? _self.isArrowVisible : isArrowVisible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class Gallery extends SceneState {
  const Gallery(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Gallery);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneState.gallery()';
}


}




/// @nodoc


class Contact extends SceneState {
  const Contact(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Contact);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneState.contact()';
}


}




// dart format on
