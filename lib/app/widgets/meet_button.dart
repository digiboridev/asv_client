import 'package:flutter/material.dart';

class MeetButton extends StatelessWidget {
  const MeetButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.tooltip = '',
  }) : super(key: key);

  final Icon icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(4, 4), // changes position of shadow
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        iconSize: 24,
        icon: icon,
        color: Colors.pink.shade800,
        onPressed: onPressed,
      ),
    );
  }
}
