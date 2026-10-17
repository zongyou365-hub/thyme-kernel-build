import json, os, time, urllib.request, urllib.error, sys

TOKEN = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN") or ""
if not TOKEN:
    print("GH_TOKEN not set", file=sys.stderr)
    raise SystemExit(2)
REPO = "zongyou365-hub/thyme-kernel-build"
H = f"https://api.github.com/repos/{REPO}"
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))

WF = "build325.yml"
if "--workflow" in sys.argv:
    WF = sys.argv[sys.argv.index("--workflow") + 1]


def api(url, method="GET", data=None):
    req = urllib.request.Request(url, method=method)
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("User-Agent", "kernel-build")
    req.add_header("Accept", "application/vnd.github+json")
    body = None
    if data is not None:
        body = json.dumps(data).encode()
        req.add_header("Content-Type", "application/json")
    with opener.open(req, body, timeout=30) as r:
        raw = r.read().decode()
        return json.loads(raw) if raw else None


def show_runs(n=8):
    runs = api(f"{H}/actions/runs?per_page={n}")["workflow_runs"]
    for r in runs:
        print(f"#{r['run_number']:>3} id={r['id']} {r['status']:<12} {str(r['conclusion']):<10} "
              f"{r['created_at']} {r['name'][:38]}")


if "--status" in sys.argv:
    show_runs()
    raise SystemExit(0)

if "--list-workflows" in sys.argv:
    for w in api(f"{H}/actions/workflows")["workflows"]:
        print(w["id"], w["path"], w["state"], w["name"])
    raise SystemExit(0)

runs = api(f"{H}/actions/runs?per_page=1")["workflow_runs"]
baseline = runs[0]["id"] if runs else 0
print("baseline run id:", baseline, flush=True)

try:
    api(f"{H}/actions/workflows/{WF}/dispatches", method="POST", data={
        "ref": "main",
        "inputs": {"ksu_branch": "susfs_new", "target": "Image",
                   "localversion": "-HyperOS3-A16-Sky-Developers"},
    })
    print("DISPATCH OK ->", WF, flush=True)
except urllib.error.HTTPError as e:
    print("DISPATCH FAIL", e.code, e.read().decode()[:500], flush=True)
    raise SystemExit(1)

deadline = time.time() + 85 * 60
last = None
found = False
while time.time() < deadline:
    try:
        rr = api(f"{H}/actions/runs?per_page=1")["workflow_runs"]
        if rr:
            r = rr[0]
            if not found:
                if r["id"] == baseline:
                    print("waiting for new run...", flush=True)
                else:
                    found = True
                    print("NEW RUN #%s id=%s" % (r["run_number"], r["id"]), flush=True)
            if found and r["id"] != baseline:
                if r["status"] != last:
                    print("[%s] %s %s" % (time.strftime("%H:%M:%S"), r["status"], r["conclusion"]), flush=True)
                    last = r["status"]
                if r["status"] == "completed":
                    print("FINAL:", r["conclusion"], flush=True)
                    print("RUN_ID:", r["id"], flush=True)
                    if r["conclusion"] == "success":
                        for a in api(f"{H}/actions/runs/{r['id']}/artifacts").get("artifacts", []):
                            print("ARTIFACT:", a["name"], a["size_in_bytes"], "bytes | id =", a["id"], flush=True)
                    break
    except Exception as e:
        print("poll error:", e, flush=True)
    time.sleep(30)
else:
    print("TIMEOUT after 85min", flush=True)
