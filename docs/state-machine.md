# Máquina de Estados — Flujo Conversacional

## Diagrama

```
START ──► WAIT_PHONE ──► SEARCH_PARTICIPANT ──► WAIT_NAME
                                      │                     │
                                      ▼                     ▼
                               WAIT_EMAIL ←──────── WAIT_CONFIRMATION
                                      │
                                      ▼
                              REGISTER_PARTICIPANT
                                      │
                                      ▼
                               WAIT_TICKET ──► UPLOAD_TICKET
                                                     │
                                                     ▼
                                              PROCESS_INVOICE
                                                     │
                                                     ▼
                                              REGISTER_PURCHASE
                                                     │
                                                     ▼
                                               ACCEPT_ENTRY
                                                     │
                                                     ▼
                                                FINISHED
                                                     │
                                                     ▼
                                                ERROR ◄── (cualquier fallo)
```

## Definición de Estados

### START
| Campo | Valor |
|-------|-------|
| **Descripción** | Estado inicial del flujo |
| **Evento** | Primer mensaje del usuario |
| **Validaciones** | Ninguna |
| **Acción** | Enviar saludo + solicitar número de celular |
| **Siguiente estado** | WAIT_PHONE |

### WAIT_PHONE
| Campo | Valor |
|-------|-------|
| **Descripción** | Esperando que el usuario ingrese su número de celular |
| **Evento** | Mensaje de texto del usuario |
| **Validaciones** | Formato: solo dígitos, 10-15 caracteres |
| **Acción** | Buscar participante en Superlikers API |
| **Siguiente estado** | SEARCH_PARTICIPANT |

### SEARCH_PARTICIPANT
| Campo | Valor |
|-------|-------|
| **Descripción** | Buscando al participante en la API |
| **Evento** | Respuesta de Superlikers API |
| **Validaciones** | Código 200 (encontrado) vs 404 (no encontrado) |
| **Acción** | Si existe → informar datos; Si no → solicitar nombre |
| **Siguiente estado** | WAIT_NAME (nuevo) / WAIT_TICKET (existente) |

### WAIT_NAME
| Campo | Valor |
|-------|-------|
| **Descripción** | Esperando nombre completo del nuevo participante |
| **Evento** | Mensaje de texto |
| **Validaciones** | Min 3 caracteres, solo letras y espacios |
| **Acción** | Almacenar nombre temporal, solicitar email |
| **Siguiente estado** | WAIT_EMAIL |

### WAIT_EMAIL
| Campo | Valor |
|-------|-------|
| **Descripción** | Esperando email del nuevo participante |
| **Evento** | Mensaje de texto |
| **Validaciones** | Formato email válido (regex) |
| **Acción** | Almacenar email, mostrar resumen, pedir confirmación |
| **Siguiente estado** | WAIT_CONFIRMATION |

### WAIT_CONFIRMATION
| Campo | Valor |
|-------|-------|
| **Descripción** | Confirmación de datos del nuevo participante |
| **Evento** | Mensaje de texto (Sí / No) |
| **Validaciones** | "sí", "si", "yes", "no" normalizados |
| **Acción** | Sí → registrar en API; No → reiniciar |
| **Siguiente estado** | REGISTER_PARTICIPANT / WAIT_NAME |

### REGISTER_PARTICIPANT
| Campo | Valor |
|-------|-------|
| **Descripción** | Registrando nuevo participante en Superlikers API |
| **Evento** | Respuesta de API POST |
| **Validaciones** | Código 201 (creado) vs error |
| **Acción** | Guardar participant_id, solicitar foto del ticket |
| **Siguiente estado** | WAIT_TICKET / ERROR |

### WAIT_TICKET
| Campo | Valor |
|-------|-------|
| **Descripción** | Esperando foto del ticket de compra |
| **Evento** | Mensaje con imagen (type: image) |
| **Validaciones** | Formato: JPEG/PNG, tamaño máximo 10MB |
| **Acción** | Descargar imagen, subir a Superlikers API |
| **Siguiente estado** | UPLOAD_TICKET |

### UPLOAD_TICKET
| Campo | Valor |
|-------|-------|
| **Descripción** | Subiendo imagen del ticket a Superlikers API |
| **Evento** | Respuesta de API upload |
| **Validaciones** | Código 200 vs error, verificar photo_id |
| **Acción** | Enviar imagen a IA para extraer datos |
| **Siguiente estado** | PROCESS_INVOICE / ERROR |

### PROCESS_INVOICE
| Campo | Valor |
|-------|-------|
| **Descripción** | Extrayendo datos de la factura con IA |
| **Evento** | Respuesta de OpenAI Vision API |
| **Validaciones** | Campos: monto, fecha, establecimiento, items |
| **Acción** | Registrar compra en Superlikers API |
| **Siguiente estado** | REGISTER_PURCHASE |

### REGISTER_PURCHASE
| Campo | Valor |
|-------|-------|
| **Descripción** | Registrando compra en Superlikers API |
| **Evento** | Respuesta de API POST purchase |
| **Validaciones** | Código 201 vs error |
| **Acción** | Solicitar aprobación de actividad |
| **Siguiente estado** | ACCEPT_ENTRY / ERROR |

### ACCEPT_ENTRY
| Campo | Valor |
|-------|-------|
| **Descripción** | Aprobando entrada del participante en la actividad |
| **Evento** | Respuesta de API PUT activity |
| **Validaciones** | Código 200, verificar puntos otorgados |
| **Acción** | Calcular y mostrar puntos |
| **Siguiente estado** | FINISHED / ERROR |

### FINISHED
| Campo | Valor |
|-------|-------|
| **Descripción** | Flujo completado exitosamente |
| **Evento** | N/A (fin del flujo) |
| **Validaciones** | N/A |
| **Acción** | Mensaje de despedida con resumen de puntos |
| **Siguiente estado** | (sesión cerrada) |

### ERROR
| Campo | Valor |
|-------|-------|
| **Descripción** | Estado de error genérico |
| **Evento** | Cualquier fallo en el flujo |
| **Validaciones** | Clasificación del error (API, timeout, validación) |
| **Acción** | Mensaje amigable, opción de reintentar |
| **Siguiente estado** | Estado anterior (reintento) o FINISHED |

## Matriz de Transiciones

| Estado Actual | Evento Válido | Validación | Siguiente Estado |
|---------------|---------------|------------|------------------|
| START | mensaje inicial | - | WAIT_PHONE |
| WAIT_PHONE | texto | formato teléfono | SEARCH_PARTICIPANT |
| SEARCH_PARTICIPANT | API success (200) | exists | WAIT_TICKET |
| SEARCH_PARTICIPANT | API success (404) | not exists | WAIT_NAME |
| SEARCH_PARTICIPANT | API error | timeout/network | ERROR |
| WAIT_NAME | texto | min 3 chars | WAIT_EMAIL |
| WAIT_EMAIL | texto | email regex | WAIT_CONFIRMATION |
| WAIT_CONFIRMATION | texto | sí/no | REGISTER_PARTICIPANT |
| REGISTER_PARTICIPANT | API success (201) | - | WAIT_TICKET |
| REGISTER_PARTICIPANT | API error | - | ERROR |
| WAIT_TICKET | imagen | format/size | UPLOAD_TICKET |
| WAIT_TICKET | texto (no imagen) | - | WAIT_TICKET (re-pedir) |
| UPLOAD_TICKET | API success | - | PROCESS_INVOICE |
| UPLOAD_TICKET | API error | - | ERROR |
| PROCESS_INVOICE | AI success | campos válidos | REGISTER_PURCHASE |
| PROCESS_INVOICE | AI error/low confidence | - | WAIT_TICKET (re-intentar) |
| REGISTER_PURCHASE | API success (201) | - | ACCEPT_ENTRY |
| REGISTER_PURCHASE | API error | - | ERROR |
| ACCEPT_ENTRY | API success | - | FINISHED |
| ACCEPT_ENTRY | API error | - | ERROR |
| ERROR | reintento | - | estado anterior |
