import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:karma_coin/data/genesis_config.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/personality_traits.dart';
import 'package:karma_coin/data/phone_number_formatter.dart';
import 'package:karma_coin/data/user.dart';
import 'package:karma_coin/services/api/api.pb.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/widgets/pill.dart';
import 'package:status_alert/status_alert.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

// Karma coin users selector
class KarmaCoinUserSelector extends StatefulWidget {
  final int communityId;
  final String title;
  final bool enableSelection;

  // todo: alwyas enbable selection and trigger appreciation of user if tapped/clicked

  final Function(Contact)? setPhoneNumberCallback;

  const KarmaCoinUserSelector(
      {super.key,
      this.communityId = 0,
      this.setPhoneNumberCallback,
      this.title = 'KARMA COIN USERS',
      this.enableSelection = true});

  @override
  State<KarmaCoinUserSelector> createState() => _KarmaCoinUserSelectorState();
}

class _KarmaCoinUserSelectorState extends State<KarmaCoinUserSelector> {
  // we assume api is available until we know otherwise
  bool apiOffline = false;
  List<Contact>? contacts;
  late TextEditingController textController;

  void _getContacts(String? prefix) {
    Future.delayed(Duration.zero, () async {
      try {
        debugPrint('getting contatcs prefix $prefix');

        GetContactsResponse resp = await api.apiServiceClient.getContacts(
            GetContactsRequest(
                prefix: prefix, communityId: widget.communityId));

        // debugPrint('got contacts: ${resp.contacts}');

        KarmaCoinUser user = accountLogic.karmaCoinUser.value!;

        // remove contacts without mobile numbers or user name
        resp.contacts
            .removeWhere((contact) => contact.userName == user.userName.value);

        resp.contacts.removeWhere((contact) =>
            contact.mobileNumber.number == user.mobileNumber.value.number);

        setState(() {
          apiOffline = false;
          contacts = resp.contacts;
        });
      } catch (e) {
        setState(() {
          apiOffline = true;
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
  initState() {
    super.initState();
    apiOffline = false;
    textController = TextEditingController();
    _getContacts(null);
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
              _getContacts(value);
            },
            style: CupertinoTheme.of(context).textTheme.pickerTextStyle),
      ),
    );

    if (contacts == null || contacts!.isEmpty) {
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
        itemCount: contacts!.length,
        itemBuilder: (context, index) {
          return _getContactWidget(context, contacts![index], index);
        },
      ),
    );
  }

  void _setAdmin(Contact contact) {
    // todo: move this to kc_user
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
    });
  }

  void _showContextMenu(BuildContext conext, int index) {
    debugPrint('showing context menu for index $index');

    Contact contact = contacts![index];

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
    // todo: add personality trait emojis from appre
    // show appreciations strip for user :-)
    String phoneNumber = '+${contact.mobileNumber.number.formatPhoneNumber()}';
    String displayName =
        '${contact.userName} ${getCommunitiesBadge(contact)}'.trim();

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
          const SizedBox(height: 6),
          Text(
            phoneNumber,
            style: CupertinoTheme.of(context).textTheme.textStyle.merge(
                  const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
          ),
        ],
      ),
      leading: const Icon(CupertinoIcons.person, size: 28),
      subtitle: _getAppreciationsStrip(context, contact),
      onTap: widget.enableSelection
          ? () {
              widget.setPhoneNumberCallback?.call(contact);
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
