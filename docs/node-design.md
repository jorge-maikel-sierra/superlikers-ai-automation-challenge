# Diseño de Nodos — n8n WhatsApp Chatbot

## Resumen

Definición completa de cada nodo del workflow de n8n. Cada nodo se describe con su tipo, responsabilidad, entradas, salidas y manejo de errores.

---

## 1. Webhook Receiver

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Webhook Node |
| **Propósito** | Recibir mensajes de WhatsApp Cloud API |
| **Método** | GET (verificación) + POST (mensajes) |
| **Path** | `/webhook/whatsapp` |

### Input (POST)
```json
{
  "entry[0].changes[0].value.messages[0]": {
    "from": "string",
    "id": "string",
    "timestamp": "string",
    "type": "text|image",
    "text.body": "string (si text)",
    "image.id": "string (si image)"
  }
}
```

### Output
```json
{
  "phone": "521234567890",
  "message_type": "text",
  "message_body": "Hola",
  "media_id": "",
  "timestamp": "1687680000",
  "message_id": "wamid.abc123"
}
```

### Errores
| Código | Causa | Acción |
|--------|-------|--------|
| 403 | Token inválido | No responder |
| 400 | Payload malformado | Log + ignorar |

---

## 2. Message Parser

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Code Node (JavaScript) |
| **Propósito** | Normalizar el payload de WhatsApp a un formato estándar |

### Input
Payload crudo del Webhook Node.

### Output
```json
{
  "phone": "521234567890",
  "message_type": "text",
  "message_body": "Hola",
  "media_id": "",
  "is_media": false,
  "timestamp": 1687680000
}
```

### Lógica
```javascript
// Pseudocódigo
const message = $input.body.entry[0].changes[0].value.messages[0];
return {
  phone: message.from,
  message_type: message.type,
  message_body: message.type === 'text' ? message.text.body : '',
  media_id: message.type === 'image' ? message.image.id : '',
  is_media: message.type === 'image',
  timestamp: parseInt(message.timestamp)
};
```

### Errores
| Situación | Acción |
|-----------|--------|
| Mensaje vacío | Descartar (no responder) |
| Tipo desconocido | Log + responder "no entendí" |

---

## 3. Session Manager

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Code Node (JavaScript) |
| **Propósito** | Gestionar el ciclo de vida de la sesión del usuario |

### Input
`phone`, `message_type`, `message_body`

### Output
```json
{
  "phone": "521234567890",
  "session": { ... } // Objeto de sesión completo
}
```

### Lógica
```javascript
const phone = $input.body.phone;
const sessionKey = `session:${phone}`;

// Intentar recuperar sesión existente
let session = getSession(sessionKey); // Desde Data Store o JSON

if (!session) {
  // Crear nueva sesión
  session = {
    phone: phone,
    state: 'START',
    name: '',
    email: '',
    participant_id: '',
    photo_id: '',
    purchase_id: '',
    invoice_data: {},
    points: 0,
    retry_count: 0,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  };
}

// Actualizar timestamp
session.updated_at = new Date().toISOString();
saveSession(sessionKey, session);
```

### Errores
| Situación | Acción |
|-----------|--------|
| Data Store no disponible | Crear sesión en memoria (volátil) |
| Sesión corrupta | Resetear a START |

---

## 4. State Router

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Switch Node + Code Node |
| **Propósito** | Determinar el siguiente paso basado en el estado actual y el tipo de mensaje |

### Input
`session.state`, `message_type`, `message_body`, `is_media`

### Lógica de Ruteo
```
state: START          → Enviar saludo → state = WAIT_PHONE
state: WAIT_PHONE     → Validar teléfono → Search Participant
state: WAIT_NAME      → Validar nombre → state = WAIT_EMAIL
state: WAIT_EMAIL     → Validar email → state = WAIT_CONFIRMATION
state: WAIT_CONFIRM   → Validar sí/no → Register o reset
state: WAIT_TICKET    → Validar imagen → Upload Ticket
state: REGISTER_PART  → Llamar API → state = WAIT_TICKET | ERROR
state: UPLOAD_TICKET  → Llamar API → Process Invoice
state: PROCESS_INV    → Llamar AI → Register Purchase
state: REGISTER_PUR   → Llamar API → Accept Entry
state: ACCEPT_ENTRY   → Llamar API → FINISHED
state: ERROR          → Manejar error → estado anterior | FINISHED
```

### Output
```json
{
  "routed_action": "search_participant",
  "session": { ... },
  "next_state": "SEARCH_PARTICIPANT"
}
```

### Errores
| Situación | Acción |
|-----------|--------|
| Estado desconocido | Resetear a START |
| Estado + tipo mensaje incompatible | ERROR |

---

## 5. Phone Validator

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Code Node |
| **Propósito** | Validar formato de número telefónico |

### Input
`message_body` (raw text from user)

### Validación
```javascript
const phone = $input.body.message_body.replace(/[^0-9]/g, '');
const isValid = phone.length >= 10 && phone.length <= 15;

if (isValid) {
  // Normalizar: si empieza con 52, agregar +
  const normalized = phone.startsWith('52') ? `+${phone}` : `+52${phone}`;
  return { valid: true, phone: normalized };
} else {
  return { valid: false, error: 'invalid_format' };
}
```

### Output
```json
{
  "valid": true,
  "phone": "+521234567890"
}
```

### Errores
| Situación | Acción |
|-----------|--------|
| Formato inválido | Responder "Ingresa un número válido de 10 dígitos" |
| Número muy corto | Pedir número completo con código de área |

---

## 6. Search Participant (HTTP Request)

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | HTTP Request Node |
| **Propósito** | Buscar participante en Superlikers API |

### Configuración
| Parámetro | Valor |
|-----------|-------|
| **Method** | GET |
| **URL** | `{{SUPERLIKERS_BASE_URL}}/campaigns/{{SUPERLIKERS_CAMPAIGN}}/participants/search?phone={{phone}}` |
| **Headers** | `X-API-Key: {{SUPERLIKERS_API_KEY}}` |
| **Retry** | 3 intentos, backoff exponencial |

### Output
```json
// Encontrado (200)
{
  "found": true,
  "participant": {
    "id": "string",
    "phone": "string",
    "name": "string",
    "email": "string"
  }
}

// No encontrado (404)
{
  "found": false,
  "participant": null
}
```

### Errores
| Código | Acción |
|--------|--------|
| 400 | ERROR: datos inválidos |
| 401 | ERROR: config API Key |
| 404 | Continúa a registro |
| 429 | Esperar + reintentar |
| 5xx | Reintentar hasta 3 veces |

---

## 7. Name Validator

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Code Node |
| **Propósito** | Validar nombre completo del participante |

### Validación
```javascript
const name = $input.body.message_body.trim();
const isValid = name.length >= 3 && /^[a-zA-ZáéíóúñÁÉÍÓÚÑ\s]+$/.test(name);

return {
  valid: isValid,
  name: name,
  error: isValid ? null : 'invalid_name'
};
```

### Output
```json
{
  "valid": true,
  "name": "Juan Pérez"
}
```

---

## 8. Email Validator

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Code Node |
| **Propósito** | Validar formato de email |

### Validación
```javascript
const email = $input.body.message_body.trim().toLowerCase();
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const isValid = emailRegex.test(email);

return {
  valid: isValid,
  email: email,
  error: isValid ? null : 'invalid_email'
};
```

---

## 9. Confirmation Router

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Switch Node |
| **Propósito** | Interpretar respuesta de confirmación |

### Lógica
```javascript
const input = $input.body.message_body.toLowerCase().trim();
const positive = ['sí', 'si', 'yes', 'dale', 'ok', 'confirmo'];
const negative = ['no', 'nop', 'cancelar', 'cancel'];

if (positive.includes(input)) return 'confirmed';
if (negative.includes(input)) return 'cancelled';
return 'invalid';
```

---

## 10. Register Participant (HTTP Request)

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | HTTP Request Node |
| **Propósito** | Crear nuevo participante en Superlikers API |

### Configuración
| Parámetro | Valor |
|-----------|-------|
| **Method** | POST |
| **URL** | `{{SUPERLIKERS_BASE_URL}}/campaigns/{{SUPERLIKERS_CAMPAIGN}}/participants` |
| **Headers** | `X-API-Key: {{SUPERLIKERS_API_KEY}}` |

### Body
```json
{
  "phone": "+521234567890",
  "name": "Juan Pérez",
  "email": "juan@example.com"
}
```

### Output (201)
```json
{
  "success": true,
  "participant_id": "part_abc123"
}
```

---

## 11. Upload Ticket (HTTP Request)

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | HTTP Request Node |
| **Propósito** | Subir imagen del ticket a Superlikers API |

### Configuración
| Parámetro | Valor |
|-----------|-------|
| **Method** | POST |
| **URL** | `{{SUPERLIKERS_BASE_URL}}/campaigns/{{SUPERLIKERS_CAMPAIGN}}/tickets/upload` |
| **Content-Type** | `multipart/form-data` |

### Body
Form-data con campo `image` (binario de la imagen descargada de WhatsApp)

### Output (200)
```json
{
  "success": true,
  "photo_id": "photo_xyz789",
  "url": "https://...",
  "size_bytes": 123456
}
```

---

## 12. Download WhatsApp Media

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | HTTP Request Node |
| **Propósito** | Descargar imagen de WhatsApp usando media_id |

### Configuración
| Parámetro | Valor |
|-----------|-------|
| **Method** | GET |
| **URL** | `https://graph.facebook.com/v17.0/{{media_id}}` |
| **Headers** | `Authorization: Bearer {{WHATSAPP_TOKEN}}` |

---

## 13. Process Invoice (AI Node — OpenAI / Claude)

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | HTTP Request Node (a OpenAI API) |
| **Propósito** | Extraer datos estructurados de la factura |

### Configuración
| Parámetro | Valor |
|-----------|-------|
| **Method** | POST |
| **URL** | `https://api.openai.com/v1/chat/completions` |
| **Headers** | `Authorization: Bearer {{OPENAI_API_KEY}}` |

### Body
```json
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "system",
      "content": "Eres un extractor de datos de facturas. Devuelve SOLO JSON válido."
    },
    {
      "role": "user",
      "content": [
        { "type": "text", "text": "Extrae los siguientes datos de esta factura en formato JSON: amount (número), currency (string), date (YYYY-MM-DD), merchant_name (string), items (array de {name, quantity, price}), total (número)" },
        { "type": "image_url", "image_url": { "url": "data:image/jpeg;base64,..." } }
      ]
    }
  ],
  "response_format": { "type": "json_object" },
  "temperature": 0.1,
  "max_tokens": 1000
}
```

### Output
```json
{
  "success": true,
  "confidence": 0.95,
  "invoice_data": {
    "amount": 1500.50,
    "currency": "MXN",
    "date": "2026-06-24",
    "merchant_name": "Soriana",
    "items": [{"name": "Producto 1", "quantity": 2, "price": 500.00}],
    "total": 1500.50
  }
}
```

### Validación de Confianza
```javascript
// Si confidence < 0.7 → pedir nueva foto
// Si confidence >= 0.7 → continuar a registro de compra
```

### Errores
| Situación | Acción |
|-----------|--------|
| OpenAI timeout | Reintentar 1 vez |
| JSON inválido | Reintentar con prompt más específico |
| Baja confianza | Pedir nueva foto |
| Campos faltantes | Reintentar o pedir datos manualmente |

---

## 14. Register Purchase (HTTP Request)

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | HTTP Request Node |
| **Propósito** | Registrar compra en Superlikers API |

### Configuración
| Parámetro | Valor |
|-----------|-------|
| **Method** | POST |
| **URL** | `{{SUPERLIKERS_BASE_URL}}/campaigns/{{SUPERLIKERS_CAMPAIGN}}/purchases` |

### Body
```json
{
  "participant_id": "part_abc123",
  "photo_id": "photo_xyz789",
  "invoice_data": { ... }
}
```

### Output (201)
```json
{
  "success": true,
  "purchase_id": "pur_456def",
  "points_earned": 150,
  "status": "pending_approval"
}
```

---

## 15. Accept Entry (HTTP Request)

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | HTTP Request Node |
| **Propósito** | Aprobar entrada del participante en la actividad |

### Configuración
| Parámetro | Valor |
|-----------|-------|
| **Method** | PUT |
| **URL** | `{{SUPERLIKERS_BASE_URL}}/campaigns/{{SUPERLIKERS_CAMPAIGN}}/activities/{{activity_id}}/entries` |

### Body
```json
{
  "participant_id": "part_abc123",
  "purchase_id": "pur_456def",
  "action": "approve"
}
```

### Output (200)
```json
{
  "success": true,
  "entry_id": "entry_789ghi",
  "status": "approved",
  "points_awarded": 150,
  "total_points": 150
}
```

---

## 16. Send WhatsApp Message

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | HTTP Request Node |
| **Propósito** | Enviar mensaje de vuelta al usuario por WhatsApp |

### Configuración
| Parámetro | Valor |
|-----------|-------|
| **Method** | POST |
| **URL** | `https://graph.facebook.com/v17.0/{{phone_number_id}}/messages` |
| **Headers** | `Authorization: Bearer {{WHATSAPP_TOKEN}}` |

### Body
```json
{
  "messaging_product": "whatsapp",
  "to": "521234567890",
  "type": "text",
  "text": { "body": "¡Hola! Bienvenido. Por favor ingresa tu número de celular." }
}
```

---

## 17. Error Handler

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Code Node + Switch |
| **Propósito** | Clasificar y manejar errores del flujo |

### Input
`error_type`, `error_message`, `session`, `retry_count`

### Lógica
```javascript
const error = $input.body;
const retryCount = error.session.retry_count || 0;

if (retryCount >= 3) {
  return {
    action: 'abort',
    message: 'Lo sentimos, no pudimos procesar tu solicitud. Intenta más tarde.'
  };
}

switch (error.error_type) {
  case 'validation':
    return {
      action: 'retry_same_state',
      message: getValidationMessage(error.error_message)
    };
  case 'api':
    return {
      action: 'retry_same_state',
      message: 'Hubo un problema con el servidor. Intenta de nuevo.',
      increment_retry: true
    };
  case 'ai_low_confidence':
    return {
      action: 'go_to_wait_ticket',
      message: 'No pudimos leer bien tu factura. Por favor envía una foto más clara.'
    };
  case 'timeout':
    return {
      action: 'retry_same_state',
      message: 'La conexión tardó demasiado. Intenta de nuevo.',
      increment_retry: true
    };
  default:
    return {
      action: 'reset',
      message: 'Ocurrió un error inesperado. Empecemos de nuevo.'
    };
}
```

### Output
```json
{
  "action": "retry_same_state|abort|go_to_wait_ticket|reset",
  "message": "Texto amigable para el usuario",
  "increment_retry": false
}
```

---

## 18. Message Builder

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Code Node |
| **Propósito** | Construir el payload de respuesta para WhatsApp |

### Input
`message_template`, `data` (datos de sesión para templates dinámicos)

### Lógica
```javascript
// Mapa de templates
const templates = {
  welcome: `¡Bienvenido a Superlikers! 🎉\n\nPara participar, primero necesito tu número de celular.\n\nEj: 5512345678`,
  ask_phone: 'Por favor ingresa tu número de celular a 10 dígitos:',
  invalid_phone: 'El número debe tener entre 10 y 15 dígitos. Intenta de nuevo:',
  found_participant: `¡Hola {{name}}! 👋\n\nYa estás registrado. Envía la foto de tu ticket de compra para participar.`,
  ask_name: 'Perfecto. ¿Cuál es tu nombre completo?',
  ask_email: 'Gracias {{name}}. Ahora ingresa tu correo electrónico:',
  confirm_data: `Confirmá tus datos:\n\nNombre: {{name}}\nEmail: {{email}}\nCelular: {{phone}}\n\n¿Son correctos? (Sí/No)`,
  registered: `¡Registrado exitosamente! ✅\n\nAhora envía la foto de tu ticket de compra.`,
  ask_ticket: 'Por favor envía la foto de tu ticket de compra (formato JPEG o PNG):',
  invalid_ticket: 'No pude procesar esa imagen. Asegúrate de que sea una foto clara del ticket en formato JPEG o PNG.',
  processing: 'Procesando tu ticket... ⏳',
  invoice_ok: `¡Ticket procesado! ✅\n\nMonto: ${{amount}}\nComercio: {{merchant}}\n\nRegistrando tu compra...`,
  points: `¡Felicidades {{name}}! 🎉\n\nHas obtenido {{points}} puntos.\n\nGracias por participar.`,
  error_generic: 'Lo siento, ocurrió un error. Por favor intentá de nuevo.',
  goodbye: 'Gracias por tu participación. ¡Hasta luego! 👋'
};
```

## Resumen de Nodos por Subflujo

| Subflujo | Nodos |
|----------|-------|
| Inicio | Webhook Receiver → Message Parser → Session Manager → Message Builder → Send WhatsApp |
| Búsqueda | Phone Validator → Search Participant (HTTP) → State Router |
| Registro | Name Validator → Email Validator → Confirmation Router → Register Participant (HTTP) |
| Ticket | Download WhatsApp Media → Upload Ticket (HTTP) |
| Compra | Process Invoice (OpenAI) → Register Purchase (HTTP) |
| Aprobación | Accept Entry (HTTP) → Message Builder |
| Error | Error Handler → Message Builder → Send WhatsApp |
