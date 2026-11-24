"""Extrae los datos privados que hoy están escritos en el código y los guarda
en seed/seed.json (carpeta ignorada por git) para subirlos a Firestore.

Uso (una sola vez, antes de quitar los datos del código):
    python tool/extract_seed.py
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read(rel):
    with open(os.path.join(ROOT, rel), encoding='utf-8') as f:
        return f.read()


def fields(block):
    """Campos `nombre: 'valor'` / `nombre: "valor"` de un constructor Dart."""
    return {m.group(1): m.group(3) for m in re.finditer(r"(\w+):\s*(['\"])(.*?)\2", block)}


# --- Profesores (contacts_screen.dart) ---
teachers = []
for block in re.findall(r"Contact\((.*?)\),", read('lib/screens/contacts_screen.dart'), re.S):
    f = fields(block)
    if 'name' in f:
        teachers.append({
            'id': f['id'], 'name': f['name'], 'subject': f['subject'], 'email': f['email'],
            'phone': '' if f.get('phone') == 'Unknown' else f.get('phone', ''),
            'office': f['office'], 'imageAsset': f.get('imageAsset', ''),
        })

# --- Horarios por ubicación (default_schedules.dart) ---
src = read('lib/data/default_schedules.dart')
loc_getters = dict(re.findall(r"'(\w+)':\s*(\w+),", src.split('static List')[0]))
schedules = {}
for loc, getter in loc_getters.items():
    body = re.search(r"get " + getter + r" => \[(.*?)\n      \];", src, re.S).group(1)
    labs = []
    for lab_name, entries in re.findall(r"LabSchedule\(\s*labName:\s*'([^']*)',\s*entries:\s*\[(.*?)\]\s*,?\s*\)", body, re.S):
        rows = []
        for i, e in enumerate(re.findall(r"ScheduleEntry\((.*?)\),", entries, re.S)):
            f = fields(e)
            rows.append({'id': f'{loc}-{lab_name}-{i}', 'day': f['day'], 'startTime': f['startTime'],
                         'endTime': f['endTime'], 'subject': f['subject'], 'group': f['group'],
                         'teacher': f['teacher']})
        labs.append({'labName': lab_name, 'entries': rows})
    schedules[loc] = {'labs': labs}

# --- Encargados de laboratorio (map_provider.dart) ---
lab_staff = {}
mp = read('lib/providers/map_provider.dart')
for loc_block in re.split(r"\n      MapLocation\(", mp)[1:]:
    loc_id = re.search(r"id: '(\w+)'", loc_block).group(1)
    staff = []
    for lab in re.findall(r"LabInfo\((.*?)\),", loc_block, re.S):
        f = fields(lab)
        staff.append({'name': f['name'], 'inCharge': f.get('inCharge', ''), 'contact': f.get('contact', '')})
    if staff:
        lab_staff[loc_id] = {'labs': staff}

os.makedirs(os.path.join(ROOT, 'seed'), exist_ok=True)
# --- Guía de constancias (editable por admins desde Firestore) ---
guides = {
    'constancias': {
        'title': 'Solicitar constancia',
        'sitoUrl': 'http://sito.upjr.edu.mx/',
        'email': 'auxiliar_escolares@upjr.edu.mx',
        'subject': 'Solicitud de Constancia',
        'tipos': ['Con promedio general', 'Con promedio cuatrimestral', 'Con número de seguro social',
                  'Con Kardex académico', 'Con periodo vacacional', 'De egresado', 'Sencilla',
                  'Carta de presentación'],
        'cutoffHour': 12,
        'readyTime': '13:30',
        'source': 'PROCESO PARA SOLICITAR CONSTANCIAS 2026 (Control Escolar)',
    }
}

out = {'teachers': teachers, 'schedules': schedules, 'labStaff': lab_staff, 'guides': guides}
with open(os.path.join(ROOT, 'seed', 'seed.json'), 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
print(f"profesores: {len(teachers)} | horarios: "
      f"{ {k: sum(len(l['entries']) for l in v['labs']) for k, v in schedules.items()} } | "
      f"encargados: { {k: len(v['labs']) for k, v in lab_staff.items()} }")
