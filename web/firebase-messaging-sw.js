importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAqi1ZsG1XdQ7nRXVU0xbzEuwaqD7SkBik",
  authDomain: "karmacoin-83d45.firebaseapp.com",
  projectId: "karmacoin-83d45",
  storageBucket: "karmacoin-83d45.appspot.com",
  messagingSenderId: "18491747418",
  appId: "1:18491747418:web:6e0edb0f24103ca0a73c63",
  measurementId: "G-BY4MSSGR0C"
});

// Necessary to receive background messages:
const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((m) => {
  console.log("onBackgroundMessage", m);
});