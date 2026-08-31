import 'package:flutter/material.dart';

final class LoadingView extends StatelessWidget {
  const LoadingView({this.label = 'Loading…', super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label),
        ],
      ),
    ),
  );
}
