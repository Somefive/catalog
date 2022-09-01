package main

promtailConfig: {
    name: "promtail-config"
    type: "k8s-objects"
    properties: objects: [{
        apiVersion: "v1"
        kind: "ConfigMap"
        metadata: name: "promtail"
        data: {
            "promtail.yaml": #"""
                server:
                  log_level: info
                  http_listen_port: 3101

                clients:
                  - url: http://$LOKIHOST:3100/loki/api/v1/push
                
                positions:
                  filename: /run/promtail/positions.yaml
                
                scrape_configs:
                  # See also https://github.com/grafana/loki/blob/master/production/ksonnet/promtail/scrape_config.libsonnet for reference
                  - job_name: kubernetes-pods
                    pipeline_stages:
                      - cri: {}
                      - static_labels:
                          cluster: $CLUSTER
                    kubernetes_sd_configs:
                      - role: pod
                    relabel_configs:
                      - source_labels:
                          - __meta_kubernetes_pod_controller_name
                        regex: ([0-9a-z-.]+?)(-[0-9a-f]{8,10})?
                        action: replace
                        target_label: __tmp_controller_name
                      - source_labels:
                          - __meta_kubernetes_pod_label_app_kubernetes_io_name
                          - __meta_kubernetes_pod_label_app
                          - __tmp_controller_name
                          - __meta_kubernetes_pod_name
                        regex: ^;*([^;]+)(;.*)?$
                        action: replace
                        target_label: app
                      - source_labels:
                          - __meta_kubernetes_pod_label_app_kubernetes_io_instance
                          - __meta_kubernetes_pod_label_release
                        regex: ^;*([^;]+)(;.*)?$
                        action: replace
                        target_label: instance
                      - source_labels:
                          - __meta_kubernetes_pod_label_app_kubernetes_io_component
                          - __meta_kubernetes_pod_label_component
                        regex: ^;*([^;]+)(;.*)?$
                        action: replace
                        target_label: component
                      - action: replace
                        source_labels:
                        - __meta_kubernetes_pod_node_name
                        target_label: node_name
                      - action: replace
                        source_labels:
                        - __meta_kubernetes_namespace
                        target_label: namespace
                      - action: replace
                        replacement: $1
                        separator: /
                        source_labels:
                        - namespace
                        - app
                        target_label: job
                      - action: replace
                        source_labels:
                        - __meta_kubernetes_pod_name
                        target_label: pod
                      - action: replace
                        source_labels:
                        - __meta_kubernetes_pod_container_name
                        target_label: container
                      - action: replace
                        replacement: /var/log/pods/*$1/*.log
                        separator: /
                        source_labels:
                        - __meta_kubernetes_pod_uid
                        - __meta_kubernetes_pod_container_name
                        target_label: __path__
                      - action: replace
                        regex: true/(.*)
                        replacement: /var/log/pods/*$1/*.log
                        separator: /
                        source_labels:
                        - __meta_kubernetes_pod_annotationpresent_kubernetes_io_config_hash
                        - __meta_kubernetes_pod_annotation_kubernetes_io_config_hash
                        - __meta_kubernetes_pod_container_name
                        target_label: __path__
                """#
        }
    }]
}