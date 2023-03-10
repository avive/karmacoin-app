import 'package:karma_coin/common/platform_info.dart';
import 'package:status_alert/status_alert.dart';

import '../../common_libs.dart';

// common widget helper functions

Widget adjustNavigationBarButtonPosition(Widget button, double x, double y) {
  return Container(
    transform: Matrix4.translationValues(x, y, 0),
    child: button,
  );
}

/// Check for Internet connection and display alert if not connected
Future<bool> checkInternetConnection(BuildContext context) async {
  bool isConnected = await PlatformInfo.isConnected();

  if (!isConnected) {
    StatusAlert.show(context,
        duration: Duration(seconds: 4),
        title: 'No Internet',
        subtitle: 'Check your connection',
        configuration:
            IconConfiguration(icon: CupertinoIcons.exclamationmark_triangle),
        dismissOnBackgroundTap: true,
        maxWidth: 260);
  }

  return isConnected;
}
