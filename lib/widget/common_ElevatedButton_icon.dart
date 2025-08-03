import 'package:everesports_server/theme/colors.dart';
import 'package:flutter/material.dart';

Widget commonElevatedButtonIcon(
  BuildContext context,
  String label,
  IconData icon,
  Function() onPressed,
) {
  return SizedBox(
    width: double.infinity,
    height: 40,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.background),
      label: Text(
        label,
        style: TextStyle(color: AppColors.background, fontFamily: 'Poppins'),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,

        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
