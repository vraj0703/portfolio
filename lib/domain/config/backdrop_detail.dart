/// How much work the title's backdrop shader does per pixel.
///
/// The backdrop (`background_run_v2.frag`) raymarches every pixel: [steps]
/// marches, each with [octaves] layers of rising heat. On a phone that was
/// the whole title frame: the title idled at 8.4 fps on the ROG Phone II at
/// DPR 2.0, and at 60 with the backdrop switched off (2026-11-18). [phone]
/// marches fewer, longer steps ([stepScale]) and weighs each by the same
/// factor, so the dunes cover the same distance and keep their light: 34.7
/// fps, and the same picture (shots on the flame-lag-backdrop-shots branch).
class BackdropDetail {
  const BackdropDetail({
    required this.steps,
    required this.octaves,
    required this.stepScale,
  });

  /// The shader as it has always been. Desktops and tablets draw this, and
  /// with these values the shader's arithmetic is unchanged.
  static const BackdropDetail full = BackdropDetail(
    steps: 80,
    octaves: 7,
    stepScale: 1,
  );

  /// Phones: a quarter of the steps, one octave fewer, each step longer.
  static const BackdropDetail phone = BackdropDetail(
    steps: 24,
    octaves: 5,
    stepScale: 3.3,
  );

  /// The detail for a device. Phones are told apart by the browser
  /// (`Browser.isPhone`), not by any component.
  static BackdropDetail forDevice({required bool phone}) =>
      phone ? BackdropDetail.phone : full;

  /// Marches per pixel, at most the shader's loop bound of 80.
  final int steps;

  /// Layers of rising heat per march, at most the shader's bound of 7.
  final int octaves;

  /// How much longer each march is than the shader's own step, and how much
  /// more each one counts.
  final double stepScale;
}
