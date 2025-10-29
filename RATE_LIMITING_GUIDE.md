# 🚦 Rate Limiting Implementation Guide

## Perché è Importante?

### **Problemi Senza Rate Limiting:**
- ❌ Un utente può creare migliaia di progetti
- ❌ Spam di feedback falsi
- ❌ Costi Firestore impazziti ($180 per 1M letture)
- ❌ Server sovraccaricato

### **Esempio Concreto:**
```
❌ Senza rate limiting:
- Utente crea 10,000 progetti → Costo: $5
- Server crolla → Downtime: 2 ore

✅ Con rate limiting:
- Utente bloccato dopo 50 progetti/ora
- Costo controllato: $0.02
- Server stabile
```

---

## 🛡️ **Strategie di Rate Limiting**

### **1. Client-Side Rate Limiting (Semplice)**

Implementiamo un RateLimiter semplice in Dart:

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
    
    // Rimuovi tentativi vecchi
    attempts.removeWhere((time) => now.difference(time) > _timeWindow);
    
    if (attempts.length >= _maxAttempts) {
      return false; // Troppi tentativi
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
  maxAttempts: 5, // Max 5 progetti al minuto
);

if (!_rateLimiter.canAttempt('addProject')) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('⏰ Troppi tentativi! Aspetta un momento...'),
      backgroundColor: Colors.orange,
    ),
  );
  return;
}
```

---

### **2. Server-Side Rate Limiting con Cloud Functions**

Per una protezione reale, serve limitare lato server:

```javascript
// functions/index.js
const admin = require('firebase-admin');
const functions = require('firebase-functions');

// Rate limiting con Firebase Firestore
async function checkRateLimit(uid, operation, limit = 10, windowMinutes = 60) {
  const collection = admin.firestore().collection('rate_limits');
  const docId = `${uid}_${operation}`;
  
  try {
    const doc = await collection.doc(docId).get();
    const now = Date.now();
    const windowStart = now - (windowMinutes * 60 * 1000);
    
    if (!doc.exists) {
      // Prima volta
      await collection.doc(docId).set({
        count: 1,
        resetAt: now + (windowMinutes * 60 * 1000),
      });
      return { allowed: true, remaining: limit - 1 };
    }
    
    const data = doc.data();
    
    if (data.resetAt < now) {
      // Finito il time window, reset
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
    
    // Incrementa counter
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

// Cloud Function per creare progetti con rate limiting
exports.createProject = functions.https.onCall(async (data, context) => {
  // Verifica autenticazione
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Devi essere autenticato');
  }
  
  // Verifica che sia admin
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(context.auth.uid)
    .get();
  
  if (!userDoc.data()?.isAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'Solo admin');
  }
  
  // CHECK RATE LIMIT
  const rateLimit = await checkRateLimit(
    context.auth.uid, 
    'createProject',
    10, // Max 10 progetti/ora
    60  // Window: 1 ora
  );
  
  if (!rateLimit.allowed) {
    throw new functions.https.HttpsError(
      'resource-exhausted', 
      `Troppi progetti! Riprova tra ${Math.ceil((rateLimit.resetAt - Date.now()) / 60000)} minuti`
    );
  }
  
  // OK, crea il progetto
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

## 📊 **Limiti Raccomandati per Tmelnik**

| Operazione | Client (min) | Server (ora) | Motivazione |
|------------|-------------|--------------|--------------|
| **Creare Progetto** | 5/min | 50/ora | Solo admin, prevent spam |
| **Feedback** | 10/min | 20/ora | Prevent spam feedback |
| **News** | 5/min | 30/ora | Solo admin, prevent spam |
| **Diario** | 20/min | 100/ora | Uso personale normale |
| **Share Instagram** | 20/min | 50/ora | Uso normale condivisione |

---

## 🎯 **Implementazione Pratica**

### **Step 1: Aggiungi Rate Limiter al Servizio**

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
    
    // Continua con la creazione...
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

### **Step 2: Mostra Messaggi Utente-Friendly**

```dart
Future<void> _saveProject() async {
  if (!_rateLimiter.canAttempt('addProject')) {
    final waitTime = _rateLimiter.timeUntilNextAttempt('addProject');
    
    if (mounted && waitTime != null) {
      final minutes = waitTime.inMinutes;
      final seconds = waitTime.inSeconds % 60;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏰ Aspetta ${minutes}m ${seconds}s prima di aggiungere un nuovo progetto'),
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

## 💰 **Impatto sui Costi**

### **Prima (Senza Rate Limiting):**
```
Scenario: Attacco spam
- 1000 progetti creati da utente malintenzionato
- Costo Firestore: $5
- Costo Cloud Functions: $10
- Downtime: 2 ore
- TOTALE: $15 + downtime
```

### **Dopo (Con Rate Limiting):**
```
Scenario: Stesso attacco
- Bloccato dopo 50 tentativi
- Costo Firestore: $0.25
- Costo Cloud Functions: $0.50
- Nessun downtime
- TOTALE: $0.75
```

**RISPARMIO: $14.25 per attacco!**

---

## ✅ **Checklist Implementazione**

- [ ] Aggiungi RateLimiter client-side
- [ ] Implementa Cloud Functions con rate limiting
- [ ] Configura limiti appropriati per ogni operazione
- [ ] Aggiungi messaggi utente-friendly
- [ ] Monitora con Firebase Analytics
- [ ] Testa con utenti reali
- [ ] Documenta i limiti per gli utenti

---

## 🎓 **Best Practices**

1. **Fail Open**: Se il rate limiting fallisce, permetti l'operazione (meglio un accesso extra che il blocco completo)
2. **Messaggi Chiari**: Spiega all'utente perché è bloccato e quando può riprovare
3. **Monitoring**: Monitora i tentativi di rate limiting per rilevare attacchi
4. **Adattamento**: Aumenta i limiti se i legittimi rimangono ostacolati
5. **Admin Bypass**: Gli admin dovrebbero avere limiti più alti

---

**Risultato**: Protezione reale, costi controllati, esperienza utente migliore! 🚀

