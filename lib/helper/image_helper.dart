import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider getCustomImageProvider(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  } else if (path.startsWith('assets/')) {
    return AssetImage(path);
  } else {
    return FileImage(File(path));
  }
}

class NexaImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const NexaImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.trim().isEmpty) {
      return _buildErrorPlaceholder();
    }
    
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder ?? (c, e, s) => _buildErrorPlaceholder(),
      );
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder ?? (c, e, s) => _buildErrorPlaceholder(),
      );
    } else {
      return Image.file(
        File(imagePath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder ?? (c, e, s) => _buildErrorPlaceholder(),
      );
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 150,
      color: Colors.grey.shade100,
      child: Icon(
        Icons.image, 
        color: Colors.grey, 
        size: width != null && width! < 100 ? 24 : 40
      ),
    );
  }
}
