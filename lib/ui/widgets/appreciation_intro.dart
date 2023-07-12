import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';

class AppreciationIntro extends StatefulWidget {
  const AppreciationIntro({super.key});

  @override
  State<AppreciationIntro> createState() => _AppreciationIntroState();
}

class _AppreciationIntroState extends State<AppreciationIntro> {
  @override
  initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _postFrameCallback(context));
  }

  void _postFrameCallback(BuildContext context) {}

  Widget _getBodyContent(BuildContext context) {
    const double sepHeight = 24.0;
    const double fontSize = 20.0;
    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 28, top: 24, bottom: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                '🌎',
                style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                      const TextStyle(fontSize: 26),
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You can appreciate anyone and anywhere.',
                  style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                        const TextStyle(fontSize: fontSize),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: sepHeight),
          Row(
            children: [
              Text(
                '📱',
                style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                      const TextStyle(fontSize: 28),
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Just pick a contact from your phone contacts or enter recipient\'s phone number.',
                  style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                        const TextStyle(fontSize: fontSize),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: sepHeight),
          Row(
            children: [
              Text(
                '😻',
                style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                      const TextStyle(fontSize: 26),
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ask recipient to sign up to Karma Coin with their phone number.',
                  style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                        const TextStyle(fontSize: fontSize),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: sepHeight),
          Row(
            children: [
              Text(
                '🥇',
                style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                      const TextStyle(fontSize: 26),
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You get a referral reward once your recipient signs up.',
                  style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                        const TextStyle(fontSize: fontSize),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          CupertinoButton.filled(
            onPressed: () => context.pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: true,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            padding: EdgeInsetsDirectional.zero,
            backgroundColor: kcPurple,
            border: kcOrangeBorder,
            leading: Container(),
            trailing: adjustNavigationBarButtonPosition(
                CupertinoButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Icon(CupertinoIcons.xmark_circle, size: 24),
                ),
                0,
                0),
            largeTitle: Center(
              child: Center(
                child: Text('HOW TO APPRECIATE',
                    style: getNavBarTitleTextStyle(context)),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: _getBodyContent(context),
          ),
        ],
      ),
    );
  }
}
