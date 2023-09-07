import 'package:karma_coin/common_libs.dart';

class Pill extends StatelessWidget {
  final String title;
  final int count;
  final Color backgroundColor;
  final bool showOneCount;
  final bool trailingCount;

  const Pill(
      {super.key,
      this.title = "",
      this.count = 1,
      this.backgroundColor = CupertinoColors.activeBlue,
      this.showOneCount = true,
      this.trailingCount = true});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitWidth,
      child: Container(
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: backgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Center(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _getCountWidget(context),
                  Text(
                    title,
                    style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                          const TextStyle(
                            fontSize: 11,
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _getCountWidget(BuildContext context) {
    if (count == 0 || (!showOneCount && count == 1)) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        height: 16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: CupertinoColors.black,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 6, right: 6),
          child: Center(
            child: Text(
              count.format(),
              style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                    const TextStyle(
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
