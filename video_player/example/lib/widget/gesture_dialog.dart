

import 'package:flutter/material.dart';

class GestureDialog extends StatelessWidget {

  const GestureDialog({
    Key key,
    @required this.icon,
    @required this.value,
  }) : super(key: key);

  final IconData icon;
  final double value;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      height: 46.0,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
          ),
          const SizedBox(width: 8,),
          Container(
            width: 100,
            child: LinearProgressIndicator(
              value: value,
              minHeight: 3.0,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).accentColor),
              backgroundColor: Colors.white.withOpacity(.3),
            ),
          ),
        ],
      ),
    );
  }
}
