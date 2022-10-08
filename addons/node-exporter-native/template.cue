apiVersion: core.oam.dev/v1beta1
kind: Application
metadata:
  name: node-exporter
  namespace: vela-system
spec:
  components:
    - type: k8s-objects
      name: node-exporter-ns
      properties:
        objects:
          - apiVersion: v1
            kind: Namespace
            metadata:
              name: o11n-system
  policies:
    - type: shared-resource
      name: shared-namespace
      properties:
        rules:
          - selector:
              resourceTypes: ["Namespace"]