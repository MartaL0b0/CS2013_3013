import json
import time
import threading

import requests

BASE = 'http://briefthreat:8080'
API_BASE = f'{BASE}/api/v1'

def get_access_token():
    r = requests.post(f'{API_BASE}/auth/login', headers={'Content-Type': 'application/json'}, data=json.dumps({'username': 'root', 'password': 'root'}))
    r.raise_for_status()
    access = r.json()['access_token']
    return access

def test_jwt_expiry():
    access = get_access_token()
    r = requests.get(f'{API_BASE}/auth/login', headers={'Authorization': f'Bearer {access}'})
    r.raise_for_status()

    time.sleep(3)
    r = requests.get(f'{API_BASE}/auth/login', headers={'Authorization': f'Bearer {access}'})
    assert r.status_code == 401

def rl_req(access, results):
    def f():
        r = requests.get(f'{API_BASE}/auth/login', headers={'Authorization': f'Bearer {access}'})
        results.add(r.status_code)
    return f

def test_ratelimit():
    threads = []
    access = get_access_token()
    results = set()
    for i in range(30):
        t = threading.Thread(target=rl_req(access, results))
        t.start()
        threads.append(t)

    for t in threads:
        t.join()

    assert results == {200, 429}
