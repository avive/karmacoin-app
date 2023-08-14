import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:karma_coin/common_libs.dart';

class DeleteDataTile extends StatelessWidget {
  const DeleteDataTile({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile.notched(
      title: const Text('Delete Local App Data'),
      leading: const Icon(CupertinoIcons.trash, size: 28),
      onTap: () {
        _displayDeleteDataWarning(context);
      },
    );
  }
}

class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile.notched(
      title: const Text('Delete Account'),
      leading: const FaIcon(FontAwesomeIcons.userXmark, size: 22),
      onTap: () {
        _displayDeleteAccountWarning(context);
      },
    );
  }
}

void _displayDeleteDataWarning(BuildContext context) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: const Text('Delete App Data'),
      content: const Text(
          '\nAre you sure that you backed up your account, you want to delete all local account data and sign out?'),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('No'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () async {
            if (context.canPop()) {
              Navigator.pop(context);
              context.pop();
            }
            Future.delayed(const Duration(milliseconds: 300), () async {
              context.go(ScreenPaths.welcome);
              Future.delayed(const Duration(milliseconds: 300), () async {
                await kc2User.signout();
                await kc2User.init();
              });
            });
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}

void _displayDeleteAccountWarning(BuildContext context) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: const Text('Delete Account'),
      content: const Text(
          '\nAre you sure that you want to delete your account? You will lose all your Karma Coins and Karma. There is no undo.'),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('No'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () async {
            if (context.canPop()) {
              Navigator.pop(context);
              context.pop();
              context.go(ScreenPaths.welcome);
            }

            await kc2Service.deleteUser();
            await kc2User.signout();
            await kc2User.init();
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}
