import 'package:flutter/material.dart';
import 'package:karma_coin/data/kc_user.dart';
import 'package:karma_coin/data/phone_number_formatter.dart';
import 'package:karma_coin/data/user.dart';
import 'package:karma_coin/services/api/api.pb.dart';
import 'package:karma_coin/services/api/types.pb.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:status_alert/status_alert.dart';

// Karma coin users selector
class KarmaCoinUserSelector extends StatefulWidget {
  final int communityId;

  final Function(String)? setPhoneNumberCallback;

  const KarmaCoinUserSelector(
      {super.key, this.communityId = 0, this.setPhoneNumberCallback});

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

  Widget _getContactWidget(BuildContext context, Contact contact, int index) {
    // todo: add personality trait emojis from appre
    // show appreciations strip for user :-)
    String phoneNumber = '+${contact.mobileNumber.number.formatPhoneNumber()}';
    String displayName =
        '${contact.userName} ${getCommunitiesBadge(contact)}'.trim();

    return CupertinoListTile(
      key: Key(index.toString()),
      padding: const EdgeInsets.only(top: 0, bottom: 6, left: 14, right: 14),
      title: Text(
        displayName,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w300,
        ),
      ),
      subtitle: Text(phoneNumber,
          style: CupertinoTheme.of(context).textTheme.textStyle),
      leading: const Icon(CupertinoIcons.person, size: 28),
      onTap: () {
        widget.setPhoneNumberCallback?.call(contact.mobileNumber.number);
        context.pop();
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
              backgroundColor: const Color.fromARGB(255, 88, 40, 138),
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
                  child: Text('Karma Coin Users',
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .navLargeTitleTextStyle
                          .merge(const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w400,
                          ))))),
          SliverFillRemaining(
            hasScrollBody: true,
            child: _getBodyContent(context),
          ),
        ],
      ),
    );
  }
}
