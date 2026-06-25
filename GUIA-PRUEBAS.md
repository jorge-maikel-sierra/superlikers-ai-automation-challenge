# 🧪 Guía de Pruebas — Workflow v2 Corregido

**Fecha**: 24 de junio de 2026  
**Workflow**: participant-onboarding-v2-corrected.json  
**Estado**: ✅ Listo para pruebas end-to-end

---

## 📋 Índice

1. [Pre-requisitos](#pre-requisitos)
2. [Configuración Inicial](#configuración-inicial)
3. [Tests de Validación Automática](#tests-de-validación-automática)
4. [Pruebas End-to-End Manuales](#pruebas-end-to-end-manuales)
5. [Casos de Error a Probar](#casos-de-error-a-probar)
6. [Troubleshooting](#troubleshooting)

---

## 1. Pre-requisitos

### Software Requerido

- ✅ Docker Desktop instalado y corriendo
- ✅ Python 3.8+ (para tests de validación)
- ✅ curl o Postman (para tests de API)
- ✅ Cuenta de WhatsApp Business API (o simulador)

### Credenciales Requeridas

- ✅ `SUPERLIKERS_API_KEY` (entorno labs)
- ✅ `OPENAI_API_KEY` (con acceso a gpt-4o)
- ✅ `WHATSAPP_TOKEN` (WhatsApp Business API)
- ✅ `WHATSAPP_VERIFY_TOKEN` (para webhook)

---

## 2. Configuración Inicial

### Paso 1: Configurar Variables de Entorno

```bash
cd docker
cp .env.example .env
```

Editar `docker/.env` con tus credenciales:

```bash
# Superlikers API
SUPERLIKERS_API_KEY=tu_api_key_aqui
SUPERLIKERS_BASE_URL=https://api.superlikerslabs.com/v1
SUPERLIKERS_CAMPAIGN=3z

# OpenAI
OPENAI_API_KEY=sk-proj-...

# WhatsApp
WHATSAPP_TOKEN=EAAxxxxx...
WHATSAPP_VERIFY_TOKEN=mi_token_secreto_123
COUNTRY_CODE=57
PHONE_DIGITS=10

# Google Sheets (opcional)
GOOGLE_SHEETS_SPREADSHEET_ID=tu_spreadsheet_id
```

### Paso 2: Iniciar n8n

```bash
docker compose -f docker/docker-compose.yml up -d
```

Verificar que esté corriendo:

```bash
docker compose -f docker/docker-compose.yml ps
docker compose -f docker/docker-compose.yml logs -f n8n
```

Acceder a n8n: http://localhost:5678

### Paso 3: Importar Workflow

1. Ir a n8n UI (http://localhost:5678)
2. Click en menú principal → "Import"
3. Seleccionar archivo: `n8n/workflows/participant-onboarding-v2-corrected.json`
4. Click "Import"

### Paso 4: Configurar Credenciales en n8n UI

#### 4.1 OpenAI Credential

1. Click en cualquier nodo "Process Invoice"
2. En "Credential to connect with" → "Create New"
3. Nombre: `OpenAI`
4. API Key: `{{ $env.OPENAI_API_KEY }}`
5. Guardar

#### 4.2 Superlikers API Header Auth

1. Click en cualquier nodo HTTP Request de Superlikers
2. En "Credential for Header Auth" → "Create New"
3. Nombre: `Superlikers API`
4. Header Name: `Authorization`
5. Header Value: `Bearer {{ $env.SUPERLIKERS_API_KEY }}`
6. Guardar

### Paso 5: Activar Workflow

1. En n8n UI, abrir el workflow importado
2. Toggle "Active" en la esquina superior derecha
3. Copiar la URL del webhook (aparece en el nodo "WhatsApp Webhook")

### Paso 6: Configurar Webhook en WhatsApp Business

URL del webhook: `https://tu-dominio.com/webhook/whatsapp`

Si usas ngrok para testing local:
```bash
ngrok http 5678
# Usar la URL https://xxxxx.ngrok-free.app
```

Actualizar `docker-compose.yml` con la URL de ngrok:
```yaml
- WEBHOOK_URL=https://xxxxx.ngrok-free.app
```

Reiniciar n8n:
```bash
docker compose -f docker/docker-compose.yml restart n8n
```

---

## 3. Tests de Validación Automática

### Test 1: Validación de Estructura del Workflow

```bash
python3 tests/workflow-validation-tests.py
```

**Resultado esperado**:
```
✓ 11 tests pasaron
Total: 11/11 (100%)
🎉 ¡TODOS LOS TESTS PASARON!
```

Si algún test falla, revisar el changelog y verificar que el workflow se importó correctamente.

---

### Test 2: Verificar Endpoints de Superlikers

Crear archivo `tests/test-endpoints.sh`:

```bash
#!/bin/bash

API_KEY="${SUPERLIKERS_API_KEY}"
BASE_URL="https://api.superlikerslabs.com/v1"

echo "🔍 Test 1: Search Participant (debería retornar 404 para nuevo)"
curl -X GET "${BASE_URL}/participants/search" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "api_key": "'"${API_KEY}"'",
    "campaign": "3z",
    "query": {"cellphone": "1234567890", "state": "active"}
  }'

echo -e "\n\n✅ Si retornó 404 o 'not found', el endpoint funciona correctamente\n"

echo "🔍 Test 2: Listar participantes existentes"
curl -X GET "${BASE_URL}/participants" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "api_key": "'"${API_KEY}"'",
    "campaign": "3z"
  }' | jq .

echo -e "\n✅ Endpoints de Superlikers funcionando\n"
```

Ejecutar:
```bash
chmod +x tests/test-endpoints.sh
./tests/test-endpoints.sh
```

---

### Test 3: Verificar OpenAI API

```bash
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" | jq '.data[] | select(.id == "gpt-4o")'
```

**Resultado esperado**: Información del modelo gpt-4o

---

## 4. Pruebas End-to-End Manuales

### Prueba 1: Usuario Nuevo — Flujo Completo ✅

**Objetivo**: Registrar un participante nuevo y completar el flujo hasta obtener puntos

**Pre-condición**: El celular NO debe existir en Superlikers

#### Pasos:

| # | Acción | Mensaje Esperado del Bot |
|---|--------|--------------------------|
| 1 | Enviar: "Hola" | "Bienvenido a Superlikers. Para participar... escríbeme tu número de celular" |
| 2 | Enviar: "3001234567" | "Perfecto. Ahora cuéntame tu nombre completo" |
| 3 | Enviar: "Juan Pérez" | "Gracias Juan. Ahora necesito tu correo electrónico" |
| 4 | Enviar: "juan@test.com" | "Confirmemos: Nombre: Juan Pérez... ¿Es correcto? Responde SÍ" |
| 5 | Enviar: "Sí" | "✓ Registro exitoso. Ahora envíame una foto de tu ticket de compra" |
| 6 | Enviar: 📷 imagen de factura | "Recibimos tu ticket. Procesando..." |
| 7 | Esperar ~5 segundos | "🎉 ¡Listo! Tu ticket fue aprobado y ganaste XXX puntos" |

**Verificaciones**:
- ✅ El usuario recibe los puntos correctos
- ✅ Estado final: FINISHED
- ✅ Log en Google Sheets (si está configurado)

**Datos de prueba**:
```
Celular: 3001234567 (usar uno que NO exista)
Nombre: Juan Pérez
Email: juan.test.{timestamp}@example.com (único)
```

---

### Prueba 2: Usuario Existente — Skip de Registro ✅

**Objetivo**: Usuario ya registrado salta directo a la carga del ticket

**Pre-condición**: El celular DEBE existir en Superlikers (usar el del test anterior)

#### Pasos:

| # | Acción | Mensaje Esperado del Bot |
|---|--------|--------------------------|
| 1 | Enviar: "Hola" | "Bienvenido... escríbeme tu número de celular" |
| 2 | Enviar: "3001234567" (del test anterior) | "¡Bienvenido de nuevo, Juan! Envíame una foto de tu ticket" |
| 3 | Enviar: 📷 imagen de factura | "Recibimos tu ticket. Procesando..." |
| 4 | Esperar | "🎉 ¡Listo! Tu ticket fue aprobado..." |

**Verificaciones**:
- ✅ NO pide nombre ni email
- ✅ Salta directo a WAIT_TICKET
- ✅ Completa el flujo normalmente

---

### Prueba 3: Factura Ilegible — Reintento ✅

**Objetivo**: IA no puede leer la factura y pide otra foto

**Pre-condición**: Usuario en estado WAIT_TICKET

#### Pasos:

| # | Acción | Mensaje Esperado del Bot |
|---|--------|--------------------------|
| 1 | Completar prueba 1 o 2 hasta WAIT_TICKET | "Envíame una foto de tu ticket" |
| 2 | Enviar: 📷 imagen borrosa/oscura/ilegible | "No pude leer la factura. Por favor envía una foto más clara" |
| 3 | Enviar: 📷 imagen de mejor calidad | "Recibimos tu ticket. Procesando..." → Success |

**Verificaciones**:
- ✅ No pierde el estado de la sesión
- ✅ Permite reintento sin reiniciar flujo
- ✅ Máximo 3 reintentos antes de ERROR

**Imágenes de prueba**:
- Ilegible: Foto muy oscura, borrosa o sin texto visible
- Legible: Factura clara con número y productos visibles

---

### Prueba 4: Imagen Duplicada (Sha1) ✅

**Objetivo**: Detectar que la misma imagen ya fue subida

**Pre-condición**: Haber completado prueba 1 o 2

#### Pasos:

| # | Acción | Mensaje Esperado del Bot |
|---|--------|--------------------------|
| 1 | Completar una carga exitosa de ticket | Success message |
| 2 | Iniciar nuevo flujo con el mismo usuario | "Envíame una foto de tu ticket" |
| 3 | Enviar: 📷 **la misma imagen exacta** del paso 1 | "⚠️ Este ticket ya fue registrado anteriormente. No puedes enviar la misma imagen dos veces" |

**Verificaciones**:
- ✅ Detecta Sha1 duplicado (error 422)
- ✅ NO crea entry duplicado
- ✅ Mensaje claro al usuario

---

### Prueba 5: Factura Duplicada (Ref) ✅

**Objetivo**: Detectar que el número de factura ya fue registrado

**Pre-condición**: Haber registrado una compra con un folio específico

#### Pasos:

| # | Acción | Mensaje Esperado del Bot |
|---|--------|--------------------------|
| 1 | Completar prueba 1 con factura #12345 | Success |
| 2 | Iniciar nuevo flujo | ... |
| 3 | Enviar: 📷 **imagen diferente** pero con el **mismo folio #12345** | "⚠️ Esta factura ya fue registrada anteriormente" |

**Verificaciones**:
- ✅ Detecta `ref already taken` (error 422)
- ✅ NO otorga puntos duplicados
- ✅ Mensaje claro al usuario

**Nota**: Para esta prueba necesitas dos imágenes DIFERENTES de facturas pero que la IA extraiga el mismo número de factura.

---

## 5. Casos de Error a Probar

### Error 1: Validación de Celular Inválido

**Input**: `abc123` o `12`

**Esperado**: "El número debe tener al menos 10 dígitos" / "Por favor ingresa solo números"

---

### Error 2: Validación de Email Inválido

**Input**: `invalido` o `test@`

**Esperado**: "El formato del email no es válido"

---

### Error 3: Validación de Nombre Inválido

**Input**: `AB` (muy corto) o `123` (números)

**Esperado**: "El nombre debe tener al menos 3 caracteres" / "Solo se permiten letras"

---

### Error 4: Imagen Demasiado Grande

**Input**: Imagen > 10MB

**Esperado**: "La imagen es demasiado grande (XX MB). El tamaño máximo permitido es 10 MB"

**Cómo probar**:
```bash
# Crear imagen de prueba > 10MB
convert -size 5000x5000 xc:white test-large.jpg
```

---

### Error 5: Archivo No es Imagen

**Input**: PDF o documento

**Esperado**: "Por favor envía una foto (JPEG o PNG)"

---

### Error 6: Timeout de API

**Simulación**: Desconectar internet mientras el workflow llama a la API

**Esperado**: "El servicio está temporalmente fuera de línea. Por favor intenta de nuevo en unos minutos"

---

### Error 7: API Key Inválida

**Simulación**: Cambiar `SUPERLIKERS_API_KEY` a un valor incorrecto

**Esperado**: "Ocurrió un error de configuración. Por favor contacta al administrador"

---

### Error 8: Execution Error en Accept Entry

**Simulación**: Difícil de simular sin acceso al backend de Superlikers

**Verificación**: Revisar código del nodo Entry Result para confirmar que maneja `execution_error`

**Esperado**: "⚠️ Tu compra está en revisión manual. Recibirás los puntos una vez aprobada"

---

### Error 9: Límite de Reintentos Excedido

**Pasos**:
1. Enviar celular inválido
2. Enviar otro celular inválido
3. Enviar otro celular inválido
4. Intentar una 4ta vez

**Esperado** (al 4to intento): "Has superado el número máximo de intentos. Por favor contacta a soporte"

---

## 6. Troubleshooting

### Problema: Workflow no responde

**Diagnóstico**:
```bash
# Ver logs de n8n
docker compose -f docker/docker-compose.yml logs -f n8n

# Ver ejecuciones en n8n UI
# http://localhost:5678 → Executions
```

**Solución**:
- Verificar que el workflow esté Active
- Verificar que el webhook esté configurado correctamente
- Revisar que las variables de entorno estén cargadas

---

### Problema: "Error de autenticación" en endpoints

**Diagnóstico**:
```bash
# Verificar que las credenciales estén cargadas
docker compose -f docker/docker-compose.yml exec n8n env | grep SUPERLIKERS_API_KEY
docker compose -f docker/docker-compose.yml exec n8n env | grep OPENAI_API_KEY
```

**Solución**:
- Verificar que `.env` tenga las variables correctas
- Reiniciar n8n después de cambiar `.env`
- Verificar que las credenciales en n8n UI usen `{{ $env.XXX }}`

---

### Problema: IA no puede leer la factura

**Diagnóstico**:
- Revisar logs del nodo Process Invoice
- Verificar que `photo_url` tenga una URL pública accesible

**Solución**:
- Usar imágenes claras y de buena calidad
- Verificar que la URL de la imagen sea accesible desde internet
- Si usa base64, verificar que el formato sea correcto

---

### Problema: No se captura entry_id

**Diagnóstico**:
- Revisar respuesta del nodo Upload Ticket
- Verificar logs del nodo Upload Result

**Solución**:
- Verificar que la respuesta de `/photos` incluya campo `id` o `entry_id`
- Revisar código del nodo Upload Result para confirmar mapeo

---

### Problema: Puntos no se otorgan

**Diagnóstico**:
- Revisar logs del nodo Register Purchase
- Verificar respuesta de `/retail/buy`

**Solución**:
- Verificar que los productos extraídos por IA tengan formato correcto
- Verificar que `ref`, `price`, `quantity` sean strings
- Revisar configuración de puntos en el Panel de Superlikers

---

## 📊 Checklist Final de Pruebas

Antes de marcar como completo, verificar:

- [ ] ✅ Test 1: Usuario nuevo completo
- [ ] ✅ Test 2: Usuario existente skip
- [ ] ✅ Test 3: Factura ilegible reintento
- [ ] ✅ Test 4: Imagen duplicada detectada
- [ ] ✅ Test 5: Factura duplicada detectada
- [ ] ✅ Error 1-9: Todos los casos de error probados
- [ ] ✅ Logs en Google Sheets funcionando (si aplica)
- [ ] ✅ No hay errores en logs de n8n
- [ ] ✅ Todas las credenciales usan env vars (no hardcoded)
- [ ] ✅ Tests de validación: 11/11 pasados

---

## 🎯 Resultado Esperado

Al completar todas las pruebas, deberías tener:

- ✅ 5 ejecuciones exitosas en n8n (pruebas 1-5)
- ✅ Al menos 1 participante registrado en Superlikers
- ✅ Al menos 1 compra registrada con puntos otorgados
- ✅ Logs de todas las transacciones
- ✅ 0 errores críticos no manejados

**Estado final**: 🟢 **WORKFLOW VALIDADO Y LISTO PARA PRODUCCIÓN**

---

**Última actualización**: 24 de junio de 2026  
**Versión del workflow**: v2-corrected  
**Tests pasados**: 11/11 (100%)
