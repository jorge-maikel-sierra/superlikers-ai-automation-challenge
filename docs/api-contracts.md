# Contratos de Datos — Superlikers API v1

## Configuración General

```
Base URL: https://api.superlikerslabs.com/v1
Campaña: 3z
Autenticación: API Key en header X-API-Key
Content-Type: application/json
```

---

## 1. Buscar Participante

### Request
```
GET /campaigns/{campaign}/participants/search?phone={phone}
Authorization: X-API-Key {api_key}
```

### Response 200 (Encontrado)
```json
{
  "id": "string",
  "phone": "string",
  "name": "string",
  "email": "string",
  "created_at": "datetime",
  "status": "active"
}
```

### Response 404 (No encontrado)
```json
{
  "error": "participant_not_found",
  "message": "No participant found with phone {phone}"
}
```

### Errores Esperados
| Código | Significado | Acción |
|--------|-------------|--------|
| 400 | Parámetros inválidos | Mostrar error al usuario |
| 401 | API Key inválida | Alerta de configuración |
| 404 | No encontrado | Flujo de registro |
| 429 | Rate limit | Esperar y reintentar |
| 5xx | Error interno | Reintentar con backoff |

---

## 2. Crear Participante

### Request
```
POST /campaigns/{campaign}/participants
Content-Type: application/json
Authorization: X-API-Key {api_key}

{
  "phone": "+521234567890",
  "name": "Juan Pérez",
  "email": "juan@example.com"
}
```

### Response 201 (Creado)
```json
{
  "id": "string",
  "phone": "+521234567890",
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "created_at": "datetime"
}
```

### Validaciones de Input
| Campo | Tipo | Requerido | Formato |
|-------|------|-----------|---------|
| phone | string | Sí | +52 seguido de 10 dígitos |
| name | string | Sí | 3-100 caracteres |
| email | string | Sí | Formato email válido |

---

## 3. Subir Imagen de Ticket

### Request
```
POST /campaigns/{campaign}/tickets/upload
Content-Type: multipart/form-data
Authorization: X-API-Key {api_key}

Form field: image (JPEG/PNG)
```

### Response 200
```json
{
  "photo_id": "string",
  "url": "string",
  "size_bytes": 123456,
  "mime_type": "image/jpeg"
}
```

### Validaciones
| Aspecto | Límite |
|---------|--------|
| Tamaño máximo | 10 MB |
| Formatos | JPEG, PNG |
| Dimensiones mínimas | 500x500 px |

---

## 4. Registrar Compra

### Request
```
POST /campaigns/{campaign}/purchases
Content-Type: application/json
Authorization: X-API-Key {api_key}

{
  "participant_id": "string",
  "photo_id": "string",
  "invoice_data": {
    "amount": 1500.50,
    "currency": "MXN",
    "date": "2026-06-24",
    "merchant_name": "Soriana",
    "items": [
      {"name": "Producto 1", "quantity": 2, "price": 500.00},
      {"name": "Producto 2", "quantity": 1, "price": 500.50}
    ],
    "total": 1500.50
  }
}
```

### Response 201
```json
{
  "purchase_id": "string",
  "amount": 1500.50,
  "points_earned": 150,
  "status": "pending_approval"
}
```

### Response 409 (Duplicado)
```json
{
  "error": "duplicate_purchase",
  "message": "This invoice was already registered",
  "existing_purchase_id": "string"
}
```

---

## 5. Aprobar Actividad / Aceptar Entry

### Request
```
PUT /campaigns/{campaign}/activities/{activity_id}/entries
Content-Type: application/json
Authorization: X-API-Key {api_key}

{
  "participant_id": "string",
  "purchase_id": "string",
  "action": "approve"
}
```

### Response 200
```json
{
  "entry_id": "string",
  "status": "approved",
  "points_awarded": 150,
  "total_points": 150
}
```

### Errores Esperados
| Código | Significado | Acción |
|--------|-------------|--------|
| 400 | Datos inválidos | Verificar payload |
| 404 | Participante/compra no existe | Revisar IDs |
| 409 | Entry ya aprobada | Informar al usuario |
| 5xx | Error interno | Reintentar |

---

## Resumen de Mapeo

| Paso del Flujo | Endpoint | Método | Input | Output Clave |
|----------------|----------|--------|-------|-------------|
| Buscar participante | /participants/search?phone= | GET | phone | id, name, email |
| Crear participante | /participants | POST | phone, name, email | id |
| Subir ticket | /tickets/upload | POST | image (multipart) | photo_id |
| Registrar compra | /purchases | POST | participant_id, photo_id, invoice_data | purchase_id, points_earned |
| Aceptar entry | /activities/{id}/entries | PUT | participant_id, purchase_id | points_awarded |
