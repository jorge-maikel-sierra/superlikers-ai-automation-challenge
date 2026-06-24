# TC-001: Usuario Nuevo — Flujo Completo

## Descripción
Validar el flujo completo de un usuario nuevo sin registro previo en Superlikers, desde el mensaje inicial hasta la obtención de puntos. El sistema debe guiar al usuario paso a paso a través de la captura de datos, registro, carga del ticket y aprobación de la entrada.

## Precondiciones
- No existe participante con el teléfono `521234567890` en Superlikers API
- OpenAI Vision API responde correctamente (OCR)
- Todas las APIs de Superlikers están operativas
- Usuario tiene una foto válida de un ticket de compra

## Input
| # | Tipo | Contenido |
|---|------|-----------|
| 1 | Texto | "Hola" |
| 2 | Texto | "521234567890" |
| 3 | Texto | "María García Hernández" |
| 4 | Texto | "maria.garcia@email.com" |
| 5 | Texto | "Sí" |
| 6 | Imagen | `soriana_ticket_1.jpg` (JPEG, 1.2 MB, 1920×2560 px) |
| 7 | — | (OCR procesa imagen automáticamente) |

## Expected Result

| Paso | Transición | API / Acción | Respuesta Esperada |
|------|------------|-------------|-------------------|
| 1 | **START → WAIT_PHONE** | — | "🎉 ¡Bienvenido a la promoción! Para participar, por favor ingresa tu número de celular a 10 dígitos (ejemplo: 5512345678)" |
| 2 | **WAIT_PHONE → SEARCH_PARTICIPANT** | `GET /campaigns/3z/participants/search?phone=521234567890` | Validación: 10 dígitos ✅ → Buscar participante |
| 3 | **SEARCH_PARTICIPANT → WAIT_NAME** | `404` `{"error": "participant_not_found"}` | "No te encontramos registrado. ¿Cuál es tu nombre completo?" |
| 4 | **WAIT_NAME → WAIT_EMAIL** | — | Validación: min 3 caracteres, solo letras ✅ → "Gracias María. ¿Cuál es tu correo electrónico?" |
| 5 | **WAIT_EMAIL → WAIT_CONFIRMATION** | — | Validación: formato email ✅ → "Confirma tus datos:\n- Nombre: María García Hernández\n- Teléfono: +52521234567890\n- Email: maria.garcia@email.com\n¿Es correcto? (Sí/No)" |
| 6 | **WAIT_CONFIRMATION → REGISTER_PARTICIPANT** | — | Validación: "sí" ✅ → Registrando participante... |
| 7 | **REGISTER_PARTICIPANT → WAIT_TICKET** | `POST /campaigns/3z/participants` → `201` `{"id": "part_f8a3b2c1"}` | "✅ ¡Registro exitoso! Ahora envía la foto de tu ticket de compra para participar. Aceptamos formatos JPEG y PNG (máx. 10 MB)." |
| 8 | **WAIT_TICKET → UPLOAD_TICKET** | — | Validación: es imagen JPEG, 1.2 MB < 10 MB, 1920×2560 > 500×500 ✅ → Subiendo imagen... |
| 9 | **UPLOAD_TICKET → PROCESS_INVOICE** | `POST /campaigns/3z/tickets/upload` → `200` `{"photo_id": "photo_d4e5f6a7"}` | "📄 Procesando tu factura con IA..." |
| 10 | **PROCESS_INVOICE → REGISTER_PURCHASE** | OCR confidence: **0.92** ≥ 0.7 ✅ → Datos extraídos: Soriana Híper, $1,250.50 MXN, 2026-06-24 | "Factura procesada:\n- Establecimiento: Soriana Híper\n- Monto: $1,250.50 MXN\n- Fecha: 2026-06-24\n- Artículos: 5\nRegistrando compra..." |
| 11 | **REGISTER_PURCHASE → ACCEPT_ENTRY** | `POST /campaigns/3z/purchases` → `201` `{"purchase_id": "pur_7b8c9d0e", "points_earned": 125}` | "✅ Compra registrada por $1,250.50 MXN. Has ganado 125 puntos. Aprobando tu participación..." |
| 12 | **ACCEPT_ENTRY → FINISHED** | `PUT /campaigns/3z/activities/3z/entries` → `200` `{"entry_id": "entry_x1y2z3a4", "status": "approved", "points_awarded": 125, "total_points": 125}` | "🎉 ¡Felicidades María! Has ganado **125 puntos** en esta actividad. Sigue participando para acumular más puntos. ¡Buena suerte!" |

## Actual Result
_Pendiente de captura_

## Status
Draft

## Evidence
_Pendiente de captura_
