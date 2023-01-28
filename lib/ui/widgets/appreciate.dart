import 'package:karma_coin/common_libs.dart';

class AppreciateWidget extends StatefulWidget {
  const AppreciateWidget({super.key});

  @override
  State<AppreciateWidget> createState() => _AppreciateWidgetState();
}

class _AppreciateWidgetState extends State<AppreciateWidget> {
  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            CupertinoSliverNavigationBar(
              leading: Container(),
              trailing: CupertinoButton(
                onPressed: () {
                  context.pop();
                },
                child: const Icon(CupertinoIcons.xmark_circle, size: 32),
              ),
              largeTitle: Text('Appreciate'),
            ),
          ];
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Appreciate',
                    style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                          TextStyle(fontSize: 24),
                        ),
                  ),
                  SizedBox(height: 14),
                  CupertinoButton.filled(
                    onPressed: () {
                      context.pop();
                    },
                    child: Text('Appreciate'),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
