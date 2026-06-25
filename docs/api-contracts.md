# Contratos de Datos — Superlikers API v1

> **Fuente de verdad**: [Postman Docs](https://documenter.getpostman.com/view/8371752/UzXKWebd)
> Los endpoints NO llevan prefijo `/campaigns/{campaign}/`. La campaña va siempre en el cuerpo de la petición como campo `campaign`.

## Configuración General

```
Base URL: https://api.superlikerslabs.com/v1
Campaña: 3z
Autenticación: api_key en el body + Authorization: Bearer {api_key} en header
Content-Type: application/json (salvo /photos que es multipart/form-data)
```

---

## 1. Buscar Participante

### Request
```
GET /participants/search
Content-Type: application/json
Authorization: Bearer {api_key}

{
  "api_key": "string",
  "campaign": "3z",
  "query": {
    "cellphone": "3001234567",
    "state": "active"
  }
}
```

> **Nota**: `cellphone` es el número local sin prefijo de país. Depende del campo de registro configurado en la campaña.

### Response 200 (Encontrado)
```json
{
  "object": {
    "id": "string",
    "email": "correo@ejemplo.com",
    "name": "Nombre Apellido",
    "distinct_id": "correo@ejemplo.com",
    "points": 0
  },
  "message": "string"
}
```

### Response 404 (No encontrado)
```json
{
  "message": "not found"
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
POST /participants
Content-Type: application/json

{
  "api_key": "string",
  "campaign": "3z",
  "properties": {
    "email": "correo@ejemplo.com",
    "celular": "3001234567",
    "name": "Nombre Apellido"
  },
  "active": true,
  "verified_cellphone": true,
  "verified_email": true,
  "not_send_verify_registration": true
}
```

> **Nota**: `distinct_id` es el email del participante. Los nombres de los campos en `properties` (ej. `celular`, `name`) dependen de la configuración de la campaña.

### Response 200 (Creado)
```json
{
  "message": "participant was successfully created"
}
```

### Validaciones de Input
| Campo | Tipo | Requerido | Formato |
|-------|------|-----------|---------|
| properties.email | string | Sí | Formato email válido |
| properties.celular | string | Sí | 10 dígitos locales |
| properties.name | string | Sí | 3-100 caracteres |

---

## 3. Subir Foto de Ticket

### Request
```
POST /photos
Content-Type: multipart/form-data

api_key: "string"
campaign: "3z"
distinct_id: "correo@ejemplo.com"
upload_photo: (binary — JPEG/PNG)
title: "Ticket de compra"
category: "tickets"
```

> **Importante**: el campo binario se llama `upload_photo`, no `image`.

### Response 200
```json
{
  "id": "string",
  "entry_id": "string",
  "url": "string",
  "image_url": "string"
}
```

> El campo `id` (o `entry_id`) es el que se usa como `id` en `/entries/accept`.

### Response 422 (Imagen duplicada)
```json
{
  "message": "Sha1 is already taken"
}
```

### Validaciones
| Aspecto | Límite |
|---------|--------|
| Tamaño máximo | 10 MB |
| Formatos | JPEG, PNG |
| Campo multipart | `upload_photo` |

---

## 4. Registrar Compra

### Request
```
POST /retail/buy
Content-Type: application/json

{
  "api_key": "string",
  "campaign": "3z",
  "distinct_id": "correo@ejemplo.com",
  "ref": "numero_de_factura",
  "products": [
    {
      "ref": "codigo_o_nombre_producto",
      "price": "500.00",
      "quantity": "2",
      "provider": "proveedor_opcional",
      "line": "linea_opcional"
    }
  ]
}
```

> **Importante**: `distinct_id` es el email del participante. Los productos deben extraerse del OCR de la factura con los campos exactos `ref`, `price`, `quantity`.

### Response 200
```json
{
  "invoice": {
    "ref": "numero_de_factura",
    "points": 150,
    "promotions_points": 0
  },
  "participant": {
    "available_points": 150,
    "accumulated_points": 150
  }
}
```

### Response 422 (Factura duplicada)
```json
{
  "message": "ref already taken"
}
```

### Errores Esperados
| Código | Significado | Acción |
|--------|-------------|--------|
| 400 | Datos inválidos / productos malformados | Verificar payload |
| 401 | API Key inválida | Alerta de configuración |
| 422 | Factura/ref ya registrada | Informar al usuario |
| 5xx | Error interno | Reintentar con backoff |

---

## 5. Aceptar Entry

### Request
```
POST /entries/accept
Content-Type: application/json

{
  "api_key": "string",
  "campaign": "3z",
  "id": "entry_id_from_photos"
}
```

> **Importante**: `id` es el campo `id` (o `entry_id`) que devuelve `POST /photos`. No es un `purchase_id` ni un `activity_id` inventado.

### Response 200
```json
{
  "ok": true,
  "data": {
    "state": "success",
    "execution_error": null
  }
}
```

### Response 200 con error de ejecución
```json
{
  "ok": "false",
  "data": {
    "state": "error",
    "execution_error": "description"
  }
}
```

> La API puede devolver `ok: "false"` (string) incluso con HTTP 200. Siempre verificar `data.execution_error`.

### Errores Esperados
| Código | Significado | Acción |
|--------|-------------|--------|
| 400 | Datos inválidos | Verificar payload |
| 404 | Entry no existe | Revisar `id` de `/photos` |
| 5xx | Error interno | Reintentar con backoff |

---

## Resumen de Mapeo

| Paso del Flujo | Endpoint | Método | Input Clave | Output Clave |
|----------------|----------|--------|-------------|-------------|
| Buscar participante | `/participants/search` | GET | `api_key`, `campaign`, `query.cellphone` | `object.id`, `object.email`, `object.name` |
| Crear participante | `/participants` | POST | `api_key`, `campaign`, `properties.email`, `properties.celular`, `properties.name` | `message: "participant was successfully created"` |
| Subir foto | `/photos` | POST multipart | `api_key`, `campaign`, `distinct_id`, `upload_photo` | `id` (= entry_id para `/entries/accept`) |
| Registrar compra | `/retail/buy` | POST | `api_key`, `campaign`, `distinct_id`, `ref`, `products[]` | `invoice.points`, `participant.available_points` |
| Aceptar entry | `/entries/accept` | POST | `api_key`, `campaign`, `id` (de `/photos`) | `ok`, `data.state`, `data.execution_error` |
