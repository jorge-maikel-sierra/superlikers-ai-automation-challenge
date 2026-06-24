# Diseño de Integraciones — WhatsApp, Superlikers, IA

## Visión General

Diagrama completo de todas las integraciones externas del sistema, incluyendo endpoints, autenticación, contratos y manejo de errores.

---

## 1. WhatsApp Business API (Meta Cloud API)

### Propósito
Canal de comunicación con el usuario. Recibe mensajes entrantes (webhook) y envía respuestas.

### Eventos Soportados

| Evento | Tipo | Descripción |
|--------|------|-------------|
| Mensaje de texto | `text` | Consultas, números, nombres, emails |
| Mensaje de imagen | `image` | Foto del ticket de compra |
| Delivery receipt | `status` | Confirmación de entrega (ignorar) |

### Autenticación

| Aspecto | Detalle |
|---------|---------|
| **Webhook Verification** | Token configurado en Meta Developer Console |
| **API Calls** | `Bearer Token` en Header (WhatsApp Permanent Token) |
| **Phone Number ID** | ID del número de teléfono asignado en Meta |

### Endpoints

#### Recibir Mensaje (Webhook)
```
GET /webhook/whatsapp?hub.mode=subscribe&hub.verify_token={TOKEN}&hub.challenge={CHALLENGE}
  → Responde con hub.challenge (verificación)

POST /webhook/whatsapp
  → Cuerpo: payload de WhatsApp Cloud API
  → Responde: 200 OK (siempre, para evitar reenvíos)
```

#### Enviar Mensaje
```
POST https://graph.facebook.com/v21.0/{PHONE_NUMBER_ID}/messages
Authorization: Bearer {WHATSAPP_TOKEN}
Content-Type: application/json

{
  "messaging_product": "whatsapp",
  "to": "{USER_PHONE}",
  "type": "text|image|template",
  "text": { "body": "mensaje" },
  "image": { "link": "url_de_imagen" }  // si type=image
}
```

### Manejo de Errores

| Código | Significado | Acción |
|--------|-------------|--------|
| 400 | Payload inválido | Revisar formato del mensaje |
| 401 | Token inválido/expirado | Renovar token en Meta Console |
| 404 | Phone number ID inválido | Verificar configuración |
| 429 | Rate limit excedido | Backoff y reintentar |
| 470 | Número no opt-in | No enviar más mensajes |

### Rate Limits

| Límite | Valor |
|--------|-------|
| Mensajes por segundo | 80 (por número de teléfono) |
| Mensajes por día | 250,000 (por negocio) |
| Templates por segundo | 10 |

---

## 2. Superlikers API

### Propósito
API REST para gestionar participantes, tickets, compras y actividades.

### Configuración General

| Variable | Valor |
|----------|-------|
| **Base URL** | `{{SUPERLIKERS_BASE_URL}}` (default: `https://api.superlikerslabs.com/v1`) |
| **API Key** | `{{SUPERLIKERS_API_KEY}}` (header `X-API-Key`) |
| **Campaña** | `{{SUPERLIKERS_CAMPAIGN}}` (default: `3z`) |
| **Timeout** | 10 segundos |
| **Retry** | 3 intentos con backoff exponencial |

### Endpoints

#### 2.1 Buscar Participante

```
GET /campaigns/{campaign}/participants/search?phone={phone}
```

| Aspecto | Detalle |
|---------|---------|
| **Propósito** | Verificar si el participante ya existe |
| **Input** | `phone` (formato E.164) |
| **Output 200** | `{ id, phone, name, email, status }` |
| **Output 404** | `{ error: "participant_not_found" }` |
| **Cache** | No cache (los datos cambian poco, pero es más seguro consultar siempre) |

#### 2.2 Crear Participante

```
POST /campaigns/{campaign}/participants
Content-Type: application/json
```

| Campo | Tipo | Requerido | Ejemplo |
|-------|------|-----------|---------|
| `phone` | string | Sí | `+521234567890` |
| `name` | string | Sí | `Juan Pérez` |
| `email` | string | Sí | `juan@example.com` |

**Output 201**: `{ id, phone, name, email, created_at }`

#### 2.3 Subir Ticket

```
POST /campaigns/{campaign}/tickets/upload
Content-Type: multipart/form-data
```

| Campo | Tipo | Requerido |
|-------|------|-----------|
| `image` | file (JPEG/PNG) | Sí |

**Output 200**: `{ photo_id, url, size_bytes, mime_type }`

#### 2.4 Registrar Compra

```
POST /campaigns/{campaign}/purchases
Content-Type: application/json
```

**Input**:
```json
{
  "participant_id": "string",
  "photo_id": "string",
  "invoice_data": {
    "amount": 1500.50,
    "currency": "MXN",
    "date": "2026-06-24",
    "merchant_name": "Soriana",
    "items": [
      { "name": "Producto X", "quantity": 2, "price": 750.25 }
    ],
    "total": 1500.50
  }
}
```

**Output 201**: `{ purchase_id, amount, points_earned, status }`

#### 2.5 Aceptar Entry

```
PUT /campaigns/{campaign}/activities/{activity_id}/entries
Content-Type: application/json
```

**Input**:
```json
{
  "participant_id": "string",
  "purchase_id": "string",
  "action": "approve"
}
```

**Output 200**: `{ entry_id, status, points_awarded, total_points }`

### Estrategia de Retry

```javascript
async function callWithRetry(url, options, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const response = await fetch(url, options);
      if (response.ok) return response;
      if (response.status === 429) {
        // Rate limit: esperar y reintentar
        await delay(1000 * Math.pow(2, attempt));
        continue;
      }
      if (response.status >= 500) {
        // Error servidor: reintentar con backoff
        await delay(1000 * Math.pow(2, attempt));
        continue;
      }
      // Error cliente (400, 401, 404): no reintentar
      return response;
    } catch (error) {
      // Network error: reintentar
      if (attempt === maxRetries) throw error;
      await delay(1000 * Math.pow(2, attempt));
    }
  }
}
```

---

## 3. OpenAI Vision API

### Propósito
Extracción de datos estructurados de imágenes de facturas/tickets de compra.

### Configuración

| Parámetro | Valor |
|-----------|-------|
| **Modelo** | `gpt-4o` (recomendado) o `gpt-4o-mini` (más económico) |
| **Max Tokens** | 1000 |
| **Temperature** | 0.1 (mínima creatividad) |
| **Timeout** | 30 segundos |
| **Cost Estimate** | ~$0.01 por factura (gpt-4o-mini: ~$0.001) |

### System Prompt

```
Eres un extractor de datos de facturas y tickets de compra en México.
Tu tarea es analizar la imagen y devolver un JSON válido con los datos extraídos.

Reglas:
- amount: monto total de la factura (número)
- currency: siempre "MXN"
- date: fecha en formato YYYY-MM-DD
- merchant_name: nombre del comercio o establecimiento
- items: array de productos con name, quantity, price
- total: suma calculada de items (debe coincidir con amount)
- confidence: nivel de confianza del 0 al 1

Si no puedes leer algún campo, devuelve null en ese campo.
Si la calidad de la imagen es muy baja, devuelve confidence < 0.3.
```

### Formato de Imagen

| Aspecto | Requisito |
|---------|-----------|
| **Formato** | JPEG, PNG |
| **Tamaño máximo** | 20MB (límite de OpenAI) |
| **Resolución mínima** | 500x500 px (enforcement de Superlikers) |
| **Codificación** | Base64 o URL pública |

### Validación de Respuesta

```javascript
function validateInvoiceData(data) {
  const errors = [];
  if (!data.amount || typeof data.amount !== 'number') errors.push('amount');
  if (!data.date || !/^\d{4}-\d{2}-\d{2}$/.test(data.date)) errors.push('date');
  if (!data.merchant_name || data.merchant_name.length < 2) errors.push('merchant_name');
  if (!data.total || typeof data.total !== 'number') errors.push('total');
  if (data.confidence < 0.7) errors.push('low_confidence');

  return {
    valid: errors.length === 0,
    errors: errors
  };
}
```

### Estrategia de Fallback

| Situación | Acción |
|-----------|--------|
| Timeout (30s) | Reintentar 1 vez con timeout de 45s |
| Error de API | Reintentar 1 vez después de 2s |
| JSON inválido | Reintentar con prompt más estricto |
| Confianza < 0.3 | Pedir nueva foto |
| Confianza 0.3-0.7 | Mostrar datos extraídos, pedir confirmación al usuario |
| Confianza >= 0.7 | Automático, continuar flujo |

---

## 4. Matriz de Integraciones

| Integración | Dirección | Protocolo | Autenticación | Latencia Esperada |
|-------------|-----------|-----------|---------------|-------------------|
| WhatsApp Webhook (in) | Meta → n8n | HTTPS POST | Token Query Param | < 1s |
| WhatsApp Send (out) | n8n → Meta | HTTPS POST | Bearer Token | 200-500ms |
| Superlikers API | n8n → Superlikers | HTTPS REST | X-API-Key Header | 200-1000ms |
| OpenAI Vision | n8n → OpenAI | HTTPS REST | Bearer Token | 3-10s |

## 5. Variables de Entorno Requeridas

```bash
# WhatsApp
WHATSAPP_TOKEN=EAAT...
WHATSAPP_PHONE_NUMBER_ID=123456
WHATSAPP_VERIFY_TOKEN=mi_token_secreto

# Superlikers
SUPERLIKERS_API_KEY=sl_api_key_abc123
SUPERLIKERS_BASE_URL=https://api.superlikerslabs.com/v1
SUPERLIKERS_CAMPAIGN=3z

# AI
OPENAI_API_KEY=sk-proj-abc123
AI_MODEL=gpt-4o
```
