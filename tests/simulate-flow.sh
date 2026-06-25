#!/bin/bash
# Simulación de flujo de WhatsApp para testing

WEBHOOK_URL="http://localhost:5678/webhook/whatsapp"
PHONE="+573001234567"
TIMESTAMP=$(date +%s)

echo "🧪 Iniciando simulación de flujo..."
echo ""

# Paso 1: Mensaje inicial
echo "Paso 1: Enviando saludo inicial..."
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "entry": [{
      "changes": [{
        "value": {
          "messages": [{
            "from": "'"$PHONE"'",
            "type": "text",
            "text": {"body": "Hola"}
          }]
        }
      }]
    }]
  }' 2>&1 | head -5

echo ""
sleep 2

# Paso 2: Enviar celular
echo "Paso 2: Enviando número de celular..."
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "entry": [{
      "changes": [{
        "value": {
          "messages": [{
            "from": "'"$PHONE"'",
            "type": "text",
            "text": {"body": "3001234567"}
          }]
        }
      }]
    }]
  }' 2>&1 | head -5

echo ""
echo "✅ Prueba básica completada"
echo "Ver ejecuciones en: http://localhost:5678"
