import 'package:flutter/material.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';

/// The way out and the radio, fixed to a portrait screen's corner.
///
/// On a portrait phone the camera sees about 24 degrees either side of the
/// corridor's line (78 degree vertical field of view at about 0.54 aspect),
/// and the BACK sign and the radio hang on the side walls by the entrance,
/// 39 degrees off that line from where the walk starts, and further off with
/// every step. So a phone visitor could neither leave the gallery nor reach
/// the radio (reported on Vishal's phone, 2026-11-18). The wall pieces stay;
/// this row does what they do, through the same handlers, wherever the camera
/// is. Shown on portrait screens only: a landscape screen sees both walls.
class GalleryPhoneControls extends StatelessWidget {
  const GalleryPhoneControls({
    required this.onBack,
    required this.onRadio,
    required this.onRadioNext,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onRadio;
  final VoidCallback onRadioNext;

  /// A thumb's target, and the gap between two of them.
  static const double size = 44;
  static const double gap = 10;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _PhoneControl(
                glyph: '♪',
                label: strings.galleryRadio,
                onTap: onRadio,
              ),
              const SizedBox(width: gap),
              _PhoneControl(
                glyph: '»',
                label: strings.galleryRadioNext,
                onTap: onRadioNext,
              ),
              const SizedBox(width: gap),
              _PhoneControl(
                glyph: '‹',
                label: strings.galleryBack,
                onTap: onBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneControl extends StatelessWidget {
  const _PhoneControl({
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  final String glyph;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: GalleryPhoneControls.size,
          height: GalleryPhoneControls.size,
          decoration: BoxDecoration(
            color: context.colors.galleryControlPlate,
            shape: BoxShape.circle,
            border: Border.all(color: context.colors.galleryControlEdge),
          ),
          alignment: Alignment.center,
          child: Text(glyph, style: context.typography.galleryControl),
        ),
      ),
    );
  }
}
