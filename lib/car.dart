import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math';
import 'package:flutter/services.dart';

class Car extends StatelessWidget {
  const Car({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: CarRacingGame(),
        overlayBuilderMap: {
          'GameOver': (context, game) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Game Over',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    (game as CarRacingGame).restart();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Restart',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}
class CarRacingGame extends FlameGame with TapCallbacks, KeyboardEvents {
  late SpriteComponent playerCar;
  final List<SpriteComponent> obstacles = [];
  final Random random = Random();

  // السرعات
  double moveSpeed = 500; // السرعة الجانبية الجديدة (أعلى من قبل)
  double verticalSpeed = 350; // سرعة لأعلى ولأسفل
  double spawnTimer = 0;
  double obstacleSpeed = 250;
  bool isGameOver = false;

  // التحكم
  bool moveLeft = false;
  bool moveRight = false;
  bool moveUp = false;
  bool moveDown = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // الخلفية
    final road = SpriteComponent()
      ..sprite = await loadSprite('background.png')
      ..size = Vector2(size.x, size.y)
      ..priority = 0;
    add(road);

    // سيارة اللاعب
    playerCar = SpriteComponent()
      ..sprite = await loadSprite('pngwing.com.png')
      ..size = Vector2(80, 130)
      ..position = Vector2(size.x / 2 - 40, size.y - 180)
      ..priority = 1;
    add(playerCar);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    // حركة فورية وسريعة
    if (moveLeft) {
      playerCar.x -= moveSpeed * dt;
    } else if (moveRight) {
      playerCar.x += moveSpeed * dt;
    }

    if (moveUp) {
      playerCar.y -= verticalSpeed * dt;
    } else if (moveDown) {
      playerCar.y += verticalSpeed * dt;
    }

    // حدود الشاشة
    if (playerCar.x < 0) playerCar.x = 0;
    if (playerCar.x > size.x - playerCar.width) {
      playerCar.x = size.x - playerCar.width;
    }
    if (playerCar.y < 0) playerCar.y = 0;
    if (playerCar.y > size.y - playerCar.height) {
      playerCar.y = size.y - playerCar.height;
    }

    // تحريك العوائق
    for (var obs in obstacles) {
      obs.y += obstacleSpeed * dt;
    }

    // إزالة العوائق الخارجة
    obstacles.removeWhere((obs) {
      if (obs.y > size.y) {
        remove(obs);
        return true;
      }
      return false;
    });

    // توليد عوائق جديدة
    spawnTimer += dt;
    if (spawnTimer > 1.2) {
      spawnObstacle();
      spawnTimer = 0;
    }

    // التحقق من الاصطدام
    for (var obs in obstacles) {
      if (playerCar.toRect().overlaps(obs.toRect())) {
        gameOver();
        break;
      }
    }
  }


  Future<void> spawnObstacle() async {
    final obstacle = SpriteComponent()
      ..sprite = await loadSprite('pngwing.com (1).png')
      ..size = Vector2(50, 80) // ✅ حجم أصغر
      ..position = Vector2(random.nextDouble() * (size.x - 50), -100)
      ..priority = 1;

    add(obstacle);
    obstacles.add(obstacle);
  }


  // ✅ استخدام مفاتيح الكيبورد
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    moveLeft = keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    moveRight = keysPressed.contains(LogicalKeyboardKey.arrowRight);
    moveUp = keysPressed.contains(LogicalKeyboardKey.arrowUp);
    moveDown = keysPressed.contains(LogicalKeyboardKey.arrowDown);
    return KeyEventResult.handled;
  }

  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    overlays.add('GameOver');
  }

  void restart() {
    isGameOver = false;
    playerCar.position = Vector2(size.x / 2 - 40, size.y - 180);
    for (var obs in obstacles) {
      remove(obs);
    }
    obstacles.clear();
    overlays.remove('GameOver');
  }
}
