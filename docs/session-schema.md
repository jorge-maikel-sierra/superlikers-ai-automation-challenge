# Modelo de Sesión — Persistencia del Estado Conversacional

## Esquema

```json
{
  "phone": "",
  "email": "",
  "name": "",
  "state": "START",
  "photo_id": "",
  "photo_url": "",
  "participant_id": "",
  "purchase_id": "",
  "invoice_ref": "",
  "invoice_data": {},
  "points": 0,
  "retry_count": 0,
  "created_at": "2026-06-24T10:00:00Z",
  "updated_at": "2026-06-24T10:05:00Z"
}
```

## Descripción de Campos

| Campo | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| `phone` | string | Sí | Número de celular del usuario (formato internacional) |
| `email` | string | No | Email del participante (solo para registro nuevo) |
| `name` | string | No | Nombre completo del participante |
| `state` | string | Sí | Estado actual en la máquina de estados |
| `photo_id` | string | No | ID de la foto del ticket retornado por la API |
| `photo_url` | string | No | URL de la imagen subida |
| `participant_id` | string | No | ID del participante en Superlikers |
| `purchase_id` | string | No | ID de la compra registrada |
| `invoice_ref` | string | No | Referencia o folio de la factura |
| `invoice_data` | object | No | Datos extraídos por IA (monto, fecha, items) |
| `points` | integer | No | Puntos acumulados en la sesión |
| `retry_count` | integer | No | Contador de reintentos (evita bucles infinitos) |
| `created_at` | datetime | Sí | Timestamp de inicio de sesión |
| `updated_at` | datetime | Sí | Timestamp de última actualización |

## Persistencia

### Estrategia: n8n In-Memory + Backup JSON

Para esta fase de desarrollo, la persistencia se maneja de forma simple:

1. **n8n In-Memory**: Cada sesión se mantiene en memoria durante la ejecución del workflow mediante variables de workflow.

2. **Backup JSON**: Al finalizar cada paso relevante, se guarda un respaldo en disco (`/data/sessions/{phone}.json`) para recuperación en caso de fallo.

### Estructura de Archivos

```
/data/sessions/
├── +521234567890.json
├── +529876543210.json
└── ...
```

### Ejemplo de Archivo Persistido

```json
{
  "phone": "+521234567890",
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "state": "WAIT_TICKET",
  "participant_id": "part_abc123",
  "photo_id": "",
  "points": 0,
  "retry_count": 0,
  "created_at": "2026-06-24T10:00:00Z",
  "updated_at": "2026-06-24T10:05:00Z"
}
```

## Operaciones

### Crear Sesión
```javascript
// Pseudocódigo n8n
{
  operation: "createSession",
  phone: $input.body.phone,
  session: {
    phone: $input.body.phone,
    state: "WAIT_PHONE",
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  }
}
```

### Actualizar Sesión
```javascript
{
  operation: "updateSession",
  phone: $input.body.phone,
  updates: {
    state: "WAIT_TICKET",
    participant_id: $input.body.participant_id,
    updated_at: new Date().toISOString()
  }
}
```

### Recuperar Sesión
```javascript
{
  operation: "getSession",
  phone: $input.body.phone
  // Retorna: session object o null si no existe
}
```

### Resetear Sesión
```javascript
{
  operation: "resetSession",
  phone: $input.body.phone
  // Elimina el archivo JSON y reinicia estado
}
```

## Consideraciones para Producción

| Aspecto | Desarrollo | Producción (futuro) |
|---------|-----------|---------------------|
| Almacenamiento | Archivos JSON | Redis |
| Persistencia | Por sesión + archivo | Clave-valor en Redis |
| Recuperación | Lectura de archivo | Redis GET |
| Escalabilidad | Single node | Redis Cluster |
| TTL | Manual | Automático (24h TTL) |
