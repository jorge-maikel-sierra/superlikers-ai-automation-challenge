# TC-007: Error de Aprobación — Entry Fallido con Compra Preservada

## Descripción
Validar que cuando el registro de compra se completa exitosamente pero la aprobación de la entrada (PUT entries) falla con error de servidor (5xx), el sistema preserva la compra registrada y notifica al usuario que su participación será revisada manualmente. La compra no debe perderse.

## Precondiciones
- **Ejecutar después de TC-001 o TC-002** (flujo previo hasta REGISTER_PURCHASE)
- `POST /campaigns/3z/purchases` responde correctamente con código **201**
- `PUT /campaigns/3z/activities/3z/entries` responde con error **500** o **503**
- El usuario ya pasó por el flujo de registro (nuevo o existente) hasta la carga de ticket

## Input
| # | Tipo | Contenido |
|---|------|-----------|
| 1 | Texto | "Hola" |
| 2 | Texto | "521234567890" |
| 3 | Imagen | `soriana_ticket_3.jpg` (JPEG, 1.1 MB — **nuevo ticket de compra, diferente a TC-001**) |

## Expected Result

| Paso | Transición | API / Acción | Respuesta Esperada |
|------|------------|-------------|-------------------|
| 1–5 | **START → PROCESS_INVOICE** | Flujo normal (saludo → teléfono → detección existente → upload → OCR) | — |
| 6 | **PROCESS_INVOICE → REGISTER_PURCHASE** | OCR confidence: **0.90** ≥ 0.7 ✅ → `{ref:"FAC-2024-0624-002", products:[{ref:"Walmart prod", price:"850.00", quantity:"1"}]}` | "Factura procesada: Walmart, $850.00 MXN. Registrando compra..." |
| 7 | **REGISTER_PURCHASE → ✅ Éxito** | `POST /retail/buy` → `200` `{"invoice":{"ref":"FAC-2024-0624-002","points":85}, "participant":{"available_points":85}}` | "✅ Compra registrada. Has ganado 85 puntos. Aprobando tu participación..." |
| 8 | **ACCEPT_ENTRY → Intento 1** | `POST /entries/accept` body: `{api_key, campaign, id:"entry_n2o3p4q5"}` | ⏱️ Timeout o respuesta **500** |
| 9 | **ACCEPT_ENTRY → Intento 2** | Retry #1 — backoff 1s | ⏱️ Respuesta **503** (Service Unavailable) |
| 10 | **ACCEPT_ENTRY → Intento 3** | Retry #2 — backoff 2s | ⏱️ Respuesta **500** |
| 11 | **ACCEPT_ENTRY → Intento 4** | Retry #3 — backoff 4s | ⏱️ Respuesta **500** |
| 12 | **→ ERROR (con compra preservada)** | `retry_count ≥ max_retries (3)` — `purchase_id: "pur_m4n5o6p7"` PERSISTE en la sesión | "⚠️ Tu compra por $850.00 MXN fue registrada exitosamente (folio: FAC-2024-0624-002), pero no pudimos completar la aprobación automática debido a un problema temporal.\n\n✅ **Tu compra está segura** — No pierdes tus puntos. Un administrador revisará y aprobará tu participación manualmente en las próximas horas.\n\nSi tienes dudas, contacta a soporte con tu ID de compra: pur_m4n5o6p7" |

### Validaciones Clave
- `purchase_id = "pur_m4n5o6p7"` debe **persistir** en la sesión incluso en estado ERROR
- La compra **NO** se pierde — existe en Superlikers con status `"pending_approval"`
- El estado ERROR debe ser informativo y no destructivo
- Se debe proporcionar un `purchase_id` que el usuario pueda引用 al contactar a soporte
- El administrador debe poder aprobar manualmente la entrada usando el `purchase_id` y `participant_id`
- El sistema no debe destruir la sesión ni los datos de la compra al entrar en ERROR

### Datos de la Compra (segundo ticket)
| Campo | Valor |
|-------|-------|
| Establecimiento | Walmart Supercenter |
| Monto | $850.00 MXN |
| Fecha | 2026-06-24 |
| invoice_ref | FAC-2024-0624-002 |
| photo_id | photo_n2o3p4q5 |
| purchase_id | pur_m4n5o6p7 |
| participant_id | part_f8a3b2c1 |
| Puntos | 85 |

## Actual Result
_Pendiente de captura_

## Status
Draft

## Evidence
_Pendiente de captura_
