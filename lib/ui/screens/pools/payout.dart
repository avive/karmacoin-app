import 'package:karma_coin/data/kc_amounts_formatter.dart';
import 'package:karma_coin/logic/user_interface.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';

/// Claim payout screen
class ClaimPayout extends StatefulWidget {
  final Pool pool;
  final PoolMember membership;

  const ClaimPayout({super.key, required this.pool, required this.membership});

  @override
  State<ClaimPayout> createState() => _ClaimPayoutState();
}

class _ClaimPayoutState extends State<ClaimPayout> {
  bool isSubmitting = true;
  late BigInt claimableAmount;

  @override
  void initState() {
    super.initState();

    claimableAmount =
        widget.membership.points - kc2Service.poolsConfiguration.minJoinBond;

    // claim payout - status is comign via state changes
    kc2User.claimPoolPayout();
  }

  Widget _getUpdateStatus(BuildContext context) {
    return ValueListenableBuilder<SubmitTransactionStatus>(
        valueListenable: kc2User.claimPayoutStatus,
        builder: (context, value, child) {
          String text = '';
          Color? color = CupertinoColors.systemRed;
          isSubmitting = false;
          switch (value) {
            case SubmitTransactionStatus.unknown:
              text = '';
              break;
            case SubmitTransactionStatus.submitting:
              isSubmitting = true;
              text = 'Please wait and take 5 deep breaths...';
              color = CupertinoTheme.of(context).textTheme.textStyle.color;
              break;
            case SubmitTransactionStatus.submitted:
              text = 'Funds claimed!';
              color = CupertinoColors.activeGreen;
              break;
            case SubmitTransactionStatus.invalidData:
              text = 'Server error. Please try again later.';
              break;
            case SubmitTransactionStatus.invalidSignature:
              text = 'Invalid signature. Please try again later.';
              break;
            case SubmitTransactionStatus.serverError:
              text = 'Server error. Please try again later.';
              break;
            case SubmitTransactionStatus.connectionTimeout:
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

          if (value == SubmitTransactionStatus.submitting) {
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
          } else {
            return Column(
              children: [
                const SizedBox(height: 14),
                textWidget,
                const SizedBox(height: 14),
                CupertinoButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          }
        });
  }

  @override
  build(BuildContext context) {
    final String claimable =
        KarmaCoinAmountFormatter.deicmalFormat.format(claimableAmount.toInt());

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
              child:
                  Text('CLAIM PAYOUT', style: getNavBarTitleTextStyle(context)),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 16),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text('Claiming $claimable points...',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .pickerTextStyle),
                      ],
                    ),
                    _getUpdateStatus(context),
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
