# 🔧 Configuración Manual de Nodos - Opción C

Ya que el workflow v1 está activo y no podemos cambiar al v2, vamos a configurar manualmente cada nodo del v1 para que funcione correctamente.

---

## 📋 INSTRUCCIONES PASO A PASO

### 1️⃣ Nodo: Search Participant

**Ubicación**: Después de "Session Load"

**Configuración actual**: POST con api_key hardcoded

**Cambiar a**:

1. Abrir el nodo "Search Participant"
2. **Method**: Cambiar de `POST` a `GET`
3. **Body/JSON Body**: Cambiar por esto:

```json
{
  "api_key": "={{ $env.SUPERLIKERS_API_KEY }}",
  "campaign": "3z",
  "query": {
    "cellphone": "{{ $json.session.local_phone || $json.localPhone || '' }}",
    "state": "active"
  }
}
```

4. Guardar (Ctrl+S)

---

### 2️⃣ Nodo: Register Participant

**Ubicación**: Después de "Confirmation Handler"

**Configuración actual**: Nodo vacío

**Configurar**:

1. Abrir el nodo "Register Participant"
2. **Method**: `POST`
3. **Send Body**: ✓ Activar
4. **Content-Type**: `JSON`
5. **Specify Body**: `Using JSON`
6. **JSON Body**:

```json
{
  "api_key": "={{ $env.SUPERLIKERS_API_KEY }}",
  "campaign": "3z",
  "properties": {
    "email": "={{ $json.session.email }}",
    "celular": "={{ $json.session.local_phone }}",
    "name": "={{ $json.session.name }}"
  },
  "active": true,
  "verified_cellphone": true,
  "verified_email": true,
  "not_send_verify_registration": true
}
```

7. Guardar

---

### 3️⃣ Nodo: Upload Ticket API

**Ubicación**: Después de "Rename Binary"

**Configurar**:

1. Abrir el nodo "Upload Ticket API"
2. **Method**: `POST`
3. **Send Body**: ✓ Activar
4. **Body Content Type**: `Multipart Form Data`
5. **Body Parameters** → Add Parameter (6 veces):
   - Name: `api_key`, Value: `={{ $env.SUPERLIKERS_API_KEY }}`
   - Name: `campaign`, Value: `3z`
   - Name: `distinct_id`, Value: `={{ $json.session.email }}`
   - Name: `title`, Value: `Ticket de compra`
   - Name: `category`, Value: `tickets`
6. **Send Binary Data**: ✓ Activar
7. **Binary Property**: `upload_photo`
8. Guardar

---

### 4️⃣ Nodo: Process Invoice

**Ubicación**: Después de "Upload Result"

**Configurar**:

1. Abrir el nodo "Process Invoice"
2. **Method**: `POST`
3. **Send Body**: ✓ Activar
4. **Content-Type**: `JSON`
5. **JSON Body**: (COPIAR TODO ESTO)

```json
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "system",
      "content": "Eres un asistente que extrae información de facturas de compra a partir de una imagen. Devuelve ÚNICAMENTE un objeto JSON válido, sin texto adicional, sin explicaciones y sin bloques de código markdown.\n\nEstructura exacta a devolver:\n{\n  \"legible\": true,\n  \"ref\": \"<numero de factura>\",\n  \"products\": [\n    { \"ref\": \"<codigo o nombre>\", \"price\": \"<precio unitario>\",\n      \"quantity\": \"<cantidad>\", \"line\": \"<linea opcional>\",\n      \"provider\": \"<proveedor opcional>\" }\n  ],\n  \"confidence_score\": 0.95\n}\n\nReglas:\n- Si la imagen NO es una factura legible o falta el número de factura o los productos, devuelve {\"legible\": false, \"confidence_score\": 0}.\n- price y quantity siempre como string numérico, sin símbolos de moneda ni separadores de miles.\n- No inventes datos que no aparezcan en la factura.\n- confidence_score del 0 al 1 según tu confianza en la extracción."
    },
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "Extrae los datos de esta factura en el formato JSON especificado. IMPORTANTE: devuelve SOLO JSON válido, sin texto adicional."
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "{{ $json.photo_url }}"
          }
        }
      ]
    }
  ],
  "response_format": { "type": "json_object" },
  "temperature": 0.1,
  "max_tokens": 1000
}
```

6. Guardar

---

### 5️⃣ Nodo: Register Purchase

**Ubicación**: Después de "Invoice Validator"

**Configurar**:

1. Abrir el nodo "Register Purchase"
2. **Method**: `POST`
3. **Send Body**: ✓ Activar
4. **Content-Type**: `JSON`
5. **Specify Body**: `Using JSON`
6. **JSON Body**:

```json
={
  "api_key": "{{ $env.SUPERLIKERS_API_KEY }}",
  "campaign": "3z",
  "distinct_id": "{{ $json.session.email }}",
  "ref": "{{ $json.invoice_data.ref }}",
  "products": {{ $json.invoice_data.products ? JSON.stringify($json.invoice_data.products) : '[]' }}
}
```

7. Guardar

---

### 6️⃣ Nodo: Accept Entry

**Ubicación**: Después de "Purchase Result"

**Configurar**:

1. Abrir el nodo "Accept Entry"
2. **Method**: `POST`
3. **Send Body**: ✓ Activar
4. **Content-Type**: `JSON`
5. **JSON Body**:

```json
{
  "api_key": "={{ $env.SUPERLIKERS_API_KEY }}",
  "campaign": "3z",
  "id": "={{ $json.session.entry_id }}"
}
```

6. Guardar

---

## ✅ CHECKLIST DE VERIFICACIÓN

Después de configurar todos los nodos:

- [ ] Guardar el workflow (Ctrl+S o Cmd+S)
- [ ] Verificar que el toggle "Active" esté ON
- [ ] Probar el webhook:

```bash
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{"test": "ping"}'
```

**Debe responder 200 OK (no 404)**

---

## 🎯 SIGUIENTE PASO

Una vez configurados todos los nodos, ejecutar prueba completa:

```bash
cd /Users/jorgesierra/Documents/dev/superlikers-ai-automation-challenge
./tests/simulate-flow.sh
```

---

**Tiempo estimado**: 10-15 minutos de configuración manual

**Alternativa más rápida**: Decirme "hazlo tú" y yo edito directamente los archivos del workflow en el contenedor de n8n.
