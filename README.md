# karmacoin-app

This repository contains the source code for the KarmaCoin cross-platform platform app.

## Tech Stack
- Built using the Flutter framework and is written in Dart.
- Uses the [KarmaCoin blockchain mockup server](https://github.com/avive/karmacoin) as a KarmaCoin API provider. The API is provided as a gRPC service.
- Uses the Firebase platform for mobile phone number based user authentication.

## Spec
- Backend API and domain data objects are provided by the [KarmaCoin blockchain server](https://github.com/avive/karmacoin). For the first public release. In the first app release, the server is mocking up the full decentralized KarmaCoin blockchain. In future app releases, the API will get data from a full KarmaCoin blockchain node.
- Account keypair should be generated using ed25519 algorithm.
- Account's private key should be stored in secure local store.
- The only supported authentication way should be phone number based. There is no need to support email based and other forms of authentication.
- App should use Firebase Auth and Firebase UI widgets for phone number based user authentication.
- Phone authentication user tokens should be stored in secure local store.
- UX should be optimized for both Android and iOS platforms using Material and Cupertino widgets.
- App targets are: iOS, Android and Web platforms.
- App State should be managed using the Provider state pattern.
- App is configured to use a specific backend endpoints. Genesis config is obtained from the backend. 
- The backend's grpc Api service is defined [here](https://github.com/avive/karmacoin/tree/main/crates/base/proto/karma_coin/core_types/api.proto).
- The backend's data types are defined [here](https://github.com/avive/karmacoin/blob/main/crates/base/proto/karma_coin/core_types/).
- App should locally store data retrieved from the backend such as transactions and accounts states. This storage doesn't need to be secure and is basically locally cached public blockchain data.
- On startup, and on a time interval, the app should query the backend for updated data and update its local store with any new data.


### Signup Happy Flow
1. App identifies that there's no signed-in user by examining the local secure store for an auth token and an account keypair.
2. App generates a new ed5519 keypair and stores it in secure local store. The public key is the user's KarmaCoin blockchain 'AccountId'
3. User authenticates using his mobile phone number using Firebase Auth and Firebase UI widgets.
4. App stores the user's authentication token in secure local store.
5. On Android and iOS platforms App should prompt user to enable push notifications for new incoming transactions and enable push notifications for new incoming transactions.
6. User sets a user's name. App checks via the API that the user's requested name is available. If not, user is prompted to choose a different name.
7. App updates the user's name in Firebase using the Firebase Auth API to the value of the user's public key.
8. App calls the Verifier Service API to verify the user's phone number. The Verifier Service API is a network service that verifies users claims and provide signed evidence data back to users. 
9. The verifier uses the Firebase admin api to verify that that user's claimed phone number is associated with the user's Firebase Auth account and that the user's provided AccountId is associated with this account.
10. App prepares and sends a `Signup Transaction` to the KarmaCoin blockchain via the KarmaCoin API. The transaction includes user's mobile phone number, user's account id and user's name. It also includes the verifier's signed data regarding verification of user's provided phone number and account id. User signs the transaction with the private account key.
11. A KarmaCoin blockchain producer verifies that the transaction is signed by the user's private key and that a verifier signed off on the user's provided data. The transaction is added to the KarmaCoin blockchain and user balance is updated with his sign-up reward. The transaction fee is always paid by the protocol for this kind of transaction.
12. The app gets a push notification when the Signup Transaction is added to the blockchain. It should also pull on an interval for new transactions via the api, and update its local store with any new transactions and updated user's account information. This is needed for the case that push notifications are not enabled on the user's device or on web platform.
13. The App gets the user's KarmaCoin balance, karma score, other data and all incoming and outgoing transactions to and from the user's account from the KarmaCoin API.
14. App UI should be updated with the current user's account data and transactions.

### New App Session (existing user) flow


