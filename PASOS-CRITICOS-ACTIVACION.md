# 🚨 PASOS CRÍTICOS PARA ACTIVAR WORKFLOW V2

## ⚠️ PROBLEMA ACTUAL

El workflow "Participant Onboarding v1" (el VIEJO con errores) está activo.  
El workflow v2-IMPORT (el CORREGIDO) está importado pero NO activo.

---

## ✅ SOLUCIÓN PASO A PASO (Exactos)

### Paso 1: Abrir n8n
- URL: http://localhost:5678
- Iniciar sesión si es necesario

### Paso 2: Ver todos los workflows
- Click en el menú lateral izquierdo: **"Workflows"** (ícono de lista)
- Deberías ver TODOS los workflows importados

### Paso 3: DESACTIVAR el workflow v1
1. Busca en la lista: **"Participant Onboarding v1"**
2. Puede que veas VARIOS workflows con nombres similares
3. El que está ACTIVO tendrá un indicador verde o toggle ON
4. Click en ese workflow para abrirlo
5. En la esquina superior derecha, busca el **toggle "Active"**
6. Click para **DESACTIVARLO** (debe ponerse en gris/rojo)
7. Confirma que dice "Workflow deactivated"

### Paso 4: Identificar el workflow v2 importado
En la lista de workflows, busca:
- Puede llamarse "Participant Onboarding v1" (n8n usa el nombre del JSON)
- Pero será el MÁS RECIENTE (fecha de importación más nueva)
- O puede tener un número de versión diferente

**CÓMO IDENTIFICAR EL CORRECTO:**
1. Abre cada workflow con nombre similar
2. El workflow CORRECTO (v2) tiene **39 nodos**
3. Debe tener un nodo llamado **"Image Size Validator"**
4. Los nodos HTTP Request (Search Participant, Register Participant, etc.) deben tener el `method` configurado

### Paso 5: ACTIVAR el workflow v2
1. Una vez identificado el workflow correcto (39 nodos + Image Size Validator)
2. Click en el **toggle "Active"** en la esquina superior derecha
3. Debe ponerse en verde/azul
4. Confirma que dice "Workflow activated"

### Paso 6: VERIFICAR que el webhook está registrado
Ejecuta este comando en terminal:

```bash
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```

**Respuesta correcta**: 200 OK o respuesta JSON (NO 404)  
**Respuesta incorrecta**: `{"code":404,"message":"The requested webhook..."}` ← Significa que el workflow NO está activo

---

## 🔍 ALTERNATIVA: Crear workflow nuevo desde cero

Si no puedes identificar cuál es el v2, haz esto:

### Opción A: Importar como nuevo workflow

1. En n8n UI, menú → **"Import from file"**
2. Selecciona: `participant-onboarding-v2-IMPORT.json`
3. **Antes de importar**: Cambia el nombre en el JSON
   - Abre el archivo en editor de texto
   - Cambia la línea: `"name": "Participant Onboarding v1"`
   - Por: `"name": "Participant Onboarding v2 CORREGIDO"`
   - Guarda el archivo
4. Importa el archivo modificado
5. Ahora será fácil identificarlo en la lista
6. Actívalo

### Opción B: Copiar nodos manualmente

Si la importación sigue fallando:

1. Abre el workflow v1 actual
2. Abre en otra pestaña el archivo JSON v2-IMPORT
3. Configura MANUALMENTE cada nodo HTTP Request:
   
   **Search Participant**:
   - Method: GET
   - Body: {ver CHANGELOG-V2.md línea 50}
   
   **Register Participant**:
   - Method: POST
   - Body: {ver CHANGELOG-V2.md línea 80}
   
   Y así con los demás...

---

## 📊 VERIFICACIÓN FINAL

Una vez activado el workflow correcto, ejecuta:

```bash
# Test 1: Webhook debe responder
curl -X POST "http://localhost:5678/webhook/whatsapp" -d '{"test":1}'

# Si responde 200 OK o JSON (no 404), continúa:

# Test 2: Mensaje de prueba
curl -X POST "http://localhost:5678/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -d '{
    "entry": [{
      "changes": [{
        "value": {
          "messages": [{
            "from": "+573001234567",
            "type": "text",
            "text": {"body": "Hola"}
          }]
        }
      }]
    }]
  }'
```

Luego revisa en n8n UI → Executions → Debería aparecer una ejecución nueva.

---

## ❓ SI NADA FUNCIONA

Avísame y haré una de estas opciones:

1. Configurar cada nodo del v1 actual para que funcione como el v2
2. Crear un script que active el workflow programáticamente
3. Exportar el v2 en un formato diferente

---

## 🎯 LO QUE ESTOY ESPERANDO

Que me confirmes UNO de estos:

- [ ] "Activé un workflow que tiene 39 nodos y un nodo llamado Image Size Validator"
- [ ] "El curl al webhook ahora responde 200 OK (no 404)"
- [ ] "No encuentro el workflow v2 en la lista"
- [ ] "La importación sigue dando error: [mensaje de error]"

Necesito saber exactamente qué ves para continuar con las pruebas.

---

**Última actualización**: 25 de junio de 2026, 00:27
