import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'package:portfolio/domain/gallery/project_data.dart';

/// Generative artwork for the project frames, ported from the React gallery's
/// `src/components/three/gallery/textures.ts`.
///
/// Each project's frame shows a procedurally drawn canvas rather than a
/// screenshot: a base gradient, a schematic keyed to the project's
/// [ProjectVisual], then the title and stat line on top. The React version
/// drew into a DOM `<canvas>` and wrapped it in a `THREE.CanvasTexture`; here
/// we record into a [ui.Picture] and rasterise to a [ui.Image], which is what
/// flutter_scene takes for a texture.
///
/// Ownership: [render] hands back an image the caller owns and must dispose
/// when the frame goes away. The React original leaked on project change
/// because its cleanup read a ref the memo had already overwritten; making
/// ownership explicit here removes that failure mode rather than porting it.
abstract final class ProjectArtwork {
  /// Edge length of the square texture, in pixels.
  static const int resolution = 1024;

  /// Draws [project]'s artwork and rasterises it.
  ///
  /// Async because [ui.Picture.toImage] is. Render once and cache — this is
  /// not cheap enough for a per-frame call.
  static Future<ui.Image> render(Project project, {int size = resolution}) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );

    paint(canvas, project, size.toDouble());

    final picture = recorder.endRecording();
    try {
      return picture.toImage(size, size);
    } finally {
      picture.dispose();
    }
  }

  /// Paints the full composition. Split out from [render] so tests can drive
  /// it against a recording canvas without rasterising.
  static void paint(ui.Canvas canvas, Project project, double s) {
    _drawBase(canvas, s, project.gradient);
    switch (project.visual) {
      case ProjectVisual.mesh:
        _drawMesh(canvas, s);
      case ProjectVisual.pipeline:
        _drawPipeline(canvas, s);
      case ProjectVisual.timeline:
        _drawTimeline(canvas, s);
      case ProjectVisual.graph:
        _drawGraph(canvas, s);
      case ProjectVisual.funnel:
        _drawFunnel(canvas, s);
      case ProjectVisual.dashboard:
        _drawDashboard(canvas, s);
      case ProjectVisual.chat:
        _drawChat(canvas, s);
    }
    _drawTitle(canvas, s, project.title);
    _drawStats(canvas, s, project.stats);
  }

  /* -- Shared layers ---------------------------------- */

  static void _drawBase(ui.Canvas canvas, double s, (Color, Color) gradient) {
    final rect = Rect.fromLTWH(0, 0, s, s);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(s, s),
          <Color>[gradient.$1, gradient.$2],
        ),
    );

    // Soft off-centre highlight, as if lit from the upper left.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(s * 0.4, s * 0.35),
          s * 0.6,
          const <Color>[Color(0x0FFFFFFF), Color(0x00FFFFFF)],
        ),
    );
  }

  static void _drawTitle(ui.Canvas canvas, double s, String title) {
    _text(
      canvas,
      title,
      const Offset(50, 40),
      fontSize: 56,
      color: const Color(0x1FFFFFFF),
      weight: FontWeight.bold,
    );
  }

  static void _drawStats(ui.Canvas canvas, double s, List<String> stats) {
    final y = s - 60;

    canvas.drawLine(
      Offset(s * 0.15, y - 25),
      Offset(s * 0.85, y - 25),
      Paint()
        ..color = const Color(0x26FFFFFF)
        ..strokeWidth = 1,
    );

    for (var i = 0; i < stats.length; i++) {
      final dx = s / 2 + (i - (stats.length - 1) / 2) * 180;
      _text(
        canvas,
        stats[i],
        Offset(dx, y),
        fontSize: 28,
        color: const Color(0x80FFFFFF),
        weight: FontWeight.bold,
        family: 'monospace',
        align: _Align.center,
      );
    }
  }

  /* -- Per-project schematics ------------------------- */

  /// Distributed mesh: three labelled nodes, fully connected, over concentric
  /// range rings.
  static void _drawMesh(ui.Canvas canvas, double s) {
    final nodes = <(double, double, double, String)>[
      (s * 0.5, s * 0.3, 35, 'PC'),
      (s * 0.25, s * 0.6, 28, 'Pi'),
      (s * 0.75, s * 0.6, 24, 'Phone'),
    ];

    final edge = Paint()
      ..color = const Color(0x40FFFFFF)
      ..strokeWidth = 2;
    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        canvas.drawLine(
          Offset(nodes[i].$1, nodes[i].$2),
          Offset(nodes[j].$1, nodes[j].$2),
          edge,
        );
      }
    }

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(
        Offset(s * 0.5, s * 0.45),
        60 + i * 40,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Color.fromRGBO(255, 255, 255, 0.08 - i * 0.015),
      );
    }

    for (final (x, y, r, label) in nodes) {
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = const Color(0x33FFFFFF),
      );
      _text(
        canvas,
        label,
        Offset(x, y),
        fontSize: 22,
        color: const Color(0xB3FFFFFF),
        weight: FontWeight.bold,
        family: 'monospace',
        align: _Align.center,
        vCenter: true,
      );
    }
  }

  /// Left-to-right processing chain with arrows between stages.
  static void _drawPipeline(ui.Canvas canvas, double s) {
    const stages = <String>['Script', 'TTS', 'Footage', 'Edit', 'Upload'];
    final y = s * 0.45;

    for (var i = 0; i < stages.length; i++) {
      final x = s * 0.12 + i * (s * 0.19);
      final box = Rect.fromLTWH(x - 35, y - 22, 70, 44);
      canvas.drawRect(box, Paint()..color = const Color(0x1AFFFFFF));
      canvas.drawRect(
        box,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x4DFFFFFF),
      );
      _text(
        canvas,
        stages[i],
        Offset(x, y),
        fontSize: 18,
        color: const Color(0xB3FFFFFF),
        family: 'monospace',
        align: _Align.center,
        vCenter: true,
      );

      if (i < stages.length - 1) {
        canvas.drawLine(
          Offset(x + 38, y),
          Offset(x + 58, y),
          Paint()
            ..color = const Color(0x4DFFFFFF)
            ..strokeWidth = 1,
        );
      }
    }
  }

  /// Career timeline: three dated milestones pinned to a horizontal axis.
  static void _drawTimeline(ui.Canvas canvas, double s) {
    const jobs = <(String, String, String)>[
      ('PayU', '2016', 'Fintech'),
      ('FieldAssist', '2018', 'FMCG'),
      ('Twin Health', '2022', 'Health'),
    ];
    final y = s * 0.48;

    canvas.drawLine(
      Offset(s * 0.12, y),
      Offset(s * 0.88, y),
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..strokeWidth = 2,
    );

    for (var i = 0; i < jobs.length; i++) {
      final (label, year, sector) = jobs[i];
      final x = s * 0.2 + i * (s * 0.3);
      canvas.drawCircle(
        Offset(x, y),
        8,
        Paint()..color = const Color(0x80FFFFFF),
      );
      _text(
        canvas,
        label,
        Offset(x, y + 22),
        fontSize: 22,
        color: const Color(0xB3FFFFFF),
        weight: FontWeight.bold,
        align: _Align.center,
      );
      _text(
        canvas,
        '$year - $sector',
        Offset(x, y + 48),
        fontSize: 16,
        color: const Color(0x59FFFFFF),
        family: 'monospace',
        align: _Align.center,
      );
    }
  }

  /// Knowledge graph: deterministic pseudo-random node cloud with proximity
  /// edges. The hash mirrors the TypeScript `rng` so the layout is identical.
  static void _drawGraph(ui.Canvas canvas, double s) {
    double rng(int i) {
      final v = (math.sin(42 + i * 127.1) * 43758.5453) % 1;
      return (v + 1) % 1;
    }

    final nodes = <Offset>[
      for (var i = 0; i < 24; i++)
        Offset(
          s * 0.15 + rng(i * 2) * s * 0.7,
          s * 0.18 + rng(i * 2 + 1) * s * 0.55,
        ),
    ];

    final edge = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 1;
    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        final a = nodes[i], b = nodes[j];
        if ((a.dx - b.dx).abs() + (a.dy - b.dy).abs() < s * 0.35) {
          canvas.drawLine(a, b, edge);
        }
      }
    }

    for (var i = 0; i < nodes.length; i++) {
      canvas.drawCircle(
        nodes[i],
        4 + rng(i + 100) * 8,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, 0.15 + rng(i + 200) * 0.2),
      );
    }
  }

  /// Escalation funnel: three tiers narrowing top to bottom.
  static void _drawFunnel(ui.Canvas canvas, double s) {
    const tiers = <(String, Color, double)>[
      ('T1 - Instant', Color(0x4D64DC96), 0.7),
      ('T2 - Local LLM', Color(0x40FFC850), 0.5),
      ('T3 - Executive', Color(0x33FF6450), 0.3),
    ];

    for (var i = 0; i < tiers.length; i++) {
      final (label, color, widthRatio) = tiers[i];
      final y = s * 0.28 + i * (s * 0.18);
      final w = s * widthRatio;
      canvas.drawRect(
        Rect.fromLTWH((s - w) / 2, y, w, s * 0.12),
        Paint()..color = color,
      );
      _text(
        canvas,
        label,
        Offset(s / 2, y + s * 0.06),
        fontSize: 22,
        color: const Color(0x99FFFFFF),
        weight: FontWeight.bold,
        family: 'monospace',
        align: _Align.center,
        vCenter: true,
      );
    }
  }

  /// Command-centre dashboard: title bar, service chips, activity rows.
  static void _drawDashboard(ui.Canvas canvas, double s) {
    canvas.drawRect(
      Rect.fromLTWH(s * 0.08, s * 0.15, s * 0.84, s * 0.6),
      Paint()..color = const Color(0x4D000000),
    );
    canvas.drawRect(
      Rect.fromLTWH(s * 0.08, s * 0.15, s * 0.84, s * 0.06),
      Paint()..color = const Color(0x14FFFFFF),
    );
    _text(
      canvas,
      'RAJ SADAN - COMMAND CENTER',
      Offset(s * 0.12, s * 0.165),
      fontSize: 16,
      color: const Color(0x80FFFFFF),
      family: 'monospace',
    );

    const services = <String>[
      'Cortex',
      'Senses',
      'Cron',
      'Knowledge',
      'WhatsApp',
    ];
    for (var i = 0; i < services.length; i++) {
      final x = s * 0.1 + i * 95;
      final y = s * 0.25;
      canvas.drawRect(
        Rect.fromLTWH(x, y, 85, 24),
        Paint()..color = const Color(0x3364DC96),
      );
      _text(
        canvas,
        services[i],
        Offset(x + 42, y + 12),
        fontSize: 12,
        color: const Color(0xB364DC96),
        family: 'monospace',
        align: _Align.center,
        vCenter: true,
      );
    }

    const rows = <String>[
      'Alert: Health check passed',
      'Briefing: Morning ready',
      'Metric: 68 capabilities',
    ];
    for (var i = 0; i < rows.length; i++) {
      final y = s * 0.35 + i * 55;
      canvas.drawRect(
        Rect.fromLTWH(s * 0.1, y, s * 0.8, 42),
        Paint()..color = const Color(0x0DFFFFFF),
      );
      _text(
        canvas,
        rows[i],
        Offset(s * 0.13, y + 13),
        fontSize: 14,
        color: const Color(0x40FFFFFF),
        family: 'monospace',
      );
    }
  }

  /// Chat transcript mock: phone frame with alternating message bubbles.
  static void _drawChat(ui.Canvas canvas, double s) {
    final px = s * 0.25, py = s * 0.12, pw = s * 0.5;

    canvas.drawRect(
      Rect.fromLTWH(px, py, pw, s * 0.68),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x33FFFFFF),
    );
    canvas.drawRect(
      Rect.fromLTWH(px, py, pw, s * 0.06),
      Paint()..color = const Color(0x14FFFFFF),
    );
    _text(
      canvas,
      'Raj Sadan Bot',
      Offset(s / 2, py + s * 0.03),
      fontSize: 16,
      color: const Color(0x80FFFFFF),
      weight: FontWeight.bold,
      align: _Align.center,
      vCenter: true,
    );

    const messages = <(String, bool, double)>[
      ('All 11 services online', true, 0.24),
      ('/status', false, 0.34),
      ('Morning briefing ready', true, 0.44),
      ('Cortex cycle: 14.2s', true, 0.54),
    ];
    for (final (body, fromBot, yRatio) in messages) {
      final bx = fromBot ? px + 15 : px + pw - 200;
      final by = s * yRatio;
      canvas.drawRect(
        Rect.fromLTWH(bx, by, 185, 32),
        Paint()
          ..color =
              fromBot ? const Color(0x14FFFFFF) : const Color(0x26FFFFFF),
      );
      _text(
        canvas,
        body,
        Offset(bx + 10, by + 8),
        fontSize: 14,
        color: const Color(0x99FFFFFF),
        family: 'monospace',
      );
    }
  }

  /* -- Text helper ------------------------------------ */

  static void _text(
    ui.Canvas canvas,
    String value,
    Offset at, {
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.normal,
    String family = 'sans-serif',
    _Align align = _Align.left,
    bool vCenter = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          fontFamily: family,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = switch (align) {
      _Align.left => at.dx,
      _Align.center => at.dx - painter.width / 2,
    };
    final dy = vCenter ? at.dy - painter.height / 2 : at.dy;

    painter.paint(canvas, Offset(dx, dy));
    painter.dispose();
  }
}

enum _Align { left, center }
