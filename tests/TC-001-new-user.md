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
| 2 | **WAIT_PHONE → SEARCH_PARTICIPANT** | `GET /participants/search` body: `{api_key, campaign, query:{cellphone:"521234567890", state:"active"}}` | Validación: 10 dígitos ✅ → Buscar participante |
| 3 | **SEARCH_PARTICIPANT → WAIT_NAME** | `404` `{"message": "not found"}` | "No te encontramos registrado. ¿Cuál es tu nombre completo?" |
| 4 | **WAIT_NAME → WAIT_EMAIL** | — | Validación: min 3 caracteres, solo letras ✅ → "Gracias María. ¿Cuál es tu correo electrónico?" |
| 5 | **WAIT_EMAIL → WAIT_CONFIRMATION** | — | Validación: formato email ✅ → "Confirma tus datos:\n- Nombre: María García Hernández\n- Email: maria.garcia@email.com\n¿Es correcto? (Sí/No)" |
| 6 | **WAIT_CONFIRMATION → REGISTER_PARTICIPANT** | — | Validación: "sí" ✅ → Registrando participante... |
| 7 | **REGISTER_PARTICIPANT → WAIT_TICKET** | `POST /participants` → `200` `{"message": "participant was successfully created"}` | "✅ ¡Registro exitoso! Ahora envía la foto de tu ticket de compra para participar." |
| 8 | **WAIT_TICKET → UPLOAD_TICKET** | — | Validación: es imagen JPEG, 1.2 MB < 10 MB ✅ → Subiendo imagen... |
| 9 | **UPLOAD_TICKET → PROCESS_INVOICE** | `POST /photos` (multipart, campo `upload_photo`) → `200` `{"id": "entry_d4e5f6a7", "url": "...", "image_url": "..."}` | "📄 Procesando tu factura con IA..." |
| 10 | **PROCESS_INVOICE → REGISTER_PURCHASE** | OCR confidence: **0.92** ≥ 0.7 ✅ → Extraído: `{ref:"FAC-0624-001", products:[{ref:"Producto Soriana", price:"1250.50", quantity:"1"}]}` | "Factura procesada. Registrando compra..." |
| 11 | **REGISTER_PURCHASE → ACCEPT_ENTRY** | `POST /retail/buy` → `200` `{"invoice":{"ref":"FAC-0624-001","points":125}, "participant":{"available_points":125}}` | "✅ Compra registrada. Has ganado 125 puntos. Aprobando tu participación..." |
| 12 | **ACCEPT_ENTRY → FINISHED** | `POST /entries/accept` body: `{api_key, campaign, id:"entry_d4e5f6a7"}` → `200` `{"ok":true, "data":{"state":"success", "execution_error":null}}` | "🎉 ¡Felicidades María! Has ganado **125 puntos**. ¡Buena suerte!" |

## Actual Result
_Pendiente de captura_

## Status
Draft

## Evidence
_Pendiente de captura_
