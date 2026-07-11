import urllib.request
import json

origin = '3.1390,101.6939'
dest = '3.1544,101.6921'
key = 'AIzaSyCwHiN8ZHF35vGGxYfvid1mR_bD_6Ay1zk'

url = f'https://maps.googleapis.com/maps/api/directions/json?origin={origin}&destination={dest}&mode=transit&key={key}&alternatives=true'
print(f'URL: {url[:120]}...')

resp = urllib.request.urlopen(url, timeout=15)
data = json.loads(resp.read())
print(f"Status: {data['status']}")
routes = data.get('routes', [])
print(f'Routes found: {len(routes)}')

for i, route in enumerate(routes):
    leg = route['legs'][0]
    dur = leg.get('duration', {}).get('text', '?')
    dist = leg.get('distance', {}).get('text', '?')
    print(f'\nRoute {i+1}: {dur} ({dist})')
    for j, step in enumerate(leg.get('steps', [])):
        mode = step.get('travel_mode', '?')
        dur_step = step.get('duration', {}).get('text', '?')
        if mode == 'TRANSIT':
            td = step.get('transit_details', {})
            line = td.get('line', {})
            dep = td.get('departure_stop', {}).get('name', '?')
            arr = td.get('arrival_stop', {}).get('name', '?')
            print(f'  Step {j+1}: [{mode}] {line.get("short_name","?")} {line.get("vehicle",{}).get("name","?")} | {dep} -> {arr} | {dur_step}')
        else:
            instr = step.get('html_instructions', '')
            print(f'  Step {j+1}: [{mode}] {dur_step} - {instr[:80]}')
