import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:karma_coin/data/payment_tx_data.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';

const _tgramUrl = 'https://t.me/karmacoinapp/1';

class AppreciationProgress extends StatefulWidget {
  final PaymentTransactionData data;

  const AppreciationProgress({super.key, required this.data});

  @override
  State<AppreciationProgress> createState() => _AppreciationProgressState();
}

class _AppreciationProgressState extends State<AppreciationProgress> {
  bool apiOffline = false;
  String? txHash;

  @override
  initState() {
    super.initState();
    apiOffline = false;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _postFrameCallback(context));
  }

  void _postFrameCallback(BuildContext context) {
    Future.delayed(Duration.zero, () async {
      try {
        String txHash = await kc2Service.sendAppreciation(
            widget.data.destPhoneNumberHash!,
            appState.kCentsAmount.value,
            widget.data.communityId,
            appState.selectedPersonalityTrait.value.index);
        setState(() {
          this.txHash = txHash;
        });
      } catch (e) {
        debugPrint('failed to send appreciation: $e');
      }
    });
  }

  Widget _getBodyContent(BuildContext context) {
    if (apiOffline) {
      return Padding(
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: Center(
          child: Text(
              'The Karma Coin Server is down.\n\nPlease try again later.',
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 28, top: 24, bottom: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _getSatus(context),
          const SizedBox(height: 32),
          _getPromo(context),
        ],
      ),
    );
  }

  Widget _getPromo(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(
        'Join the Karma Coin Community',
        style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.merge(
              const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.only(left: 0, right: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '✅',
                  style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                        const TextStyle(fontSize: 24),
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Learn more about who, when and how to appreciate.',
                    style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                          const TextStyle(fontSize: 18),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '✅',
                  style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                        const TextStyle(fontSize: 24),
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bring positive change.',
                    style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                          const TextStyle(fontSize: 18),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '✅',
                  style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                        const TextStyle(fontSize: 24),
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Connect with fellow Karma seekers.',
                    style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                          const TextStyle(fontSize: 18),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '✅',
                  style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                        const TextStyle(fontSize: 24),
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Get more Karma and Karma Coins for good actions.',
                    style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                          const TextStyle(fontSize: 18),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: 300,
        child: CupertinoButton.filled(
          onPressed: () async {
            await openUrl(_tgramUrl);
          },
          child:
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FaIcon(FontAwesomeIcons.telegram, size: 24),
            SizedBox(width: 14),
            Text('Join on Telegram'),
          ]),
        ),
      ),
    ]);
  }

  Widget _getSatus(BuildContext context) {
    return ValueListenableBuilder<TxSubmissionStatus>(
      valueListenable: appState.txSubmissionStatus,
      builder: (context, value, child) {
        switch (value) {
          case TxSubmissionStatus.submitting:
            return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              const CupertinoActivityIndicator(
                radius: 14,
              ),
              const SizedBox(width: 18),
              Text(
                'Sending appreciation...',
                style: CupertinoTheme.of(context)
                    .textTheme
                    .navTitleTextStyle
                    .merge(
                      const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w600),
                    ),
              ),
            ]);
          case TxSubmissionStatus.submitted:
            return Text(
              '✅ Appreciation sent!',
              style: CupertinoTheme.of(context)
                  .textTheme
                  .navTitleTextStyle
                  .merge(
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
            );
          case TxSubmissionStatus.error:
            return Text(
              '🙊 Failed to send appreciation. Please try again later.',
              style: CupertinoTheme.of(context)
                  .textTheme
                  .navTitleTextStyle
                  .merge(
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
            );
          case TxSubmissionStatus.idle:
            return Container();
        }
      },
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
                child: Text('APPRECIATION',
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
