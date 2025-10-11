## Issue 1: Grafana Dashboard Kubernetes > Cluster shows No Data

check:

    kubectl get podmonitors -n monitoring No resources found in monitoring namespace.
    result:
    No resources found in monitoring namespace.

The absence of PodMonitor resources explains why your Grafana dashboards show “No Data”, especially for pod-level metrics like CPU and memory usage. Let’s fix that.

create manifest: kubelet-cadvisor-podmonitor.yaml

    apiVersion: monitoring.coreos.com/v1
    kind: PodMonitor
    metadata:
    name: kubelet-cadvisor
    namespace: monitoring
    spec:
    selector:
        matchLabels:
        k8s-app: kubelet
    namespaceSelector:
        matchNames:
        - kube-system
    podMetricsEndpoints:
        - port: http-metrics
        path: /metrics/cadvisor
        interval: 30s

apply the manifest:

    kubectl apply -f kubelet-cadvisor-podmonitor.yaml


