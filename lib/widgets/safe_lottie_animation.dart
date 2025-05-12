import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:station_meteo/utils/animation_utils.dart';

class SafeLottieAnimation extends StatefulWidget {
  final String animationType;
  final double width;
  final double height;
  final bool repeat;
  final bool animate;
  final BoxFit fit;

  const SafeLottieAnimation({
    Key? key,
    required this.animationType,
    this.width = 200,
    this.height = 200,
    this.repeat = true,
    this.animate = true,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  State<SafeLottieAnimation> createState() => _SafeLottieAnimationState();
}

class _SafeLottieAnimationState extends State<SafeLottieAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.animate) {
      _controller.forward();
      if (widget.repeat) {
        _controller.repeat(reverse: false);
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AnimationUtils.checkInternetConnection(),
      builder: (context, snapshot) {
        final hasInternet = snapshot.data ?? false;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!hasInternet) {
          return Icon(
            AnimationUtils.getFallbackIcon(widget.animationType),
            size: widget.width / 2,
            color: AnimationUtils.getFallbackColor(widget.animationType),
          );
        }

        return Lottie.network(
          AnimationUtils.getWeatherAnimationUrl(widget.animationType),
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          controller: _controller,
          onLoaded: (composition) {
            setState(() {
              _isLoading = false;
              _controller.duration = composition.duration;
              if (widget.animate) {
                _controller.forward();
                if (widget.repeat) {
                  _controller.repeat(reverse: false);
                }
              }
            });
          },
          frameBuilder: (context, child, composition) {
            if (composition == null) {
              return Center(
                child: SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }
            return child;
          },
          errorBuilder: (context, error, stackTrace) {
            print('Erreur de chargement Lottie: $error');
            setState(() {
              _hasError = true;
            });
            return Icon(
              AnimationUtils.getFallbackIcon(widget.animationType),
              size: widget.width / 2,
              color: AnimationUtils.getFallbackColor(widget.animationType),
            );
          },
        );
      },
    );
  }
}
