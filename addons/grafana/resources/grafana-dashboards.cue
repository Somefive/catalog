output: {
    type: "k8s-objects"
    properties: objects: [{
        apiVersion: "v1"
        kind: "ConfigMap"
        metadata: name: "grafana-dashboards"
        data: {
          "dashboards.yaml": #"""
            apiVersion: 1
            providers:
            - name: dashboards
              type: file
              updateIntervalSeconds: 30
              options:
                path: /etc/dashboards
                foldersFromFilesStructure: true
            """#
        }
    }]

    traits: [{
        type: "grafana-dashboards"
        properties: {
            name: "kubernetes-overview"
            dashboards: [
                kubernetesOverview,
                kubevelaSystem,
                kubernetesDeployment
            ]
        }
    }]
}

kubernetesOverview: {
    title: "Kubernetes Overview"
    defaultVariables: {
        datasource: "Prometheus:local"
        job: "kubernetes-apiservers"
    }
    prometheusTemplating: ["job", "cluster"]
    panelParams: [{
        title: "Requests"
        pos: [0, 0]
    }, {
        title: "Request QPS (by verb)"
        promql: [{
            metrics: "apiserver_request_total"
            rate: true
            sumBy: ["verb"]
        }]
        graph: yLabel: "req/s"
        pos: [0, 1]
    }, {
        title: "Request QPS (by resource)"
        promql: [{
            metrics: "apiserver_request_total"
            rate: true
            sumBy: ["resource"]
        }]
        graph: yLabel: "req/s"
        pos: [6, 1]
    }, {
        title: "Detail Request QPS"
        promql: [{
            metrics: "apiserver_request_total"
            rate: true
            sumBy: ["verb", "resource"]
        }]
        graph: yLabel: "req/s"
        graph: legendTable: ["avg", "current"]
        pos: [12, 1]
        size: [12, 8]
    }, {
        title: "Latency"
        promql: [{
            metrics: "apiserver_request_duration_seconds"
            quantiles: [99, 75]
            filter: "verb!~\"CONNECT|WATCH\""
        }]
        graph: yLabel: "latency"
        graph: yFormat: "s"
        pos: [0, 9]
    }, {
        title: "Average Latency (by verb)"
        promql: [{
            metrics: "apiserver_request_duration_seconds"
            quantile_avg: true
            filter: "verb!~\"CONNECT|WATCH\""
            sumBy: ["verb"]
        }]
        graph: yLabel: "latency"
        graph: yFormat: "s"
        pos: [6, 9]
    }, {
        title: "Average Latency (by verb, resource)"
        promql: [{
            metrics: "apiserver_request_duration_seconds"
            quantile_avg: true
            filter: "verb!~\"CONNECT|WATCH\""
            sumBy: ["verb", "resource"]
        }]
        graph: yLabel: "latency"
        graph: yFormat: "s"
        graph: legendTable: ["avg", "current"]
        pos: [12, 9]
        size: [12, 8]
    }, {
        title: "WorkQueue"
        pos: [0, 17]
    }, {
        title: "Service Time"
        promql: [{
            metrics: "workqueue_queue_duration_seconds"
            quantiles: [99, 75]
        }]
        graph: yLabel: "service time"
        graph: yFormat: "s"
        pos: [0, 18]
    }, {
        title: "Process Time"
        promql: [{
            metrics: "workqueue_work_duration_seconds"
            quantiles: [99, 75]
        }]
        graph: yLabel: "process time"
        graph: yFormat: "s"
        pos: [6, 18]
    }, {
        title: "QueueSize"
        promql: [{
            name: "count"
            metrics: "workqueue_depth"
            sumBy: []
        }]
        pos: [12, 18]
    }, {
        title: "Retry Rate"
        promql: [{
            name: "rate"
            metrics: "workqueue_retries_total"
            sumBy: []
            rate: true
        }]
        graph: yLabel: "retries/s"
        pos: [18, 18]
    }, {
        title: "Watches"
        pos: [0, 19]
    }, {
        title: "Number of Watches"
        promql: [{
            metrics: "apiserver_registered_watchers"
            sumBy: ["kind"]
        }]
        graph: yLabel: "count"
        graph: legendTable: ["avg", "current"]
        pos: [0, 20]
        size: [9, 8]
    }, {
        title: "Watch Event Rate"
        promql: [{
            metrics: "apiserver_watch_events_sizes"
            quantiles: [99, 75]
        }]
        graph: yLabel: "events/s"
        pos: [9, 20]
    }, {
        title: "Watch Event Rate (by resource)"
        promql: [{
            metrics: "apiserver_watch_events_sizes"
            sumBy: ["kind"]
            quantile_avg: true
        }]
        graph: yLabel: "events/s"
        graph: legendTable: ["avg", "current"]
        pos: [15, 20]
        size: [9, 8]
    }, {
        title: "Storage"
        pos: [0, 28]
    }, {
        title: "Number of Objects"
        promql: [{
            metrics: "etcd_object_counts"
            sumBy: ["resource"]
        }]
        graph: yLabel: "count"
        graph: legendTable: ["avg", "current"]
        pos: [0, 29]
        size: [9, 8]
    }, {
        title: "ETCD Request Latency"
        promql: [{
            metrics: "etcd_request_duration_seconds"
            quantiles: [99, 75]
        }]
        graph: yLabel: "latency"
        graph: yFormat: "s"
        pos: [9, 29]
    }, {
        title: "ETCD Request Average Latency"
        promql: [{
            metrics: "etcd_request_duration_seconds"
            sumBy: ["type"]
            quantile_avg: true
        }]
        graph: yLabel: "latency"
        graph: yFormat: "s"
        graph: legendTable: ["avg", "current"]
        pos: [15, 29]
        size: [9, 8]
    }]
}

kubevelaSystem: {
    title: "KubeVela System"
    defaultVariables: {
        datasource: "Prometheus:local"
        job: "kubernetes-pods"
        app_kubernetes_io_name: "vela-core"
    }
    prometheusTemplating: ["job", "app_kubernetes_io_name"]
    panelParams: [{
        title: "Computation Resource"
        pos: [0, 0]
    }, {
        title: "Number of Applications"
        promql: [{
            metrics: "application_phase_number"
            sumBy: []
        }]
        stat: {}
        pos: [0, 1]
        size: [4, 8]
    }, {
        title: "KubeVela Controller Resource Usage"
        promql: [{
            name: "Memory"
            raw: "sum(container_memory_working_set_bytes{container=~\"kubevela\"}) / sum(container_spec_memory_limit_bytes{container=~\"kubevela\"})"
        }, {
            name: "CPU"
            raw: "sum(rate(container_cpu_usage_seconds_total{container=\"kubevela\"}[$rate_interval])) / sum(container_spec_cpu_quota{container=\"kubevela\"}/100000)"
        }]
        gauge: true
        pos: [4, 1]
        size: [5, 8]
    }, {
        title: "ClusterGateway Resource Usage"
        promql: [{
            name: "Memory"
            raw: "sum(container_memory_working_set_bytes{container=~\"kubevela-vela-core-cluster-gateway\"}) / sum(container_spec_memory_limit_bytes{container=~\"kubevela-vela-core-cluster-gateway\"})"
        }, {
            name: "CPU"
            raw: "sum(rate(container_cpu_usage_seconds_total{container=\"kubevela-vela-core-cluster-gateway\"}[$rate_interval])) / sum(container_spec_cpu_quota{container=\"kubevela-vela-core-cluster-gateway\"}/100000)"
        }]
        gauge: true
        pos: [9, 1]
        size: [5, 8]
    }, {
        title: "CPU Usage"
        promql: [{
            name: "KubeVela Controller"
            metrics: "container_cpu_usage_seconds_total"
            filter: "container=\"kubevela\""
            sumBy: []
            rate: true
            ignoreDashboardFilter: true
        }, {
            name: "ClusterGateway"
            metrics: "container_cpu_usage_seconds_total"
            filter: "container=\"kubevela-vela-core-cluster-gateway\""
            sumBy: []
            rate: true
            ignoreDashboardFilter: true
        }]
        graph: yLabel: "cores"
        pos: [14, 1]
        size: [5, 8]
    }, {
        title: "Memory Usage"
        promql: [{
            name: "KubeVela Controller"
            metrics: "container_memory_working_set_bytes"
            filter: "container=\"kubevela\""
            sumBy: []
            ignoreDashboardFilter: true
        }, {
            name: "ClusterGateway"
            metrics: "container_memory_working_set_bytes"
            filter: "container=\"kubevela-vela-core-cluster-gateway\""
            sumBy: []
            ignoreDashboardFilter: true
        }]
        graph: yLabel: "bytes"
        pos: [19, 1]
        size: [5, 8]
    }, {
        title: "Controller"
        pos: [0, 9]
    }, {
        title: "Controller Queue"
        promql: [{
            metrics: "workqueue_depth"
            sumBy: ["name"]
        }]
        graph: yLabel: "counts"
        graph: legendTable: ["avg", "current"]
        pos: [0, 9]
    }, {
        title: "Controller Queue Add Rate"
        promql: [{
            metrics: "workqueue_adds_total"
            sumBy: ["name"]
            rate: true
        }]
        graph: yLabel: "counts/s"
        graph: legendTable: ["avg", "current"]
        pos: [6, 9]
    }, {
        title: "Reconcile Rate"
        promql: [{
            metrics: "controller_runtime_reconcile_total"
            sumBy: ["result", "controller"]
            rate: true
        }]
        graph: yLabel: "counts/s"
        graph: legendTable: ["avg", "current"]
        pos: [12, 9]
    }, {
        title: "Average Reconcile Time"
        promql: [{
            metrics: "controller_runtime_reconcile_time_seconds"
            sumBy: ["controller"]
            quantile_avg: true
        }]
        graph: yFormat: "s"
        graph: legendTable: ["avg", "current"]
        pos: [18, 9]
    }, {
        title: "ApplicationController Reconcile Time"
        promql: [{
            metrics: "controller_runtime_reconcile_time_seconds"
            filter: "app_kubernetes_io_name=\"vela-core\",controller=\"application\""
            quantiles: [99, 75]
        }]
        graph: yFormat: "s"
        graph: legendTable: ["avg", "current"]
        pos: [0, 17]
    }, {
        title: "ApplicationController Reconcile Time"
        promql: [{
            name: "CreateAppHandler"
            metrics: "create_app_handler_time_seconds"
            quantile_avg: true
        }, {
            name: "HandleFinalizers"
            metrics: "handle_finalizers_time_seconds"
            quantile_avg: true
        }, {
            name: "ParseAppfile"
            metrics: "parse_appFile_time_seconds"
            quantile_avg: true
        }, {
            name: "PrepareAppRevision"
            metrics: "prepare_current_appRevision_time_seconds"
            quantile_avg: true
        }, {
            name: "ApplyAppRevision"
            metrics: "apply_appRevision_time_seconds"
            quantile_avg: true
        }, {
            name: "ApplyPolicies"
            metrics: "apply_policies"
            quantile_avg: true
        }, {
            name: "GCResourceTracker"
            metrics: "gc_resourceTrackers_time_seconds"
            quantile_avg: true
        }]
        graph: yFormat: "s"
        graph: legendTable: ["avg", "current"]
        pos: [6, 17]
    }, {
        title: "ApplicationController Client Request Throughput"
        promql: [{
            metrics: "client_request_time_seconds_count"
            sumBy: ["verb", "Kind"]
            rate: true
        }]
        graph: yLabel: "req/s"
        graph: legendTable: ["avg", "current"]
        pos: [12, 17]
    }, {
        title: "ApplicationController Client Request Average Time"
        promql: [{
            metrics: "client_request_time_seconds"
            sumBy: ["verb", "Kind"]
            quantile_avg: true
        }]
        graph: yFormat: "s"
        graph: legendTable: ["avg", "current"]
        pos: [18, 17]
    }, {
        title: "Application"
        pos: [0, 25]
    }, {
        title: "Number of Applications"
        promql: [{
            name: "All"
            metrics: "application_phase_number"
        }, {
            metrics: "application_phase_number"
            sumBy: ["phase"]
        }]
        graph: yLabel: "counts"
        pos: [0, 26]
        size: [4, 8]
    }, {
        title: "Number of Steps"
        promql: [{
            name: "All"
            metrics: "workflow_step_phase_number"
        }, {
            metrics: "workflow_step_phase_number"
            sumBy: ["step_type"]
        }]
        graph: yLabel: "counts"
        pos: [4, 26]
        size: [5, 8]
    }, {
        title: "StepStatus Distribution"
        promql: [{
            metrics: "workflow_step_phase_number"
            sumBy: ["phase"]
        }, {
            metrics: "workflow_step_phase_number"
            sumBy: ["phase", "step_type"]
        }]
        graph: yLabel: "counts"
        pos: [9, 26]
        size: [5, 8]
    }, {
        title: "Workflow Initialize Rate"
        promql: [{
            name: "Rate"
            metrics: "workflow_initialized_num"
            sumBy: []
            rate: true
        }]
        graph: yLabel: "counts/s"
        pos: [14, 26]
        size: [5, 8]
    }, {
        title: "Workflow Average Complete Time"
        promql: [{
            metrics: "workflow_finished_time_seconds"
            sumBy: ["phase"]
            quantile_avg: true
        }]
        graph: yFormat: "s"
        pos: [19, 26]
        size: [5, 8]
    }]
}

kubernetesDeployment: {
    title: "Kubernetes Deployment"
    defaultVariables: {
        datasource: "Prometheus:local"
        job: "kubernetes-nodes-cadvisor"
    }
    prometheusTemplating: ["cluster"]
    variables: [{
        name: "job"
        promql: "label_values(up, job)"
    }, {
        name: "namespace"
        promql: "label_values(kube_deployment_metadata_generation, namespace)"
    }, {
        name: "name"
        label: "Deployment"
        promql: "label_values(kube_deployment_metadata_generation{namespace=\"$namespace\"}, deployment)"
    }]
    panelParams: [{
        title: "Deployment"
        pos: [0, 0]
    }, {
        title: "Pods"
        promql: [{
            metrics: "kube_pod_info"
            sumBy: ["uid", "pod", "pod_ip", "host_ip", "node"]
            filter: "pod=~\"${name}-[0-9a-z]+-[0-9a-z]+\""
        }]
        table: true
        transformations: [{
            id: "reduce"
            options: {
                mode: "reduceFields"
                reducers: ["lastNotNull"]
            }
        }, {
            id: "organize",
            options: {
                indexByName: {
                    "Value": 5,
                    "host_ip": 3,
                    "node": 4,
                    "pod": 1,
                    "pod_ip": 2,
                    "uid": 0
                }
                renameByName: {
                    "Value": "",
                    "host_ip": "Host IP",
                    "node": "Node",
                    "pod": "Name",
                    "pod_ip": "Pod IP",
                    "uid": "UID"
                }
            }
        }]
        overrides: [{
            matcher: {
                id: "byName"
                options: "Value"
            }
            properties: [{
                id: "custom.hidden"
                value: true
            }]
        }]
        pos: [0, 1]
        size: [12, 8]
    }, {
        title: "Replicas"
        promql: [{
            name: "Current"
            metrics: "kube_deployment_status_replicas"
            filter: "deployment=~\"${name}\""
        }, {
            name: "Available"
            metrics: "kube_deployment_status_replicas_available"
            filter: "deployment=~\"${name}\""
        }, {
            name: "Unavailable"
            metrics: "kube_deployment_status_replicas_unavailable"
            filter: "deployment=~\"${name}\""
        }, {
            name: "Updated"
            metrics: "kube_deployment_status_replicas_updated"
            filter: "deployment=~\"${name}\""
        }, {
            name: "Desired"
            metrics: "kube_deployment_spec_replicas"
            filter: "deployment=~\"${name}\""
        }]
        pos: [12, 1]
        size: [6, 8]
    }, {
        title: "Desired Replicas"
        promql: [{
            metrics: "kube_deployment_spec_replicas"
            filter: "deployment=~\"${name}\""
        }]
        stat: plain: true
        pos: [18, 1]
        size: [2, 4]
    }, {
        title: "Available Replicas"
        promql: [{
            metrics: "kube_deployment_status_replicas_available"
            filter: "deployment=~\"${name}\""
        }]
        stat: plain: true
        pos: [20, 1]
        size: [2, 4]
    }, {
        title: "Metadata Generation"
        promql: [{
            metrics: "kube_deployment_metadata_generation"
            filter: "deployment=~\"${name}\""
        }]
        stat: plain: true
        pos: [22, 1]
        size: [2, 4]
    }, {
        title: "Ready Replicas"
        promql: [{
            metrics: "kube_deployment_status_replicas_ready"
            filter: "deployment=~\"${name}\""
        }]
        stat: plain: true
        pos: [18, 5]
        size: [2, 4]
    }, {
        title: "Updated Replicas"
        promql: [{
            metrics: "kube_deployment_status_replicas_updated"
            filter: "deployment=~\"${name}\""
        }]
        stat: plain: true
        pos: [20, 5]
        size: [2, 4]
    }, {
        title: "Observed Generation"
        promql: [{
            metrics: "kube_deployment_status_observed_generation"
            filter: "deployment=~\"${name}\""
        }]
        stat: plain: true
        pos: [22, 5]
        size: [2, 4]
    }, {
        title: "Computation Resources"
        pos: [0, 9]
    }, {
        title: "Memory Usage"
        promql: [{
            raw: #"sum(container_memory_working_set_bytes{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"}) / sum(container_spec_memory_limit_bytes{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"})"#
        }]
        gauge: true
        pos: [0, 10]
        size: [3, 8]
    }, {
        title: "Memory"
        promql: [{
            raw: #"sum(container_memory_working_set_bytes{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"})"#
        }]
        stat: plain: true
        unit: "bytes"
        pos: [3, 10]
        size: [3, 4]
    }, {
        title: "Memory Limit"
        promql: [{
            raw: #"sum(container_spec_memory_limit_bytes{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"})"#
        }]
        stat: plain: true
        unit: "bytes"
        pos: [3, 14]
        size: [3, 4]
    }, {
        title: "Memory Usage"
        promql: [{
            name: "{{pod}}"
            raw: #"sum(container_memory_working_set_bytes{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"}) by (pod)"#
        }]
        unit: "bytes"
        pos: [6, 10]
        size: [6, 8]
    }, {
        title: "CPU Usage"
        promql: [{
            raw: #"sum(rate(container_cpu_usage_seconds_total{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"}[$rate_interval])) / sum(container_spec_cpu_quota{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"}/100000)"#
        }]
        gauge: true
        pos: [12, 10]
        size: [3, 8]
    }, {
        title: "CPU"
        promql: [{
            raw: #"sum(rate(container_cpu_usage_seconds_total{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"}[$rate_interval]))"#
        }]
        stat: plain: true
        pos: [15, 10]
        size: [3, 4]
    }, {
        title: "CPU Limit"
        promql: [{
            raw: #"sum(container_spec_cpu_quota{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"}/100000)"#
        }]
        stat: plain: true
        pos: [15, 14]
        size: [3, 4]
    }, {
        title: "CPU Usage"
        promql: [{
            name: "{{pod}}"
            raw: #"sum(rate(container_cpu_usage_seconds_total{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"}[$rate_interval])) by (pod)"#
        }]
        pos: [18, 10]
        size: [6, 8]
    }, {
        title: "Network IO"
        promql: [{
            name: "Out"
            raw: #"-sum(rate(container_network_transmit_bytes_total{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",job="$job"}[$rate_interval]))"#
        }, {
            name: "In"
            raw: #"sum(rate(container_network_receive_bytes_total{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",job="$job"}[$rate_interval]))"#
        }]
        graph: yFormat: "binBps"
        pos: [0, 18]
        size: [6, 8]
    }, {
        title: "Network IO (Packets)"
        promql: [{
            name: "Out"
            raw: #"-sum(rate(container_network_transmit_packets_total{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",job="$job"}[$rate_interval]))"#
        }, {
            name: "In"
            raw: #"sum(rate(container_network_transmit_packets_total{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",job="$job"}[$rate_interval]))"#
        }]
        graph: yFormat: "pps"
        pos: [6, 18]
        size: [6, 8]
    }, {
        title: "File IO"
        promql: [{
            name: "Read"
            raw: #"sum(rate(container_fs_reads_bytes_total{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",job="$job"}[$rate_interval]))"#
        }, {
            name: "Write"
            raw: #"sum(rate(container_fs_write_bytes_total{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",job="$job"}[$rate_interval]))"#
        }]
        graph: yFormat: "binBps"
        pos: [12, 18]
        size: [6, 8]
    }, {
        title: "Processes"
        promql: [{
            raw: #"sum(container_processes{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"})"#
        }]
        stat: {}
        pos: [18, 18]
        size: [3, 4]
    }, {
        title: "Sockets"
        promql: [{
            raw: #"sum(container_sockets{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"})"#
        }]
        stat: {}
        pos: [21, 18]
        size: [3, 4]
    }, {
        title: "Threads"
        promql: [{
            raw: #"sum(container_threads{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"})"#
        }]
        stat: {}
        pos: [18, 22]
        size: [3, 4]
    }, {
        title: "Up Time"
        promql: [{
            raw: #"max(time() - container_start_time_seconds{cluster="$cluster",namespace="$namespace",pod=~"${name}-[0-9a-z]+-[0-9a-z]+",container!="",job="$job"}) by (pod)"#
        }]
        unit: "s"
        stat: plain: true
        pos: [21, 22]
        size: [3, 4]
    }]
}