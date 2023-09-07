import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';

class StakingIntro extends StatefulWidget {
  const StakingIntro({super.key});

  @override
  State<StakingIntro> createState() => _StakingIntroState();
}

class _StakingIntroState extends State<StakingIntro> {
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
              const FaIcon(FontAwesomeIcons.coins, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'You can earn Karma Coins by staking some of your coins on Karmachain.',
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
              const FaIcon(FontAwesomeIcons.lock, size: 30),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  'Staking increases Karma Coin security and you get rewarded for it.',
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
              const FaIcon(FontAwesomeIcons.peopleGroup, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You stake by joining a ming pool. A mining pool is a group of people who stake together.',
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
              const FaIcon(FontAwesomeIcons.medal, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'You can stake with as little as 1 Karma Coin.',
                  style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                        const TextStyle(fontSize: fontSize),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: sepHeight),
          CupertinoButton(
            onPressed: () async {
              // TODO: implement me
            },
            child: const Text('Learn More'),
          ),
          const SizedBox(height: sepHeight),
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
                child: Text('STAKE & EARN',
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
