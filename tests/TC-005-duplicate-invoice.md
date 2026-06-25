# TC-005: Factura Duplicada — Mismo Folio, Diferente Foto

## Descripción
Validar que el sistema detecta cuando un usuario intenta registrar una segunda compra con el mismo folio fiscal (invoice_ref) pero con una foto diferente. La API debe rechazar la operación con código 409 y el sistema debe informar al usuario del registro previo.

## Precondiciones
- **Ejecutar después de TC-001 o TC-002** (existencia de compra registrada)
- Existe una compra registrada con `invoice_ref = "FAC-2024-0624-001"` (folio de Soriana)
- El usuario envía una foto diferente del **mismo ticket** (otro ángulo, mismo folio)
- El participante ya existe: `part_f8a3b2c1` (María García Hernández)

## Input
| # | Tipo | Contenido |
|---|------|-----------|
| 1 | Texto | "Hola, María aquí" |
| 2 | Texto | "521234567890" |
| 3 | Imagen | `soriana_ticket_2_angulo.jpg` (JPEG, 1.8 MB — **misma factura, diferente ángulo**) |

## Expected Result

| Paso | Transición | API / Acción | Respuesta Esperada |
|------|------------|-------------|-------------------|
| 1 | **START → WAIT_PHONE** | — | Saludo + solicitud de número |
| 2 | **WAIT_PHONE → SEARCH_PARTICIPANT** | `GET /participants/search` body: `{api_key, campaign, query:{cellphone:"521234567890", state:"active"}}` | Buscando... |
| 3 | **SEARCH_PARTICIPANT → WAIT_TICKET** | `200` `{"object":{"id": "part_f8a3b2c1", "email":"maria.garcia@email.com"}}` | "👋 ¡Bienvenida de nuevo, María! Envía la foto de tu ticket." |
| 4 | **WAIT_TICKET → UPLOAD_TICKET** | — | Validación ✅ → Subiendo... |
| 5 | **UPLOAD_TICKET → PROCESS_INVOICE** | `POST /photos` (multipart, campo `upload_photo`) → `200` `{"id": "entry_i9j0k1l2", "url": "..."}` | "📄 Procesando..." |
| 6 | **PROCESS_INVOICE → REGISTER_PURCHASE** | OCR confidence: **0.91** ≥ 0.7 ✅ → `{ref:"FAC-2024-0624-001", products:[...]}` | "Factura procesada. Registrando compra..." |
| 7 | **REGISTER_PURCHASE → Detección Duplicado** | `POST /retail/buy` → `422` `{"message": "ref already taken"}` | "⚠️ Esta factura (folio FAC-2024-0624-001) ya fue registrada anteriormente. No se van a duplicar puntos." |
| 8 | **→ WAIT_TICKET** | Sesión vuelve a WAIT_TICKET | "Si tenés otro ticket diferente, podés enviarlo para acumular más puntos." |

### Validaciones Clave
- La API retorna `422` al detectar el folio duplicado en `/retail/buy` (no `409`)
- El sistema **NO** debe pasar el error 422 al usuario como un error técnico
- La sesión regresa a WAIT_TICKET para que el usuario envíe un ticket diferente
- No existe `purchase_id` reutilizable: la compra duplicada se descarta limpiamente

## Actual Result
_Pendiente de captura_

## Status
Draft

## Evidence
_Pendiente de captura_
