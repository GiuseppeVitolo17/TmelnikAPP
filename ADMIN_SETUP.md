# Admin Setup Guide

## 🔐 **User Role System**

The app now has two types of users:
- **Normal Users**: Can view projects and share them on Instagram
- **Admin Users**: Can view, add, and manage projects

## 📋 **How to Set Up Admins**

### **Option 1: Using Firebase Console (Recommended)**

1. **Go to Firebase Console**
   - Open [Firebase Console](https://console.firebase.google.com/)
   - Select your project: `TmelnikAPP`

2. **Navigate to Firestore Database**
   - Click on "Firestore Database" in the left menu
   - Find the `users` collection

3. **Find the User**
   - Look for the user document by their UID
   - The UID is the document ID in the `users` collection

4. **Set Admin Status**
   - Click on the user document
   - Find the `isAdmin` field
   - Change the value from `false` to `true`
   - Save the changes

### **Option 2: Using Firestore Rules (Advanced)**

You can also set up admin users programmatically by creating a Cloud Function or using the Firebase Admin SDK.

## 🎯 **What Admins Can Do**

### **Admin Features:**
- ✅ View all projects
- ✅ Add new projects (via + button)
- ✅ Share projects on Instagram
- ✅ Access to the "Add Project" screen

### **Admin UI Differences:**
- **Floating Action Button (+)**: Visible only to admins in the Project Offers screen
- **Add Project Screen**: Full form to create new project offers with:
  - Title, location, duration
  - Target audience
  - Description
  - Multiple benefits
  - Contact information (Instagram)
  - Expiration date

## 👥 **Normal User Features**

Normal users can:
- ✅ View all available projects
- ✅ Share projects on Instagram
- ❌ Cannot add or edit projects
- ❌ No + button visible

## 🔄 **User Role Initialization**

When a user logs in for the first time (via Google Sign-In or Email/Password):
- A document is automatically created in the `users` collection
- Default role: `isAdmin: false` (normal user)
- Email and UID are stored
- Creation timestamp is recorded

## 📊 **Firestore Structure**

### **Users Collection** (`users`)
```
users/
  {uid}/
    - email: string
    - isAdmin: boolean
    - createdAt: string (ISO 8601)
```

### **Projects Collection** (`projects`)
```
projects/
  {projectId}/
    - title: string
    - location: string
    - duration: string
    - targeting: string
    - description: string
    - benefits: array<string>
    - contact: string
    - expires: string
    - createdAt: string (ISO 8601)
```

## 🚀 **Quick Start for Admins**

1. **Login to the app** with your Google account or Email/Password
2. **Wait for admin privileges** (someone needs to set `isAdmin: true` in Firestore)
3. **Restart the app** or logout/login again
4. **You'll see the + button** in the Project Offers screen
5. **Tap + to add a new project**
6. **Fill in the form** and save

## 🔒 **Security Notes**

- By default, all new users are **normal users**
- Admin status must be manually granted via Firebase Console
- There's no self-service admin registration (by design)
- Consider implementing proper security rules in Firestore to restrict write access to admins only

## 📝 **Recommended Firestore Security Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - read by all, write by admins only
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // Projects collection - read by all, write by admins only
    match /projects/{projectId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null && 
                                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

## 🎓 **First Admin Setup**

To set up the **first admin** in your system:

1. Create an account in the app (Google Sign-In or Email/Password)
2. Go to Firebase Console → Firestore Database
3. Find your user document in the `users` collection
4. Manually set `isAdmin: true`
5. Logout and login again in the app
6. You're now an admin! 🎉

---

**Need help?** Contact the development team or check the Firebase Console documentation.

