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

class CreatePool extends StatefulWidget {
  const CreatePool({super.key});

  @override
  State<CreatePool> createState() => _CreatePoolState();
}

class _CreatePoolState extends State<CreatePool> {
  bool apiDown = false;
  NominationPoolsConfiguration? config;
  bool isSubmitting = false;

  // validate input data and show alert if invalid
  Future<bool> _validateData() async {
    if (kc2User.userInfo.value == null) {
      if (context.mounted) {
        StatusAlert.show(
          context,
          duration: const Duration(seconds: 2),
          title: 'Oops...',
          subtitle: 'Please login to your account.',
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

    if (appState.kCentsAmount.value < config!.minCreateBond) {
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
          subtitle: 'Insufficient balance. Consider sending less.',
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
    final accountId = kc2User.identity.accountId;
    await kc2User.createPool(
        amount: appState.kCentsAmount.value,
        root: accountId,
        nominator: accountId,
        bouncer: accountId);
  }

  @override
  void initState() {
    super.initState();

    // set initial value to 1 KC (todo: take from nomniation pools config)
    appState.kCentsAmount.value = GenesisConfig.kCentsPerCoinBigInt;
    kc2User.createPoolStatus.value = CreatePoolStatus.unknown;

    Future.delayed(Duration.zero, () async {
      try {
        NominationPoolsConfiguration conf =
            await (kc2Service as KC2NominationPoolsInterface)
                .getPoolsConfiguration();
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
            title: 'Server unreachable',
            subtitle: 'Please try later.',
            configuration: const IconConfiguration(
                icon: CupertinoIcons.exclamationmark_triangle),
            maxWidth: statusAlertWidth,
          );
        }
      }
    });
  }

  Widget _getUpdateStatus(BuildContext context) {
    return ValueListenableBuilder<CreatePoolStatus>(
        valueListenable: kc2User.createPoolStatus,
        builder: (context, value, child) {
          String text = '';
          Color? color = CupertinoColors.systemRed;
          isSubmitting = false;
          switch (value) {
            case CreatePoolStatus.unknown:
              text = '';
              break;
            case CreatePoolStatus.creating:
              isSubmitting = true;
              text = 'Please wait and take 5 deep breaths...';
              color = CupertinoTheme.of(context).textTheme.textStyle.color;
              break;
            case CreatePoolStatus.created:
              text = 'Pool created!';
              color = CupertinoColors.activeGreen;
              Future.delayed(Duration.zero, () {
                if (context.mounted) {
                  debugPrint('Pool created!');
                  context.pop();
                }
              });
              break;
            case CreatePoolStatus.invalidData:
              text = 'Server error. Please try again later.';
              break;
            case CreatePoolStatus.invalidSignature:
              text = 'Invalid signature. Please try again later.';
              break;
            case CreatePoolStatus.serverError:
              text = 'Server error. Please try again later.';
              break;
            case CreatePoolStatus.connectionTimeout:
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

          if (value == CreatePoolStatus.creating) {
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
          kcNavBar(context, 'CREATE POOL'),
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
                      child: const Text('Create Pool'),
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
