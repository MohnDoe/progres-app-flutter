import 'package:flutter/material.dart';

class BottomBarButton extends StatelessWidget {
  const BottomBarButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  final void Function()? onTap;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
        child: Column(
          spacing: 4,
          mainAxisSize: MainAxisSize.min,
          children: [icon, Text(label)],
        ),
      ),
    );
  }
}
