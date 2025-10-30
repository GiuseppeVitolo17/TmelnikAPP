# 🚦 Rate Limiting Implementation Guide

## Why is it important?

### Problems without rate limiting
- ❌ A user can create thousands of projects
- ❌ Spam with fake feedback
- ❌ Firestore costs spike ($180 per 1M reads)
- ❌ Overloaded server

### Concrete example
```
❌ Without rate limiting:
- User creates 10,000 projects → Cost: $5
- Server crashes → Downtime: 2 hours

✅ With rate limiting:
- User blocked after 50 projects/hour
- Controlled cost: $0.02
- Stable server
```

---

## 🛡️ Rate limiting strategies

### 1) Client-side rate limiting (simple)

Implement a simple RateLimiter in Dart:

```dart
// lib/utils/rate_limiter.dart
class RateLimiter {
  final Map<String, List<DateTime>> _attempts = {};
  final Duration _timeWindow;
  final int _maxAttempts;
  
  RateLimiter({
    Duration timeWindow = const Duration(minutes: 1),
    int maxAttempts = 10,
  })  : _timeWindow = timeWindow,
        _maxAttempts = maxAttempts;
  
  bool canAttempt(String operation) {
    final now = DateTime.now();
    final attempts = _attempts.putIfAbsent(operation, () => <DateTime>[]);
    
    // Remove old attempts
    attempts.removeWhere((time) => now.difference(time) > _timeWindow);
    
    if (attempts.length >= _maxAttempts) {
      return false; // Too many attempts
    }
    
    attempts.add(now);
    return true; // OK
  }
  
  Duration? timeUntilNextAttempt(String operation) {
    final attempts = _attempts[operation] ?? [];
    if (attempts.isEmpty) return null;
    
    final oldestAttempt = attempts.first;
    final elapsed = DateTime.now().difference(oldestAttempt);
    final remaining = _timeWindow - elapsed;
    
    return remaining.isNegative ? null : remaining;
  }
}

// USAGE
final _rateLimiter = RateLimiter(
  timeWindow: Duration(minutes: 1),
  maxAttempts: 5, // Max 5 projects per minute
);

if (!_rateLimiter.canAttempt('addProject')) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('⏰ Too many attempts! Please wait...'),
      backgroundColor: Colors.orange,
    ),
  );
  return;
}
```

---

### **2. Server-Side Rate Limiting with Cloud Functions**

For real protection, enforce limits on the server:

```javascript
// functions/index.js
const admin = require('firebase-admin');
const functions = require('firebase-functions');

// Rate limiting using Firebase Firestore
async function checkRateLimit(uid, operation, limit = 10, windowMinutes = 60) {
  const collection = admin.firestore().collection('rate_limits');
  const docId = `${uid}_${operation}`;
  
  try {
    const doc = await collection.doc(docId).get();
    const now = Date.now();
    const windowStart = now - (windowMinutes * 60 * 1000);
    
    if (!doc.exists) {
      // First time
      await collection.doc(docId).set({
        count: 1,
        resetAt: now + (windowMinutes * 60 * 1000),
      });
      return { allowed: true, remaining: limit - 1 };
    }
    
    const data = doc.data();
    
    if (data.resetAt < now) {
      // Window ended, reset
      await collection.doc(docId).set({
        count: 1,
        resetAt: now + (windowMinutes * 60 * 1000),
      });
      return { allowed: true, remaining: limit - 1 };
    }
    
    if (data.count >= limit) {
      return { 
        allowed: false, 
        remaining: 0,
        resetAt: data.resetAt
      };
    }
    
    // Increment counter
    await collection.doc(docId).update({
      count: admin.firestore.FieldValue.increment(1),
    });
    
    return { 
      allowed: true, 
      remaining: limit - data.count - 1 
    };
  } catch (error) {
    console.error('Rate limit check failed:', error);
    return { allowed: true }; // Fail open
  }
}

// Cloud Function to create projects with rate limiting
exports.createProject = functions.https.onCall(async (data, context) => {
  // Auth check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  // Admin check
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(context.auth.uid)
    .get();
  
  if (!userDoc.data()?.isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Admins only');
  }
  
  // CHECK RATE LIMIT
  const rateLimit = await checkRateLimit(
    context.auth.uid, 
    'createProject',
    10, // Max 10 projects/hour
    60  // Window: 1 hour
  );
  
  if (!rateLimit.allowed) {
    throw new functions.https.HttpsError(
      'resource-exhausted', 
      `Too many projects! Try again in ${Math.ceil((rateLimit.resetAt - Date.now()) / 60000)} minutes`
    );
  }
  
  // OK, create project
  const projectData = data.project;
  
  await admin.firestore()
    .collection('project_offers')
    .doc()
    .set({
      ...projectData,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: context.auth.uid,
      isActive: true,
    });
  
  return { 
    success: true, 
    remaining: rateLimit.remaining 
  };
});
```

---

## 📊 **Recommended Limits for Tmelnik**

| Operazione | Client (min) | Server (ora) | Motivazione |
|------------|-------------|--------------|--------------|
| **Create Project** | 5/min | 50/hour | Admins only, prevent spam |
| **Feedback** | 10/min | 20/hour | Prevent spam feedback |
| **News** | 5/min | 30/hour | Admins only, prevent spam |
| **Diary** | 20/min | 100/hour | Normal personal usage |
| **Share Instagram** | 20/min | 50/hour | Normal sharing usage |

---

## 🎯 **Practical Implementation**

### **Step 1: Add Rate Limiter to the Service**

Modifica `lib/services/project_service.dart`:

```dart
import '../utils/rate_limiter.dart';

class ProjectService {
  final RateLimiter _rateLimiter = RateLimiter(
    timeWindow: Duration(minutes: 1),
    maxAttempts: 5,
  );
  
  Future<bool> addProject(ProjectOffer offer) async {
    // Check rate limit
    if (!_rateLimiter.canAttempt('addProject')) {
      throw Exception('Rate limit exceeded');
    }
    
    // Continue with creation...
    try {
      await FirebaseFirestore.instance
          .collection('project_offers')
          .add(offer.toFirestore());
      return true;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
```

### **Step 2: Show User-Friendly Messages**

```dart
Future<void> _saveProject() async {
  if (!_rateLimiter.canAttempt('addProject')) {
    final waitTime = _rateLimiter.timeUntilNextAttempt('addProject');
    
    if (mounted && waitTime != null) {
      final minutes = waitTime.inMinutes;
      final seconds = waitTime.inSeconds % 60;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏰ Please wait ${minutes}m ${seconds}s before adding a new project'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
    return;
  }
  
  // Procedi con il salvataggio...
}
```

---

## 💰 **Cost Impact**

### **Before (No Rate Limiting):**
```
Scenario: Spam attack
- 1000 projects created by malicious user
- Costo Firestore: $5
- Costo Cloud Functions: $10
- Downtime: 2 hours
- TOTAL: $15 + downtime
```

### **After (With Rate Limiting):**
```
Scenario: Same attack
- Blocked after 50 attempts
- Firestore cost: $0.25
- Cloud Functions cost: $0.50
- No downtime
- TOTAL: $0.75
```

**SAVINGS: $14.25 per attack!**

---

## ✅ **Implementation Checklist**

- [ ] Add client-side RateLimiter
- [ ] Implement Cloud Functions with rate limiting
- [ ] Configure appropriate limits per operation
- [ ] Add user-friendly messages
- [ ] Monitor with Firebase Analytics
- [ ] Test with real users
- [ ] Document limits for users

---

## 🎓 **Best Practices**

1. **Fail Open**: If rate limiting fails, allow the operation (better one extra access than a full block)
2. **Clear Messages**: Explain why the user is blocked and when to retry
3. **Monitoring**: Track attempts to detect abuse
4. **Adaptation**: Raise limits if legitimate users are blocked
5. **Admin Bypass**: Admins should have higher limits

---

**Result**: Real protection, controlled costs, better UX! 🚀

