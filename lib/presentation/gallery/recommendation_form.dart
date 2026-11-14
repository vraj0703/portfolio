import 'package:flutter/material.dart';
import 'package:portfolio/domain/gallery/testimonial_data.dart';
import 'package:portfolio/domain/style/colors.dart';
import 'package:portfolio/domain/style/strings.dart';
import 'package:portfolio/domain/style/text_styles.dart';

/// The "add yours" form: a recommendation for Vishal, written here and
/// pasted into LinkedIn.
///
/// Nothing is sent from the site. Submitting hands the words to [onSubmit],
/// which copies them, opens Vishal's LinkedIn in a new tab and keeps them in
/// the visitor's own browser; this then says, in one line, what to do there.
///
/// Stateful because it owns four text controllers, which have to be
/// disposed, and whether the words have gone yet. That is the repo's
/// "genuinely required" case; nothing else here keeps state.
class RecommendationForm extends StatefulWidget {
  const RecommendationForm({required this.onSubmit, super.key});

  /// Called with the visitor's words when they submit a complete form.
  final Future<void> Function(PendingRecommendation) onSubmit;

  /// Opens the form over [context].
  static Future<void> open(
    BuildContext context, {
    required Future<void> Function(PendingRecommendation) onSubmit,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: context.colors.menuScrim,
      builder: (_) => RecommendationForm(onSubmit: onSubmit),
    );
  }

  @override
  State<RecommendationForm> createState() => _RecommendationFormState();
}

class _RecommendationFormState extends State<RecommendationForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _role = TextEditingController();
  final _relationship = TextEditingController();
  final _words = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _relationship.dispose();
    _words.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final recommendation = PendingRecommendation(
      name: _name.text,
      role: _role.text,
      relationship: _relationship.text,
      words: _words.text,
    );
    // Not awaited before the state flips: opening LinkedIn has to happen
    // inside this press, or the browser treats the new tab as a pop-up.
    final done = widget.onSubmit(recommendation);
    setState(() => _sent = true);
    await done;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final colors = context.colors;
    final type = context.typography;

    String? required(String? value) => (value == null || value.trim().isEmpty)
        ? strings.recommendRequired
        : null;

    return Dialog(
      backgroundColor: colors.menuPanel,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.menuEdge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _sent
              ? _Done(
                  message: strings.recommendDone,
                  close: strings.recommendClose,
                )
              : Form(
                  key: _form,
                  child: FocusTraversalGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          strings.recommendFormTitle,
                          style: type.creditsTitle.copyWith(
                            color: colors.menuText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _Field(
                          controller: _name,
                          label: strings.recommendName,
                          validator: required,
                          autofocus: true,
                        ),
                        _Field(controller: _role, label: strings.recommendRole),
                        _Field(
                          controller: _relationship,
                          label: strings.recommendRelationship,
                        ),
                        _Field(
                          controller: _words,
                          label: strings.recommendWords,
                          validator: required,
                          lines: 5,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                strings.recommendCancel,
                                style: type.menuAction.copyWith(
                                  color: colors.menuTextSoft,
                                ),
                              ),
                            ),
                            FilledButton(
                              onPressed: _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.galleryControlPlate,
                                foregroundColor: colors.galleryControlInk,
                                minimumSize: const Size(48, 48),
                              ),
                              child: Text(
                                strings.recommendSubmit,
                                style: type.menuAction.copyWith(
                                  color: colors.galleryControlInk,
                                ),
                              ),
                            ),
                          ],
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

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.validator,
    this.lines = 1,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final int lines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        autofocus: autofocus,
        minLines: lines,
        maxLines: lines,
        textInputAction: lines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        style: context.typography.creditsBody.copyWith(color: colors.menuText),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: context.typography.creditsBody.copyWith(
            color: colors.menuTextSoft,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colors.menuEdge),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colors.menuMark, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colors.menuMark),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colors.menuMark, width: 2),
          ),
        ),
      ),
    );
  }
}

/// After the words have gone: the one line that says what to do on LinkedIn.
class _Done extends StatelessWidget {
  const _Done({required this.message, required this.close});

  final String message;
  final String close;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: Text(
            message,
            style: context.typography.creditsBody.copyWith(
              color: colors.menuText,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: colors.galleryControlPlate,
              foregroundColor: colors.galleryControlInk,
              minimumSize: const Size(48, 48),
            ),
            child: Text(
              close,
              style: context.typography.menuAction.copyWith(
                color: colors.galleryControlInk,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
