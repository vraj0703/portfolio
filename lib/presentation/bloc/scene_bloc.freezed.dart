// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scene_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Initialize value)?  initialize,TResult Function( CloseCurtain value)?  closeCurtain,TResult Function( TapDown value)?  tapDown,TResult Function( LoadTitle value)?  loadTitle,TResult Function( TitleLoaded value)?  titleLoaded,TResult Function( GameReady value)?  gameReady,TResult Function( OnScroll value)?  onScroll,TResult Function( UpdateUIOpacity value)?  updateUIOpacity,TResult Function( ToggleArrow value)?  toggleArrow,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize(_that);case CloseCurtain() when closeCurtain != null:
return closeCurtain(_that);case TapDown() when tapDown != null:
return tapDown(_that);case LoadTitle() when loadTitle != null:
return loadTitle(_that);case TitleLoaded() when titleLoaded != null:
return titleLoaded(_that);case GameReady() when gameReady != null:
return gameReady(_that);case OnScroll() when onScroll != null:
return onScroll(_that);case UpdateUIOpacity() when updateUIOpacity != null:
return updateUIOpacity(_that);case ToggleArrow() when toggleArrow != null:
return toggleArrow(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Initialize value)  initialize,required TResult Function( CloseCurtain value)  closeCurtain,required TResult Function( TapDown value)  tapDown,required TResult Function( LoadTitle value)  loadTitle,required TResult Function( TitleLoaded value)  titleLoaded,required TResult Function( GameReady value)  gameReady,required TResult Function( OnScroll value)  onScroll,required TResult Function( UpdateUIOpacity value)  updateUIOpacity,required TResult Function( ToggleArrow value)  toggleArrow,}){
final _that = this;
switch (_that) {
case Initialize():
return initialize(_that);case CloseCurtain():
return closeCurtain(_that);case TapDown():
return tapDown(_that);case LoadTitle():
return loadTitle(_that);case TitleLoaded():
return titleLoaded(_that);case GameReady():
return gameReady(_that);case OnScroll():
return onScroll(_that);case UpdateUIOpacity():
return updateUIOpacity(_that);case ToggleArrow():
return toggleArrow(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Initialize value)?  initialize,TResult? Function( CloseCurtain value)?  closeCurtain,TResult? Function( TapDown value)?  tapDown,TResult? Function( LoadTitle value)?  loadTitle,TResult? Function( TitleLoaded value)?  titleLoaded,TResult? Function( GameReady value)?  gameReady,TResult? Function( OnScroll value)?  onScroll,TResult? Function( UpdateUIOpacity value)?  updateUIOpacity,TResult? Function( ToggleArrow value)?  toggleArrow,}){
final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize(_that);case CloseCurtain() when closeCurtain != null:
return closeCurtain(_that);case TapDown() when tapDown != null:
return tapDown(_that);case LoadTitle() when loadTitle != null:
return loadTitle(_that);case TitleLoaded() when titleLoaded != null:
return titleLoaded(_that);case GameReady() when gameReady != null:
return gameReady(_that);case OnScroll() when onScroll != null:
return onScroll(_that);case UpdateUIOpacity() when updateUIOpacity != null:
return updateUIOpacity(_that);case ToggleArrow() when toggleArrow != null:
return toggleArrow(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initialize,TResult Function()?  closeCurtain,TResult Function( TapDownEvent tapDownEvent)?  tapDown,TResult Function()?  loadTitle,TResult Function()?  titleLoaded,TResult Function()?  gameReady,TResult Function()?  onScroll,TResult Function( double opacity)?  updateUIOpacity,TResult Function( bool isVisible)?  toggleArrow,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize();case CloseCurtain() when closeCurtain != null:
return closeCurtain();case TapDown() when tapDown != null:
return tapDown(_that.tapDownEvent);case LoadTitle() when loadTitle != null:
return loadTitle();case TitleLoaded() when titleLoaded != null:
return titleLoaded();case GameReady() when gameReady != null:
return gameReady();case OnScroll() when onScroll != null:
return onScroll();case UpdateUIOpacity() when updateUIOpacity != null:
return updateUIOpacity(_that.opacity);case ToggleArrow() when toggleArrow != null:
return toggleArrow(_that.isVisible);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initialize,required TResult Function()  closeCurtain,required TResult Function( TapDownEvent tapDownEvent)  tapDown,required TResult Function()  loadTitle,required TResult Function()  titleLoaded,required TResult Function()  gameReady,required TResult Function()  onScroll,required TResult Function( double opacity)  updateUIOpacity,required TResult Function( bool isVisible)  toggleArrow,}) {final _that = this;
switch (_that) {
case Initialize():
return initialize();case CloseCurtain():
return closeCurtain();case TapDown():
return tapDown(_that.tapDownEvent);case LoadTitle():
return loadTitle();case TitleLoaded():
return titleLoaded();case GameReady():
return gameReady();case OnScroll():
return onScroll();case UpdateUIOpacity():
return updateUIOpacity(_that.opacity);case ToggleArrow():
return toggleArrow(_that.isVisible);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initialize,TResult? Function()?  closeCurtain,TResult? Function( TapDownEvent tapDownEvent)?  tapDown,TResult? Function()?  loadTitle,TResult? Function()?  titleLoaded,TResult? Function()?  gameReady,TResult? Function()?  onScroll,TResult? Function( double opacity)?  updateUIOpacity,TResult? Function( bool isVisible)?  toggleArrow,}) {final _that = this;
switch (_that) {
case Initialize() when initialize != null:
return initialize();case CloseCurtain() when closeCurtain != null:
return closeCurtain();case TapDown() when tapDown != null:
return tapDown(_that.tapDownEvent);case LoadTitle() when loadTitle != null:
return loadTitle();case TitleLoaded() when titleLoaded != null:
return titleLoaded();case GameReady() when gameReady != null:
return gameReady();case OnScroll() when onScroll != null:
return onScroll();case UpdateUIOpacity() when updateUIOpacity != null:
return updateUIOpacity(_that.opacity);case ToggleArrow() when toggleArrow != null:
return toggleArrow(_that.isVisible);case _:
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


class CloseCurtain implements SceneEvent {
  const CloseCurtain();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CloseCurtain);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.closeCurtain()';
}


}




/// @nodoc


class TapDown implements SceneEvent {
  const TapDown(this.tapDownEvent);
  

 final  TapDownEvent tapDownEvent;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TapDownCopyWith<TapDown> get copyWith => _$TapDownCopyWithImpl<TapDown>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TapDown&&(identical(other.tapDownEvent, tapDownEvent) || other.tapDownEvent == tapDownEvent));
}


@override
int get hashCode => Object.hash(runtimeType,tapDownEvent);

@override
String toString() {
  return 'SceneEvent.tapDown(tapDownEvent: $tapDownEvent)';
}


}

/// @nodoc
abstract mixin class $TapDownCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $TapDownCopyWith(TapDown value, $Res Function(TapDown) _then) = _$TapDownCopyWithImpl;
@useResult
$Res call({
 TapDownEvent tapDownEvent
});




}
/// @nodoc
class _$TapDownCopyWithImpl<$Res>
    implements $TapDownCopyWith<$Res> {
  _$TapDownCopyWithImpl(this._self, this._then);

  final TapDown _self;
  final $Res Function(TapDown) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tapDownEvent = null,}) {
  return _then(TapDown(
null == tapDownEvent ? _self.tapDownEvent : tapDownEvent // ignore: cast_nullable_to_non_nullable
as TapDownEvent,
  ));
}


}

/// @nodoc


class LoadTitle implements SceneEvent {
  const LoadTitle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadTitle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.loadTitle()';
}


}




/// @nodoc


class TitleLoaded implements SceneEvent {
  const TitleLoaded();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TitleLoaded);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.titleLoaded()';
}


}




/// @nodoc


class GameReady implements SceneEvent {
  const GameReady();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameReady);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.gameReady()';
}


}




/// @nodoc


class OnScroll implements SceneEvent {
  const OnScroll();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnScroll);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneEvent.onScroll()';
}


}




/// @nodoc


class UpdateUIOpacity implements SceneEvent {
  const UpdateUIOpacity(this.opacity);
  

 final  double opacity;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateUIOpacityCopyWith<UpdateUIOpacity> get copyWith => _$UpdateUIOpacityCopyWithImpl<UpdateUIOpacity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateUIOpacity&&(identical(other.opacity, opacity) || other.opacity == opacity));
}


@override
int get hashCode => Object.hash(runtimeType,opacity);

@override
String toString() {
  return 'SceneEvent.updateUIOpacity(opacity: $opacity)';
}


}

/// @nodoc
abstract mixin class $UpdateUIOpacityCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $UpdateUIOpacityCopyWith(UpdateUIOpacity value, $Res Function(UpdateUIOpacity) _then) = _$UpdateUIOpacityCopyWithImpl;
@useResult
$Res call({
 double opacity
});




}
/// @nodoc
class _$UpdateUIOpacityCopyWithImpl<$Res>
    implements $UpdateUIOpacityCopyWith<$Res> {
  _$UpdateUIOpacityCopyWithImpl(this._self, this._then);

  final UpdateUIOpacity _self;
  final $Res Function(UpdateUIOpacity) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? opacity = null,}) {
  return _then(UpdateUIOpacity(
null == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class ToggleArrow implements SceneEvent {
  const ToggleArrow(this.isVisible);
  

 final  bool isVisible;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToggleArrowCopyWith<ToggleArrow> get copyWith => _$ToggleArrowCopyWithImpl<ToggleArrow>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToggleArrow&&(identical(other.isVisible, isVisible) || other.isVisible == isVisible));
}


@override
int get hashCode => Object.hash(runtimeType,isVisible);

@override
String toString() {
  return 'SceneEvent.toggleArrow(isVisible: $isVisible)';
}


}

/// @nodoc
abstract mixin class $ToggleArrowCopyWith<$Res> implements $SceneEventCopyWith<$Res> {
  factory $ToggleArrowCopyWith(ToggleArrow value, $Res Function(ToggleArrow) _then) = _$ToggleArrowCopyWithImpl;
@useResult
$Res call({
 bool isVisible
});




}
/// @nodoc
class _$ToggleArrowCopyWithImpl<$Res>
    implements $ToggleArrowCopyWith<$Res> {
  _$ToggleArrowCopyWithImpl(this._self, this._then);

  final ToggleArrow _self;
  final $Res Function(ToggleArrow) _then;

/// Create a copy of SceneEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isVisible = null,}) {
  return _then(ToggleArrow(
null == isVisible ? _self.isVisible : isVisible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Loading value)?  loading,TResult Function( Logo value)?  logo,TResult Function( LogoOverlayRemoving value)?  logoOverlayRemoving,TResult Function( TitleLoading value)?  titleLoading,TResult Function( Title value)?  title,TResult Function( Active value)?  active,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that);case Logo() when logo != null:
return logo(_that);case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving(_that);case TitleLoading() when titleLoading != null:
return titleLoading(_that);case Title() when title != null:
return title(_that);case Active() when active != null:
return active(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Loading value)  loading,required TResult Function( Logo value)  logo,required TResult Function( LogoOverlayRemoving value)  logoOverlayRemoving,required TResult Function( TitleLoading value)  titleLoading,required TResult Function( Title value)  title,required TResult Function( Active value)  active,}){
final _that = this;
switch (_that) {
case Loading():
return loading(_that);case Logo():
return logo(_that);case LogoOverlayRemoving():
return logoOverlayRemoving(_that);case TitleLoading():
return titleLoading(_that);case Title():
return title(_that);case Active():
return active(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Loading value)?  loading,TResult? Function( Logo value)?  logo,TResult? Function( LogoOverlayRemoving value)?  logoOverlayRemoving,TResult? Function( TitleLoading value)?  titleLoading,TResult? Function( Title value)?  title,TResult? Function( Active value)?  active,}){
final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that);case Logo() when logo != null:
return logo(_that);case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving(_that);case TitleLoading() when titleLoading != null:
return titleLoading(_that);case Title() when title != null:
return title(_that);case Active() when active != null:
return active(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool isSvgReady,  bool isGameReady)?  loading,TResult Function()?  logo,TResult Function()?  logoOverlayRemoving,TResult Function()?  titleLoading,TResult Function()?  title,TResult Function( double uiOpacity,  bool isArrowVisible)?  active,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that.isSvgReady,_that.isGameReady);case Logo() when logo != null:
return logo();case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving();case TitleLoading() when titleLoading != null:
return titleLoading();case Title() when title != null:
return title();case Active() when active != null:
return active(_that.uiOpacity,_that.isArrowVisible);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool isSvgReady,  bool isGameReady)  loading,required TResult Function()  logo,required TResult Function()  logoOverlayRemoving,required TResult Function()  titleLoading,required TResult Function()  title,required TResult Function( double uiOpacity,  bool isArrowVisible)  active,}) {final _that = this;
switch (_that) {
case Loading():
return loading(_that.isSvgReady,_that.isGameReady);case Logo():
return logo();case LogoOverlayRemoving():
return logoOverlayRemoving();case TitleLoading():
return titleLoading();case Title():
return title();case Active():
return active(_that.uiOpacity,_that.isArrowVisible);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool isSvgReady,  bool isGameReady)?  loading,TResult? Function()?  logo,TResult? Function()?  logoOverlayRemoving,TResult? Function()?  titleLoading,TResult? Function()?  title,TResult? Function( double uiOpacity,  bool isArrowVisible)?  active,}) {final _that = this;
switch (_that) {
case Loading() when loading != null:
return loading(_that.isSvgReady,_that.isGameReady);case Logo() when logo != null:
return logo();case LogoOverlayRemoving() when logoOverlayRemoving != null:
return logoOverlayRemoving();case TitleLoading() when titleLoading != null:
return titleLoading();case Title() when title != null:
return title();case Active() when active != null:
return active(_that.uiOpacity,_that.isArrowVisible);case _:
  return null;

}
}

}

/// @nodoc


class Loading extends SceneState {
  const Loading({this.isSvgReady = false, this.isGameReady = false}): super._();
  

@JsonKey() final  bool isSvgReady;
@JsonKey() final  bool isGameReady;

/// Create a copy of SceneState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadingCopyWith<Loading> get copyWith => _$LoadingCopyWithImpl<Loading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Loading&&(identical(other.isSvgReady, isSvgReady) || other.isSvgReady == isSvgReady)&&(identical(other.isGameReady, isGameReady) || other.isGameReady == isGameReady));
}


@override
int get hashCode => Object.hash(runtimeType,isSvgReady,isGameReady);

@override
String toString() {
  return 'SceneState.loading(isSvgReady: $isSvgReady, isGameReady: $isGameReady)';
}


}

/// @nodoc
abstract mixin class $LoadingCopyWith<$Res> implements $SceneStateCopyWith<$Res> {
  factory $LoadingCopyWith(Loading value, $Res Function(Loading) _then) = _$LoadingCopyWithImpl;
@useResult
$Res call({
 bool isSvgReady, bool isGameReady
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
@pragma('vm:prefer-inline') $Res call({Object? isSvgReady = null,Object? isGameReady = null,}) {
  return _then(Loading(
isSvgReady: null == isSvgReady ? _self.isSvgReady : isSvgReady // ignore: cast_nullable_to_non_nullable
as bool,isGameReady: null == isGameReady ? _self.isGameReady : isGameReady // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class Logo extends SceneState {
  const Logo(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Logo);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SceneState.logo()';
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

// dart format on
