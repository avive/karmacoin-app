import '../../common_libs.dart';

class DeleteAccountTile extends StatelessWidget {
  DeleteAccountTile({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile.notched(
      title: const Text('Delete App Data'),
      leading: const Icon(CupertinoIcons.delete, size: 28),
      onTap: () {
        _displayWarning(context);
      },
    );
  }
}

void _displayWarning(BuildContext context) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: const Text('Delete App Data'),
      content: const Text(
          '\nAre you sure that you backed up your account, you want to delete all local account data and sign out?'),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          /// This parameter indicates this action is the default,
          /// and turns the action's text to bold text.
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('No'),
        ),
        CupertinoDialogAction(
          /// This parameter indicates the action would perform
          /// a destructive action such as deletion, and turns
          /// the action's text color to red.
          isDestructiveAction: true,
          onPressed: () async {
            if (context.canPop()) {
              Navigator.pop(context);
              context.pop();
            }
            Future.delayed(Duration(milliseconds: 300), () async {
              context.go(ScreenPaths.welcome);
              Future.delayed(Duration(milliseconds: 300), () async {
                await accountLogic.clear();
                await authLogic.signOut();
              });
            });
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}
