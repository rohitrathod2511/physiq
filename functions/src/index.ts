import * as admin from 'firebase-admin';

// Initialize Firebase Admin globally
if (!admin.apps.length) {
    admin.initializeApp();
}

// Re-export user management functions
export * from './user';
export * from './plan';
export * from './invite';
export * from './nutrition';
