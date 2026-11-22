import 'package:flutter/widgets.dart';

/// Off the web there is no iframe: nothing is drawn and nothing loads, so
/// the frame keeps its picture.
class LiveFrameView extends StatelessWidget {
  const LiveFrameView({
    required this.url,
    required this.onLoaded,
    required this.fade,
    super.key,
  });

  final String url;
  final VoidCallback onLoaded;
  final Duration fade;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
