import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';

class NetworkAvatar extends StatelessWidget {
  const NetworkAvatar({
    required this.imageUrl,
    super.key,
    this.radius = 24,
    this.heroTag,
  });

  final String imageUrl;
  final double radius;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surfaceElevated,
      backgroundImage: CachedNetworkImageProvider(imageUrl),
    );

    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: avatar);
    }

    return avatar;
  }
}
