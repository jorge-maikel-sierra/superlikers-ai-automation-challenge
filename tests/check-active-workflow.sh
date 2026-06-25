#!/bin/bash
# Script para verificar el workflow activo y obtener información útil

echo "🔍 Verificando workflows en n8n..."
echo ""

echo "📁 Workflows en disco:"
docker exec superlikers-n8n ls -1 /home/node/.n8n/workflows/
echo ""

echo "📊 Últimas activaciones en logs:"
docker exec superlikers-n8n cat /home/node/.n8n/n8nEventLog.log | \
  grep "workflow.activated" | \
  tail -3 | \
  jq -r '.payload | "WorkflowID: \(.workflowId) | Name: \(.workflowName) | VersionID: \(.activeVersionId)"'
echo ""

echo "⚠️  Últimos errores:"
docker exec superlikers-n8n cat /home/node/.n8n/n8nEventLog.log | \
  grep "workflow.failed" | \
  tail -3 | \
  jq -r '.payload | "Error: \(.errorMessage) | Node: \(.errorNodeType) | Workflow: \(.workflowName)"'
echo ""

echo "✅ Para activar el workflow v2-corrected:"
echo "   1. Ir a http://localhost:5678"
echo "   2. Desactivar 'Participant Onboarding v1' (si está activo)"
echo "   3. Abrir el workflow correcto en Workflows"
echo "   4. Activar con el toggle"
echo ""
