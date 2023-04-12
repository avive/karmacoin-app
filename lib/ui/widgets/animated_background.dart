import 'package:flutter/material.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:simple_animations/simple_animations.dart';

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    Brightness brightness = WidgetsBinding.instance.window.platformBrightness;
    Color bcgColor =
        brightness == Brightness.dark ? Colors.black : Colors.white;

    final movieTween = MovieTween()
      ..tween('color1', ColorTween(begin: kcOrange, end: bcgColor),
          duration: const Duration(seconds: 10))
      ..tween('color2', ColorTween(begin: kcPurple, end: bcgColor),
          duration: const Duration(seconds: 10));

    return MirrorAnimationBuilder<Movie?>(
        tween: movieTween,
        duration: movieTween.duration,
        builder: (context, value, child) {
          Color color1 = value!.get('color1');
          Color color2 = value.get('color2');
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color1, color2]),
            ),
          );
        });
  }
}
