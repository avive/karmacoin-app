import 'package:karma_coin/services/api/api.pbgrpc.dart';

import '../common_libs.dart';

enum UserNameAvailabilityStatus {
  unknown,
  checking,
  available,
  unavailable,
  error
}

/// The UserNameAvailabilityLogic class is responsible for checking if a user name
/// is available. Karma Coin user names are unique
class UserNameAvailabilityLogic extends ChangeNotifier {
  String _userName = '';
  UserNameAvailabilityStatus _status = UserNameAvailabilityStatus.available;

  String get userName => _userName;
  UserNameAvailabilityStatus get status => _status;

  /// Check for name availability using a Karmacoin API service provider
  Future<void> check(String userName) async {
    _userName = userName;
    _status = UserNameAvailabilityStatus.checking;
    notifyListeners();

    if (userName.isEmpty) {
      _status = UserNameAvailabilityStatus.unavailable;
      notifyListeners();
      return;
    }

    // todo - call the api to check if the user name is available

    try {
      GetUserInfoByUserNameResponse resp = await api.apiServiceClient
          .getUserInfoByUserName(
              GetUserInfoByUserNameRequest(userName: userName));

      if (resp.hasUser()) {
        debugPrint('api result: user name is not available');
        _status = UserNameAvailabilityStatus.unavailable;
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('error checking user name availability: $e');
      _status = UserNameAvailabilityStatus.error;
      notifyListeners();
      return;
    }

    debugPrint('api result: user name is available');
    _status = UserNameAvailabilityStatus.available;
    notifyListeners();
  }
}
