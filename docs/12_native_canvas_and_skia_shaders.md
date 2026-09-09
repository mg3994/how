# 12. Low-Level Custom Graphics & Skia Runtime Shaders

## 1. Dual Graphics Architecture

DartNative provides two distinct custom graphics pipelines based on application performance and visual requirements:

```
                          Custom Graphics Pipeline
                                     │
                 ┌───────────────────┴───────────────────┐
                 ▼                                       ▼
    ┌───────────────────────────┐           ┌───────────────────────────┐
    │     Standard Canvas       │           │       Skia Engine         │
    │      (`CustomPaint`)      │           │    (`CanvasSurface`)      │
    ├───────────────────────────┤           ├───────────────────────────┤
    │ CoreGraphics (iOS)        │           │ Embedded Skia GPU         │
    │ android.graphics (Android)│           │ SkSL Custom Shaders       │
    │ Zero GPU memory overhead  │           │ Complex path blending     │
    └───────────────────────────┘           └───────────────────────────┘
```

---

## 2. Platform CoreGraphics / Android Canvas (`CustomPaint`)

By default, the `CustomPaint` widget delegates drawing calls directly to host OS drawing contexts:
- **iOS**: Executed inside `UIView.drawRect:` using **CoreGraphics** (`CGContextRef`).
- **Android**: Executed inside `View.onDraw()` using `android.graphics.Canvas`.

```dart
import 'package:dartnative/dartnative.dart';

class CircleProgressWidget extends StatelessWidget {
  final double progress;

  const CircleProgressWidget({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 100),
      painter: CircleProgressPainter(progress),
    );
  }
}

class CircleProgressPainter extends CustomPainter {
  final double progress;

  CircleProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background track paint
    final trackPaint = Paint()
      :color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc paint
    final progressPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90 degrees in radians
      6.28318 * progress, // Progress arc angle
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
```

---

## 3. GPU Skia Runtime Shaders (`CanvasSurface` & SkSL)

For GPU-accelerated fragment shaders, fluid simulations, procedural noise, or complex particle effects, import `dartnative_skia`:

```dart
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_skia/dartnative_skia.dart';

// SkSL Fragment Shader Source Code
const String _skslSource = '''
  uniform float2 iResolution;
  uniform float iTime;

  half4 main(float2 fragCoord) {
    float2 uv = fragCoord / iResolution.xy;
    float col = 0.5 + 0.5 * sin(iTime + uv.x * 10.0);
    return half4(col, uv.y, 0.8, 1.0);
  }
''';

class ShaderDemoScreen extends StatefulWidget {
  const ShaderDemoScreen({super.key});

  @override
  State<ShaderDemoScreen> createState() => _ShaderDemoScreenState();
}

class _ShaderDemoScreenState extends State<ShaderDemoScreen> with SingleTickerProviderStateMixin {
  late final RuntimeEffect _effect;

  @override
  void initState() {
    super.initState();
    _effect = RuntimeEffect.parse(_skslSource);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skia SkSL Shader')),
      body: CanvasSurface(
        painter: ShaderPainter(effect: _effect, time: DateTime.now().millisecondsSinceEpoch / 1000.0),
      ),
    );
  }
}

class ShaderPainter extends CustomPainter {
  final RuntimeEffect effect;
  final double time;

  ShaderPainter({required this.effect, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final shader = effect.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant ShaderPainter oldDelegate) => true;
}
```

When using `CanvasSurface`, DartNative binds a native `CAMetalLayer` / `CAEAGLLayer` (iOS) or `SurfaceView` (Android) backed directly by an embedded Skia GPU rendering context.
