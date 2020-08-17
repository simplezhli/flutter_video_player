

import 'package:flutter/material.dart';

class SeekDialog extends StatelessWidget {

  const SeekDialog({
    Key key,
    @required this.child,
  }) : super(key: key);

  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      height: 36.0,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
        ],
      ),
    );
  }
}
