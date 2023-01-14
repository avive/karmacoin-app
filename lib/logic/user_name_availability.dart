import '../common_libs.dart';

enum UserNameAvailabilityStatus {
  unknown,
  checking,
  available,
  unavailable,
  error
}

class UserNameAvailabilityLogic extends ChangeNotifier {
  String _userName = '';
  UserNameAvailabilityStatus _status = UserNameAvailabilityStatus.unknown;

  String get userName => _userName;
  UserNameAvailabilityStatus get status => _status;

  /// Check for name availability using a Karmacoin API service provider
  Future<void> check(String userName) async {
    _userName = userName;
    _status = UserNameAvailabilityStatus.checking;
    notifyListeners();

    // todo - call the api to check if the user name is available
    await Future.delayed(const Duration(milliseconds: 500));

    _status = UserNameAvailabilityStatus.available;
    notifyListeners();
  }
}
