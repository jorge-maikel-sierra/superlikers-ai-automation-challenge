# Workflow Blueprint — n8n Chatbot WhatsApp

## Visión General

Blueprint completo del workflow de n8n para el chatbot de WhatsApp de Superlikers. Define el flujo principal, los subflujos, las dependencias entre componentes, y las entradas/salidas de cada etapa.

## Arquitectura del Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        WHATSAPP CLOUD API                           │
│  (Webhook configurado en Meta → POST a n8n)                        │
└───────────────────────────┬─────────────────────────────────────────┘
                            │ Mensaje entrante (texto / imagen)
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     WEBHOOK RECEIVER                                │
│  • Valida token de verificación (GET)                              │
│  • Recibe payload (POST)                                           │
│  • Extrae: phone, message_type, message_body, media_id            │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     SESSION MANAGER                                 │
│  • Busca sesión existente por phone                                │
│  • Crea sesión nueva si no existe                                 │
│  • Actualiza `updated_at`                                          │
│  • Resetea `retry_count` si cambió de estado                      │
└───────────────────────────┬─────────────────────────────────────────┘
                            │ session object
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     STATE ROUTER                                    │
│  • Lee session.state                                               │
│  • Clasifica tipo de mensaje (texto vs imagen)                    │
│  • Enruta al subflujo correspondiente                             │
└──┬──────────┬──────────┬──────────┬──────────┬─────────────────────┘
   │          │          │          │          │
   ▼          ▼          ▼          ▼          ▼
 Flujo     Flujo      Flujo      Flujo      Flujo
 Inicio    Búsqueda  Registro   Ticket     Error
           Participante         &
                                Compra

## Flujo Principal

### Trigger
Webhook POST desde WhatsApp Cloud API cuando un usuario envía un mensaje al número del negocio.

### Input
```json
{
  "object": "whatsapp_business_account",
  "entry": [{
    "changes": [{
      "value": {
        "messaging_product": "whatsapp",
        "metadata": { "phone_number_id": "123456" },
        "contacts": [{ "wa_id": "521234567890" }],
        "messages": [{
          "from": "521234567890",
          "id": "wamid.abc123",
          "timestamp": "1687680000",
          "type": "text",
          "text": { "body": "Hola" }
        }]
      }
    }]
  }]
}
```

### Output Final
```json
{
  "to": "521234567890",
  "type": "text",
  "text": { "body": "¡Gracias por participar! Has obtenido 150 puntos." }
}
```

## Subflujos

### 1. Subflujo de Inicio (START → WAIT_PHONE)

| Aspecto | Detalle |
|---------|---------|
| **Entrada** | Mensaje inicial del usuario (cualquier texto) |
| **Propósito** | Dar la bienvenida y solicitar el número de celular |
| **Salida** | Mensaje de bienvenida + estado WAIT_PHONE |
| **Dependencia** | Session Manager |

```
START
  │
  ▼
¿Primer mensaje? ──Sí──► Enviar saludo + pedir celular
  │                        │
  No                       ▼
  │                   session.state = WAIT_PHONE
  ▼
Pasar a State Router
```

### 2. Subflujo de Búsqueda (WAIT_PHONE → SEARCH_PARTICIPANT)

| Aspecto | Detalle |
|---------|---------|
| **Entrada** | Número de teléfono (texto) |
| **Validación** | Solo dígitos, 10-15 caracteres, formato:+52 |
| **Propósito** | Buscar participante en Superlikers API |
| **Salida** | Participante encontrado → WAIT_TICKET / No encontrado → WAIT_NAME |

```
WAIT_PHONE
  │
  ▼
¿Teléfono válido? ──No──► Pedir nuevamente + incrementar retry
  │
  Sí
  ▼
GET /participants/search?phone={phone}
  │
  ├── 200 (encontrado) → informar datos → WAIT_TICKET
  ├── 404 (no existe)  → solicitar nombre → WAIT_NAME
  └── error            → ERROR
```

### 3. Subflujo de Registro (WAIT_NAME → REGISTER_PARTICIPANT)

| Aspecto | Detalle |
|---------|---------|
| **Entrada** | Nombre → Email → Confirmación |
| **Validaciones** | Nombre: 3+ caracteres, solo letras. Email: regex. Confirmación: sí/no |
| **Propósito** | Registrar nuevo participante en Superlikers API |
| **Salida** | Participante creado → WAIT_TICKET |

```
WAIT_NAME ──► WAIT_EMAIL ──► WAIT_CONFIRMATION ──► REGISTER_PARTICIPANT
                                                          │
                                                     POST /participants
                                                          │
                                          ┌───────────────┴────────┐
                                          ▼                       ▼
                                    201 (creado)              ERROR
                                          │
                                          ▼
                                     WAIT_TICKET
```

### 4. Subflujo de Ticket y Compra (WAIT_TICKET → ACCEPT_ENTRY)

| Aspecto | Detalle |
|---------|---------|
| **Entrada** | Imagen JPEG/PNG (máx 10MB) |
| **Propósito** | Subir ticket, procesar con IA, registrar compra, aceptar entry |
| **Dependencias** | Superlikers API (upload, purchase, entry), OpenAI Vision |

```
WAIT_TICKET
  │
  ▼
¿Es imagen? ──No──► Re-pedir ticket
  │
  Sí
  ▼
POST /tickets/upload (multipart)
  │
  ├── 200 → photo_id obtenido → PROCESS_INVOICE
  └── error → ERROR
              │
              ▼
       OpenAI Vision API (extraer: monto, fecha, comercio, items)
              │
    ┌─────────┴────────────┐
    │                       │
  Datos válidos         Baja confianza
    │                       │
    ▼                       ▼
POST /purchases        WAIT_TICKET (re-intentar)
    │
  ┌─┴──────────────┐
  │                 │
201              ERROR
  │                 │
  ▼                 ▼
PUT /entries     ERROR
(approve)
  │
  ├── 200 → puntos calculados → FINISHED
  └── error → ERROR
```

### 5. Subflujo de Error (ERROR → recuperación)

| Aspecto | Detalle |
|---------|---------|
| **Entrada** | Cualquier fallo en el flujo |
| **Propósito** | Manejar errores gracefully, ofrecer reintento |
| **Salida** | Estado anterior (reintento) o FINISHED (abandono) |

```
ERROR
  │
  ▼
Clasificar error:
  ├── Usuario (formato inválido) → pedir corrección + mantener estado
  ├── API (timeout/5xx) → reintentar hasta 3 veces + backoff
  ├── IA (baja confianza) → pedir nueva foto
  └── Infraestructura → mensaje genérico + escalar
```

## Dependencias entre Subflujos

```
Inicio ──► Búsqueda ──► Registro ──► Ticket ──► Compra ──► Aprobación ──► Fin
                │                                                          
                └── (si existe) ──► Ticket (salta Registro)               
                                                                            
Cualquier subflujo puede transicionar a ERROR                              
ERROR puede reintentar al estado anterior o finalizar                      
```

## Matriz de Dependencias de Datos

| Subflujo | Datos Requeridos | Datos Producidos |
|----------|-----------------|------------------|
| Inicio | — | phone, state |
| Búsqueda | phone | participant_id, name, email (o null) |
| Registro | phone, name, email | participant_id |
| Ticket | participant_id | photo_id |
| Compra | participant_id, photo_id | invoice_data, purchase_id |
| Aprobación | participant_id, purchase_id | points |
| Error | error_type, previous_state | retry_count, state |

## Resumen Visual del Pipeline

```
WhatsApp ──► Webhook ──► Session ──► State ──► Subflujo ──► WhatsApp
   │                    Mgr         Router      │
   │                                             │
   └─────────────────── API calls ───────────────┘
                        │
                   Superlikers / OpenAI
```

## Consideraciones de Diseño

1. **Idempotencia**: Cada subflujo debe ser re-ejecutable sin efectos secundarios.
2. **Timeout**: La sesión expira después de 30 minutos de inactividad.
3. **Concurrencia**: Un usuario solo puede tener una sesión activa.
4. **Backoff**: Reintentos con backoff exponencial (1s, 2s, 4s, máximo 3 intentos).
5. **Rollback**: Si un subflujo falla después de escribir datos, se registra el error pero no se deshace automáticamente.
