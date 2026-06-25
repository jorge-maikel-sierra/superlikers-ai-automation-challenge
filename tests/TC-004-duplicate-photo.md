# TC-004: Imagen Duplicada — Misma Foto Enviada Dos Veces

## Descripción
Validar que el sistema detecta cuando el usuario envía la misma foto de ticket que ya fue registrada anteriormente. El sistema debe informar al usuario sobre el duplicado y continuar el flujo hacia la aprobación de entrada sin duplicar la compra.

## Precondiciones
- **Ejecutar después de TC-001 o TC-002** (existencia de compra registrada)
- El usuario ya tiene una compra registrada exitosamente con `photo_id = "photo_d4e5f6a7"`
- Sesión del usuario está en estado ACTIVA (no necesariamente en WAIT_TICKET — puede iniciar un nuevo flujo)
- El sistema reutiliza el `participant_id` del usuario existente

## Input
| # | Tipo | Contenido |
|---|------|-----------|
| 1 | Texto | "Hola, quiero participar otra vez" |
| 2 | Texto | "521234567890" |
| 3 | Imagen | `soriana_ticket_1.jpg` (JPEG, 1.2 MB — **exactamente el mismo archivo que TC-001**) |

## Expected Result

| Paso | Transición | API / Acción | Respuesta Esperada |
|------|------------|-------------|-------------------|
| 1 | **START → WAIT_PHONE** | — | Saludo + solicitud de número |
| 2 | **WAIT_PHONE → SEARCH_PARTICIPANT** | `GET /participants/search` body: `{api_key, campaign, query:{cellphone:"521234567890", state:"active"}}` | Buscando participante... |
| 3 | **SEARCH_PARTICIPANT → WAIT_TICKET** | `200` `{"object":{"id":"part_f8a3b2c1", "name":"María García Hernández", "email":"maria.garcia@email.com"}}` | "👋 ¡Bienvenida de nuevo, María! Envía la foto de tu ticket de compra." |
| 4 | **WAIT_TICKET → UPLOAD_TICKET** | — | Validación de imagen ✅ → Subiendo... |
| 5 | **UPLOAD_TICKET → PROCESS_INVOICE** | `POST /photos` (multipart, campo `upload_photo`) → `422` `{"message": "Sha1 is already taken"}` | — |
| 6 | **Detección Duplicado** | API devuelve 422 con "Sha1 is already taken" | "⚠️ Esta foto de ticket ya fue registrada anteriormente. Por favor envía un ticket diferente." |
| 7 | **→ WAIT_TICKET** | Sesión vuelve a WAIT_TICKET | "Puedes enviar la foto de un ticket diferente para acumular más puntos." |

### Validaciones Clave
- La API devuelve `422` con `"message": "Sha1 is already taken"` al detectar imagen duplicada en `/photos`
- El sistema NO debe intentar `/retail/buy` si `/photos` ya retornó 422
- El flujo regresa a WAIT_TICKET para que el usuario envíe un ticket diferente
- El mensaje debe ser informativo, no un error técnico

## Actual Result
_Pendiente de captura_

## Status
Draft

## Evidence
_Pendiente de captura_
