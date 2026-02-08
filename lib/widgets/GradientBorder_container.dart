import 'package:flutter/material.dart';

import 'package:flutterbhz/widgets/MyColors.dart';

class GradientBorderContainer extends StatelessWidget {
  const GradientBorderContainer({
    super.key,
    required this.height,
    required this.width,
    required this.widget
  });

  final double height;
  final double width;
  final Widget widget;




  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(0,0,0,30),
        child: Container(
            height: height,
            width: width,
            padding: const EdgeInsets.all(3), // border thickness
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ MyColors.ocur, Colors.brown],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // inside color
                  borderRadius: BorderRadius.circular(13),
                ),
                child:widget,
            )
        )
    );
  }

}
