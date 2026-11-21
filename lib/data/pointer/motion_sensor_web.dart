import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:portfolio/domain/pointer/pointer_path.dart';
import 'package:web/web.dart' as web;

/// The browser's `deviceorientation`, and `prefers-reduced-motion`.
///
/// Holds a listener while started, so the one who starts it stops it: the
/// adapter starts it on the logo and title scenes and stops it on leaving
/// them, and the sensor costs nothing anywhere else.
class MotionSensor {
  /// Asked each time: the visitor can change it while the page is open.
  bool get prefersReducedMotion =>
      web.window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  TiltPermission _permission = _needsAsking()
      ? TiltPermission.notAsked
      : TiltPermission.notNeeded;

  /// What became of the permission (`tilt_permission`).
  TiltPermission get permission => _permission;

  /// Safari on iOS gives tilt only to a page that asked, inside a tap.
  static bool _needsAsking() {
    final type = web.window.getProperty<JSObject?>(
      'DeviceOrientationEvent'.toJS,
    );
    if (type == null) return false;
    return type.getProperty<JSAny?>('requestPermission'.toJS).isA<JSFunction>();
  }

  /// Asks for tilt, once. Must be called inside the tap's own handler: iOS
  /// refuses the prompt outside a user gesture. Denied, or failing, leaves
  /// the drift in charge, silently.
  void requestPermission() {
    if (_permission != TiltPermission.notAsked) return;
    // Asked: not to be asked again, whatever the answer.
    _permission = TiltPermission.denied;
    try {
      final type = web.window.getProperty<JSObject>(
        'DeviceOrientationEvent'.toJS,
      );
      final promise = type.callMethod<JSPromise<JSString>>(
        'requestPermission'.toJS,
      );
      promise.toDart.then(
        (answer) {
          _permission = answer.toDart == 'granted'
              ? TiltPermission.granted
              : TiltPermission.denied;
        },
        onError: (Object _) {
          _permission = TiltPermission.denied;
        },
      );
    } catch (_) {
      _permission = TiltPermission.denied;
    }
  }

  JSFunction? _listener;

  /// Starts reporting the tilt: beta, gamma and the screen's angle (degrees).
  void start(void Function(double beta, double gamma, double angle) onTilt) {
    if (_listener != null) return;
    final listener = ((web.Event e) {
      final o = e as web.DeviceOrientationEvent;
      final beta = o.beta;
      final gamma = o.gamma;
      // A desktop browser fires one event with no values: no sensor.
      if (beta == null || gamma == null) return;
      onTilt(beta, gamma, web.window.screen.orientation.angle.toDouble());
    }).toJS;
    _listener = listener;
    web.window.addEventListener('deviceorientation', listener);
  }

  void stop() {
    final listener = _listener;
    if (listener == null) return;
    web.window.removeEventListener('deviceorientation', listener);
    _listener = null;
  }
}
