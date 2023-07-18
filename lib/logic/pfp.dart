// import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class ProfilePict {
  /// Get profile picture url for a user's phone number (with plus)
  static Future<String> getProfilePictUrl(String phoneNumber) async {
    // obtain firebase account id for karma coin accountId using the cloud function

    /*
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getuserid')
          .call({'phoneNumber': phoneNumber});
    } on FirebaseFunctionsException catch (error) {
      debugPrint('${error.code}, ${error.details}, ${error.message}}');
    }*/

    /*
   
    curl -m 70 -X POST https://getuserid-4325ps3n6q-uc.a.run.app \
    -H "Authorization: bearer $(gcloud auth print-identity-token)" \
    -H "Content-Type: application/json" \
    -d '{
      "phoneNumber": "+972549805XXX"
    }'

    create url for media using the firebase account id:

    %2F is the encoded version of

    https://firebasestorage.googleapis.com/v0/b/karmacoin-user-media/o/4Qcr4Mq7A8VohkjHMdqd7jsORPc2%2Fprofile.png?alt=media



    */
    return "";
  }

  /// Get profile picture for a phone number (with plus)
  static Future<Widget> getProfilePict(String phoneNumber) async {
    // check if profile picture exists and download it if it is

    // use local cache

    // return random avatar if pict not available

    return Image.asset("assets/images/default_profile.png");
  }
}
