#!/bin/bash

# Manual Firebase Login Helper
# This script helps you complete Firebase login manually

echo "🔐 Firebase Login Manual"
echo "========================"
echo ""
echo "Per completare il login Firebase, segui questi passaggi:"
echo ""
echo "1. Vai su: https://console.firebase.google.com"
echo "2. Accedi con il tuo account Google"
echo "3. Seleziona il progetto: tmelnikapp"
echo ""
echo "OPPURE"
echo ""
echo "Esegui questo comando nel terminale:"
echo "  firebase login"
echo ""
echo "Questo dovrebbe aprire automaticamente il browser."
echo ""
echo "Se il browser non si apre, puoi anche:"
echo "  1. Apri Chrome manualmente"
echo "  2. Vai su: https://console.firebase.google.com"
echo "  3. Accedi e poi torna qui"
echo ""
read -p "Premi INVIO quando hai completato il login..." 

echo ""
echo "Verificando login..."
if firebase projects:list &> /dev/null; then
    echo "✅ Login completato con successo!"
    firebase projects:list
    echo ""
    firebase use tmelnikapp
    echo ""
    echo "✅ Tutto pronto!"
else
    echo "❌ Login non ancora completato."
    echo "Riprova eseguendo: firebase login"
fi

