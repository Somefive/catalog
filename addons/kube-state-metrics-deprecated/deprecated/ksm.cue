output: {
    type: "webservice"
    properties: {
        image: "bitnami/kube-state-metrics:2.4.2"
        imagePullPolicy: "IfNotPresent"
        ports: [{
            port: 8080
            expose: true
        }]
        livenessProbe: {
            httpGet: {
                path: "/healthz"
                port: 8080
            }
            initialDelaySeconds: 5
            timeoutSeconds: 5
        }
        readinessProbe: {
            httpGet: {
                path: "/"
                port: 8080
            }
            initialDelaySeconds: 5
            timeoutSeconds: 5
        }
    }
    traits: [{
        type: "service-account"
        properties: name: "kube-state-metrics"
    }]
}