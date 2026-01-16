import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/universal_meal_image.dart';

class ImageFullScreen extends StatefulWidget {
  static const fullScreenHeroTag = 'fullScreenTag';

  const ImageFullScreen({super.key});

  @override
  State<ImageFullScreen> createState() => _ImageFullScreenState();
}

class _ImageFullScreenState extends State<ImageFullScreen> {
  late String imageUrl;

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as ImageFullScreenArguments;
    imageUrl = args.imageUrl;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: InteractiveViewer(
        child: Hero(
          tag: ImageFullScreen.fullScreenHeroTag,
          child: UniversalMealImage(
            width: double.infinity,
            height: double.infinity,
            imageUrl: imageUrl,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class ImageFullScreenArguments {
  final String imageUrl;

  ImageFullScreenArguments(this.imageUrl);
}
