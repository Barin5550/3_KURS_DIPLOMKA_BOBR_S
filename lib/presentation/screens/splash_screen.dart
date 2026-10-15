// Экран-заставка (Splash), который видно сразу после запуска приложения.
// Слой: presentation (интерфейс). Пока показывается анимация логотипа,
// проверяет сохранённый вход («Запомнить меня») и заранее грузит каталог.
// Открывается роутером по адресу /splash (core/router/app_router.dart).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/common.dart';

/// Экран-заставка: логотип, название и проверка сохранённой сессии.
///
/// Переход дальше выполняет redirect роутера: как только AuthController
/// узнает, есть ли сессия, роутер откроет главную или экран входа.
///
/// ConsumerStatefulWidget — виджет с состоянием из библиотеки Riverpod
/// (Riverpod — менеджер состояния; через `ref` экран читает провайдеры).
class SplashScreen extends ConsumerStatefulWidget {
  /// Создаёт заставку; [minDuration] — сколько её минимум показывать.
  const SplashScreen({
    super.key,
    this.minDuration = const Duration(milliseconds: 1500),
  });

  /// Минимальное время показа заставки (по умолчанию 1,5 секунды), чтобы
  /// она не мелькнула на долю секунды.
  final Duration minDuration;

  /// Создаёт объект состояния, в котором живёт вся логика экрана.
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

/// Состояние заставки: анимация появления и запуск проверки входа.
///
/// SingleTickerProviderStateMixin даёт «тикер» (сигнал каждого кадра),
/// без которого не работает AnimationController.
class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Контроллер анимации появления логотипа: длится 0,9 секунды и
  /// запускается сразу при создании (`..forward()`).
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  /// Вызывается один раз при появлении экрана: запускает _start.
  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Ждёт минимальное время показа и прогрев каталога, затем
  /// восстанавливает сессию пользователя.
  Future<void> _start() async {
    // Обе задачи идут параллельно; ждём, пока закончатся обе.
    await Future.wait([Future<void>.delayed(widget.minDuration), _warmUp()]);
    // Если экран уже закрыт, дальше ничего не делаем.
    if (!mounted) return;
    // Проверяем «Запомнить меня». После этого AuthController меняет
    // состояние, и роутер сам переводит на главную или на вход.
    await ref.read(authControllerProvider.notifier).restoreSession();
  }

  /// Заранее загружаем каталог тем, пока показывается заставка.
  Future<void> _warmUp() async {
    try {
      // Запрашиваем список направлений; провайдер запомнит результат,
      // и следующие экраны получат его сразу. Ждём не больше 3 секунд:
      // если сервер недоступен, заставка не должна висеть.
      await ref
          .read(directionsProvider.future)
          .timeout(const Duration(seconds: 3));
    } on Object {
      // Ошибку каталога (или долгий ответ) покажет экран, который его
      // использует.
    }
  }

  /// Вызывается при закрытии экрана: освобождает контроллер анимации.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Строит внешний вид заставки.
  @override
  Widget build(BuildContext context) {
    // Плавная кривая анимации: быстро в начале, медленно в конце.
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return Scaffold(
      // Тёмно-синий фон заставки из палитры приложения.
      backgroundColor: AppColors.navyDark,
      // ContentFrame ограничивает ширину на широких экранах.
      body: ContentFrame(
        child: Center(
          // Содержимое плавно проявляется из прозрачного...
          child: FadeTransition(
            opacity: fade,
            // ...и одновременно увеличивается с 85 % до 100 %.
            child: ScaleTransition(
              scale: Tween(begin: .85, end: 1.0).animate(fade),
              // Логотип, название, подзаголовок и индикатор — столбиком.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Большой логотип приложения.
                  const AppLogo(size: 112),
                  const SizedBox(height: 24),
                  // Название приложения крупным белым шрифтом.
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
                  // Подзаголовок полупрозрачным белым цветом.
                  Text(
                    'Персональный план обучения',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .75),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Оранжевый крутящийся индикатор загрузки 28×28.
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
