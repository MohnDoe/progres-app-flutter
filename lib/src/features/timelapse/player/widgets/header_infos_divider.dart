import 'package:flutter/material.dart';
import 'package:progres/font_awesome_flutter/lib/font_awesome_flutter.dart';

class HeaderInfosDivider extends StatelessWidget {
  const HeaderInfosDivider({super.key, this.count = 7, this.size = 10});
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          count,
          (_) => FaIcon(
            FontAwesomeIcons.solidChevronRight,
            size: size,
            color: Theme.of(context).dividerColor,
          ),
        ).toList(),
      ),
    );
  }
}
