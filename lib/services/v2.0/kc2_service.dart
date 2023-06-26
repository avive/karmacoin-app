import 'package:flutter_js/flutter_js.dart';
import 'package:karma_coin/common_libs.dart';

class KarmachainService {
  final JavascriptRuntime jsRuntime = getJavascriptRuntime();

  // Init the JS engine
  Future<void> init() async {
    try {
      String karmaJs = await rootBundle.loadString("assets/js/kc2.js");
      JsEvalResult res =
          jsRuntime.evaluate("""var window = global = globalThis;""");
      res = jsRuntime.evaluate(karmaJs);
      debugPrint(res.stringResult);
    } on PlatformException catch (e) {
      debugPrint('Failed to init js engine: ${e.details}');
      rethrow;
    }
  }

  // Connect to a karmachain api service. e.g  "ws://127.0.0.1:9944"
  void connectToApi(String wsUrl, bool createTestAccounts) {
    try {
      JsEvalResult res =
          jsRuntime.evaluate("""init(wsUrl, $createTestAccounts);""");
      debugPrint('Karma JS api result: ${res.stringResult}');
    } on PlatformException catch (e) {
      debugPrint('Failed to connect to api: ${e.details}');
      rethrow;
    }
  }

  subscribeToAccount(String address) {
    try {
      jsRuntime.evaluate("karma.init()");
    } on PlatformException catch (e) {
      debugPrint('Failed to bootstrap karma: ${e.details}');
      rethrow;
    }
  }
}
