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
| 2 | **WAIT_PHONE → SEARCH_PARTICIPANT** | `GET /campaigns/3z/participants/search?phone=521234567890` | Buscando... |
| 3 | **SEARCH_PARTICIPANT → WAIT_TICKET** | `200` `{"id": "part_f8a3b2c1"}` | "👋 ¡Bienvenida de nuevo, María! Envía la foto de tu ticket." |
| 4 | **WAIT_TICKET → UPLOAD_TICKET** | — | Validación ✅ → Subiendo... |
| 5 | **UPLOAD_TICKET → PROCESS_INVOICE** | `POST /campaigns/3z/tickets/upload` → `200` `{"photo_id": "photo_i9j0k1l2"}` | "📄 Procesando..." |
| 6 | **PROCESS_INVOICE → REGISTER_PURCHASE** | OCR confidence: **0.91** ≥ 0.7 ✅ → invoice_ref: `FAC-2024-0624-001` | "Factura procesada. Registrando compra..." |
| 7 | **REGISTER_PURCHASE → Detección Duplicado** | `POST /campaigns/3z/purchases` → `409` `{"error": "duplicate_purchase", "message": "This invoice was already registered", "existing_purchase_id": "pur_7b8c9d0e"}` | "⚠️ Esta factura (folio FAC-2024-0624-001) ya fue registrada el 2026-06-24 por un monto de $1,250.50 MXN en Soriana Híper. No es necesario volver a registrarla." |
| 8 | **→ ACCEPT_ENTRY** | Reutiliza `purchase_id: "pur_7b8c9d0e"` | "Aprobando tu participación..." |
| 9 | **→ FINISHED** | — | "✅ Tu participación ya está registrada. Si tienes otro ticket diferente, puedes enviarlo para acumular más puntos." |

### Validaciones Clave
- La API retorna `409` con `error: "duplicate_purchase"` al detectar el folio duplicado
- El sistema **NO** debe pasar el error 409 al usuario como un error del sistema
- El mensaje debe mostrar los datos de la compra original (fecha, monto, establecimiento)
- La sesión continúa hacia ACCEPT_ENTRY usando la compra existente

## Actual Result
_Pendiente de captura_

## Status
Draft

## Evidence
_Pendiente de captura_
