import 'package:flutter/material.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/services/v2.0/types.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/widgets/pill.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:status_alert/status_alert.dart';

enum FetchStatus { idle, loading, loaded, error }

// Karma coin users selector
class KarmaCoinUserSelector extends StatefulWidget {
  final int communityId;
  final String title;
  final bool enableSelection;

  // TODO: alwyas enbable selection and trigger appreciation of user if tapped/clicked

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
  // we assume api is available until we know otherwise
  bool apiOffline = false;
  List<Contact> contacts = [];
  late TextEditingController textController;
  // limit per request
  final limit = 30;
  final localUserName = kc2User.userInfo.value!.userName;
  final localUserPhoneNumberHash = kc2User.userInfo.value!.phoneNumberHash;
  FetchStatus featchStatus = FetchStatus.idle;
  late String? lastPrefix;
  final ScrollController scrollController = ScrollController();
  bool additionalResultsAvailable = false;
  //
  //
  int lastRequestFromIndex = 0;
  String lastRequestedPrefix = '';

  void setFetchState(FetchStatus status) {
    setState(() {
      featchStatus = status;
    });
  }

  void _loadAdditionalContacts() {
    if (additionalResultsAvailable) {
      debugPrint('Loading more contacts on scroll...');
      _loadContacts(lastPrefix!);
    } else {
      debugPrint('No more results to load on scrol...');
    }
  }

  /// Load more contacts from the server for a prefix
  void _loadContacts(String prefix) {
    prefix = prefix.toLowerCase();

    if (prefix != lastRequestedPrefix) {
      // change of prefix - reset index and contacts
      setState(() {
        lastRequestedPrefix = prefix;
        lastRequestFromIndex = 0;
        contacts.clear();
      });
    }

    Future.delayed(Duration.zero, () async {
      try {
        debugPrint('getting contatcs prefix $prefix');
        setFetchState(FetchStatus.loading);
        List<Contact> results = await kc2Service.getContacts(prefix,
            fromIndex: lastRequestFromIndex, limit: limit);

        // if there are less results than limit, we know there are no more results to fetch
        additionalResultsAvailable = results.length < limit ? false : true;

        lastRequestFromIndex += results.length;

        // cleanup results
        results.removeWhere((contact) =>
            contact.userName.trim().isEmpty ||
            contact.userName == localUserName ||
            contact.phoneNumberHash == localUserPhoneNumberHash);

        debugPrint('got ${results.length} contacts');

        setState(() {
          apiOffline = false;
          featchStatus = FetchStatus.loaded;
          contacts.addAll(results);
        });
      } catch (e) {
        setState(() {
          apiOffline = true;
          featchStatus = FetchStatus.error;
        });
        if (!mounted) return;
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
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    apiOffline = false;
    textController = TextEditingController();
    scrollController.addListener(_loadAdditionalContacts);
    _loadContacts('');
  }

  Widget _getBodyContent(BuildContext context) {
    if (apiOffline == true || featchStatus == FetchStatus.error) {
      return Padding(
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: Center(
          child: Text('Server is down.\n\nPlease try again later.',
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
        ),
      );
    }

    List<Widget> widgets = [];

    widgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 12),
        child: CupertinoSearchTextField(
            controller: textController,
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.text,
            placeholder: 'Enter a user name',
            onChanged: (value) {
              _loadContacts(value);
            },
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
      ),
    );

    if (contacts.isEmpty && featchStatus == FetchStatus.loaded) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 64, bottom: 36),
          child: Center(
            child: Text('😞 No matching users found',
                textAlign: TextAlign.center,
                style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
          ),
        ),
      );
    } else if (featchStatus == FetchStatus.loading) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 64, bottom: 36),
          child: Center(
            child: Text('⌛️ One sec please...',
                textAlign: TextAlign.center,
                style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
          ),
        ),
      );
    } else {
      widgets.add(_getContactsList(context));
    }

    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 24),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets),
    );
  }

  Widget _getContactsList(BuildContext context) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 24),
        separatorBuilder: (context, index) {
          return const Divider(
            thickness: 1,
            indent: 0,
          );
        },
        controller: scrollController,
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          return _getContactWidget(context, contacts[index], index);
        },
      ),
    );
  }

  void _setAdmin(Contact contact) {
    // TODO: move this to kc2
    /*
    Future.delayed(Duration.zero, () async {
      try {
        KarmaCoinUser localUser = accountLogic.karmaCoinUser.value!;
        ed.KeyPair keyPair = accountLogic.keyPair.value!;

        SetCommunityAdminData data = SetCommunityAdminData(
          communityId: widget.communityId,
          targetAccountId: contact.accountId,
          timestamp: Int64(DateTime.now().millisecondsSinceEpoch),
          admin: true,
        );

        List<int> message = data.writeToBuffer();

        Uint8List edSignature =
            ed.sign(keyPair.privateKey, Uint8List.fromList(message));

        SetCommunityAdminRequest request = SetCommunityAdminRequest(
            fromAccountId: localUser.userData.accountId,
            data: message,
            signature: edSignature);

        await api.apiServiceClient.setCommunityAdmin(request);
        if (!mounted) return;
        StatusAlert.show(context,
            duration: const Duration(seconds: 4),
            title: 'Allright',
            subtitle: 'User is now an admin',
            configuration: const IconConfiguration(icon: CupertinoIcons.smiley),
            dismissOnBackgroundTap: true,
            maxWidth: statusAlertWidth);
      } catch (e) {
        debugPrint('error setting admin: $e');
        if (!mounted) return;
        StatusAlert.show(context,
            duration: const Duration(seconds: 4),
            title: 'Ooops',
            subtitle: 'Server error',
            configuration: const IconConfiguration(
                icon: CupertinoIcons.exclamationmark_triangle),
            dismissOnBackgroundTap: true,
            maxWidth: statusAlertWidth);
        return;
      }
    });*/
  }

  void _showContextMenu(BuildContext conext, int index) {
    debugPrint('showing context menu for index $index');

    Contact contact = contacts[index];

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'Make user ${contact.userName} a community admin?',
          style: CupertinoTheme.of(context)
              .textTheme
              .dateTimePickerTextStyle
              .merge(
                const TextStyle(
                  fontSize: 20,
                ),
              ),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              _setAdmin(contact);
              Navigator.pop(context);
            },
            child: const Text('Yes'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            isDefaultAction: true,
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  Widget _getContactWidget(BuildContext context, Contact contact, int index) {
    // TODO: add personality trait emojis from appreciation
    // show appreciations strip for user :-)
    // String phoneNumber = '+${contact.mobileNumber.number.formatPhoneNumber()}';
    String displayName =
        '${contact.userName} ${contact.getCommunitiesBadge()}'.trim();

    bool isAdmin = false;

    for (CommunityMembership m in contact.communityMemberships) {
      Community? c = GenesisConfig.communities[widget.communityId];
      if (c == null) {
        continue;
      }

      if (m.isAdmin) {
        isAdmin = true;
      }
    }

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
      onTap: widget.enableSelection
          ? () {
              widget.contactSelectedCallback?.call(contact);
              context.pop();
            }
          : null,
    );

    if (!isAdmin) {
      return GestureDetector(
          onLongPress: () => _showContextMenu(context, index), child: tile);
    }

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
          SliverFillRemaining(
            hasScrollBody: true,
            child: _getBodyContent(context),
          ),
        ],
      ),
    );
  }
}
