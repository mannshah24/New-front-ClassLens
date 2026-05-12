import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

Future<T?> navigatorWithAnimation<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    ),
  );
}


void splashScreenNavigator(BuildContext context, Widget page){
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
        pageBuilder:(context,animation,secondaryAnimation)=> page,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context,animation,secondaryAnimation,child){
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var fadeTween = Tween<double>(begin: 0, end: 1);

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child),

          );
        }),
  );
}
