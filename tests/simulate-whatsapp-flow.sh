#!/bin/bash

# Script para simular el flujo de WhatsApp y probar el workflow completo
# Este script simula mensajes de WhatsApp enviándolos al webhook de n8n

set -e

WEBHOOK_URL="http://localhost:5678/webhook/whatsapp"
PHONE="+573001234567"
LOCAL_PHONE="3001234567"
TIMESTAMP=$(date +%s)

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "══════════════════════════════════════════════════════════════════"
echo "  🧪 SIMULACIÓN DE FLUJO COMPLETO - USUARIO NUEVO"
echo "══════════════════════════════════════════════════════════════════"
echo ""

# Función para enviar mensaje de texto
send_text_message() {
    local message=$1
    local step=$2
    
    echo -e "${BLUE}[$step]${NC} Enviando: ${YELLOW}\"$message\"${NC}"
    
    PAYLOAD=$(cat <<EOF
{
  "entry": [{
    "changes": [{
      "value": {
        "messages": [{
          "from": "$PHONE",
          "id": "msg_$TIMESTAMP",
          "timestamp": "$TIMESTAMP",
          "type": "text",
          "text": {
            "body": "$message"
          }
        }],
        "contacts": [{
          "profile": {
            "name": "Test User"
          }
        }]
      }
    }]
  }]
}
EOF
)
    
    RESPONSE=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD")
    
    echo -e "${GREEN}  ✓${NC} Mensaje enviado"
    echo ""
    sleep 2
}

# Función para simular envío de imagen
send_image_message() {
    local caption=$1
    local step=$2
    local media_id="media_$TIMESTAMP"
    
    echo -e "${BLUE}[$step]${NC} Enviando: ${YELLOW}📷 Imagen (caption: \"$caption\")${NC}"
    
    PAYLOAD=$(cat <<EOF
{
  "entry": [{
    "changes": [{
      "value": {
        "messages": [{
          "from": "$PHONE",
          "id": "msg_img_$TIMESTAMP",
          "timestamp": "$TIMESTAMP",
          "type": "image",
          "image": {
            "id": "$media_id",
            "mime_type": "image/jpeg",
            "sha256": "test_sha_$TIMESTAMP",
            "caption": "$caption"
          }
        }],
        "contacts": [{
          "profile": {
            "name": "Test User"
          }
        }]
      }
    }]
  }]
}
EOF
)
    
    RESPONSE=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD")
    
    echo -e "${GREEN}  ✓${NC} Imagen enviada"
    echo ""
    sleep 2
}

# Test 1: Mensaje inicial
echo "═══ Test 1: Inicio del flujo ═══"
send_text_message "Hola" "Paso 1"

# Test 2: Enviar celular
echo "═══ Test 2: Validación de celular ═══"
send_text_message "$LOCAL_PHONE" "Paso 2"

# Test 3: Enviar nombre (si es usuario nuevo)
echo "═══ Test 3: Captura de nombre ═══"
send_text_message "Juan Pérez Test" "Paso 3"

# Test 4: Enviar email
echo "═══ Test 4: Captura de email ═══"
send_text_message "juan.test.$TIMESTAMP@example.com" "Paso 4"

# Test 5: Confirmar datos
echo "═══ Test 5: Confirmación de datos ═══"
send_text_message "Sí" "Paso 5"

# Test 6: Enviar foto del ticket
echo "═══ Test 6: Carga de ticket ═══"
send_image_message "Ticket de compra" "Paso 6"

echo ""
echo "══════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ SIMULACIÓN COMPLETA${NC}"
echo "══════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Para ver los resultados:"
echo "  1. Ir a http://localhost:5678"
echo "  2. Click en 'Executions' en el menú lateral"
echo "  3. Revisar las ejecuciones del workflow"
echo ""
echo "📝 Para ver los logs:"
echo "  docker exec superlikers-n8n cat /home/node/.n8n/n8nEventLog.log | tail -50"
echo ""
