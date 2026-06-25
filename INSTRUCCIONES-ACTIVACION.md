# 📋 Instrucciones de Activación y Prueba del Workflow

## ⚠️ IMPORTANTE

El workflow ha sido **importado exitosamente** a n8n pero requiere **activación manual** desde la interfaz web para que el webhook funcione.

---

## 🚀 Paso 1: Acceder a n8n

1. Abrir navegador en: **http://localhost:5678**
2. Iniciar sesión (si es necesario)

---

## 📝 Paso 2: Localizar el Workflow

1. En el menú lateral izquierdo, click en **"Workflows"**
2. Buscar: **"Participant Onboarding v1"**
3. Click en el workflow para abrirlo

---

## 🔐 Paso 3: Configurar Credenciales

### 3.1 Credencial de OpenAI

1. Click en cualquier nodo **"Process Invoice"** (color morado/púrpura)
2. En el panel derecho, buscar **"Credential to connect with"**
3. Si dice "Create New":
   - Click en "Create New"
   - Nombre: **"OpenAI"**
   - API Key: Copiar de `docker/.env` la variable `OPENAI_API_KEY`
   - Click "Save"
4. Si ya existe, seleccionar la credencial existente

### 3.2 Credencial de Superlikers API

1. Click en cualquier nodo HTTP Request de Superlikers (ej: **"Search Participant"**, "Register Participant", etc.)
2. En "Authentication" → "Header Auth"
3. Si dice "Create New":
   - Click en "Create New"  
   - Nombre: **"Superlikers API"**
   - Header Name: **"Authorization"**
   - Header Value: **"Bearer TU_API_KEY_AQUI"** (reemplazar con el valor de `SUPERLIKERS_API_KEY` de `docker/.env`)
   - Click "Save"
4. Si ya existe, seleccionar la credencial existente

**Nodos que usan esta credencial**:
- Search Participant
- Register Participant
- Upload Ticket API
- Register Purchase
- Accept Entry

---

## ✅ Paso 4: Activar el Workflow

1. En la esquina superior derecha, buscar el **toggle "Active"**
2. **Click para activarlo** (debe ponerse en verde/azul)
3. Esperar confirmación: "Workflow activated"

---

## 🔗 Paso 5: Obtener URL del Webhook

1. Click en el nodo **"WhatsApp Webhook"** (primer nodo del workflow)
2. En el panel derecho, buscar **"Webhook URLs"**
3. Copiar la **Production URL**: 
   ```
   http://localhost:5678/webhook/whatsapp
   ```
4. Si usas ngrok o túnel, la URL será:
   ```
   https://tu-dominio.ngrok-free.app/webhook/whatsapp
   ```

---

## 🧪 Paso 6: Probar el Webhook (Verificación)

### Test de Verificación de WhatsApp

```bash
curl -X GET "http://localhost:5678/webhook/whatsapp?hub.mode=subscribe&hub.verify_token=test&hub.challenge=challenge123"
```

**Respuesta esperada**:
```json
{
  "isVerification": true,
  "verified": false,
  "challenge": "Verification failed - token mismatch"
}
```

Si obtienes esto, el webhook está funcionando ✅

### Test de Mensaje Simple

```bash
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{
    "entry": [{
      "changes": [{
        "value": {
          "messages": [{
            "from": "+573001234567",
            "type": "text",
            "text": {"body": "Hola"}
          }],
          "contacts": [{
            "profile": {"name": "Test User"}
          }]
        }
      }]
    }]
  }'
```

**Respuesta esperada**: 200 OK

---

## 📊 Paso 7: Verificar Ejecución

1. En n8n, ir a **"Executions"** (menú lateral)
2. Deberías ver la ejecución del webhook
3. Click en la ejecución para ver el detalle
4. Verificar que:
   - ✅ "Message Parser" procesó el mensaje
   - ✅ "State Router" identificó el estado
   - ✅ Flujo continuó correctamente

---

## 🔍 Paso 8: Pruebas Exhaustivas

### Caso 1: Usuario Nuevo — Flujo Completo

Ejecutar el script de simulación:

```bash
cd /Users/jorgesierra/Documents/dev/superlikers-ai-automation-challenge
./tests/simulate-flow.sh
```

O manualmente:

```bash
# 1. Saludo inicial
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"+573001234567","type":"text","text":{"body":"Hola"}}]}}]}]}'

# 2. Enviar celular
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"+573001234567","type":"text","text":{"body":"3001234567"}}]}}]}]}'

# 3. Enviar nombre
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"+573001234567","type":"text","text":{"body":"Juan Pérez"}}]}}]}]}'

# 4. Enviar email
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"+573001234567","type":"text","text":{"body":"juan@test.com"}}]}}]}]}'

# 5. Confirmar
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"+573001234567","type":"text","text":{"body":"Sí"}}]}}]}]}'
```

**Verificar en Executions**:
- ✅ Todos los pasos se ejecutan
- ✅ Sesión se mantiene entre mensajes
- ✅ Estados cambian correctamente

---

## ⚠️ Problemas Comunes

### Problema: "Webhook not registered"

**Solución**: El workflow NO está activo. Activar desde la UI (paso 4).

### Problema: "Credential missing"

**Solución**: Configurar credenciales de OpenAI y Superlikers (paso 3).

### Problema: Ejecución falla en nodo HTTP

**Solución**:
1. Verificar que `docker/.env` tiene las API keys correctas
2. Verificar que las credenciales en n8n usan las variables de entorno
3. Revisar logs: 
   ```bash
   docker exec superlikers-n8n cat /home/node/.n8n/n8nEventLog.log | tail -50
   ```

### Problema: No se guardan sesiones

**Solución**:
1. Verificar que el nodo "Save Session" está conectado
2. Verificar que DataTable está configurado
3. Revisar ejecuciones para ver errores

---

## 📈 Métricas de Éxito

Después de las pruebas, deberías tener:

- ✅ Al menos 5 ejecuciones exitosas en "Executions"
- ✅ 0 errores en nodos HTTP Request
- ✅ Sesiones guardadas en DataTable
- ✅ Estados transicionando correctamente
- ✅ Validaciones funcionando (Phone, Name, Email)

---

## 🎯 Siguiente Paso: Integración con WhatsApp Real

Una vez que las pruebas locales funcionen:

1. **Exponer n8n con ngrok**:
   ```bash
   ngrok http 5678
   ```

2. **Actualizar docker-compose.yml**:
   ```yaml
   - WEBHOOK_URL=https://tu-id.ngrok-free.app
   ```

3. **Reiniciar n8n**:
   ```bash
   docker compose -f docker/docker-compose.yml restart n8n
   ```

4. **Configurar webhook en WhatsApp Business API**:
   - URL: `https://tu-id.ngrok-free.app/webhook/whatsapp`
   - Verify Token: El configurado en `.env`

---

## ✅ Checklist de Validación

Antes de considerar completo:

- [ ] Workflow importado
- [ ] Workflow activo (toggle verde)
- [ ] Credencial OpenAI configurada
- [ ] Credencial Superlikers configurada
- [ ] Webhook responde a GET (verificación)
- [ ] Webhook responde a POST (mensajes)
- [ ] Test 1: Saludo inicial funciona
- [ ] Test 2: Validación de celular funciona
- [ ] Test 3: Captura de nombre funciona
- [ ] Test 4: Captura de email funciona
- [ ] Test 5: Confirmación funciona
- [ ] Estados se guardan correctamente
- [ ] No hay errores en logs

---

**Última actualización**: 24 de junio de 2026  
**Estado**: Workflow importado, requiere activación manual
