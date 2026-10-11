import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/common.dart';

/// Экран-заставка: логотип, название и проверка сохранённой сессии.
///
/// Переход дальше выполняет redirect роутера: как только AuthController
/// узнает, есть ли сессия, роутер откроет главную или экран входа.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.minDuration = const Duration(milliseconds: 1500),
  });

  final Duration minDuration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future.wait([Future<void>.delayed(widget.minDuration), _warmUp()]);
    if (!mounted) return;
    await ref.read(authControllerProvider.notifier).restoreSession();
  }

  /// Заранее загружаем каталог тем, пока показывается заставка.
  Future<void> _warmUp() async {
    try {
      await ref.read(directionsProvider.future);
    } on Object {
      // Ошибку каталога покажет экран, который его использует.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: ContentFrame(
        child: Center(
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: Tween(begin: .85, end: 1.0).animate(fade),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 112),
                  const SizedBox(height: 24),
                  const Text(
                    'Маршрут',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Персональный план обучения',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .75),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.orange,
                    ),
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
