import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/components/pill.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:status_alert/status_alert.dart';

const _pageSize = 30;

// Karma coin users selector
class KarmaCoinUserSelector extends StatefulWidget {
  final int communityId;
  final String title;
  final bool enableSelection;

  // todo: alwyas enbable selection and trigger appreciation of user if tapped/clicked

  final Function(Contact)? contactSelectedCallback;

  const KarmaCoinUserSelector(
      {super.key,
      this.communityId = 0,
      this.contactSelectedCallback,
      this.title = 'KARMA COIN USERS',
      this.enableSelection = true});

  @override
  State<KarmaCoinUserSelector> createState() => _KarmaCoinUserSelectorState();
}

class _KarmaCoinUserSelectorState extends State<KarmaCoinUserSelector> {
  final PagingController<int, Contact> _pagingController =
      PagingController(firstPageKey: 0);

  // we assume api is available until we know otherwise
  late TextEditingController _textController;
  // limit per request
  final _localUserName = kc2User.userInfo.value?.userName;
  final _localUserPhoneNumberHash = kc2User.userInfo.value?.phoneNumberHash;
  String _searchTerm = '';
  PagingStatus _pagingStatus = PagingStatus.loadingFirstPage;

  Future<void> _fetchPage(int pageKey) async {
    try {
      final List<Contact> results = await kc2Service.getContacts(_searchTerm,
          fromIndex: pageKey, limit: _pageSize);

      // if there are less results than limit, we know there are no more results to fetch
      bool additionalResultsAvailable =
          results.length < _pageSize ? false : true;

      // cleanup results
      results.removeWhere((contact) =>
          contact.userName.trim().isEmpty ||
          contact.userName == _localUserName ||
          contact.phoneNumberHash == _localUserPhoneNumberHash);

      if (!additionalResultsAvailable) {
        _pagingController.appendLastPage(results);
      } else {
        final nextPageKey = pageKey + results.length;
        _pagingController.appendPage(results, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
      if (!context.mounted) return;
      StatusAlert.show(context,
          duration: const Duration(seconds: 2),
          title: 'Server Error',
          subtitle: 'Please try later',
          configuration: const IconConfiguration(
              icon: CupertinoIcons.exclamationmark_triangle),
          dismissOnBackgroundTap: true,
          maxWidth: statusAlertWidth);
      debugPrint('error getting contacts: $e');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    _textController = TextEditingController();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    _pagingController.addStatusListener((status) {
      setState(() {
        _pagingStatus = status;
      });

      if (status == PagingStatus.subsequentPageError) {
        // todo: show error
      }
    });
  }

  void _updateSearchTerm(String searchTerm) {
    _searchTerm = searchTerm;
    _pagingController.refresh();
  }

  Widget _getBodyContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _getSearchBar(context),
        CustomScrollView(
          slivers: <Widget>[
            _getContactsList(context),
          ],
        )
      ],
    );
  }

  Widget _getSearchBar(BuildContext context) {
    return SliverToBoxAdapter(
        child: Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 12),
      child: CupertinoSearchTextField(
          controller: _textController,
          autofocus: true,
          autocorrect: false,
          keyboardType: TextInputType.text,
          placeholder: 'Enter a user name',
          onChanged: (value) {
            _updateSearchTerm(value);
          },
          style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
    ));
  }

  Widget _getContactsList(BuildContext context) {
    return PagedSliverList<int, Contact>(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<Contact>(
        itemBuilder: (context, item, index) =>
            _getContactWidget(context, item, index),
      ),
    );
  }

  Widget _getContactWidget(BuildContext context, Contact contact, int index) {
    String displayName =
        '${contact.userName} ${contact.getCommunitiesBadge()}'.trim();

    Widget tile = CupertinoListTile.notched(
      key: Key(index.toString()),
      padding: const EdgeInsets.only(top: 0, bottom: 6, left: 14, right: 14),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle.merge(
                  const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
          ),
        ],
      ),
      leading: RandomAvatar(displayName, height: 50, width: 50),
      subtitle: _getAppreciationsStrip(context, contact),
      onTap: widget.enableSelection && widget.contactSelectedCallback != null
          ? () {
              widget.contactSelectedCallback?.call(contact);
              context.pop();
            }
          : null,
    );

    return tile;
  }

  Widget? _getAppreciationsStrip(BuildContext context, Contact contact) {
    List<Widget> pills = [];
    for (TraitScore score in contact.traitScores) {
      PersonalityTrait trait = GenesisConfig.personalityTraits[score.traitId];

      String title = '${trait.emoji} ${trait.name}';

      Color backgroundColor = CupertinoColors.activeBlue;

      if (score.communityId > 0) {
        Community? community = GenesisConfig.communities[score.communityId];

        if (community != null) {
          backgroundColor =
              GenesisConfig.communityColors[score.communityId]!.backgroundColor;

          String communityEmoji =
              GenesisConfig.communities[score.communityId]!.emoji;

          title = '$communityEmoji $title';
        }
      }

      if (score.score > 1) {
        title += ' x${score.score}';
      }
      pills.add(
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 4),
          child: Pill(
            title: title,
            count: 0,
            backgroundColor: backgroundColor,
          ),
        ),
      );
    }

    if (pills.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        child: Wrap(children: pills),
      );
    }

    return null;
  }

  Color _getNavBarBackgroundColor() {
    if (widget.communityId == 0) {
      return const Color.fromARGB(
          255, 88, 40, 138); //CupertinoTheme.of(context).barBackgroundColor;
    } else {
      return GenesisConfig.communityColors[widget.communityId]!.backgroundColor;
    }
  }

  TextStyle _getNavBarTitleStyle() {
    if (widget.communityId == 0) {
      return // CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle;

          CupertinoTheme.of(context)
              .textTheme
              .navLargeTitleTextStyle
              .merge(const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w400,
              ));
    } else {
      return CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.merge(
          TextStyle(
              color: GenesisConfig
                  .communityColors[widget.communityId]!.textColor));
    }
  }

  Border? _getNavBarBorder() {
    if (widget.communityId == 0) {
      return kcOrangeBorder;
    } else {
      return null;
    }
  }

  @override
  build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: true,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            padding: EdgeInsetsDirectional.zero,
            backgroundColor: _getNavBarBackgroundColor(),
            border: _getNavBarBorder(),
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
              child: Text(
                widget.title,
                style: _getNavBarTitleStyle(),
              ),
            ),
          ),
          _getSearchBar(context),
          SliverFillRemaining(
            hasScrollBody: true,
            child: CustomScrollView(
              slivers: [_getContactsList(context)],
            ),
          ),
        ],
      ),
    );
  }
}
