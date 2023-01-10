# karmacoin-app

This repository contains the source code for the KarmaCoin cross-platform platform app.

## Tech Stack
- Built using the Flutter framework and is written in Dart.
- Uses the [KarmaCoin blockchain mockup server](#) as a KarmaCoin API provider. The API is provided as a gRPC service.
- Uses the Firebase platform for mobile phone number based user authentication.

## Spec
- Backend API and domain data objects are provided by the [KarmaCoin blockchain mockup server](#).
- Account keypair should be generated using ed25519 algorithm.
- Account's private key should be stored in secure local store.
- The only supported authentication way should be phone number based. There is no need to support email based and other forms of authentication.
- App should use Firebase Auth and Firebase UI widgets for phone number based user authentication.
- Phone authentication user tokens should be stored in secure local store.
- UX should be optimized for both Android and iOS platforms using Material and Cupertino widgets.
- App targets are: iOS, Android and Web platforms.
- App State should be managed using the Provider state pattern.
- App is configured to use a specific backend endpoints. Genesis config is obtained from the backend. 
- App should locally store data retrieved from the backend such as transactions and accounts states. This storage doesn't need to be secure and is basically locally cached public blockchain data.
- On startup, and on a time interval, the app should query the backend for updated data and update its local store with any new data.
