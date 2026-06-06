import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_text.dart';

class PublicStandaloneScreen extends StatelessWidget {
  const PublicStandaloneScreen({
    super.key,
    required this.title,
    required this.child,
    this.titleWidget,
    this.rightWidget,
  });

  final String title;
  final Widget child;
  final Widget? titleWidget;
  final Widget? rightWidget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.localize.back,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go('/');
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: titleWidget ?? Text(title),
        actions: [
          if (rightWidget != null)
            rightWidget!,
        ],
      ),
      body: child,
    );
  }
}
