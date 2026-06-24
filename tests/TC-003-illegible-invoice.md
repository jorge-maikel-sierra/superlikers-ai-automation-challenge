# TC-003: Factura Ilegible — Reintento con Foto Clara

## Descripción
Validar que el sistema maneja correctamente el caso de una foto de ticket con baja calidad (borrosa, oscura o con reflejos) que la IA no puede procesar con suficiente confianza (OCR < 0.7). El sistema debe solicitar una foto más clara y permitir el reintento sin perder el estado de la sesión.

## Precondiciones
- Usuario completó el registro (nuevo o existente) y está en estado **WAIT_TICKET**
- Usuario tiene una foto borrosa/ilegible y otra foto clara del mismo ticket
- Se ejecuta después de TC-001 o TC-002 (el usuario ya está en WAIT_TICKET)

## Input
| # | Tipo | Contenido |
|---|------|-----------|
| 1 | Imagen | `soriana_ticket_borroso.jpg` (JPEG, 0.8 MB, 1200×1600 px, imagen desenfocada con poca iluminación) |
| 2 | Imagen | `soriana_ticket_claro.jpg` (JPEG, 1.5 MB, 1920×2560 px, imagen nítida con buena iluminación) |

## Expected Result

| Paso | Transición | API / Acción | Respuesta Esperada |
|------|------------|-------------|-------------------|
| 1 | **WAIT_TICKET → UPLOAD_TICKET** | — | Validación: es imagen JPEG, 0.8 MB < 10 MB ✅ → Subiendo imagen... |
| 2 | **UPLOAD_TICKET → PROCESS_INVOICE** | `POST /campaigns/3z/tickets/upload` → `200` `{"photo_id": "photo_g7h8i9j0"}` | "📄 Procesando tu factura con IA..." |
| 3 | **PROCESS_INVOICE → WAIT_TICKET** | OCR confidence: **0.45** < 0.7 ❌ | "😕 No pude leer bien tu factura. La foto está borrosa o con poca luz. Por favor envía una foto más clara, asegurándote de que se vean bien el total, la fecha y el establecimiento." |
| 4 | **WAIT_TICKET → UPLOAD_TICKET** (reintento) | — | Validación: es imagen JPEG, 1.5 MB < 10 MB ✅ → Subiendo imagen... |
| 5 | **UPLOAD_TICKET → PROCESS_INVOICE** | `POST /campaigns/3z/tickets/upload` → `200` `{"photo_id": "photo_h8i9j0k1"}` | "📄 Procesando tu factura con IA..." |
| 6 | **PROCESS_INVOICE → REGISTER_PURCHASE** | OCR confidence: **0.95** ≥ 0.7 ✅ → Datos extraídos: Soriana Híper, $1,250.50 MXN, 2026-06-24 | "Factura procesada correctamente. Continuando con el registro..." |
| 7 | **REGISTER_PURCHASE → ACCEPT_ENTRY** | `POST /campaigns/3z/purchases` → `201` `{"purchase_id": "pur_k1l2m3n4", "points_earned": 125}` | "✅ Compra registrada. Aprobando tu participación..." |
| 8 | **ACCEPT_ENTRY → FINISHED** | `PUT /campaigns/3z/activities/3z/entries` → `200` | "🎉 ¡Felicidades! Has ganado **125 puntos**." |

### Validaciones Clave
- El sistema **NO** debe perder el estado de la sesión entre reintentos
- El contador `retry_count` en la sesión debe incrementarse con cada reintento
- Si se superan 3 reintentos con OCR < 0.7, el sistema debe escalar a soporte
- La session debe mantener `participant_id`, `phone` y demás datos intactos durante el reintento

## Actual Result
_Pendiente de captura_

## Status
Draft

## Evidence
_Pendiente de captura_
