importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');
//import { initializeApp } from "firebase/app";
//import { getAnalytics } from "firebase/analytics";

//firebase.initializeApp({
//  'messagingSenderId': '755750996078'
//});

// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
          apiKey: "AIzaSyBhmtPyfM07qTdPTU6lLQuK9mKtnW_hKBM",
          authDomain: "vizman-e18a8.firebaseapp.com",
          databaseURL: "https://vizman-e18a8.firebaseio.com",
          projectId: "vizman-e18a8",
          storageBucket: "vizman-e18a8.appspot.com",
          messagingSenderId: "125322571852",
          appId: "1:125322571852:web:76427f2b34b9339d4184e9",
          measurementId: "G-RJTPTQMJJ0"
};
    firebase.initializeApp(firebaseConfig);

    const messaging = firebase.messaging();

//
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: payload.notification.icon || '/firebase-logo.png' // Replace with your custom icon if needed
  };
    self.registration.showNotification(notificationTitle, notificationOptions);
  });
