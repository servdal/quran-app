
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Paksa aplikasi ke mode landscape.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MurottalApp());
}

class MurottalApp extends StatelessWidget {
  const MurottalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mushaf Murottal Player',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFF020B1C),
      ),
      home: const MurottalPlayerPage(),
    );
  }
}

class MurottalPlayerPage extends StatefulWidget {
  const MurottalPlayerPage({super.key});

  @override
  State<MurottalPlayerPage> createState() => _MurottalPlayerPageState();
}

class _MurottalPlayerPageState extends State<MurottalPlayerPage>
    with TickerProviderStateMixin {
  late final AnimationController _beatController;
  late final AnimationController _glowController;

  bool _isPlaying = true;
  bool _showArabic = true;
  bool _showTransliteration = true;
  bool _showTranslation = true;

  double _progress = 0.12;

  @override
  void initState() {
    super.initState();

    _beatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _beatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);

    if (_isPlaying) {
      _beatController.repeat(reverse: true);
    } else {
      _beatController.stop();
    }
  }

  void _openVisibilityPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF08162F),
      barrierColor: Colors.black.withValues(alpha: .55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            void update(VoidCallback fn) {
              modalSetState(fn);
              setState(fn);
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Icon(Icons.visibility_outlined, color: Colors.cyanAccent),
                        SizedBox(width: 10),
                        Text(
                          'Tampilan Teks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      value: _showArabic,
                      activeColor: Colors.cyanAccent,
                      title: const Text('Teks Arab'),
                      onChanged: (value) => update(() => _showArabic = value),
                    ),
                    SwitchListTile.adaptive(
                      value: _showTransliteration,
                      activeColor: Colors.cyanAccent,
                      title: const Text('Transliterasi'),
                      onChanged: (value) =>
                          update(() => _showTransliteration = value),
                    ),
                    SwitchListTile.adaptive(
                      value: _showTranslation,
                      activeColor: Colors.cyanAccent,
                      title: const Text('Terjemahan'),
                      onChanged: (value) =>
                          update(() => _showTranslation = value),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openMenu() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 140, vertical: 50),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xF2081630),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: .22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: .08),
                  blurRadius: 35,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _MenuAction(
                  icon: Icons.library_music_outlined,
                  title: 'Daftar Surah',
                  onTap: () {},
                ),
                _MenuAction(
                  icon: Icons.graphic_eq,
                  title: 'Equalizer',
                  onTap: () {},
                ),
                _MenuAction(
                  icon: Icons.visibility_outlined,
                  title: 'Tampilan Teks',
                  onTap: () {
                    Navigator.pop(context);
                    _openVisibilityPanel();
                  },
                ),
                _MenuAction(
                  icon: Icons.settings_outlined,
                  title: 'Pengaturan',
                  onTap: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _BackgroundLayer()),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                child: Column(
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 105,
                            child: _buildLeftRail(),
                          ),
                          Expanded(
                            child: _buildCenterContent(size),
                          ),
                          SizedBox(
                            width: 105,
                            child: _buildRightRail(),
                          ),
                        ],
                      ),
                    ),
                    _buildPlayerControls(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF071933),
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: .22),
            ),
          ),
          padding: const EdgeInsets.all(7),
          child: Image.asset(
            'assets/mascot.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.smart_toy_outlined,
              color: Colors.cyanAccent,
              size: 34,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mushaf Murottal Player',
              style: TextStyle(
                fontSize: 27,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'SOFTWARE HOUSE',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.6,
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          children: [
            const Text(
              'Surah Ar-Rahman',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Surah ke-55  •  78 Ayat',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .56),
                fontSize: 13,
              ),
            ),
          ],
        ),
        const Spacer(),
        _CircleButton(
          icon: Icons.menu_rounded,
          onTap: _openMenu,
        ),
      ],
    );
  }

  Widget _buildLeftRail() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          icon: Icons.chevron_left_rounded,
          onTap: () {},
          size: 64,
        ),
        const Spacer(),
        _CircleButton(
          icon: Icons.tune_rounded,
          onTap: () {},
          size: 64,
        ),
      ],
    );
  }

  Widget _buildRightRail() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          icon: Icons.chevron_right_rounded,
          onTap: () {},
          size: 64,
        ),
        const Spacer(),
        _CircleButton(
          icon: Icons.visibility_outlined,
          onTap: _openVisibilityPanel,
          size: 64,
        ),
      ],
    );
  }

  Widget _buildCenterContent(Size size) {
    final compactHeight = size.height < 500;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: compactHeight ? 125 : 170,
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _beatController,
                    _glowController,
                  ]),
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(
                        math.min(constraints.maxWidth * .65, 720),
                        compactHeight ? 115 : 160,
                      ),
                      painter: _BeatPainter(
                        beat: _isPlaying ? _beatController.value : .18,
                        phase: _glowController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 2),
            _VerseBadge(number: 13),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showArabic) ...[
                    const SizedBox(height: 10),
                    Text(
                      'فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: compactHeight ? 35 : 48,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(alpha: .22),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_showTransliteration) ...[
                    const SizedBox(height: 5),
                    const Text(
                      'Fa bi-ayyi ālā’i rabbikumā tukadzdzibān',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        color: Color(0xFF23E7A8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_showTranslation) ...[
                    const SizedBox(height: 9),
                    Text(
                      'Maka nikmat Tuhanmu yang manakah yang kamu dustakan?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white.withValues(alpha: .88),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayerControls() {
    return Container(
      height: 88,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: const Color(0xB8081730),
        border: Border.all(
          color: const Color(0xFF4D7CFE).withValues(alpha: .16),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '02:35',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: Colors.cyanAccent,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white,
                overlayColor: Colors.cyanAccent.withValues(alpha: .12),
              ),
              child: Slider(
                value: _progress,
                onChanged: (v) => setState(() => _progress = v),
              ),
            ),
          ),
          const SizedBox(width: 15),
          const Text(
            '21:07',
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 30),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.skip_previous_rounded),
            iconSize: 34,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _togglePlay,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00D7FF),
                    Color(0xFF6B4EFF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D7FF).withValues(alpha: .25),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF071731),
                ),
                child: Icon(
                  _isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.skip_next_rounded),
            iconSize: 34,
          ),
          const SizedBox(width: 22),
          IconButton(
            tooltip: 'Teks',
            onPressed: _openVisibilityPanel,
            icon: const Icon(Icons.translate_rounded),
          ),
        ],
      ),
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.15),
          radius: 1.15,
          colors: [
            Color(0xFF0A2250),
            Color(0xFF041329),
            Color(0xFF020817),
          ],
          stops: [0, .55, 1],
        ),
      ),
      child: CustomPaint(
        painter: _BackgroundPatternPainter(),
      ),
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: .035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const step = 42.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final path = Path()
          ..moveTo(x + step * .5, y)
          ..lineTo(x + step, y + step * .25)
          ..lineTo(x + step * .75, y + step * .5)
          ..lineTo(x + step, y + step * .75)
          ..lineTo(x + step * .5, y + step)
          ..lineTo(x, y + step * .75)
          ..lineTo(x + step * .25, y + step * .5)
          ..lineTo(x, y + step * .25)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BeatPainter extends CustomPainter {
  final double beat;
  final double phase;

  _BeatPainter({
    required this.beat,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.height * .35, 62.0);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00D7FF),
          Color(0xFF4F7BFF),
          Color(0xFF8F4DFF),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: baseRadius + 25),
      );

    canvas.drawCircle(center, baseRadius + beat * 7, ringPaint);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF5CCFFF).withValues(alpha: .18 + .18 * beat);

    canvas.drawCircle(center, baseRadius + 15 + beat * 10, glowPaint);

    // Equalizer tengah.
    const barCount = 9;
    const barWidth = 10.0;
    const gap = 6.0;
    final totalWidth = barCount * barWidth + (barCount - 1) * gap;
    final startX = center.dx - totalWidth / 2;

    final eqPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF23E7FF),
          Color(0xFF5B62FF),
          Color(0xFF9D4DFF),
        ],
      ).createShader(
        Rect.fromCenter(center: center, width: totalWidth, height: 90),
      );

    for (int i = 0; i < barCount; i++) {
      final wave = .45 +
          .55 *
              ((math.sin(
                        (i * .82) +
                            (phase * math.pi * 2) +
                            beat * 2.2,
                      ) +
                      1) /
                  2);
      final h = 22 + wave * 60;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          startX + i * (barWidth + gap),
          center.dy - h / 2,
          barWidth,
          h,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, eqPaint);
    }

    // Waveform kiri/kanan.
    final wavePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00CCFF),
          Color(0xFF4D7CFE),
          Color(0xFF9A4DFF),
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    const barsPerSide = 24;
    final sideStartOffset = baseRadius + 40;

    for (int side = -1; side <= 1; side += 2) {
      for (int i = 0; i < barsPerSide; i++) {
        final normalized = i / barsPerSide;
        final amplitude = 8 +
            34 *
                (1 - normalized) *
                (.35 +
                    .65 *
                        ((math.sin(
                                  i * .9 +
                                      phase * math.pi * 2 +
                                      (side == -1 ? 0 : 1.4),
                                ) +
                                1) /
                            2)) *
                (.5 + beat * .5);

        final x = center.dx +
            side *
                (sideStartOffset +
                    i * ((size.width / 2 - sideStartOffset - 10) /
                        barsPerSide));

        canvas.drawLine(
          Offset(x, center.dy - amplitude),
          Offset(x, center.dy + amplitude),
          wavePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BeatPainter oldDelegate) {
    return oldDelegate.beat != beat || oldDelegate.phase != phase;
  }
}

class _VerseBadge extends StatelessWidget {
  final int number;

  const _VerseBadge({
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF74BFFF),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: .12),
            blurRadius: 15,
          ),
        ],
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xB8081730),
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: .25),
            ),
          ),
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: .04),
              border: Border.all(
                color: Colors.white.withValues(alpha: .07),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 30,
                  color: Colors.cyanAccent,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*
Tambahkan asset berikut ke pubspec.yaml:

flutter:
  assets:
    - assets/mascot.png

Lalu simpan gambar maskot Anda sebagai:
assets/mascot.png

Catatan:
- File ini fokus pada UI dan animasi beat/equalizer.
- Tombol play/pause saat ini hanya mengatur animasi UI.
- Untuk audio sungguhan, Anda dapat menghubungkan just_audio atau audioplayers.
*/
