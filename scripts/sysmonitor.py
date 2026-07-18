#!/usr/bin/env python3
"""
financas-sysmonitor — background system watcher
Alerts immediately on CPU/memory spikes or thermal warnings.
Writes ~/.financas-system-status.json for the dashboard to read.
No sudo needed.
"""

import subprocess, time, json, os, sys
from datetime import datetime

# ── Thresholds ───────────────────────────────
CPU_WARN    = 80   # %
CPU_CRIT    = 95   # %
MEM_WARN    = 80   # %
MEM_CRIT    = 92   # %
INTERVAL    = 20   # seconds between checks
STATUS_FILE = os.path.expanduser("~/.financas-system-status.json")

# State — avoid repeat alerts
_last_alert = {}

def notify(title: str, body: str, sound: str = "Basso"):
    script = f'display notification "{body}" with title "{title}" sound name "{sound}"'
    subprocess.run(["osascript", "-e", script], capture_output=True)

def alert(key: str, title: str, body: str, cooldown: int = 120):
    now = time.time()
    if now - _last_alert.get(key, 0) > cooldown:
        notify(title, body)
        _last_alert[key] = now
        print(f"[ALERT] {title}: {body}")

def get_cpu() -> float:
    try:
        r = subprocess.run(
            ["top", "-l", "2", "-n", "0", "-s", "0.5"],
            capture_output=True, text=True, timeout=8
        )
        for line in reversed(r.stdout.split("\n")):
            if "CPU usage" in line:
                idle = float(line.split("idle")[0].split(",")[-1].strip().replace("%", ""))
                return round(100.0 - idle, 1)
    except Exception as e:
        print(f"[cpu] {e}")
    return 0.0

def get_memory() -> float:
    try:
        r = subprocess.run(["memory_pressure"], capture_output=True, text=True, timeout=5)
        for line in r.stdout.split("\n"):
            if "System-wide memory free percentage" in line:
                free = float(line.split(":")[1].strip().replace("%", ""))
                return round(100.0 - free, 1)
    except Exception as e:
        print(f"[mem] {e}")
    return 0.0

def get_thermal_level() -> int:
    """0=normal 1=fair 2=serious 3=critical — no sudo needed"""
    try:
        r = subprocess.run(
            ["sysctl", "machdep.xcpm.cpu_thermal_level"],
            capture_output=True, text=True, timeout=2
        )
        return int(r.stdout.split(":")[1].strip())
    except:
        return 0

THERMAL_LABELS = {0: "Normal", 1: "Elevada", 2: "Séria", 3: "Crítica ⚠"}

def write_status(cpu: float, mem: float, thermal: int):
    status = {
        "cpu":      cpu,
        "memory":   mem,
        "thermal":  THERMAL_LABELS.get(thermal, "?"),
        "thermal_level": thermal,
        "ollama":   is_port_open(11434),
        "lmstudio": is_port_open(1234),
        "ts":       datetime.now().strftime("%H:%M:%S")
    }
    try:
        with open(STATUS_FILE, "w") as f:
            json.dump(status, f)
    except:
        pass

def is_port_open(port: int) -> bool:
    import socket
    try:
        with socket.create_connection(("localhost", port), timeout=0.5):
            return True
    except:
        return False

# ── Main loop ────────────────────────────────
print(f"[sysmonitor] started — interval {INTERVAL}s — thresholds CPU>{CPU_WARN}% MEM>{MEM_WARN}%")

while True:
    try:
        cpu     = get_cpu()
        mem     = get_memory()
        thermal = get_thermal_level()

        write_status(cpu, mem, thermal)
        print(f"[{datetime.now().strftime('%H:%M:%S')}] CPU:{cpu}%  MEM:{mem}%  Thermal:{THERMAL_LABELS[thermal]}")

        # ── CPU alerts
        if cpu >= CPU_CRIT:
            alert("cpu_crit", "🔴 CPU Crítica", f"CPU em {cpu}% — feche apps pesados", cooldown=60)
        elif cpu >= CPU_WARN:
            alert("cpu_warn", "🟡 CPU Alta", f"CPU em {cpu}%", cooldown=120)

        # ── Memory alerts
        if mem >= MEM_CRIT:
            alert("mem_crit", "🔴 Memória Crítica", f"RAM em {mem}% — feche modelos LLM", cooldown=60)
        elif mem >= MEM_WARN:
            alert("mem_warn", "🟡 Memória Alta", f"RAM em {mem}%", cooldown=120)

        # ── Thermal alerts
        if thermal >= 3:
            alert("thermal_crit", "🌡 Temperatura Crítica", "Mac superaquecendo — pause processamento", cooldown=60)
        elif thermal >= 2:
            alert("thermal_warn", "🌡 Temperatura Elevada", "Thermal throttling ativo — pode ficar lento", cooldown=180)

    except Exception as e:
        print(f"[loop error] {e}")

    time.sleep(INTERVAL)
