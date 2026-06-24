# Arquitectura General — Chatbot WhatsApp + n8n

## Visión General

Sistema de automatización para concursos y promociones vía WhatsApp, construido sobre **n8n** como orquestador central. Los usuarios interactúan mediante mensajes de WhatsApp, y n8n gestiona el flujo conversacional, la integración con la API de Superlikers, y el procesamiento de facturas con IA.

## Componentes

| Componente | Rol | Tecnología |
|-----------|-----|------------|
| **WhatsApp Business API** | Canal de entrada/salida de mensajes | Meta WhatsApp Cloud API |
| **n8n** | Orquestador del flujo conversacional | n8n + Docker |
| **MCP Server (n8n)** | Gestión programática de workflows | MCP Protocol |
| **Superlikers API** | Backend de participantes, compras, actividades | REST API |
| **OpenAI / Claude** | Extracción de datos de facturas (OCR + NLP) | API de Vision + Chat Completions |
| **Webhook Receiver** | Endpoint para recibir mensajes de WhatsApp | n8n Webhook node |
| **Persistencia Local** | Estado de sesión del usuario | n8n Workflow Data / JSON local |

## Diagrama de Arquitectura

```
┌────────────────────────────────────────────────────────────┐
│                      WhatsApp Cloud API                     │
│  (Mensajes del usuario → Webhook configurado en Meta)      │
└────────────────────────┬───────────────────────────────────┘
                         │ POST (mensaje entrante)
                         ▼
┌────────────────────────────────────────────────────────────┐
│                    n8n Orchestrator                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐ │
│  │ Webhook       │→│ State Machine │→│ HTTP Request     │ │
│  │ Receiver      │  │ (Conversación)│  │ (Superlikers API)│ │
│  └──────────────┘  └──────────────┘  └──────────────────┘ │
│                           │                                │
│  ┌───────────────────────▼──────────────────────────────┐  │
│  │            AI Processing Layer                        │  │
│  │  ┌─────────────────┐  ┌──────────────────────────┐  │  │
│  │  │ OpenAI Vision   │  │ Message Classifier       │  │  │
│  │  │ (Invoice OCR)   │  │ (Intención del usuario)  │  │  │
│  │  └─────────────────┘  └──────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────┘  │
└────────────────────────┬───────────────────────────────────┘
                         │ GET/POST/PUT
                         ▼
┌────────────────────────────────────────────────────────────┐
│                 Superlikers API (v1)                        │
│  ┌────────────┐  ┌────────────┐  ┌──────────────────────┐ │
│  │ Participants│  │ Purchases  │  │ Activities           │ │
│  └────────────┘  └────────────┘  └──────────────────────┘ │
└────────────────────────────────────────────────────────────┘
```

## Flujo de Datos

```
1. Usuario envía mensaje de WhatsApp
2. Meta reenvía POST al webhook de n8n
3. n8n recibe el mensaje y lo clasifica
4. n8n recupera o crea la sesión del usuario
5. Según el estado actual, n8n ejecuta la lógica correspondiente:
   a. Solicitar número de celular
   b. Buscar/registrar participante en Superlikers API
   c. Solicitar foto del ticket
   d. Procesar factura con OpenAI Vision
   e. Registrar compra
   f. Aprobar actividad
   g. Informar puntos
6. n8n responde al usuario vía WhatsApp
7. La sesión se actualiza y persiste
```

## Dependencias

| Dependencia | Versión | Propósito |
|-------------|---------|-----------|
| n8n | latest (Docker) | Orquestación de workflows |
| Docker Engine | 24+ | Contenedorización |
| Docker Compose | v2+ | Orquestación de servicios |
| Node.js | 18+ | Entorno n8n |
| OpenAI API | N/A | Procesamiento de facturas |
| Superlikers API | v1 | Datos de campaña |

## Decisiones Técnicas

| Decisión | Opción | Justificación |
|----------|--------|---------------|
| Orquestador | **n8n** | Bajo código, fácil mantenimiento, ideal para flujos conversacionales con branching |
| Contenedorización | **Docker + Compose** | Entorno reproducible, fácil deploy, aislamiento |
| Procesamiento IA | **OpenAI Vision** | Soporte nativo para imágenes de tickets, mejor accuracy en OCR |
| Estado de sesión | **n8n In-Memory + JSON Backup** | Simple, sin dependencias externas; para producción usar Redis |
| API Key | **Header-based** | Sencillo, estándar REST, sin overhead de OAuth |

## Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Timeout de API externa | Alto | Implementar retry con backoff exponencial |
| Factura ilegible | Medio | Solicitar nueva foto, guiar al usuario |
| Límite de tasa WhatsApp | Medio | Controlar rate de mensajes, colas |
| Fallo de OpenAI | Medio | Fallback a Claude, mensaje de error amigable |
| Estado inconsistente | Alto | Validar transiciones, logging detallado |
