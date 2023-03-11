import 'package:karma_coin/common_libs.dart';

class Pill extends StatelessWidget {
  final String title;
  final int count;
  final Color backgroundColor;

  const Pill(Key? key, this.title,
      {this.count = 1, this.backgroundColor = CupertinoColors.activeBlue})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: Center(
          child: Row(children: [
            _getCountWidget(context),
            Text(
              title,
              style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                    TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _getCountWidget(BuildContext context) {
    if (count == 0) {
      return Container();
    }

    debugPrint(count.format());

    return Padding(
      padding: EdgeInsets.only(right: 6),
      child: Container(
        height: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: CupertinoColors.black,
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 6, right: 6),
          child: Center(
            child: Text(
              count.format(),
              style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                    TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
