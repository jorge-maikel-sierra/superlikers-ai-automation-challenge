# TC-002: Usuario Existente — Skip de Registro

## Descripción
Validar que un usuario ya registrado en Superlikers omite los pasos de registro (WAIT_NAME, WAIT_EMAIL, WAIT_CONFIRMATION) y pasa directamente a la carga del ticket. El sistema debe reconocer al usuario por su teléfono.

## Precondiciones
- Existe participante activo con el teléfono `529987654321` en Superlikers API
- El participante tiene datos: nombre "Carlos López Martínez", email "carlos.lopez@email.com"
- OpenAI Vision API responde correctamente
- Usuario tiene una foto válida de un ticket de compra

## Input
| # | Tipo | Contenido |
|---|------|-----------|
| 1 | Texto | "Buenos días" |
| 2 | Texto | "529987654321" |
| 3 | Imagen | `elektra_ticket_1.jpg` (JPEG, 2.1 MB, 3024×4032 px) |
| 4 | — | (OCR procesa imagen automáticamente) |

## Expected Result

| Paso | Transición | API / Acción | Respuesta Esperada |
|------|------------|-------------|-------------------|
| 1 | **START → WAIT_PHONE** | — | "🎉 ¡Bienvenido a la promoción! Para participar, por favor ingresa tu número de celular a 10 dígitos." |
| 2 | **WAIT_PHONE → SEARCH_PARTICIPANT** | `GET /campaigns/3z/participants/search?phone=529987654321` | Validación: 10 dígitos ✅ → Buscando participante... |
| 3 | **SEARCH_PARTICIPANT → WAIT_TICKET** | `200` `{"id": "part_a1b2c3d4", "name": "Carlos López Martínez", "email": "carlos.lopez@email.com", "status": "active"}` | "👋 ¡Bienvenido de nuevo, Carlos! Ahora envía la foto de tu ticket de compra para participar." |
| 4 | **WAIT_TICKET → UPLOAD_TICKET** | — | Validación: es imagen JPEG, 2.1 MB < 10 MB, 3024×4032 > 500×500 ✅ → Subiendo imagen... |
| 5 | **UPLOAD_TICKET → PROCESS_INVOICE** | `POST /campaigns/3z/tickets/upload` → `200` `{"photo_id": "photo_b2c3d4e5"}` | "📄 Procesando tu factura con IA..." |
| 6 | **PROCESS_INVOICE → REGISTER_PURCHASE** | OCR confidence: **0.88** ≥ 0.7 ✅ → Datos extraídos: Elektra, $2,300.00 MXN, 2026-06-24 | "Factura procesada:\n- Establecimiento: Elektra\n- Monto: $2,300.00 MXN\n- Fecha: 2026-06-24\nRegistrando compra..." |
| 7 | **REGISTER_PURCHASE → ACCEPT_ENTRY** | `POST /campaigns/3z/purchases` → `201` `{"purchase_id": "pur_c3d4e5f6", "points_earned": 230}` | "✅ Compra registrada por $2,300.00 MXN. Has ganado 230 puntos. Aprobando tu participación..." |
| 8 | **ACCEPT_ENTRY → FINISHED** | `PUT /campaigns/3z/activities/3z/entries` → `200` `{"entry_id": "entry_b5c6d7e8", "status": "approved", "points_awarded": 230, "total_points": 230}` | "🎉 ¡Felicidades Carlos! Has ganado **230 puntos** en esta actividad. Total acumulado: 230 puntos. ¡Sigue así!" |

### Validaciones Clave
- El flujo **NO** debe pasar por los estados WAIT_NAME, WAIT_EMAIL ni WAIT_CONFIRMATION
- El sistema debe reconocer al participante existente y saltar directamente a WAIT_TICKET
- El mensaje de bienvenida debe incluir el nombre del usuario: "Bienvenido de nuevo, Carlos"

## Actual Result
_Pendiente de captura_

## Status
Draft

## Evidence
_Pendiente de captura_
