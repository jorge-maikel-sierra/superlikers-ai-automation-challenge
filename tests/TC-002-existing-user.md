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
| 2 | **WAIT_PHONE → SEARCH_PARTICIPANT** | `GET /participants/search` body: `{api_key, campaign, query:{cellphone:"529987654321", state:"active"}}` | Validación: 10 dígitos ✅ → Buscando participante... |
| 3 | **SEARCH_PARTICIPANT → WAIT_TICKET** | `200` `{"object":{"id":"part_a1b2c3d4", "name":"Carlos López Martínez", "email":"carlos.lopez@email.com", "distinct_id":"carlos.lopez@email.com"}}` | "👋 ¡Bienvenido de nuevo, Carlos! Ahora envía la foto de tu ticket de compra para participar." |
| 4 | **WAIT_TICKET → UPLOAD_TICKET** | — | Validación: es imagen JPEG, 2.1 MB < 10 MB ✅ → Subiendo imagen... |
| 5 | **UPLOAD_TICKET → PROCESS_INVOICE** | `POST /photos` (multipart, campo `upload_photo`) → `200` `{"id": "entry_b2c3d4e5", "url": "...", "image_url": "..."}` | "📄 Procesando tu factura con IA..." |
| 6 | **PROCESS_INVOICE → REGISTER_PURCHASE** | OCR confidence: **0.88** ≥ 0.7 ✅ → Extraído: `{ref:"FAC-ELEKTRA-001", products:[{ref:"TV LG 55", price:"2300.00", quantity:"1"}]}` | "Factura procesada. Registrando compra..." |
| 7 | **REGISTER_PURCHASE → ACCEPT_ENTRY** | `POST /retail/buy` → `200` `{"invoice":{"ref":"FAC-ELEKTRA-001","points":230}, "participant":{"available_points":230}}` | "✅ Compra registrada. Has ganado 230 puntos. Aprobando tu participación..." |
| 8 | **ACCEPT_ENTRY → FINISHED** | `POST /entries/accept` body: `{api_key, campaign, id:"entry_b2c3d4e5"}` → `200` `{"ok":true, "data":{"state":"success", "execution_error":null}}` | "🎉 ¡Felicidades Carlos! Has ganado **230 puntos**. ¡Sigue así!" |

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
