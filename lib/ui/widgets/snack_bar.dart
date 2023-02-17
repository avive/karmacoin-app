import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';

class GloblaSnackWdiget extends StatefulWidget {
  const GloblaSnackWdiget({super.key});

  @override
  State<GloblaSnackWdiget> createState() => _GloblaSnackWdigetState();
}

class _GloblaSnackWdigetState extends State<GloblaSnackWdiget> {
  _GloblaSnackWdigetState();
  bool _snackBarVisible = false;

  static SnackBar _snackBar = SnackBar(
      duration: const Duration(seconds: 5),
      content: Column(
        children: [
          Row(
            children: [
              ValueListenableBuilder<SnackType>(
                  valueListenable: appState.snackType,
                  builder: (context, value, child) {
                    return Icon(Icons.error_outline, color: Colors.red);
                  }),
              ValueListenableBuilder<String>(
                  valueListenable: appState.snackMessage,
                  builder: (context, value, child) {
                    return Text(value);
                  }),
            ],
          ),
        ],
      ));

  @override
  build(BuildContext context) {
    return ValueListenableBuilder<String>(
        valueListenable: appState.snackMessage,
        builder: (context, value, child) {
          if (value.isNotEmpty && !_snackBarVisible) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (value.isNotEmpty && !_snackBarVisible) {
                debugPrint(_snackBarVisible.toString());
                setState(() {
                  _snackBarVisible = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(_snackBar);

                Future.delayed(const Duration(milliseconds: 5000), () {
                  setState(() {
                    appState.snackMessage.value = '';
                  });
                });
              }
            });
          }
          return Container();
        });
  }
}
