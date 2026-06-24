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
| 2 | **WAIT_PHONE → SEARCH_PARTICIPANT** | `GET /campaigns/3z/participants/search?phone=521234567890` | Buscando participante... |
| 3 | **SEARCH_PARTICIPANT → WAIT_TICKET** | `200` `{"id": "part_f8a3b2c1", "name": "María García Hernández"}` | "👋 ¡Bienvenida de nuevo, María! Envía la foto de tu ticket de compra." |
| 4 | **WAIT_TICKET → UPLOAD_TICKET** | — | Validación de imagen ✅ → Subiendo... |
| 5 | **UPLOAD_TICKET → PROCESAR DUPLICADO** | `POST /campaigns/3z/tickets/upload` → `200` `{"photo_id": "photo_d4e5f6a7"}` (sistema detecta que `photo_id` ya existe en una compra previa) | — |
| 6 | **Detección Duplicado** | Consulta interna o API → `409` duplicado detectado | "⚠️ Esta foto de ticket ya fue registrada anteriormente el 2026-06-24 por un monto de $1,250.50 MXN en Soriana Híper. No es necesario volver a registrarla." |
| 7 | **→ ACCEPT_ENTRY** | Reutiliza `purchase_id: "pur_7b8c9d0e"` existente | "Aprobando tu participación..." |
| 8 | **→ FINISHED** | `PUT /campaigns/3z/activities/3z/entries` → `200` (si no está ya aprobada) o mensaje informativo | "✅ Tu participación ya está registrada. Puedes seguir participando con un ticket diferente." |

### Validaciones Clave
- **No se debe crear un duplicado** en la tabla de purchases
- El sistema debe detectar el `photo_id` duplicado antes de llamar a `POST /purchases` o manejar el `409` de la API
- El flujo debe continuar sin bloquear al usuario
- El mensaje debe ser informativo, no un error grave

## Actual Result
_Pendiente de captura_

## Status
Draft

## Evidence
_Pendiente de captura_
