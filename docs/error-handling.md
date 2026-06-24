# Estrategia de Manejo de Errores — n8n WhatsApp Chatbot

## Visión General

Clasificación y tratamiento de todos los errores que pueden ocurrir en el sistema. Cada error tiene una causa, método de detección, estrategia de recuperación y mensaje para el usuario.

---

## Categorías de Error

```
Errores
├── Usuario
│   ├── Formato inválido
│   ├── Tipo de mensaje incorrecto
│   └── Abandono / timeout
├── Validación
│   ├── Teléfono inválido
│   ├── Nombre inválido
│   ├── Email inválido
│   └── Imagen no soportada
├── IA
│   ├── Baja confianza en OCR
│   ├── Timeout de API
│   └── JSON inválido
├── API (Superlikers)
│   ├── 400 Bad Request
│   ├── 401 Unauthorized
│   ├── 404 Not Found
│   ├── 409 Conflict (duplicado)
│   ├── 429 Rate Limit
│   └── 5xx Server Error
└── Infraestructura
    ├── Red / DNS
    ├── n8n interno
    └── Timeout general
```

---

## 1. Errores de Usuario

### 1.1 Formato de Teléfono Inválido

| Campo | Detalle |
|-------|---------|
| **Causa** | Usuario ingresa letras, símbolos, o número muy corto/largo |
| **Detección** | Phone Validator: regex `/^[0-9]{10,15}$/` después de limpiar no dígitos |
| **Recuperación** | Re-preguntar conservando el estado WAIT_PHONE |
| **Retry** | No incrementa `retry_count` (es error de validación, no de sistema) |
| **Mensaje** | "El número debe tener entre 10 y 15 dígitos. Intentá de nuevo." |

### 1.2 Nombre Inválido

| Campo | Detalle |
|-------|---------|
| **Causa** | Nombre < 3 caracteres, o contiene números/símbolos |
| **Detección** | Name Validator: `length >= 3 && /^[a-zA-ZáéíóúñÁÉÍÓÚÑ\s]+$/` |
| **Recuperación** | Re-preguntar conservando estado WAIT_NAME |
| **Mensaje** | "Ingresá un nombre válido (solo letras, mínimo 3 caracteres)." |

### 1.3 Email Inválido

| Campo | Detalle |
|-------|---------|
| **Causa** | Email no cumple formato estándar |
| **Detección** | Email Validator: regex `/^[^\s@]+@[^\s@]+\.[^\s@]+$/` |
| **Recuperación** | Re-preguntar conservando estado WAIT_EMAIL |
| **Mensaje** | "El email no tiene un formato válido. Intentá de nuevo." |

### 1.4 Respuesta de Confirmación Inválida

| Campo | Detalle |
|-------|---------|
| **Causa** | Usuario no responde "sí" o "no" (o variantes) |
| **Detección** | Confirmation Router: match contra listas positivas y negativas |
| **Recuperación** | Re-preguntar con opciones claras |
| **Mensaje** | "Respondé 'Sí' si los datos son correctos, o 'No' para corregirlos." |

### 1.5 Mensaje de Texto en Lugar de Imagen

| Campo | Detalle |
|-------|---------|
| **Causa** | Usuario está en estado WAIT_TICKET y envía texto |
| **Detección** | State Router: `state=WAIT_TICKET && type=text` |
| **Recuperación** | Re-pedir la imagen |
| **Incremento retry** | Sí (máximo 3, luego redirigir a soporte) |
| **Mensaje** | "Necesito una foto de tu ticket de compra. Enviá la imagen." |

---

## 2. Errores de Validación Interna

### 2.1 Estado Desconocido

| Campo | Detalle |
|-------|---------|
| **Causa** | Sesión corrupta o estado no mapeado en State Router |
| **Detección** | Switch Node sin caso coincidente |
| **Recuperación** | Resetear sesión a START |
| **Mensaje** | "Hubo un problema con tu sesión. Empecemos de nuevo." |

### 2.2 Imagen No Soportada

| Campo | Detalle |
|-------|---------|
| **Causa** | Archivo no es JPEG/PNG o supera 10MB |
| **Detección** | Validar mime type y tamaño antes de subir |
| **Recuperación** | Pedir imagen en formato correcto |
| **Mensaje** | "Solo aceptamos fotos en formato JPEG o PNG de hasta 10MB." |

---

## 3. Errores de IA

### 3.1 Baja Confianza en OCR

| Campo | Detalle |
|-------|---------|
| **Causa** | Imagen borrosa, parcial, con mala iluminación |
| **Detección** | OpenAI devuelve `confidence < 0.7` |
| **Recuperación** | Pedir nueva foto más clara |
| **Incremento retry** | Sí (máximo 3 intentos de foto) |
| **Mensaje** | "No pudimos leer bien tu ticket. Enviá una foto más clara, con buena luz y que se vea toda la factura." |

### 3.2 Timeout de IA

| Campo | Detalle |
|-------|---------|
| **Causa** | OpenAI tarda más de 30s en responder |
| **Detección** | Timeout en HTTP Request Node |
| **Recuperación** | Reintentar 1 vez con timeout de 45s |
| **Mensaje** | "El procesamiento está tomando más tiempo de lo normal. Intentá de nuevo." |

### 3.3 JSON Inválido de IA

| Campo | Detalle |
|-------|---------|
| **Causa** | OpenAI devuelve texto no parseable como JSON |
| **Detección** | `JSON.parse()` falla en el nodo de validación |
| **Recuperación** | Reintentar con prompt más estricto (response_format: json_object) |
| **Mensaje** | (interno, no mostrar al usuario) |

---

## 4. Errores de API (Superlikers)

### 4.1 400 Bad Request

| Campo | Detalle |
|-------|---------|
| **Causa** | Payload inválido (datos faltantes, formato incorrecto) |
| **Detección** | HTTP status code 400 |
| **Recuperación** | Verificar datos antes de reenviar. Si persiste, ERROR con escalado |
| **Mensaje** | "Hubo un problema con los datos. Por favor intentá de nuevo." |

### 4.2 401 Unauthorized

| Campo | Detalle |
|-------|---------|
| **Causa** | API Key inválida o expirada |
| **Detección** | HTTP status code 401 |
| **Recuperación** | No reintentar. Alerta de configuración |
| **Mensaje** | "Error de configuración del sistema. Contactá al administrador." |

### 4.3 404 Not Found

| Campo | Detalle |
|-------|---------|
| **Causa** | Recurso no existe (participante, actividad, etc.) |
| **Detección** | HTTP status code 404 |
| **Recuperación** | Depende del contexto: en búsqueda → flujo de registro. En compra → error |
| **Mensaje** | "No encontramos el recurso solicitado." |

### 4.4 409 Conflict (Duplicado)

| Campo | Detalle |
|-------|---------|
| **Causa** | Compra ya registrada (misma factura) |
| **Detección** | HTTP status code 409 + `duplicate_purchase` |
| **Recuperación** | Informar al usuario, continuar a aprobación si ya existe purchase_id |
| **Mensaje** | "Esta factura ya fue registrada anteriormente. Tus puntos ya están siendo procesados." |

### 4.5 429 Rate Limit

| Campo | Detalle |
|-------|---------|
| **Causa** | Demasiadas requests en poco tiempo |
| **Detección** | HTTP status code 429 + header `Retry-After` |
| **Recuperación** | Esperar según Retry-After (o 1s, 2s, 4s backoff) y reintentar hasta 3 veces |
| **Mensaje** | (interno, no mostrar al usuario) |

### 4.6 5xx Server Error

| Campo | Detalle |
|-------|---------|
| **Causa** | Error interno del servidor de Superlikers |
| **Detección** | HTTP status code 500+ |
| **Recuperación** | Reintentar con backoff exponencial (1s, 2s, 4s), máximo 3 intentos |
| **Mensaje** | "El servidor está teniendo problemas. Intentá de nuevo en unos minutos." |

---

## 5. Errores de Infraestructura

### 5.1 Error de Red

| Campo | Detalle |
|-------|---------|
| **Causa** | DNS, conectividad, firewall |
| **Detección** | Excepción de red (fetch fail, ECONNREFUSED, ENOTFOUND) |
| **Recuperación** | Reintentar 1 vez tras 2s |
| **Mensaje** | "Error de conexión. Verificá tu conexión a internet e intentá de nuevo." |

### 5.2 Timeout General

| Campo | Detalle |
|-------|---------|
| **Causa** | El workflow completo excede el timeout de n8n |
| **Detección** | n8n marca ejecución como "cancelled" |
| **Recuperación** | El usuario recibe error de WhatsApp (no entregado); debe reintentar |
| **Mensaje** | N/A (WhatsApp muestra error de entrega) |

---

## 6. Estrategia de Retry

### Algoritmo de Backoff Exponencial

```javascript
function getBackoffDelay(attempt) {
  // attempt empieza en 1
  return Math.min(1000 * Math.pow(2, attempt - 1), 10000); // max 10s
}

// Uso:
// Attempt 1: 1s
// Attempt 2: 2s
// Attempt 3: 4s
// Attempt 4: 8s
// Attempt 5+: 10s (capped)
```

### Límites de Retry por Tipo

| Tipo de Error | Máximo de Reintentos | Backoff |
|---------------|---------------------|---------|
| Validación usuario | 3 por campo | No (inmediato) |
| API (timeout/5xx) | 3 | Exponencial |
| API (429 rate limit) | 3 | Según Retry-After |
| IA (timeout) | 1 | Simple (2s) |
| Red | 1 | Simple (2s) |
| 401 / 400 persistente | 0 | No reintentar |

### Protección anti-bucle

```javascript
// En Error Handler
if (session.retry_count >= 3) {
  // Máximo de reintentos alcanzado
  return {
    action: 'abort',
    message: 'Lo sentimos, no pudimos procesar tu solicitud después de varios intentos. Por favor contactá a soporte.'
  };
}
```

---

## 7. Matriz de Mensajes al Usuario

| Error | Tipo | Mensaje en Español |
|-------|------|--------------------|
| Teléfono inválido | validación | "El número debe tener entre 10 y 15 dígitos. Intentá de nuevo." |
| Nombre inválido | validación | "Ingresá un nombre válido (solo letras, mínimo 3 caracteres)." |
| Email inválido | validación | "El email no tiene un formato válido. Intentá de nuevo." |
| Confirmación inválida | validación | "Respondé 'Sí' si los datos son correctos, o 'No' para corregirlos." |
| Texto en vez de imagen | usuario | "Necesito una foto de tu ticket de compra. Enviá la imagen." |
| Imagen no soportada | usuario | "Solo aceptamos fotos en formato JPEG o PNG." |
| IA baja confianza | sistema | "No pudimos leer bien tu ticket. Enviá una foto más clara." |
| API error temporal | sistema | "El sistema está procesando tu solicitud. Intentá de nuevo en unos minutos." |
| API 401/403 | sistema | "Error de configuración. Contactá al administrador." |
| Compra duplicada | sistema | "Esta factura ya fue registrada. Tus puntos ya están siendo procesados." |
| Red/timeout | sistema | "Hubo un error de conexión. Intentá de nuevo." |
| Límite de reintentos | sistema | "Comunicate con soporte para ayudarte con tu registro." |
