# Plan de Implementación — n8n Chatbot WhatsApp

## Visión General

Plan de construcción del workflow de n8n dividido en 9 fases incrementales. Cada fase produce un workflow funcional y testeable de forma independiente.

---

## Estrategia de Implementación

```
Fase 1 ──► Fase 2 ──► Fase 3 ──► Fase 4 ──► Fase 5 ──► Fase 6 ──► Fase 7 ──► Fase 8 ──► Fase 9
               │                     │                     │
               ▼                     ▼                     ▼
           Workflow parcial      Workflow parcial      Workflow completo
           (búsqueda + registro) (ticket + compra)     + logging + testing
```

### Principios
1. **Cada fase es autónoma** — se puede probar de forma independiente
2. **Una fase no comienza hasta que la anterior está verificada**
3. **Mock de dependencias externas** al inicio, reemplazar con APIs reales progresivamente
4. **Logging desde la Fase 1** — no esperar a la Fase 8 para instrumentar
5. **Testing manual por fase** — verificar con casos reales antes de avanzar

---

## Fase 1: Session Manager

### Objetivo
Workflow base que recibe mensajes de WhatsApp, gestiona sesiones y enruta según estado.

### Dependencias
- n8n corriendo en Docker
- Webhook expuesto (ngrok o tunnel similar)
- Configuración básica de WhatsApp Cloud API

### Tareas
```
[ ] 1.1 Crear Webhook Receiver (GET/POST handler)
[ ] 1.2 Crear Message Parser (normalizar payload)
[ ] 1.3 Implementar Session Manager (CRUD sesiones)
[ ] 1.4 Implementar State Router (switch por estado)
[ ] 1.5 Implementar Message Builder (templates de respuesta)
[ ] 1.6 Implementar Send WhatsApp Node
[ ] 1.7 Configurar persistencia (Data Store + JSON)
```

### Riesgos
| Riesgo | Mitigación |
|--------|------------|
| Webhook no accesible desde Meta | Usar ngrok para desarrollo local |
| Token de WhatsApp inválido | Verificar en Meta Developer Console |

### Criterios de Aceptación
- Webhook responde 200 a GET (verificación) y POST (mensajes)
- Sesión se crea al recibir primer mensaje
- Sesión se recupera en mensajes subsiguientes
- Estado START → envía saludo → transiciona a WAIT_PHONE
- Sesión expira después de 30 min de inactividad
- Logging: cada operación registrada

---

## Fase 2: Búsqueda de Participante

### Objetivo
Workflow que valida el teléfono, busca al participante en Superlikers API y bifurca entre registro o ticket.

### Dependencias
- Fase 1 completa y verificada
- API Key de Superlikers configurada
- Acceso a endpoint `participants/search`

### Tareas
```
[ ] 2.1 Implementar Phone Validator (formato + normalización)
[ ] 2.2 Crear Search Participant (HTTP Request a Superlikers)
[ ] 2.3 Implementar bifurcación: encontrado → WAIT_TICKET / no encontrado → WAIT_NAME
[ ] 2.4 Manejar errores de API (404, 429, 5xx)
[ ] 2.5 Agregar reintentos con backoff exponencial
```

### Riesgos
| Riesgo | Mitigación |
|--------|------------|
| API de Superlikers no disponible | Mock interno para desarrollo |
| Formato de teléfono inconsistente | Normalización agresiva (solo dígitos + E.164) |

### Criterios de Aceptación
- Teléfono de 10 dígitos es aceptado y normalizado a +52
- Teléfono con formato inválido recibe mensaje de error
- Participante existente (200) → flujo continúa a WAIT_TICKET
- Participante no encontrado (404) → flujo continúa a WAIT_NAME
- Error 429 → reintenta con backoff
- Error 5xx → reintenta máximo 3 veces

---

## Fase 3: Registro de Participante

### Objetivo
Workflow que recolecta nombre, email, confirmación y registra nuevo participante.

### Dependencias
- Fase 2 completa y verificada
- API Key de Superlikers configurada
- Acceso a endpoint `POST /participants`

### Tareas
```
[ ] 3.1 Implementar Name Validator
[ ] 3.2 Implementar Email Validator
[ ] 3.3 Implementar Confirmation Router (sí/no)
[ ] 3.4 Crear Register Participant (HTTP Request)
[ ] 3.5 Implementar flujo de corrección (si usuario dice "no")
```

### Riesgos
| Riesgo | Mitigación |
|--------|------------|
| Usuario ingresa datos inconsistentes | Validación en cada campo + confirmación final |
| Email inválido pasa validación | Regex estricto + pruebas con casos borde |

### Criterios de Aceptación
- Nombre se valida (>3 caracteres, solo letras)
- Email se valida (regex estándar)
- Confirmación funciona con "sí", "si", "yes", "no"
- Si confirma → POST a Superlikers → WAIT_TICKET
- Si no confirma → vuelve a WAIT_NAME
- Error de API → ERROR con reintento

---

## Fase 4: Subida de Ticket

### Objetivo
Workflow que recibe la imagen del ticket, la descarga de WhatsApp y la sube a Superlikers API.

### Dependencias
- Fase 3 completa (o Fase 2 para participantes existentes)
- API Key de Superlikers configurada
- Token de WhatsApp con permiso `whatsapp_business_messaging`

### Tareas
```
[ ] 4.1 Validar tipo de mensaje (debe ser imagen)
[ ] 4.2 Descargar imagen de WhatsApp (GET media)
[ ] 4.3 Validar formato (JPEG/PNG) y tamaño (max 10MB)
[ ] 4.4 Subir imagen a Superlikers (POST /tickets/upload)
[ ] 4.5 Guardar photo_id en sesión
[ ] 4.6 Manejar error: texto en vez de imagen → re-pedir
```

### Riesgos
| Riesgo | Mitigación |
|--------|------------|
| Imagen muy pesada (>10MB) | Validar tamaño antes de subir |
| Media ID expirado | WhatsApp media expira en horas; el usuario debe reenviar |

### Criterios de Aceptación
- Mensaje de texto en WAIT_TICKET → re-pedir imagen
- Imagen válida → se descarga y sube
- Upload exitoso → photo_id guardado → PROCESS_INVOICE
- Upload fallido → ERROR con mensaje amigable

---

## Fase 5: Procesamiento de Factura (IA)

### Objetivo
Workflow que envía la imagen a OpenAI Vision, extrae datos estructurados y valida la respuesta.

### Dependencias
- Fase 4 completa y verificada
- API Key de OpenAI configurada
- Modelo `gpt-4o` o `gpt-4o-mini` disponible

### Tareas
```
[ ] 5.1 Construir prompt de sistema para extracción de facturas
[ ] 5.2 Crear HTTP Request a OpenAI Vision API
[ ] 5.3 Validar respuesta JSON (campos requeridos)
[ ] 5.4 Calcular confidence score
[ ] 5.5 Bifurcar por nivel de confianza (>= 0.7 automático / < 0.7 pedir nueva foto)
[ ] 5.6 Manejar errores: timeout, JSON inválido, baja confianza
```

### Riesgos
| Riesgo | Mitigación |
|--------|------------|
| Costo de API de OpenAI | Usar gpt-4o-mini para desarrollo, monitorear uso |
| Respuesta inconsistente | Temperature = 0.1, response_format: json_object |
| Imagen no legible para IA | Guiar al usuario sobre cómo tomar la foto |

### Criterios de Aceptación
- OpenAI devuelve JSON con amount, date, merchant_name, items, total
- Confidence >= 0.7 → continúa a registro de compra
- Confidence < 0.7 → pide nueva foto
- Error de API → reintenta 1 vez
- JSON inválido → reintenta con prompt más estricto

---

## Fase 6: Registro de Compra

### Objetivo
Workflow que registra la compra en Superlikers API usando los datos extraídos por IA.

### Dependencias
- Fase 5 completa y verificada
- API Key de Superlikers configurada
- Acceso a endpoint `POST /purchases`

### Tareas
```
[ ] 6.1 Construir payload de purchase con datos de invoice + photo_id
[ ] 6.2 Crear HTTP Request a POST /purchases
[ ] 6.3 Manejar error 409 (compra duplicada)
[ ] 6.4 Guardar purchase_id y points_earned en sesión
```

### Criterios de Aceptación
- Compra registrada → purchase_id guardado → ACCEPT_ENTRY
- Compra duplicada (409) → mensaje "Ya registrada" → continuar a ACCEPT_ENTRY
- Error 4xx/5xx → ERROR con reintento

---

## Fase 7: Aprobación de Entry

### Objetivo
Workflow que aprueba la entrada del participante en la actividad y muestra los puntos obtenidos.

### Dependencias
- Fase 6 completa y verificada
- API Key de Superlikers configurada
- Acceso a endpoint `PUT /activities/{id}/entries`

### Tareas
```
[ ] 7.1 Obtener activity_id de la configuración
[ ] 7.2 Construir payload de entry (participant_id + purchase_id + approve)
[ ] 7.3 Crear HTTP Request a PUT /entries
[ ] 7.4 Calcular y mostrar puntos totales
[ ] 7.5 Mensaje de despedida / resumen final
```

### Criterios de Aceptación
- Entry aprobado → points_awarded mostrados al usuario
- Mensaje final con resumen de puntos
- Error → reintento con backoff

---

## Fase 8: Logging y Observabilidad

### Objetivo
Implementar logging estructurado en todos los nodos y generar métricas clave.

### Dependencias
- Fases 1-7 completas
- Estructura de directorios `/data/logs/` y `/data/metrics/`

### Tareas
```
[ ] 8.1 Implementar Logger Node centralizado
[ ] 8.2 Agregar logging operativo a todos los nodos
[ ] 8.3 Agregar logging de negocio en eventos clave
[ ] 8.4 Agregar logging de errores en todos los catch
[ ] 8.5 Implementar recolector de métricas
[ ] 8.6 Crear script de parseo de logs para dashboard CLI
```

### Criterios de Aceptación
- Cada nodo registra su operación (INFO)
- Eventos de negocio registrados con datos estructurados
- Errores registrados con tipo, código y contexto
- Métricas de negocio generadas al completar flujo

---

## Fase 9: Testing y Puesta a Punto

### Objetivo
Probar el flujo completo, corregir errores y documentar el sistema.

### Dependencias
- Fases 1-8 completas

### Tareas
```
[ ] 9.1 Probar flujo completo: usuario nuevo (registro → ticket → compra → puntos)
[ ] 9.2 Probar flujo completo: usuario existente (ticket → compra → puntos)
[ ] 9.3 Probar flujo de error: teléfono inválido
[ ] 9.4 Probar flujo de error: imagen no soportada
[ ] 9.5 Probar flujo de error: API de Superlikers caída
[ ] 9.6 Probar flujo de error: timeout de IA
[ ] 9.7 Probar flujo de error: compra duplicada (409)
[ ] 9.8 Probar expiración de sesión por timeout
[ ] 9.9 Verificar logging y métricas
[ ] 9.10 Documentar resultados y ajustes necesarios
```

### Criterios de Aceptación
- Flujo completo funciona de principio a fin
- Todos los casos de error manejados gracefulmente
- Logs y métricas generados correctamente
- Documentación de pruebas actualizada

---

## Diagrama de Dependencias entre Fases

```
Fase 1 (Session Manager)
  │
  ▼
Fase 2 (Búsqueda Participante)
  │
  ├──► Fase 3 (Registro) ──► Fase 4 (Ticket)
  │                              │
  └──► Fase 4 (Ticket) ◄────────┘
          │
          ▼
      Fase 5 (IA Factura)
          │
          ▼
      Fase 6 (Registro Compra)
          │
          ▼
      Fase 7 (Aprobación Entry)
          │
          ▼
      Fase 8 (Logging + Métricas)
          │
          ▼
      Fase 9 (Testing)
```

---

## Estimación de Esfuerzo

| Fase | Nodos Nuevos | Dependencias | Complejidad |
|------|-------------|--------------|-------------|
| Fase 1 | 6 | Media | Alta (setup inicial) |
| Fase 2 | 4 | Superlikers API | Media |
| Fase 3 | 5 | Superlikers API | Media |
| Fase 4 | 4 | WhatsApp + Superlikers APIs | Alta (manejo de imágenes) |
| Fase 5 | 3 | OpenAI API | Alta (prompt engineering) |
| Fase 6 | 2 | Superlikers API | Baja |
| Fase 7 | 2 | Superlikers API | Baja |
| Fase 8 | 2 | — | Media |
| Fase 9 | 0 | Todo lo anterior | Media |
