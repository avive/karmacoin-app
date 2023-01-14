import '../common_libs.dart';

/// HoldItNowScreen is the screen that asks the user to hold while
/// their account is created on-chain
class HoldItNowScreen extends StatelessWidget {
  const HoldItNowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Setup'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
                Text('Hold it now. Setting up your new account...'),
              ])),
    );
  }
}
