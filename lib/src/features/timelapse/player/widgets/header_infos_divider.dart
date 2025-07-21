import 'package:flutter/material.dart';
import 'package:progres/font_awesome_flutter/lib/font_awesome_flutter.dart';

class HeaderInfosDivider extends StatelessWidget {
  const HeaderInfosDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          7,
          (_) => FaIcon(
            FontAwesomeIcons.solidChevronRight,
            size: 10,
            color: Theme.of(context).dividerColor,
          ),
        ).toList(),
      ),
    );
  }
}
