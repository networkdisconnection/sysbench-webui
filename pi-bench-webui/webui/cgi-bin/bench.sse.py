#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Cross-platform SSE CGI: run the platform script and stream its stdout line-by-line

import os, sys, subprocess, shlex, time

def is_head():
    return os.environ.get("REQUEST_METHOD","GET").upper() == "HEAD"

def write_headers():
    sys.stdout.write("Content-Type: text/event-stream; charset=utf-8\r\n")
    sys.stdout.write("Cache-Control: no-cache, no-store, must-revalidate\r\n")
    sys.stdout.write("Pragma: no-cache\r\n")
    sys.stdout.write("X-Content-Type-Options: nosniff\r\n\r\n")
    sys.stdout.flush()

if is_head():
    write_headers()
    sys.exit(0)

write_headers()

# Resolve platform runner
home = os.path.expanduser("~")
linux_script = os.path.join(home, "scripts", "pi-bench-lite.sh")
win_script   = os.path.join(home, "scripts", "pi-bench-lite.ps1")

is_windows = os.name == "nt" or sys.platform.startswith("win")

if is_windows:
    if not os.path.exists(win_script):
        sys.stdout.write("event: error\ndata: 找不到可執行腳本: %s\r\n\r\n" % win_script)
        sys.stdout.flush()
        sys.exit(0)
    cmd = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", win_script]
else:
    if not os.path.exists(linux_script):
        sys.stdout.write("event: error\ndata: 找不到可執行腳本: %s\r\n\r\n" % linux_script)
        sys.stdout.flush()
        sys.exit(0)
    cmd = ["bash", linux_script]

# Spawn
try:
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
except Exception as e:
    sys.stdout.write("event: error\ndata: 無法啟動腳本: %s\r\n\r\n" % str(e).replace("\r"," ").replace("\n"," "))
    sys.stdout.flush()
    sys.exit(0)

try:
    for line in proc.stdout:
        line = line.rstrip("\r\n")
        try:
            sys.stdout.write("data: %s\r\n\r\n" % line)
            sys.stdout.flush()
        except BrokenPipeError:
            # client disconnected
            try:
                proc.terminate()
            except Exception:
                pass
            sys.exit(0)
    proc.wait()
finally:
    try:
        sys.stdout.write("event: done\r\ndata: ok\r\n\r\n")
        sys.stdout.flush()
    except Exception:
        pass
