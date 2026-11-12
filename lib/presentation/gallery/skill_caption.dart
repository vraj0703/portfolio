import 'package:flutter/material.dart';
import 'package:portfolio/domain/gallery/skill_data.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';

/// What the key under the pointer, or the key pressed, is.
///
/// The caps are coloured glass with no legend: at the size they are drawn a
/// printed label would be a smudge, and several labels are shortened to fit
/// (TS, CF, Tail). So the name lives here, under the board, in full — and is
/// announced, because a screen reader has no other way to know what a key
/// is.
class SkillCaption extends StatelessWidget {
  const SkillCaption({required this.skill, super.key});

  /// The skill to name, or null for no caption.
  final Skill? skill;

  @override
  Widget build(BuildContext context) {
    final skill = this.skill;
    if (skill == null) return const SizedBox.shrink();

    final kind = context.strings.skillCategory(skill.category);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
        child: Semantics(
          liveRegion: true,
          label: '${skill.name}, $kind',
          excludeSemantics: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.galleryControlPlate,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.colors.galleryControlEdge),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(skill.name, style: context.typography.skillCaptionName),
                  const SizedBox(height: 4),
                  Text(
                    kind.toUpperCase(),
                    style: context.typography.skillCaptionKind,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
