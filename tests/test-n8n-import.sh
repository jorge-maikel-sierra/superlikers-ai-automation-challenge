#!/bin/bash

# Script para verificar que n8n está corriendo y el workflow se puede importar

set -e

echo "🔍 Verificando entorno de n8n..."
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verificar que Docker está corriendo
echo "📦 Verificando Docker..."
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker no está corriendo${NC}"
    echo "  Por favor inicia Docker Desktop"
    exit 1
fi
echo -e "${GREEN}✓ Docker está corriendo${NC}"
echo ""

# 2. Verificar que el contenedor de n8n existe
echo "🐳 Verificando contenedor de n8n..."
if ! docker ps -a | grep -q superlikers-n8n; then
    echo -e "${YELLOW}⚠ Contenedor 'superlikers-n8n' no encontrado${NC}"
    echo "  Iniciando n8n..."
    cd docker && docker compose up -d
    sleep 5
else
    echo -e "${GREEN}✓ Contenedor 'superlikers-n8n' encontrado${NC}"
fi
echo ""

# 3. Verificar que n8n está corriendo
echo "🚀 Verificando estado de n8n..."
if ! docker ps | grep -q superlikers-n8n; then
    echo -e "${YELLOW}⚠ n8n no está corriendo, iniciando...${NC}"
    cd docker && docker compose start n8n
    sleep 5
fi
echo -e "${GREEN}✓ n8n está corriendo${NC}"
echo ""

# 4. Verificar que n8n responde en el puerto 5678
echo "🌐 Verificando endpoint de n8n..."
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:5678/healthz > /dev/null 2>&1; then
        echo -e "${GREEN}✓ n8n responde en http://localhost:5678${NC}"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "  Esperando que n8n esté listo... ($RETRY_COUNT/$MAX_RETRIES)"
            sleep 2
        else
            echo -e "${RED}✗ n8n no responde después de $MAX_RETRIES intentos${NC}"
            echo "  Verifica los logs: docker compose -f docker/docker-compose.yml logs n8n"
            exit 1
        fi
    fi
done
echo ""

# 5. Verificar variables de entorno
echo "🔐 Verificando variables de entorno..."
MISSING_VARS=()

check_env_var() {
    VAR_NAME=$1
    if docker compose -f docker/docker-compose.yml exec -T n8n env | grep -q "^${VAR_NAME}="; then
        echo -e "  ${GREEN}✓${NC} $VAR_NAME está configurado"
    else
        echo -e "  ${RED}✗${NC} $VAR_NAME NO está configurado"
        MISSING_VARS+=("$VAR_NAME")
    fi
}

check_env_var "SUPERLIKERS_API_KEY"
check_env_var "SUPERLIKERS_BASE_URL"
check_env_var "OPENAI_API_KEY"

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠ Variables faltantes: ${MISSING_VARS[*]}${NC}"
    echo "  Configúralas en docker/.env y reinicia n8n"
    echo "  docker compose -f docker/docker-compose.yml restart n8n"
else
    echo -e "${GREEN}✓ Todas las variables de entorno requeridas están configuradas${NC}"
fi
echo ""

# 6. Verificar que el workflow corregido existe
echo "📄 Verificando workflow corregido..."
WORKFLOW_PATH="n8n/workflows/participant-onboarding-v2-corrected.json"
if [ -f "$WORKFLOW_PATH" ]; then
    WORKFLOW_SIZE=$(ls -lh "$WORKFLOW_PATH" | awk '{print $5}')
    echo -e "${GREEN}✓ Workflow encontrado: $WORKFLOW_PATH ($WORKFLOW_SIZE)${NC}"
    
    # Validar que es JSON válido
    if jq empty "$WORKFLOW_PATH" 2>/dev/null; then
        echo -e "${GREEN}✓ JSON válido${NC}"
    else
        echo -e "${RED}✗ JSON inválido${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Workflow no encontrado en: $WORKFLOW_PATH${NC}"
    exit 1
fi
echo ""

# 7. Ejecutar tests de validación
echo "🧪 Ejecutando tests de validación..."
if [ -f "tests/workflow-validation-tests.py" ]; then
    /usr/bin/python3 tests/workflow-validation-tests.py
    TEST_RESULT=$?
    
    if [ $TEST_RESULT -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ TODOS LOS TESTS PASARON${NC}"
    else
        echo ""
        echo -e "${RED}❌ ALGUNOS TESTS FALLARON${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ Tests de validación no encontrados${NC}"
fi
echo ""

# 8. Resumen final
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ VERIFICACIÓN COMPLETA${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Próximos pasos:"
echo ""
echo "1. Acceder a n8n:"
echo "   → http://localhost:5678"
echo ""
echo "2. Importar workflow:"
echo "   → Menú → Import → Seleccionar: n8n/workflows/participant-onboarding-v2-corrected.json"
echo ""
echo "3. Configurar credenciales en n8n UI:"
echo "   → OpenAI Credential (nombre: 'OpenAI')"
echo "   → Superlikers API Header Auth (nombre: 'Superlikers API')"
echo ""
echo "4. Activar workflow:"
echo "   → Toggle 'Active' en la esquina superior derecha"
echo ""
echo "5. Configurar webhook de WhatsApp:"
echo "   → Copiar URL del nodo 'WhatsApp Webhook'"
echo "   → Configurar en WhatsApp Business API"
echo ""
echo "📚 Para más información, ver:"
echo "   → GUIA-PRUEBAS.md (paso a paso completo)"
echo "   → RESUMEN-ENTREGA.md (overview del proyecto)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
