# 📊 Estado Actual del Proyecto - Workflow en n8n

**Fecha**: 25 de junio de 2026, 00:16  
**Estado**: Workflow importado, ejecutándose pero requiere cambio de versión

---

## ✅ Lo que está funcionando

1. ✅ **n8n está corriendo** y responde en http://localhost:5678
2. ✅ **Workflow importado** correctamente (4 versiones disponibles)
3. ✅ **Workflow activo**: "Participant Onboarding v1"
4. ✅ **Ejecuciones funcionando**: El workflow se ejecuta cuando recibe requests
5. ✅ **Variables de entorno** configuradas (SUPERLIKERS_API_KEY, OPENAI_API_KEY)

---

## ⚠️ Problema Identificado

**El workflow activo es la versión v1 (original) en lugar de la v2-corrected (corregida)**

### Evidencia:
```
Workflow activo: "Participant Onboarding v1"
Workflow ID: geR3efpK8GTzUpTN
```

### Impacto:
- ❌ Los endpoints de API no están configurados correctamente (son nodos vacíos en v1)
- ❌ El nodo de IA no tiene el prompt configurado
- ❌ Falta manejo de errores de duplicados
- ❌ Falta validación de tamaño de imagen
- ❌ Webhook no está registrado correctamente

### Errores observados en logs:
```
Error: "Bad request - please check your parameters"
Node: "Send WhatsApp Message"
```

Esto indica que el nodo de WhatsApp intenta enviar mensajes pero falla por configuración incorrecta.

---

## 🔧 Solución Requerida

### ACCIÓN INMEDIATA: Activar el workflow v2-corrected

1. **Ir a n8n**: http://localhost:5678

2. **Desactivar workflow v1**:
   - En el menú lateral: Workflows
   - Buscar: "Participant Onboarding v1"
   - Click en el workflow
   - Toggle "Active" → OFF (desactivar)

3. **Verificar workflows disponibles**:
   Deberías ver estos workflows importados:
   - participant-onboarding-v1.json
   - participant-onboarding-v1-final.json
   - participant-onboarding-v1-updated.json
   - **participant-onboarding-v2-corrected.json** ← ESTE ES EL CORRECTO

4. **Activar workflow v2-corrected**:
   - Si no aparece en la lista de Workflows, importarlo:
     - Menú → Import
     - Seleccionar: `n8n/workflows/participant-onboarding-v2-corrected.json`
   - Abrir el workflow
   - Configurar credenciales (si no están):
     - OpenAI Credential
     - Superlikers API Header Auth
   - Toggle "Active" → ON

5. **Verificar webhook**:
   ```bash
   curl -X POST "http://localhost:5678/webhook/whatsapp" \
     -H "Content-Type: application/json" \
     -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"+573001234567","type":"text","text":{"body":"test"}}]}}]}]}'
   ```
   
   **Respuesta esperada**: 200 OK (no 404)

---

## 📋 Workflows Disponibles

| Archivo | Descripción | Estado |
|---------|-------------|--------|
| `participant-onboarding-v1.json` | Original sin modificar | ❌ No usar |
| `participant-onboarding-v1-updated.json` | Con updates parciales | ❌ No usar |
| `participant-onboarding-v1-final.json` | Versión previa | ❌ No usar |
| **`participant-onboarding-v2-corrected.json`** | **Versión con TODAS las correcciones** | ✅ **USAR ESTE** |

---

## 🧪 Tests Pendientes (una vez activado v2)

### Test 1: Verificación de webhook
```bash
curl -X GET "http://localhost:5678/webhook/whatsapp?hub.mode=subscribe&hub.verify_token=test&hub.challenge=test123"
```

### Test 2: Flujo completo paso a paso
```bash
# 1. Saludo
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"+573001234567","type":"text","text":{"body":"Hola"}}]}}]}]}'

# 2. Celular
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"+573001234567","type":"text","text":{"body":"3001234567"}}]}}]}]}'

# 3. Nombre
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"+573001234567","type":"text","text":{"body":"Juan Pérez"}}]}}]}]}'

# 4. Email
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"+573001234567","type":"text","text":{"body":"juan@test.com"}}]}}]}]}'

# 5. Confirmación
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"+573001234567","type":"text","text":{"body":"Sí"}}]}}]}]}'
```

---

## 📊 Checklist Post-Activación

Una vez que el workflow v2-corrected esté activo:

- [ ] Webhook responde (no 404)
- [ ] Test mensaje inicial funciona
- [ ] Validación de celular funciona
- [ ] Captura de nombre funciona
- [ ] Captura de email funciona
- [ ] Confirmación funciona
- [ ] NO hay errores "Bad request"
- [ ] Ejecuciones aparecen en "Executions" sin errores
- [ ] Estados se guardan en sesión

---

## 🎯 Diferencias Clave: v1 vs v2-corrected

| Aspecto | v1 (Actual) | v2-corrected (Requerido) |
|---------|-------------|--------------------------|
| **Search Participant** | POST, api_key hardcoded | GET, env var, campo state |
| **Register Participant** | Nodo vacío | POST completo configurado |
| **Upload Ticket** | Nodo vacío | Multipart/form-data |
| **Process Invoice** | Nodo vacío | GPT-4o + prompt completo |
| **Register Purchase** | Nodo vacío | POST con productos |
| **Accept Entry** | Nodo vacío | POST con entry_id |
| **Image Size Validator** | No existe | Nuevo nodo (10MB) |
| **Retry Limit** | No implementado | MAX_RETRIES=3 |
| **Manejo duplicados** | No implementado | Sha1 + ref manejados |
| **Tests pasados** | 1/11 (9%) | 11/11 (100%) |

---

## 💡 ¿Por qué v1 está activo?

El comando `n8n import:workflow` importa el workflow pero **no lo activa automáticamente** ni reemplaza workflows existentes con el mismo nombre. 

Cuando hay múltiples workflows con nombres similares, n8n usa el que fue activado manualmente primero.

---

## ✅ Próximos Pasos

1. **CRÍTICO**: Cambiar de v1 a v2-corrected (ver sección "Solución Requerida")
2. Ejecutar tests de verificación
3. Validar flujo completo
4. Corregir errores encontrados (si los hay)
5. Documentar resultados finales

---

**Estado**: ⚠️ **BLOQUEADO** hasta que se active el workflow v2-corrected

**ETA**: 5-10 minutos para cambiar workflow + 15 minutos de testing exhaustivo

---

**Última actualización**: 25 de junio de 2026, 00:16
