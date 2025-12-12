#!/bin/bash

# Script per avviare l'app Flutter su Chrome
# IMPORTANTE: SEMPRE usare la porta 5000 - non cambiare mai questa porta!

cd /Users/giuseppe/TmelnikAPP

# Libera la porta 5000 se occupata
echo "Liberando porta 5000..."
lsof -ti:5000 | xargs kill -9 2>/dev/null
sleep 2

# Avvia Flutter su Chrome porta 5000
echo "Avviando app su Chrome porta 5000..."
flutter run -d chrome --web-port 5000

