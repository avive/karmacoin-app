import 'package:karma_coin/common/platform_info.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/logic/user_interface.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';
import 'package:karma_coin/ui/components/amount_input.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/logic/app_state.dart';
import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:status_alert/status_alert.dart';

class JoinPool extends StatefulWidget {
  final Pool pool;

  const JoinPool({super.key, required this.pool});

  @override
  State<JoinPool> createState() => _JoinPoolState();
}

class _JoinPoolState extends State<JoinPool> {
  bool apiDown = false;
  NominationPoolsConfiguration? config;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // set initial value to 1 KC - update it from pool config later
    appState.kCentsAmount.value = GenesisConfig.kCentsPerCoinBigInt;
    kc2User.joinPoolStatus.value = JoinPoolStatus.unknown;

    Future.delayed(Duration.zero, () async {
      try {
        NominationPoolsConfiguration conf =
            await (kc2Service as KC2NominationPoolsInterface)
                .getPoolsConfiguration();
        appState.kCentsAmount.value = conf.minJoinBond;
        setState(() {
          config = conf;
        });
      } catch (e) {
        apiDown = true;
        debugPrint('Can\'t read pools config: $e');
        if (context.mounted) {
          StatusAlert.show(
            context,
            duration: const Duration(seconds: 2),
            title: 'Server Unreachable',
            subtitle: 'Please try later.',
            configuration: const IconConfiguration(
                icon: CupertinoIcons.exclamationmark_triangle),
            maxWidth: statusAlertWidth,
          );
        }
      }
    });
  }

  // validate input data and show alert if invalid
  Future<bool> _validateData() async {
    if (kc2User.userInfo.value == null) {
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: 'Oops...',
          subtitle: 'Please sing-in',
          configuration: const IconConfiguration(
              icon: CupertinoIcons.exclamationmark_triangle),
          maxWidth: statusAlertWidth,
        );
      }
      return false;
    }

    bool isConnected = await PlatformInfo.isConnected();

    if (!isConnected) {
      if (context.mounted) {
        StatusAlert.show(context,
            duration: const Duration(seconds: 4),
            title: 'No Internet',
            subtitle: 'Check your connection.',
            configuration: const IconConfiguration(
                icon: CupertinoIcons.exclamationmark_triangle),
            dismissOnBackgroundTap: true,
            maxWidth: statusAlertWidth);
      }
      return false;
    }

    if (config == null) {
      // failed to get pool config from api
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: 'Server Unreachable',
          subtitle: 'Please try again later.',
          configuration: const IconConfiguration(
              icon: CupertinoIcons.exclamationmark_triangle),
          maxWidth: statusAlertWidth,
        );
      }
      return false;
    }

    if (appState.kCentsAmount.value < config!.minJoinBond) {
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: 'Insufficient Bond',
          subtitle: 'Minimum bond amount is 1 Karma Coin.',
          configuration: const IconConfiguration(
              icon: CupertinoIcons.exclamationmark_triangle),
          maxWidth: statusAlertWidth,
        );
      }
      return false;
    }

    debugPrint('user balance: ${kc2User.userInfo.value!.balance.toString()}');

    if (kc2User.userInfo.value!.balance < appState.kCentsAmount.value) {
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: '',
          subtitle: 'Insufficient balance. Consider bonding less.',
          configuration:
              const IconConfiguration(icon: CupertinoIcons.xmark_circle),
          maxWidth: statusAlertWidth,
        );
      }
      return false;
    }

    return true;
  }

  /// Send the join tx to the chain
  Future<void> _send() async {
    setState(() {
      isSubmitting = true;
    });

    await kc2User.joinPool(
        amount: appState.kCentsAmount.value, poolId: widget.pool.id);
  }

  Widget _getUpdateStatus(BuildContext context) {
    return ValueListenableBuilder<JoinPoolStatus>(
        valueListenable: kc2User.joinPoolStatus,
        builder: (context, value, child) {
          String text = '';
          Color? color = CupertinoColors.systemRed;
          isSubmitting = false;
          switch (value) {
            case JoinPoolStatus.unknown:
              text = '';
              break;
            case JoinPoolStatus.joining:
              isSubmitting = true;
              text = 'Please wait and take 5 deep breaths...';
              color = CupertinoTheme.of(context).textTheme.textStyle.color;
              break;
            case JoinPoolStatus.joined:
              text = 'Joined pool!';
              color = CupertinoColors.activeGreen;
              Future.delayed(Duration.zero, () {
                if (context.mounted && Navigator.canPop(context)) {
                  debugPrint('Pool joined!');
                  Navigator.of(context).pop();
                }
              });
              break;
            case JoinPoolStatus.invalidData:
              text = 'Server error. Please try again later.';
              break;
            case JoinPoolStatus.invalidSignature:
              text = 'Invalid signature. Please try again later.';
              break;
            case JoinPoolStatus.serverError:
              text = 'Server error. Please try again later.';
              break;
            case JoinPoolStatus.connectionTimeout:
              text = 'Connection timeout. Please try again later.';
              break;
          }

          Text textWidget = Text(
            text,
            textAlign: TextAlign.center,
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w400, color: color),
                ),
          );

          if (value == JoinPoolStatus.joining) {
            return Column(
              children: [
                const SizedBox(height: 14),
                textWidget,
                const SizedBox(height: 14),
                const CupertinoActivityIndicator(
                  radius: 20,
                ),
              ],
            );
          }

          return Column(
            children: [
              const SizedBox(height: 14),
              textWidget,
            ],
          );
        });
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          kcNavBar(context, 'JOIN POOL ${widget.pool.id}'),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 16),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text('Amount to bond',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .pickerTextStyle),
                        CupertinoButton(
                          onPressed: () {
                            Navigator.of(context).push(CupertinoPageRoute(
                                fullscreenDialog: true,
                                builder: ((context) => const AmountInputWidget(
                                    coinKind: CoinKind.kCoins,
                                    feeType: FeeType.payment,
                                    title: 'AMOUNT'))));
                          },
                          child: ValueListenableBuilder<BigInt>(
                              valueListenable: appState.kCentsAmount,
                              builder: (context, value, child) =>
                                  Text(KarmaCoinAmountFormatter.format(value))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (await _validateData()) {
                                await _send();
                              }
                            },
                      child: const Text('Join Pool'),
                    ),
                    const SizedBox(height: 14),
                    _getUpdateStatus(context),
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
