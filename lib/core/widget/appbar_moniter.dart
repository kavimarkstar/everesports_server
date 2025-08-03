import 'package:everesports_server/theme/colors.dart';
import 'package:flutter/material.dart';

Widget appBarMoniter(BuildContext context, String text, IconData icon) {
  return Container(
    margin: const EdgeInsets.only(right: 16),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: mainColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: mainColor.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: mainColor, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: mainColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
