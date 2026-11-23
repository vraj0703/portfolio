// Writes docs/CREDITS.md from the one credits record (PORTFOLIO-31).
//
//   dart run tool/write_credits.dart
import 'dart:io';

import 'package:portfolio/domain/contact/credits.dart';

void main() {
  File('docs/CREDITS.md').writeAsStringSync(Credits.markdown());
  stdout.writeln('docs/CREDITS.md: ${Credits.items.length} items');
}
