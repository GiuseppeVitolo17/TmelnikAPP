# ✅ Server-Side Validation - Complete Guide

## Why validate server-side?

### Issues without validation
- ❌ Malicious clients send invalid data
- ❌ Database fills with broken records
- ❌ Buggy UI due to missing/invalid data
- ❌ Security issues (injection-style)
- ❌ Massive spam

### Concrete example

```
❌ Malicious user creates 1000 projects with:
{
  title: "",           // EMPTY
  location: "🦄",      // Emoji only
  description: "x".repeat(100000), // Huge text
  benefits: ["", "", ""] // Empty items
}

Result:
- Dirty database
- App crashes due to huge payload
- Firestore cost spikes
```

---

## 🛡️ Validation strategies

### 1) Firestore Security Rules

Ottimo per sicurezza base, gratis, ma limitata:

```javascript
// firestore.rules
match /project_offers/{offerId} {
  function isValidProject() {
    let data = request.resource.data;
    
    // REQUIRED FIELDS
    return 
      data.title is string && data.title.size() > 3 &&
      data.location is string && data.location.size() > 2 &&
      data.description is string && data.description.size() > 10 &&
      data.benefits is list && data.benefits.size() > 0 &&
      data.targeting is string && data.targeting.size() > 2 &&
      data.createdAt is timestamp &&
      data.isActive is bool;
  }
  
  allow create: if isAdmin() && isValidProject();
  allow update: if isAdmin() && isValidProject();
}
```

Rules limits:
- ❌ Cannot validate semantics (e.g., “valid benefit?”)
- ❌ Cannot call external APIs
- ❌ Limited complex logic
- ✅ Great for basic field checks, free and fast

---

### 2) Cloud Functions (recommended)

For complex validations and real control:

```javascript
// functions/index.js
const admin = require('firebase-admin');
const functions = require('firebase-functions');

// Project validator
function validateProject(data) {
  const errors = [];
  
  // TITLE
  if (!data.title || typeof data.title !== 'string') {
    errors.push('title: required string');
  } else if (data.title.length < 5) {
    errors.push('title: min 5 characters');
  } else if (data.title.length > 100) {
    errors.push('title: max 100 characters');
  }
  
  // LOCATION
  if (!data.location || typeof data.location !== 'string') {
    errors.push('location: required string');
  } else if (data.location.length < 2) {
    errors.push('location: min 2 characters');
  }
  
  // DESCRIPTION
  if (!data.description || typeof data.description !== 'string') {
    errors.push('description: required');
  } else if (data.description.length < 20) {
    errors.push('description: min 20 characters');
  } else if (data.description.length > 5000) {
    errors.push('description: max 5000 characters');
  }
  
  // BENEFITS
  if (!Array.isArray(data.benefits)) {
    errors.push('benefits: must be array');
  } else if (data.benefits.length === 0) {
    errors.push('benefits: at least 1 benefit required');
  } else if (data.benefits.length > 20) {
    errors.push('benefits: max 20 items');
  } else {
    // Validate each benefit
    data.benefits.forEach((benefit, i) => {
      if (typeof benefit !== 'string' || benefit.trim().length === 0) {
        errors.push(`benefits[${i}]: must be non-empty string`);
      } else if (benefit.length > 200) {
        errors.push(`benefits[${i}]: max 200 characters`);
      }
    });
  }
  
  // DATES
  if (data.departureDate && !isValidDate(data.departureDate)) {
    errors.push('departureDate: invalid date');
  }
  
  if (data.returnDate && !isValidDate(data.returnDate)) {
    errors.push('returnDate: invalid date');
  }
  
  // Ensure returnDate is after departureDate
  if (data.departureDate && data.returnDate) {
    if (new Date(data.returnDate) < new Date(data.departureDate)) {
      errors.push('returnDate must be after departureDate');
    }
  }
  
  return {
    valid: errors.length === 0,
    errors
  };
}

function isValidDate(date) {
  const d = new Date(date);
  return d instanceof Date && !isNaN(d);
}

// HTTPS callable to create projects
exports.createProject = functions.https.onCall(async (data, context) => {
  // 1) Auth check
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated', 
      'Must be authenticated'
    );
  }
  
  // 2) Admin check
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(context.auth.uid)
    .get();
  
  if (!userDoc.exists || !userDoc.data().isAdmin) {
    throw new functions.https.HttpsError(
      'permission-denied', 
      'Admin only'
    );
  }
  
  // 3) Validate data
  const validation = validateProject(data.project);
  if (!validation.valid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Validation failed: ${validation.errors.join(', ')}`
    );
  }
  
  // 4) Clean and sanitize
  const cleanData = {
    title: data.project.title.trim(),
    location: data.project.location.trim(),
    description: data.project.description.trim(),
    targeting: data.project.targeting.trim(),
    benefits: data.project.benefits
      .map(b => b.trim())
      .filter(b => b.length > 0),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdBy: context.auth.uid,
    isActive: true,
  };
  
  // 5) Save
  const docRef = await admin.firestore()
    .collection('project_offers')
    .add(cleanData);
  
  return { 
    success: true, 
    id: docRef.id,
    warnings: [] 
  };
});
```

---

### 3) Client-side validation (bonus)

Does not replace server validation, but improves UX and reduces errors:

```dart
// lib/services/project_validator.dart
class ProjectValidator {
  static ValidationResult validateProject(Map<String, dynamic> data) {
    final errors = <String>[];
    
    // Title
    if (data['title'] == null || (data['title'] as String).trim().isEmpty) {
      errors.add('Title is required');
    } else if ((data['title'] as String).length < 5) {
      errors.add('Title must be at least 5 characters');
    }
    
    // Description
    final desc = data['description'] as String?;
    if (desc == null || desc.trim().isEmpty) {
      errors.add('Description is required');
    } else if (desc.length < 20) {
      errors.add('Description too short (min 20 characters)');
    }
    
    // Benefits
    final benefits = data['benefits'] as List?;
    if (benefits == null || benefits.isEmpty) {
      errors.add('Add at least one benefit');
    } else if (benefits.length > 20) {
      errors.add('Max 20 benefits');
    }
    
    // Dates validation
    final departure = data['departureDate'] as DateTime?;
    final returnDate = data['returnDate'] as DateTime?;
    
    if (departure != null && returnDate != null) {
      if (returnDate.isBefore(departure)) {
        errors.add('Return date must be after departure');
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  ValidationResult({required this.isValid, required this.errors});
}

// USAGE
final result = ProjectValidator.validateProject(projectData);
if (!result.isValid) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result.errors.join('\n')),
      backgroundColor: Colors.red,
    ),
  );
  return;
}
```

---

## 📋 Validation standards for Tmelnik

### **ProjectOffer**
| Field | Rules | Error message |
|-------|--------|------------------|
| `title` | 5-100 chars, required | "Title must be 5-100 chars" |
| `location` | 2-100 chars, required | "Provide a valid location" |
| `description` | 20-5000 chars, required | "Description too short/long" |
| `benefits` | 1-20 items, non-empty | "Add at least one benefit" |
| `targeting` | 2-200 chars | "Specify target audience" |
| `instagramAccount` | Valid username | "Invalid Instagram username" |
| `expiresAt` | Future date | "Deadline must be in the future" |

### **JournalEntry**
| Field | Rules | Error message |
|-------|--------|------------------|
| `content` | 1-5000 chars | "Content cannot be empty" |
| `date` | Valid date | "Invalid date" |
| `mood` | Valid emoji | "Select a mood" |

### **Feedback**
| Field | Rules | Error message |
|-------|--------|------------------|
| `title` | 3-200 chars | "Title too short/long" |
| `description` | 10-2000 chars | "Description insufficient" |
| `rating` | 1-5 | "Rating must be between 1 and 5" |
| `tags` | Max 10 tags | "Too many tags" |

---

## 🎯 Practical implementation

### Step 1: Create validator file
```bash
lib/services/project_validator.dart
```

### Step 2: Use in services
```dart
// lib/services/firebase_firestore_service.dart
Future<void> addProjectOffer(ProjectOffer offer) async {
  // VALIDATE BEFORE SENDING
  final result = ProjectValidator.validateProject(offer.toFirestore());
  if (!result.isValid) {
    throw Exception(result.errors.join(', '));
  }
  
  // Proceed with save...
  await _firestore.collection('project_offers').add(offer.toFirestore());
}
```

### Step 3: Show errors to the user
```dart
try {
  await projectService.addProject(project);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ Project created!'),
      backgroundColor: Colors.green,
    ),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('❌ Error: $e'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 5),
    ),
  );
}
```

---

## 💰 Impact

### Before (no validation)
```
Scenario: User sends 1000 invalid projects
- 1000 write operations → $0.36
- Dirty database → Maintenance: 2 hours
- App bugs → Fix: 4 hours
- TOTAL: $0.36 + 6 hours work
```

### After (with validation)
```
Scenario: Same attempt
- Blocked before write → $0
- Clean database → 0 hours
- No bugs → 0 hours
- TOTAL: $0
```

**SAVINGS: significant time and cost per attack avoided.**

---

## ✅ Implementation checklist

- [ ] Create client-side `ProjectValidator`
- [ ] Implement Cloud Functions with validation
- [ ] Define Firestore security rules
- [ ] Test all edge cases
- [ ] Document rules for users
- [ ] Monitor validation errors
- [ ] Update rules based on feedback

---

## 🎓 Best practices

1. **Multi-layer**: Client + Server + Firestore Rules
2. **Clear messages**: Always explain what went wrong
3. **Fail fast**: Block early, don’t wait
4. **Sanitization**: Clean data before saving
5. **Monitoring**: Track failed validations
6. **Documentation**: Clear rules for users

---

**Result**: Clean database, more stable app, fewer bugs, controlled costs. 🚀

