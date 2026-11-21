/// The phone's tilt and the visitor's motion preference, from the browser
/// (PORTFOLIO-27). Read only by the game's pointer adapter: no component
/// reads a sensor.
///
/// Conditionally imported the same way `PageVisibility` is: a fact about a
/// browser, with nothing to say anywhere else.
library;

export 'motion_sensor_stub.dart'
    if (dart.library.js_interop) 'motion_sensor_web.dart';
