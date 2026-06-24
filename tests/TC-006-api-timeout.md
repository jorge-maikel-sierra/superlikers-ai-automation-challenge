# TC-006: Timeout de API — Reintentos Agotados

## Descripción
Validar el comportamiento del sistema cuando la API de Superlikers no responde dentro del tiempo de espera. El sistema debe implementar un mecanismo de reintentos con backoff exponencial y, al agotar los reintentos, mostrar un mensaje de error amigable.

## Precondiciones
- API de Superlikers temporalmente no disponible (timeout simulado)
- El usuario inicia un flujo nuevo
- Timeout inicial configurado a **5 segundos**
- Backoff: 1s → 2s → 4s (capped a 10s), máximo **3 reintentos**

## Input
| # | Tipo | Contenido |
|---|------|-----------|
| 1 | Texto | "Hola" |
| 2 | Texto | "521234567890" |

## Expected Result

| Paso | Transición | API / Acción | Respuesta Esperada |
|------|------------|-------------|-------------------|
| 1 | **START → WAIT_PHONE** | — | Saludo + solicitud de número |
| 2 | **WAIT_PHONE → SEARCH_PARTICIPANT** | — | Validación: 10 dígitos ✅ → Consultando API... |
| 3 | **Intento 1 (timeout 5s)** | `GET /campaigns/3z/participants/search?phone=521234567890` | ⏱️ **Timeout** después de 5s sin respuesta |
| 4 | **Backoff 1s → Intento 2** | Retry #1 — espera 1s, timeout 5s | ⏱️ **Timeout** después de 5s sin respuesta |
| 5 | **Backoff 2s → Intento 3** | Retry #2 — espera 2s, timeout 5s | ⏱️ **Timeout** después de 5s sin respuesta |
| 6 | **Backoff 4s → Intento 4** | Retry #3 — espera 4s (capped), timeout 5s | ⏱️ **Timeout** después de 5s sin respuesta |
| 7 | **→ ERROR** | `retry_count ≥ max_retries (3)` | "😓 Lo sentimos, el servicio de verificación está temporalmente fuera de línea. Hemos intentado conectarnos varias veces sin éxito. Por favor intenta de nuevo en unos minutos. Si el problema persiste, contacta a soporte." |

### Backoff Chronology
```
T=0s    → Intento 1 (timeout 5s) → falla en T=5s
T=6s    → Intento 2 (backoff 1s, timeout 5s) → falla en T=11s
T=13s   → Intento 3 (backoff 2s, timeout 5s) → falla en T=18s
T=22s   → Intento 4 (backoff 4s, timeout 5s) → falla en T=27s
T=27s   → Max retries alcanzado → ERROR
```

### Validaciones Clave
- Cada intento debe tener un timeout de **5 segundos**
- Los tiempos de espera entre reintentos deben ser: 1s, 2s, 4s (exponencial, cap 10s)
- El contador `retry_count` en la sesión debe incrementarse en cada reintento
- El `retry_count` debe reiniciarse si el usuario inicia un nuevo flujo después del error
- El mensaje de error debe ser amigable y no mostrar detalles técnicos
- La sesión del usuario debe conservarse para que pueda reintentar más tarde

## Actual Result
_Pendiente de captura_

## Status
Draft

## Evidence
_Pendiente de captura_
