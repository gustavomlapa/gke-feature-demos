#!/usr/bin/env python3
import http.server
import json
import os
import socketserver
import ssl
import sys
import urllib.request
from typing import Any, Dict, List, Tuple

PORT = int(os.environ.get("PORT", "8080"))
STATIC_DIR = os.path.join(os.path.dirname(__file__), "static")

# Kubernetes in-cluster config
SA_TOKEN_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/token"
SA_CA_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
K8S_HOST = os.environ.get("KUBERNETES_SERVICE_HOST")
K8S_PORT = os.environ.get("KUBERNETES_SERVICE_PORT", "443")

def is_in_cluster() -> bool:
    return os.path.exists(SA_TOKEN_PATH) and K8S_HOST is not None

def get_k8s_token() -> str:
    if os.path.exists(SA_TOKEN_PATH):
        with open(SA_TOKEN_PATH, "r") as f:
            return f.read().strip()
    return ""

def k8s_api_get(path: str) -> Dict[str, Any]:
    if not is_in_cluster():
        return {}
    token = get_k8s_token()
    url = f"https://{K8S_HOST}:{K8S_PORT}{path}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    
    ctx = ssl.create_default_context()
    if os.path.exists(SA_CA_PATH):
        ctx.load_verify_locations(SA_CA_PATH)
    else:
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

    try:
        with urllib.request.urlopen(req, context=ctx, timeout=5) as response:
            return json.loads(response.read().decode("utf-8"))
    except Exception as e:
        print(f"[WARN] Error querying K8s API at {path}: {e}", file=sys.stderr)
        return {}

def categorize_node(labels: Dict[str, str]) -> Tuple[str, bool, str]:
    cc_label = labels.get("cloud.google.com/compute-class", "")
    is_spot = labels.get("cloud.google.com/gke-spot") == "true" or labels.get("cloud.google.com/gke-preemptible") == "true"
    
    if cc_label.startswith("autopilot"):
        return "Autopilot (Serverless)", is_spot, cc_label
    elif cc_label:
        return "Custom ComputeClass", is_spot, cc_label
    else:
        return "Standard (Manual)", is_spot, "None (Standard Pool)"

def parse_pod_info(raw_pod: Dict[str, Any]) -> Dict[str, Any]:
    metadata = raw_pod.get("metadata", {})
    spec = raw_pod.get("spec", {})
    status = raw_pod.get("status", {})
    
    node_selector = spec.get("nodeSelector", {})
    compute_class = node_selector.get("cloud.google.com/compute-class", "None (Standard Pool)")
    
    containers = spec.get("containers", [])
    cpu_req = "N/A"
    mem_req = "N/A"
    if containers:
        res = containers[0].get("resources", {}).get("requests", {})
        cpu_req = res.get("cpu", "default")
        mem_req = res.get("memory", "default")
    
    container_statuses = status.get("containerStatuses", [])
    ready = any(cs.get("ready", False) for cs in container_statuses) if container_statuses else False
    
    return {
        "name": metadata.get("name", "unknown"),
        "namespace": metadata.get("namespace", "default"),
        "app_label": metadata.get("labels", {}).get("app", "app"),
        "node": spec.get("nodeName", "Pending"),
        "compute_class": compute_class,
        "cpu_request": cpu_req,
        "memory_request": mem_req,
        "status": status.get("phase", "Unknown"),
        "ready": ready
    }

def generate_cluster_summary(nodes: List[Dict[str, Any]], pods: List[Dict[str, Any]]) -> Dict[str, Any]:
    total_nodes = len(nodes)
    autopilot_nodes = sum(1 for n in nodes if "Autopilot" in n.get("category", ""))
    custom_nodes = sum(1 for n in nodes if "Custom" in n.get("category", ""))
    standard_nodes = sum(1 for n in nodes if "Standard" in n.get("category", ""))
    spot_nodes = sum(1 for n in nodes if n.get("is_spot", False))
    
    total_pods = len(pods)
    running_pods = sum(1 for p in pods if p.get("ready", False))
    
    return {
        "total_nodes": total_nodes,
        "autopilot_nodes": autopilot_nodes,
        "custom_nodes": custom_nodes,
        "standard_nodes": standard_nodes,
        "spot_nodes": spot_nodes,
        "total_pods": total_pods,
        "running_pods": running_pods
    }

def get_cluster_data() -> Dict[str, Any]:
    if is_in_cluster():
        raw_nodes = k8s_api_get("/api/v1/nodes").get("items", [])
        raw_pods = k8s_api_get("/api/v1/namespaces/default/pods").get("items", [])
        raw_classes = k8s_api_get("/apis/cloud.google.com/v1/computeclasses").get("items", [])
    else:
        # Modo de simulação/desenvolvimento local
        raw_nodes = [
            {
                "metadata": {
                    "name": "gke-standard-default-pool-abc1",
                    "labels": {
                        "node.kubernetes.io/instance-type": "e2-standard-2",
                        "topology.kubernetes.io/zone": "us-central1-a",
                        "kubernetes.io/arch": "amd64"
                    }
                },
                "status": {"conditions": [{"type": "Ready", "status": "True"}]}
            },
            {
                "metadata": {
                    "name": "gke-standard-autopilot-pool-xyz2",
                    "labels": {
                        "node.kubernetes.io/instance-type": "e2-medium",
                        "cloud.google.com/compute-class": "autopilot",
                        "cloud.google.com/gke-spot": "true",
                        "topology.kubernetes.io/zone": "us-central1-b",
                        "kubernetes.io/arch": "amd64"
                    }
                },
                "status": {"conditions": [{"type": "Ready", "status": "True"}]}
            },
            {
                "metadata": {
                    "name": "gke-standard-nap-n4-spot-987a",
                    "labels": {
                        "node.kubernetes.io/instance-type": "n4-standard-4",
                        "cloud.google.com/compute-class": "resilient-cost-saver",
                        "cloud.google.com/gke-spot": "true",
                        "topology.kubernetes.io/zone": "us-central1-a",
                        "kubernetes.io/arch": "amd64"
                    }
                },
                "status": {"conditions": [{"type": "Ready", "status": "True"}]}
            }
        ]
        raw_pods = [
            {
                "metadata": {"name": "legacy-standard-workload-1", "namespace": "default", "labels": {"app": "legacy"}},
                "spec": {"nodeName": "gke-standard-default-pool-abc1", "containers": [{"resources": {"requests": {"cpu": "200m", "memory": "256Mi"}}}]},
                "status": {"phase": "Running", "containerStatuses": [{"ready": True}]}
            },
            {
                "metadata": {"name": "serverless-autopilot-workload-1", "namespace": "default", "labels": {"app": "autopilot-demo"}},
                "spec": {"nodeName": "gke-standard-autopilot-pool-xyz2", "nodeSelector": {"cloud.google.com/compute-class": "autopilot"}, "containers": [{"resources": {"requests": {"cpu": "500m", "memory": "512Mi"}}}]},
                "status": {"phase": "Running", "containerStatuses": [{"ready": True}]}
            },
            {
                "metadata": {"name": "spot-batch-fallback-workload-1", "namespace": "default", "labels": {"app": "resilient-batch"}},
                "spec": {"nodeName": "gke-standard-nap-n4-spot-987a", "nodeSelector": {"cloud.google.com/compute-class": "resilient-cost-saver"}, "containers": [{"resources": {"requests": {"cpu": "1000m", "memory": "1Gi"}}}]},
                "status": {"phase": "Running", "containerStatuses": [{"ready": True}]}
            }
        ]
        raw_classes = [
            {
                "metadata": {"name": "resilient-cost-saver"},
                "spec": {
                    "nodePoolAutoCreation": {"enabled": True},
                    "priorities": [
                        {"machineFamily": "n4", "spot": True},
                        {"machineFamily": "n4", "spot": False},
                        {"machineFamily": "n2", "spot": False}
                    ]
                }
            }
        ]

    nodes_list = []
    for n in raw_nodes:
        meta = n.get("metadata", {})
        labels = meta.get("labels", {})
        category, is_spot, cc_name = categorize_node(labels)
        nodes_list.append({
            "name": meta.get("name", "unknown"),
            "category": category,
            "compute_class": cc_name,
            "instance_type": labels.get("node.kubernetes.io/instance-type", "unknown"),
            "zone": labels.get("topology.kubernetes.io/zone", "unknown"),
            "arch": labels.get("kubernetes.io/arch", "amd64"),
            "is_spot": is_spot,
            "ready": any(c.get("type") == "Ready" and c.get("status") == "True" for c in n.get("status", {}).get("conditions", []))
        })

    pods_list = [parse_pod_info(p) for p in raw_pods if not p.get("metadata", {}).get("name", "").startswith("compute-classes-dashboard")]
    summary = generate_cluster_summary(nodes_list, pods_list)

    return {
        "summary": summary,
        "nodes": nodes_list,
        "pods": pods_list,
        "compute_classes": raw_classes,
        "is_in_cluster": is_in_cluster()
    }

class DashboardHTTPHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=STATIC_DIR, **kwargs)

    def do_GET(self):
        if self.path == "/api/status":
            data = get_cluster_data()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(data).encode("utf-8"))
        elif self.path == "/healthz":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b"{\"status\": \"ok\"}")
        else:
            if self.path == "/" or self.path == "":
                self.path = "/index.html"
            super().do_GET()

    def log_message(self, format, *args):
        # Evitar flood de logs no console para polling continuo
        if "/api/status" not in (args[0] if args else ""):
            super().log_message(format, *args)

def run_server():
    print(f"Starting Compute Classes Dashboard on port {PORT}...")
    with socketserver.TCPServer(("", PORT), DashboardHTTPHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server.")

if __name__ == "__main__":
    run_server()
