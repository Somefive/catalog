if parameter.externalName != "" || parameter.serviceType != "" {
    output: prometheusService
}

prometheusService: {
    type: "k8s-objects"
    properties: objects: [{
        apiVersion: "v1"
        kind: "Service"
        metadata: name: "prometheus-server"
        spec: {
            if parameter.externalName == "" {
                selector: "app.oam.dev/component": "prometheus-server"
                _ports: [{
                    if !parameter.thanos {
                        name: "http"
                        port: 9090
                        targetPort: 9090
                    }
                }, {
                    if parameter.thanos {
                        name: "http-sidecar"
                        port: 10902
                        targetPort: 10902
                    }
                }, {
                    if parameter.thanos {
                        name: "grpc"
                        port: 10901
                        targetPort: 10901
                    }
                }]
                ports: [for port in _ports if port.port != _|_ {port}]
                type:  parameter.serviceType
            }
            if parameter.externalName != "" {
                type: "ExternalName"
                externalName: parameter.externalName
            }
        }
    }]
}