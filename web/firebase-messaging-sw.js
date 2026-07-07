importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyChJ_be6rHgJ1q8VjTUmuqpI2N-ZwX-tk4',
  appId: '1:331132217293:web:9540fb8749fe0bf743c684',
  messagingSenderId: '331132217293',
  projectId: 'lottery-advance',
  authDomain: 'lottery-advance.firebaseapp.com',
  storageBucket: 'lottery-advance.firebasestorage.app',
  measurementId: 'G-2WRPKYY5TC',
});

firebase.messaging();
