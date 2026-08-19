import unittest
import json
from server import categorize_node, parse_pod_info, generate_cluster_summary

class TestComputeClassDashboard(unittest.TestCase):

    def test_categorize_standard_node(self):
        labels = {
            "node.kubernetes.io/instance-type": "e2-standard-2",
            "topology.kubernetes.io/zone": "us-central1-a"
        }
        category, is_spot, compute_class = categorize_node(labels)
        self.assertEqual(category, "Standard (Manual)")
        self.assertFalse(is_spot)
        self.assertEqual(compute_class, "None (Standard Pool)")

    def test_categorize_autopilot_node(self):
        labels = {
            "node.kubernetes.io/instance-type": "e2-medium",
            "cloud.google.com/compute-class": "autopilot",
            "cloud.google.com/gke-spot": "true"
        }
        category, is_spot, compute_class = categorize_node(labels)
        self.assertEqual(category, "Autopilot (Serverless)")
        self.assertTrue(is_spot)
        self.assertEqual(compute_class, "autopilot")

    def test_categorize_custom_compute_class_node(self):
        labels = {
            "node.kubernetes.io/instance-type": "n4-standard-4",
            "cloud.google.com/compute-class": "resilient-cost-saver",
            "cloud.google.com/gke-spot": "true"
        }
        category, is_spot, compute_class = categorize_node(labels)
        self.assertEqual(category, "Custom ComputeClass")
        self.assertTrue(is_spot)
        self.assertEqual(compute_class, "resilient-cost-saver")

    def test_parse_pod_info(self):
        raw_pod = {
            "metadata": {
                "name": "worker-autopilot-1",
                "namespace": "default",
                "labels": {"app": "autopilot-worker"}
            },
            "spec": {
                "nodeName": "gke-node-xyz",
                "nodeSelector": {"cloud.google.com/compute-class": "autopilot"},
                "containers": [{
                    "name": "worker",
                    "resources": {
                        "requests": {"cpu": "250m", "memory": "512Mi"}
                    }
                }]
            },
            "status": {
                "phase": "Running",
                "containerStatuses": [{"ready": True}]
            }
        }
        parsed = parse_pod_info(raw_pod)
        self.assertEqual(parsed["name"], "worker-autopilot-1")
        self.assertEqual(parsed["compute_class"], "autopilot")
        self.assertEqual(parsed["node"], "gke-node-xyz")
        self.assertEqual(parsed["status"], "Running")
        self.assertTrue(parsed["ready"])
        self.assertEqual(parsed["cpu_request"], "250m")

    def test_generate_cluster_summary(self):
        nodes = [
            {"category": "Standard (Manual)", "is_spot": False},
            {"category": "Autopilot (Serverless)", "is_spot": True},
            {"category": "Custom ComputeClass", "is_spot": True}
        ]
        pods = [
            {"compute_class": "None (Standard Pool)", "ready": True},
            {"compute_class": "autopilot", "ready": True},
            {"compute_class": "resilient-cost-saver", "ready": True}
        ]
        summary = generate_cluster_summary(nodes, pods)
        self.assertEqual(summary["total_nodes"], 3)
        self.assertEqual(summary["autopilot_nodes"], 1)
        self.assertEqual(summary["spot_nodes"], 2)
        self.assertEqual(summary["total_pods"], 3)

if __name__ == "__main__":
    unittest.main()
