import 'package:karma_coin/logic/user_interface.dart';
import 'package:karma_coin/services/v2.0/nomination_pools/interfaces.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';

enum Operation { leavePool, unbondPool }

/// Leave pool screen. user needs to unbound pool before he can withdraw and leave
class LeavePool extends StatefulWidget {
  final Pool pool;
  final PoolMember membership;

  const LeavePool({super.key, required this.pool, required this.membership});

  @override
  State<LeavePool> createState() => _LeavePoolState();
}

class _LeavePoolState extends State<LeavePool> {
  bool isSubmitting = true;
  Operation operation = Operation.unbondPool;

  @override
  void initState() {
    super.initState();

    if (widget.membership.points == BigInt.zero) {
      // user already unbound and can leave
      operation = Operation.leavePool;
      kc2User.withdrawPoolUnboundedAmount();
    } else {
      // request to unbound bonded funds
      operation = Operation.unbondPool;
      kc2User.unboundPoolBondedAmount();
    }
  }

  Widget _getStatus(BuildContext context) {
    return ValueListenableBuilder<SubmitTransactionStatus>(
        valueListenable: kc2User.leavePoolStatus,
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
              switch (operation) {
                case Operation.leavePool:
                  text = 'Left pool and claimed bonded funds!';
                  break;
                case Operation.unbondPool:
                  text =
                      'Your stake was unbound. You can widthdraw it in 24 hours.';
                  break;
              }
              color = CupertinoColors.activeGreen;
              /*
              Future.delayed(Duration.zero, () {
                if (context.mounted && context.canPop()) {
                  context.pop();
                }
              });*/
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
                    if (context.mounted && context.canPop()) {
                      context.pop();
                    }
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
    String buttonLabel =
        operation == Operation.leavePool ? 'Leave pool' : 'Withdraw';

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
              child: Text(buttonLabel, style: getNavBarTitleTextStyle(context)),
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
                children: [_getStatus(context)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
