# Plan de Pruebas — Chatbot WhatsApp + Superlikers

## Objetivo

Validar el flujo conversacional completo del chatbot, incluyendo casos felices, casos borde y escenarios de error.

---

## 1. Usuario Nuevo — Flujo Completo

### Descripción
Un usuario nuevo sin registro previo completa el flujo de principio a fin.

### Precondiciones
- No existe participante con ese teléfono en Superlikers
- OpenAI / API responde correctamente

### Pasos
| # | Acción | Respuesta Esperada |
|---|--------|-------------------|
| 1 | Enviar mensaje: "Hola" | Saludo + solicitud de número |
| 2 | Enviar: "521234567890" | Confirmación + solicitud de nombre |
| 3 | Enviar: "Juan Pérez" | Confirmación + solicitud de email |
| 4 | Enviar: "juan@example.com" | Resumen de datos + confirmación |
| 5 | Enviar: "Sí" | Registro exitoso + solicitud de ticket |
| 6 | Enviar imagen (ticket válido) | Confirmación de recepción + "procesando..." |
| 7 | — | Mensaje con puntos obtenidos |

### Criterio de Éxito
El usuario recibe sus puntos y llega al estado FINISHED.

---

## 2. Usuario Existente — Skip de Registro

### Descripción
Un usuario ya registrado salta los pasos de registro.

### Precondiciones
- Existe participante con ese teléfono en Superlikers

### Pasos
| # | Acción | Respuesta Esperada |
|---|--------|-------------------|
| 1 | Enviar mensaje inicial | Saludo + solicitud de número |
| 2 | Enviar teléfono registrado | "Bienvenido de nuevo, Juan" + solicitud de ticket |
| 3 | Enviar imagen del ticket | Confirmación + puntos |

### Criterio de Éxito
El usuario no pasa por WAIT_NAME/WAIT_EMAIL/WAIT_CONFIRMATION.

---

## 3. Factura Ilegible — Reintento

### Descripción
El usuario envía una foto que la IA no puede procesar.

### Precondiciones
- Usuario en estado WAIT_TICKET o PROCESS_INVOICE

### Pasos
| # | Acción | Respuesta Esperada |
|---|--------|-------------------|
| 1 | Enviar imagen borrosa/oscura | "No pude leer la factura" |
| 2 | — | "Por favor envía una foto más clara" |
| 3 | Enviar imagen de mejor calidad | Procesamiento exitoso |

### Criterio de Éxito
El sistema permite reintento sin perder el estado de la sesión. Máximo 3 reintentos antes de escalar a soporte.

---

## 4. Imagen Duplicada

### Descripción
El usuario envía la misma foto del ticket dos veces.

### Precondiciones
- Usuario ya subió una foto exitosamente

### Pasos
| # | Acción | Respuesta Esperada |
|---|--------|-------------------|
| 1 | Enviar la misma imagen de nuevo | "Esta factura ya fue registrada" |
| 2 | — | Mostrar datos de la compra existente |

### Criterio de Éxito
No se duplica la compra, se informa al usuario del registro previo.

---

## 5. Factura Duplicada (Mismo Folio)

### Descripción
El usuario sube una imagen diferente pero con el mismo folio/número de factura que una ya registrada.

### Precondiciones
- Compra previa registrada con ese folio

### Pasos
| # | Acción | Respuesta Esperada |
|---|--------|-------------------|
| 1 | Enviar nueva imagen (mismo folio) | "Esta factura ya fue registrada anteriormente" |
| 2 | — | Mostrar fecha y monto de la compra original |

### Criterio de Éxito
La API retorna 409 y el flujo lo maneja sin crear duplicados.

---

## 6. Timeout de API

### Descripción
La API de Superlikers no responde dentro del tiempo esperado.

### Precondiciones
- API de Superlikers temporalmente no disponible

### Pasos
| # | Acción | Respuesta Esperada |
|---|--------|-------------------|
| 1 | Cualquier paso que dependa de API | Timeout (5s) |
| 2 | — | Reintento automático (max 3) |
| 3 | — | "El servicio está temporalmente fuera de línea" |
| 4 | — | "Por favor intenta de nuevo en unos minutos" |

### Criterio de Éxito
Se implementa retry con backoff exponencial: 5s, 15s, 45s. Si fallan los 3 intentos, el flujo pasa a ERROR con mensaje amigable.

---

## 7. Error de Aprobación

### Descripción
La aprobación de la entrada falla por un error del servidor.

### Precondiciones
- Compra registrada exitosamente

### Pasos
| # | Acción | Respuesta Esperada |
|---|--------|-------------------|
| 1 | PUT /activities/.../entries falla | Mensaje de error controlado |
| 2 | Reintento automático | Segundo intento |
| 3 | Si persiste | "Tu compra está registrada, recibirás los puntos en breve" + escalar a soporte |

### Criterio de Éxito
La compra no se pierde aunque la aprobación falle. El participante puede ser aprobado manualmente después.

---

## 8. Número Inválido

### Descripción
El usuario ingresa un número de teléfono con formato incorrecto.

### Pasos
| # | Acción | Respuesta Esperada |
|---|--------|-------------------|
| 1 | Enviar: "123" (muy corto) | "El número debe tener al menos 10 dígitos" |
| 2 | Enviar: "abc" (no dígitos) | "Por favor ingresa solo números" |
| 3 | Enviar: "521234567890123" (muy largo) | "El número no puede exceder 15 dígitos" |
| 4 | Enviar formato correcto | Continuar flujo normalmente |

### Criterio de Éxito
Validación de formato antes de llamar a la API.

---

## 9. Email Inválido

### Descripción
El usuario ingresa un email con formato incorrecto.

### Pasos
| # | Acción | Respuesta Esperada |
|---|--------|-------------------|
| 1 | Enviar: "invalido" | "El formato del email no es válido" |
| 2 | Enviar: "test@" | "El formato del email no es válido" |
| 3 | Enviar email válido | Continuar flujo |

### Criterio de Éxito
Validación con regex antes de continuar.

---

## 10. Formato de Imagen Incorrecto

### Descripción
El usuario envía un archivo que no es una imagen.

### Pasos
| # | Acción | Respuesta Esperada |
|---|--------|-------------------|
| 1 | Enviar documento PDF | "Por favor envía una foto (JPEG o PNG)" |
| 2 | Enviar archivo de video | "Por favor envía una foto (JPEG o PNG)" |
| 3 | Enviar imagen JPEG/PNG | Continuar flujo |

### Criterio de Éxito
Validación de tipo MIME antes de procesar.

---

## Resumen de Cobertura

| Escenario | Tipo | Prioridad | Automatable |
|-----------|------|-----------|-------------|
| Usuario nuevo | Happy path | Crítica | Sí |
| Usuario existente | Happy path | Crítica | Sí |
| Factura ilegible | Error recovery | Alta | Sí |
| Imagen duplicada | Validación | Alta | Sí |
| Factura duplicada | Validación | Alta | Sí |
| Timeout API | Error recovery | Alta | Parcial |
| Error aprobación | Error recovery | Media | Sí |
| Número inválido | Validación input | Crítica | Sí |
| Email inválido | Validación input | Alta | Sí |
| Formato imagen | Validación input | Alta | Sí |
