# Estrategia de Logging — n8n WhatsApp Chatbot

## Visión General

Estructura de logging en tres capas: logs operativos (seguimiento de ejecución), logs de negocio (eventos del dominio) y logs de errores (incidencias). Los logs se escriben a archivos JSON en `/data/logs/` y también se envían a stdout de n8n para visualización en `docker logs`.

---

## Arquitectura de Logging

```
┌────────────────────────────────────────────┐
│              n8n Workflow                    │
│                                              │
│  Code Node: Logger                           │
│  ┌─────────────────────────────────────┐    │
│  │ log(level, category, message, data) │    │
│  └──────────┬──────────────────────────┘    │
│             │                               │
│    ┌────────┴────────┐                     │
│    ▼                 ▼                      │
│ stdout (console)  Archivos JSON             │
│ (docker logs)     /data/logs/               │
│                   ├── operations/           │
│                   ├── business/             │
│                   └── errors/              │
└────────────────────────────────────────────┘
```

---

## Formato de Log

```json
{
  "timestamp": "2026-06-24T10:00:00.000Z",
  "level": "INFO",
  "category": "business",
  "component": "session-manager",
  "phone": "+521234567890",
  "message": "Sesión creada exitosamente",
  "data": {
    "session_id": "sess_abc123",
    "state": "START"
  },
  "execution_id": "exec_xyz789"
}
```

### Campos Comunes

| Campo | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| `timestamp` | ISO 8601 | Sí | Momento exacto del evento |
| `level` | string | Sí | `DEBUG`, `INFO`, `WARN`, `ERROR` |
| `category` | string | Sí | `operation`, `business`, `error` |
| `component` | string | Sí | Nombre del nodo o subflujo |
| `phone` | string | No | Número de teléfono del usuario |
| `message` | string | Sí | Descripción legible del evento |
| `data` | object | No | Datos adicionales estructurados |
| `execution_id` | string | Sí | ID de ejecución de n8n |

---

## 1. Logs Operativos

Registran el flujo de ejecución del workflow. Son el equivalente a "trace" o "debug" en sistemas tradicionales.

### Propósito
- Depuración durante desarrollo
- Seguimiento de ejecución en producción
- Reconstrucción de flujo para troubleshooting

### Eventos a Registrar

| Componente | Evento | Nivel |
|------------|--------|-------|
| Webhook Receiver | Mensaje recibido | INFO |
| Webhook Receiver | Verificación GET procesada | DEBUG |
| Message Parser | Payload parseado | DEBUG |
| Session Manager | Sesión creada | INFO |
| Session Manager | Sesión recuperada | DEBUG |
| Session Manager | Sesión expirada | WARN |
| Session Manager | Sesión eliminada | INFO |
| State Router | Ruteo ejecutado | DEBUG |
| State Router | Estado desconocido | WARN |
| Phone Validator | Validación exitosa | DEBUG |
| Phone Validator | Validación fallida | DEBUG |
| HTTP Request | Request enviado | INFO |
| HTTP Request | Response recibido | DEBUG |
| Message Builder | Template renderizado | DEBUG |
| Send WhatsApp | Mensaje enviado | INFO |

### Ejemplo
```json
{
  "timestamp": "2026-06-24T10:00:00.000Z",
  "level": "INFO",
  "category": "operation",
  "component": "webhook-receiver",
  "phone": "+521234567890",
  "message": "Mensaje entrante recibido",
  "data": {
    "message_type": "text",
    "message_length": 25,
    "wa_message_id": "wamid.abc123"
  },
  "execution_id": "exec_xyz789"
}
```

---

## 2. Logs de Negocio

Registran eventos significativos del dominio. Son los logs que interesan al negocio.

### Propósito
- Seguimiento de KPIs
- Reportes de actividad
- Auditoría de transacciones

### Eventos a Registrar

| Evento | Datos Asociados | Nivel |
|--------|----------------|-------|
| Participante encontrado | phone, participant_id, name | INFO |
| Nuevo participante registrado | phone, participant_id, name, email | INFO |
| Ticket subido | phone, photo_id, size | INFO |
| Factura procesada (IA) | phone, amount, merchant, confidence | INFO |
| Compra registrada | phone, purchase_id, points_earned | INFO |
| Entry aprobado | phone, entry_id, points_awarded | INFO |
| Puntos otorgados | phone, total_points | INFO |
| Flujo completado | phone, total_time_seconds | INFO |
| Usuario abandonó | phone, last_state | WARN |
| Compra duplicada | phone, existing_purchase_id | WARN |

### Ejemplo
```json
{
  "timestamp": "2026-06-24T10:05:00.000Z",
  "level": "INFO",
  "category": "business",
  "component": "register-purchase",
  "phone": "+521234567890",
  "message": "Compra registrada exitosamente",
  "data": {
    "participant_id": "part_abc123",
    "purchase_id": "pur_456def",
    "amount": 1500.50,
    "points_earned": 150,
    "merchant": "Soriana"
  },
  "execution_id": "exec_xyz789"
}
```

---

## 3. Logs de Error

Registran todas las incidencias del sistema.

### Propósito
- Alertas de monitoreo
- Diagnóstico de fallos
- Análisis de tendencias de error

### Campos Adicionales para Errores

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `error_type` | string | Clasificación del error (api, validation, ai, network) |
| `error_code` | string | Código específico (HTTP status, error code) |
| `stack_trace` | string | Traza del error (solo en desarrollo) |
| `retry_count` | number | Intentos realizados |

### Eventos a Registrar

| Evento | Datos Asociados | Nivel |
|--------|----------------|-------|
| API error (4xx) | endpoint, status, error_code | WARN |
| API error (5xx) | endpoint, status, retry_count | ERROR |
| API error (401/403) | endpoint | ERROR |
| IA timeout | model, timeout_ms | ERROR |
| IA baja confianza | confidence, amount_detected | WARN |
| Error de validación | field, input_value | WARN |
| Error de red | error_message | ERROR |
| Límite de reintentos alcanzado | phone, error_type | ERROR |
| Estado desconocido | state_value | ERROR |

### Ejemplo
```json
{
  "timestamp": "2026-06-24T10:03:00.000Z",
  "level": "ERROR",
  "category": "error",
  "component": "search-participant",
  "phone": "+521234567890",
  "message": "Error 500 al buscar participante",
  "data": {
    "error_type": "api",
    "error_code": 500,
    "endpoint": "/campaigns/3z/participants/search",
    "retry_count": 3
  },
  "execution_id": "exec_xyz789"
}
```

---

## 4. Implementación en n8n

### Logger Node (Code Node)

```javascript
// Logger centralizado - usar en cada Code Node relevante
const LOG_DIR = '/data/logs';

function log(level, category, component, phone, message, data = {}) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    level,
    category,
    component,
    phone: phone || '',
    message,
    data,
    execution_id: $execution?.id || 'unknown'
  };

  // 1. Console (visible en docker logs)
  const prefix = `[${level}] [${category}] [${component}]`;
  console.log(`${prefix} ${message}`, JSON.stringify(data));

  // 2. Archivo JSON por categoría
  const filePath = `${LOG_DIR}/${category}/${timestamp}.json`;
  // Usar $dataStore o función de escritura para append al archivo
  appendToFile(filePath, JSON.stringify(logEntry) + '\n');

  return logEntry;
}
```

### Uso en Cada Nodo

```javascript
// En Session Manager
const logger = log('INFO', 'operation', 'session-manager', phone, 'Sesión recuperada', {
  state: session.state,
  is_new: false
});

// En Error Handler
const logger = log('ERROR', 'error', 'search-participant', phone, 'Error 500 en API', {
  error_type: 'api',
  error_code: 500,
  retry_count: 2
});
```

---

## 5. Estructura de Archivos

```
/data/logs/
├── operations/
│   ├── 2026-06-24_10-00-00_001.json
│   ├── 2026-06-24_10-00-01_002.json
│   └── ...
├── business/
│   ├── 2026-06-24_10-05-00_001.json
│   ├── 2026-06-24_10-05-30_002.json
│   └── ...
└── errors/
    ├── 2026-06-24_10-03-00_001.json
    ├── 2026-06-24_10-04-00_002.json
    └── ...
```

### Rotación de Logs

| Parámetro | Valor |
|-----------|-------|
| **Retención** | 7 días |
| **Rotación** | Diaria (archivo por día) |
| **Limpieza** | Script semanal vía cron o tarea n8n programada |
| **Tamaño máximo** | 100MB por archivo |

---

## 6. Consideraciones de Privacidad

| Campo | ¿Loggear? | Nota |
|-------|-----------|------|
| phone | Sí (ofuscado en debug) | Necesario para correlación |
| name | Sí | Necesario para auditoría |
| email | Sí | Necesario para auditoría |
| photo_id | Sí | Referencia a imagen, no contenido |
| invoice_data.monto | Sí | Sin datos sensibles |
| invoice_data.items | No | Contiene datos de compra |
| Imagen del ticket | No | Nunca loggear imágenes |

### Ofuscación para Debug
```javascript
function obfuscatePhone(phone) {
  if (!phone) return '';
  return phone.slice(0, 5) + '****' + phone.slice(-3);
  // +52123****890
}
```
