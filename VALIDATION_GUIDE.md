# ✅ Validazione Lato Server - Guida Completa

## Perché Validare Server-Side?

### **Problemi Senza Validazione**
- ❌ Client malintenzionato invia dati invalidi
- ❌ Database pieno di record rotti
- ❌ UI buggy per dati mancanti
- ❌ Bug di sicurezza (SQL injection-style)
- ❌ Spam massivo

### **Esempio Concreto:**

```
❌ User malintenzionato crea 1000 progetti con:
{
  title: "",           // VUOTO
  location: "🦄",      // Solo emoji
  description: "x".repeat(100000), // Testo gigante
  benefits: ["", "", ""] // Array vuoto
}

Risultato:
- Database pieno di spazzatura
- App crash per troppi dati
- Costo Firestore: $50
```

---

## 🛡️ **Strategie di Validazione**

### **1. Validazione con Firestore Security Rules**

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

**Limiti delle Rules:**
- ❌ Non può validare contenuto semantico ("benefit valido?")
- ❌ Non può chiamare API esterne
- ❌ Non può validare logic complesse
- ✅ Buono per validazione campi base
- ✅ Gratis
- ✅ Veloce

---

### **2. Validazione con Cloud Functions (Raccomandato)**

Per validazioni complesse e controllo reale:

```javascript
// functions/index.js
const admin = require('firebase-admin');
const functions = require('firebase-functions');

// Validatore per progetti
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
    // Valida ogni benefit
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
  
  // Valida che returnDate sia dopo departureDate
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

// Cloud Function per creare progetti
exports.createProject = functions.https.onCall(async (data, context) => {
  // 1. Verifica autenticazione
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated', 
      'Must be authenticated'
    );
  }
  
  // 2. Verifica admin
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
  
  // 3. VALIDA I DATI
  const validation = validateProject(data.project);
  if (!validation.valid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Validation failed: ${validation.errors.join(', ')}`
    );
  }
  
  // 4. Pulisci e sanitizza dati
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
  
  // 5. Salva
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

### **3. Validazione Client-Side (Bonus)**

Non sostituisce il server, ma migliora l’UX e riduce errori:

```dart
// lib/services/project_validator.dart
class ProjectValidator {
  static ValidationResult validateProject(Map<String, dynamic> data) {
    final errors = <String>[];
    
    // Title
    if (data['title'] == null || (data['title'] as String).trim().isEmpty) {
      errors.add('Il titolo è obbligatorio');
    } else if ((data['title'] as String).length < 5) {
      errors.add('Il titolo deve avere almeno 5 caratteri');
    }
    
    // Description
    final desc = data['description'] as String?;
    if (desc == null || desc.trim().isEmpty) {
      errors.add('La descrizione è obbligatoria');
    } else if (desc.length < 20) {
      errors.add('La descrizione deve essere più dettagliata (min 20 caratteri)');
    }
    
    // Benefits
    final benefits = data['benefits'] as List?;
    if (benefits == null || benefits.isEmpty) {
      errors.add('Aggiungi almeno un benefit');
    } else if (benefits.length > 20) {
      errors.add('Massimo 20 benefits');
    }
    
    // Dates validation
    final departure = data['departureDate'] as DateTime?;
    final returnDate = data['returnDate'] as DateTime?;
    
    if (departure != null && returnDate != null) {
      if (returnDate.isBefore(departure)) {
        errors.add('La data di ritorno deve essere dopo la partenza');
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

## 📋 **Standard di Validazione per Tmelnik**

### **ProjectOffer**
| Campo | Regole | Messaggio Errore |
|-------|--------|------------------|
| `title` | 5-100 caratteri, obbligatorio | "Il titolo deve essere tra 5 e 100 caratteri" |
| `location` | 2-100 caratteri, obbligatorio | "Indica una location valida" |
| `description` | 20-5000 caratteri, obbligatorio | "Descrizione troppo corta/lunga" |
| `benefits` | 1-20 elementi, non vuoti | "Aggiungi almeno un benefit" |
| `targeting` | 2-200 caratteri | "Specifica il target audience" |
| `instagramAccount` | Formato username valido | "Inserisci un username Instagram valido" |
| `expiresAt` | Data futura | "La scadenza deve essere futura" |

### **JournalEntry**
| Campo | Regole | Messaggio Errore |
|-------|--------|------------------|
| `content` | 1-5000 caratteri | "Il contenuto non può essere vuoto" |
| `date` | Data valida | "Data non valida" |
| `mood` | Emoji valida | "Seleziona un mood" |

### **Feedback**
| Campo | Regole | Messaggio Errore |
|-------|--------|------------------|
| `title` | 3-200 caratteri | "Titolo troppo corto/lungo" |
| `description` | 10-2000 caratteri | "Descrizione insufficiente" |
| `rating` | 1-5 numeri | "Rating deve essere tra 1 e 5" |
| `tags` | Max 10 tags | "Troppi tag" |

---

## 🎯 **Implementazione Pratica**

### **Step 1: Crea il file validatore**
```bash
lib/services/project_validator.dart
```

### **Step 2: Usa nei servizi**
```dart
// lib/services/firebase_firestore_service.dart
Future<void> addProjectOffer(ProjectOffer offer) async {
  // VALIDA PRIMA DI INVIARE
  final result = ProjectValidator.validateProject(offer.toFirestore());
  if (!result.isValid) {
    throw Exception(result.errors.join(', '));
  }
  
  // Procedi con il salvataggio...
  await _firestore.collection('project_offers').add(offer.toFirestore());
}
```

### **Step 3: Mostra errori all'utente**
```dart
try {
  await projectService.addProject(project);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('✅ Progetto creato!'),
      backgroundColor: Colors.green,
    ),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('❌ Errore: $e'),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 5),
    ),
  );
}
```

---

## 💰 **Impatto**

### **Prima (Senza Validazione):**
```
Scenario: User invia 1000 progetti invalidi
- 1000 write operations → $0.36
- Database sporco → Manutenzione: 2 ore
- Bug nell'app → Fix: 4 ore
- TOTALE: $0.36 + 6 ore lavoro
```

### **Dopo (Con Validazione):**
```
Scenario: Stesso tentativo
- Bloccato prima del write → $0
- Database pulito → 0 ore
- Nessun bug → 0 ore
- TOTALE: $0
```

**RISPARMIO: $0.36 + 6 ore per ogni attacco!**

---

## ✅ **Checklist Implementazione**

- [ ] Creare `ProjectValidator` client-side
- [ ] Implementare Cloud Functions con validazione
- [ ] Definire regole Firestore security rules
- [ ] Testare tutti i casi edge
- [ ] Documentare regole per utenti
- [ ] Monitorare errori di validazione
- [ ] Aggiornare regole basandosi sui feedback

---

## 🎓 **Best Practices**

1. **Strato Multiplo**: Client + Server + Firestore Rules
2. **Messaggi Chiari**: Spiega sempre cosa non va
3. **Fail Fast**: Blocca subito, non aspettare
4. **Sanitizzazione**: Pulisci i dati prima di salvare
5. **Monitoring**: Traccia le validazioni fallite
6. **Documentazione**: Regole chiare per gli utenti

---

**Risultato**: Database pulito, app più stabile, meno bug, costi controllati! 🚀

