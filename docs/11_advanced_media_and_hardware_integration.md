# 11. Advanced Media & Hardware Platform Integration

## 1. Native Media Architecture

DartNative handles media rendering and hardware capabilities by embedding true host platform components directly into the view hierarchy rather than streaming pixel buffers over channels.

```
┌──────────────────────────────────────────────────────────────────┐
│                   DartNative View Hierarchy                      │
│                                                                  │
│  ┌───────────────────────┐          ┌─────────────────────────┐  │
│  │   Camera Preview      │          │   Video Player View     │  │
│  │   (AVCaptureVideo     │          │   (AVPlayerLayer /      │  │
│  │    PreviewLayer /     │          │    ExoPlayer Surface)   │  │
│  │    SurfaceTexture)    │          │                         │  │
│  └───────────────────────┘          └─────────────────────────┘  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. Hardware Camera Stream (`dartnative_camera`)

The `dartnative_camera` plugin binds native `AVCaptureSession` (iOS) and `Camera2` / `CameraX` (Android) pipelines directly to native preview views.

```dart
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_camera/dartnative_camera.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await Camera.getAvailableCameras();
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras.first, ResolutionPreset.high);
      await _controller!.initialize();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    // Renders native AVCaptureVideoPreviewLayer / SurfaceTexture
    return CameraPreview(_controller!);
  }
}
```

---

## 3. High-Performance Video Player (`dartnative_video_player`)

`dartnative_video_player` wraps native hardware-accelerated video views (`AVPlayerLayer` on iOS, `ExoPlayer` / `StyledPlayerView` on Android):

```dart
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_video_player/dartnative_video_player.dart';

Widget buildVideoWidget(String videoUrl) {
  return VideoPlayer(
    url: videoUrl,
    autoPlay: true,
    looping: true,
    aspectRatio: 16 / 9,
    showControls: true,
    onVideoEnded: () => print('Video playback finished'),
  );
}
```

- **Features**: Hardware H.264 / HEVC decoding, HTTP live streaming (HLS), background audio session registration, and native picture-in-picture (PiP) support.

---

## 4. Native Vector Animation Engine (`dartnative_lottie`)

Instead of parsing JSON vector keyframes in Dart, `dartnative_lottie` delegates animation playback directly to CoreAnimation (iOS) and Airbnb Lottie Android (`LottieAnimationView`):

```dart
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_lottie/dartnative_lottie.dart';

Widget buildLottieAnimation() {
  return Lottie.asset(
    'assets/animations/success.json',
    width: 200,
    height: 200,
    repeat: true,
  );
}
```

---

## 5. Google Maps Integration (`dartnative_google_maps`)

`dartnative_google_maps` embeds host `GMSMapView` (iOS) and `MapView` (Android) instances as first-class native view nodes inside the Yoga layout hierarchy:

```dart
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_google_maps/dartnative_google_maps.dart';

Widget buildMapView() {
  return GoogleMap(
    initialCameraPosition: const CameraPosition(
      target: LatLng(37.7749, -122.4194), // San Francisco
      zoom: 12.0,
    ),
    markers: {
      Marker(
        markerId: 'sf_pin',
        position: const LatLng(37.7749, -122.4194),
        title: 'San Francisco',
      ),
    },
  );
}
```

---

## 6. Social Authentication (`dartnative_social_sign_in`)

Provides native authentication sheets for **Sign in with Apple** (`ASAuthorizationController`) and **Google Sign-In** (`Credential Manager` / `One Tap`):

```dart
import 'package:dartnative/dartnative.dart';
import 'package:dartnative_social_sign_in/dartnative_social_sign_in.dart';

Future<void> handleAppleSignIn() async {
  final credential = await SocialSignIn.signInWithApple(
    scopes: [AppleScope.email, AppleScope.fullName],
  );
  print('Apple User ID: ${credential.userIdentifier}');
}
```
