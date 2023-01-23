import 'package:karma_coin/common_libs.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  @override
  build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usee Home Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(mainAxisAlignment: MainAxisAlignment.start, children: const [
          Text('Karma Score...'),
          SizedBox(height: 14),
        ]),
      ),
    );
  }
}