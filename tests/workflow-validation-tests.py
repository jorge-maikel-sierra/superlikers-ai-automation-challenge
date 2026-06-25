#!/usr/bin/env python3
"""
Suite de Tests de Validación del Workflow Corregido
Valida que todos los nodos críticos estén configurados correctamente
"""
import json
import sys
from typing import Dict, List, Tuple

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def load_workflow(path: str) -> Dict:
    """Carga el workflow JSON"""
    with open(path, 'r') as f:
        data = json.load(f)
        return data[0] if isinstance(data, list) else data

def test_search_participant(nodes: List[Dict]) -> Tuple[bool, str]:
    """Test: Search Participant debe usar GET con api_key de env"""
    node = next((n for n in nodes if n.get('name') == 'Search Participant'), None)
    
    if not node:
        return False, "Nodo 'Search Participant' no encontrado"
    
    params = node.get('parameters', {})
    method = params.get('method', '')
    json_body = params.get('jsonBody', '')
    
    errors = []
    
    if method != 'GET':
        errors.append(f"Método debe ser GET, encontrado: {method}")
    
    if 'SUPERLIKERS_API_KEY' not in json_body:
        errors.append("No usa $env.SUPERLIKERS_API_KEY")
    
    if '"state"' not in json_body and "'state'" not in json_body:
        errors.append("Falta campo query.state")
    
    if errors:
        return False, "; ".join(errors)
    
    return True, "GET configurado, usa env var, incluye state"

def test_register_participant(nodes: List[Dict]) -> Tuple[bool, str]:
    """Test: Register Participant debe tener body completo"""
    node = next((n for n in nodes if n.get('name') == 'Register Participant'), None)
    
    if not node:
        return False, "Nodo 'Register Participant' no encontrado"
    
    params = node.get('parameters', {})
    method = params.get('method', '')
    json_body = params.get('jsonBody', '')
    
    errors = []
    
    if method != 'POST':
        errors.append(f"Método debe ser POST, encontrado: {method}")
    
    required_fields = ['api_key', 'campaign', 'properties', 'active', 'verified_cellphone', 'verified_email']
    for field in required_fields:
        if field not in json_body:
            errors.append(f"Falta campo: {field}")
    
    if errors:
        return False, "; ".join(errors)
    
    return True, "POST con todos los campos requeridos"

def test_upload_ticket(nodes: List[Dict]) -> Tuple[bool, str]:
    """Test: Upload Ticket debe usar multipart/form-data"""
    node = next((n for n in nodes if n.get('name') == 'Upload Ticket API'), None)
    
    if not node:
        return False, "Nodo 'Upload Ticket API' no encontrado"
    
    params = node.get('parameters', {})
    method = params.get('method', '')
    content_type = params.get('contentType', '')
    
    errors = []
    
    if method != 'POST':
        errors.append(f"Método debe ser POST, encontrado: {method}")
    
    if 'multipart' not in content_type.lower():
        errors.append(f"ContentType debe ser multipart/form-data, encontrado: {content_type}")
    
    if errors:
        return False, "; ".join(errors)
    
    return True, "POST con multipart/form-data configurado"

def test_process_invoice(nodes: List[Dict]) -> Tuple[bool, str]:
    """Test: Process Invoice debe tener prompt de IA configurado"""
    node = next((n for n in nodes if n.get('name') == 'Process Invoice'), None)
    
    if not node:
        return False, "Nodo 'Process Invoice' no encontrado"
    
    params = node.get('parameters', {})
    method = params.get('method', '')
    json_body = params.get('jsonBody', '')
    
    errors = []
    
    if method != 'POST':
        errors.append(f"Método debe ser POST, encontrado: {method}")
    
    if not json_body:
        errors.append("No tiene jsonBody configurado")
    elif 'model' not in json_body:
        errors.append("Falta campo 'model'")
    elif 'messages' not in json_body:
        errors.append("Falta campo 'messages'")
    elif 'response_format' not in json_body:
        errors.append("Falta response_format para JSON")
    
    if errors:
        return False, "; ".join(errors)
    
    return True, "Configurado con modelo, prompt y response_format"

def test_register_purchase(nodes: List[Dict]) -> Tuple[bool, str]:
    """Test: Register Purchase debe tener body con productos dinámicos"""
    node = next((n for n in nodes if n.get('name') == 'Register Purchase'), None)
    
    if not node:
        return False, "Nodo 'Register Purchase' no encontrado"
    
    params = node.get('parameters', {})
    method = params.get('method', '')
    json_body = params.get('jsonBody', '')
    
    errors = []
    
    if method != 'POST':
        errors.append(f"Método debe ser POST, encontrado: {method}")
    
    required_fields = ['api_key', 'campaign', 'distinct_id', 'ref', 'products']
    for field in required_fields:
        if field not in json_body:
            errors.append(f"Falta campo: {field}")
    
    if errors:
        return False, "; ".join(errors)
    
    return True, "POST con ref y productos configurados"

def test_accept_entry(nodes: List[Dict]) -> Tuple[bool, str]:
    """Test: Accept Entry debe usar entry_id de la sesión"""
    node = next((n for n in nodes if n.get('name') == 'Accept Entry'), None)
    
    if not node:
        return False, "Nodo 'Accept Entry' no encontrado"
    
    params = node.get('parameters', {})
    method = params.get('method', '')
    json_body = params.get('jsonBody', '')
    
    errors = []
    
    if method != 'POST':
        errors.append(f"Método debe ser POST, encontrado: {method}")
    
    if 'entry_id' not in json_body:
        errors.append("No usa session.entry_id")
    
    if errors:
        return False, "; ".join(errors)
    
    return True, "POST con entry_id de sesión"

def test_image_size_validator(nodes: List[Dict]) -> Tuple[bool, str]:
    """Test: Debe existir validador de tamaño de imagen"""
    node = next((n for n in nodes if n.get('name') == 'Image Size Validator'), None)
    
    if not node:
        return False, "Nodo 'Image Size Validator' no encontrado"
    
    js_code = node.get('parameters', {}).get('jsCode', '')
    
    if 'MAX_SIZE' not in js_code and '10' not in js_code:
        return False, "No valida límite de 10MB"
    
    return True, "Validador de 10MB presente"

def test_upload_result_duplicates(nodes: List[Dict]) -> Tuple[bool, str]:
    """Test: Upload Result debe manejar Sha1 duplicado"""
    node = next((n for n in nodes if n.get('name') == 'Upload Result'), None)
    
    if not node:
        return False, "Nodo 'Upload Result' no encontrado"
    
    js_code = node.get('parameters', {}).get('jsCode', '')
    
    if 'Sha1 is already taken' not in js_code:
        return False, "No maneja error de imagen duplicada"
    
    if 'entry_id' not in js_code:
        return False, "No captura entry_id de la respuesta"
    
    return True, "Maneja duplicados y captura entry_id"

def test_purchase_result_duplicates(nodes: List[Dict]) -> Tuple[bool, str]:
    """Test: Purchase Result debe manejar ref duplicado"""
    node = next((n for n in nodes if n.get('name') == 'Purchase Result'), None)
    
    if not node:
        return False, "Nodo 'Purchase Result' no encontrado"
    
    js_code = node.get('parameters', {}).get('jsCode', '')
    
    if 'ref already taken' not in js_code:
        return False, "No maneja error de factura duplicada"
    
    return True, "Maneja factura duplicada"

def test_entry_result_execution_error(nodes: List[Dict]) -> Tuple[bool, str]:
    """Test: Entry Result debe manejar execution_error"""
    node = next((n for n in nodes if n.get('name') == 'Entry Result'), None)
    
    if not node:
        return False, "Nodo 'Entry Result' no encontrado"
    
    js_code = node.get('parameters', {}).get('jsCode', '')
    
    if 'execution_error' not in js_code:
        return False, "No maneja execution_error"
    
    return True, "Maneja execution_error correctamente"

def test_retry_limit(nodes: List[Dict]) -> Tuple[bool, str]:
    """Test: Validadores deben tener límite de retry_count"""
    validators = ['Phone Validator', 'Name Handler', 'Email Validator', 'Invoice Validator']
    
    missing = []
    for validator_name in validators:
        node = next((n for n in nodes if n.get('name') == validator_name), None)
        if not node:
            missing.append(f"{validator_name} no encontrado")
            continue
        
        js_code = node.get('parameters', {}).get('jsCode', '')
        if 'MAX_RETRIES' not in js_code and 'retry_count >= 3' not in js_code:
            missing.append(f"{validator_name} sin límite de retry")
    
    if missing:
        return False, "; ".join(missing)
    
    return True, f"Todos los validadores tienen límite de retry"

def run_all_tests(workflow_path: str):
    """Ejecuta todos los tests"""
    print(f"{Colors.BOLD}{'='*80}{Colors.RESET}")
    print(f"{Colors.BOLD}  SUITE DE VALIDACIÓN DEL WORKFLOW CORREGIDO{Colors.RESET}")
    print(f"{Colors.BOLD}{'='*80}{Colors.RESET}\n")
    
    print(f"📂 Cargando workflow: {workflow_path}\n")
    
    try:
        workflow = load_workflow(workflow_path)
        nodes = workflow.get('nodes', [])
        print(f"✓ Workflow cargado: {len(nodes)} nodos\n")
    except Exception as e:
        print(f"{Colors.RED}✗ Error cargando workflow: {e}{Colors.RESET}")
        return 1
    
    tests = [
        ("1. Search Participant (GET + env var)", test_search_participant),
        ("2. Register Participant (POST + body)", test_register_participant),
        ("3. Upload Ticket (multipart)", test_upload_ticket),
        ("4. Process Invoice (IA configurada)", test_process_invoice),
        ("5. Register Purchase (productos dinámicos)", test_register_purchase),
        ("6. Accept Entry (entry_id)", test_accept_entry),
        ("7. Image Size Validator (10MB)", test_image_size_validator),
        ("8. Upload Result (duplicados Sha1)", test_upload_result_duplicates),
        ("9. Purchase Result (duplicados ref)", test_purchase_result_duplicates),
        ("10. Entry Result (execution_error)", test_entry_result_execution_error),
        ("11. Retry Limit (MAX_RETRIES)", test_retry_limit),
    ]
    
    print(f"{Colors.BOLD}TESTS DE CONFIGURACIÓN:{Colors.RESET}\n")
    
    passed = 0
    failed = 0
    
    for name, test_func in tests:
        success, message = test_func(nodes)
        
        if success:
            print(f"  {Colors.GREEN}✓{Colors.RESET} {name}")
            print(f"    {Colors.BLUE}→{Colors.RESET} {message}")
            passed += 1
        else:
            print(f"  {Colors.RED}✗{Colors.RESET} {name}")
            print(f"    {Colors.RED}→{Colors.RESET} {message}")
            failed += 1
        print()
    
    print(f"{Colors.BOLD}{'='*80}{Colors.RESET}\n")
    print(f"{Colors.BOLD}RESUMEN:{Colors.RESET}")
    print(f"  {Colors.GREEN}✓ {passed} tests pasaron{Colors.RESET}")
    if failed > 0:
        print(f"  {Colors.RED}✗ {failed} tests fallaron{Colors.RESET}")
    print(f"\n{Colors.BOLD}Total: {passed}/{len(tests)} ({100*passed//len(tests)}%){Colors.RESET}\n")
    
    if failed == 0:
        print(f"{Colors.GREEN}{Colors.BOLD}🎉 ¡TODOS LOS TESTS PASARON!{Colors.RESET}")
        print(f"{Colors.GREEN}El workflow está listo para ser importado a n8n.{Colors.RESET}\n")
        return 0
    else:
        print(f"{Colors.YELLOW}⚠️  Algunos tests fallaron. Revisa la configuración.{Colors.RESET}\n")
        return 1

if __name__ == '__main__':
    workflow_path = sys.argv[1] if len(sys.argv) > 1 else \
        '/Users/jorgesierra/Documents/dev/superlikers-ai-automation-challenge/n8n/workflows/participant-onboarding-v2-corrected.json'
    
    sys.exit(run_all_tests(workflow_path))
