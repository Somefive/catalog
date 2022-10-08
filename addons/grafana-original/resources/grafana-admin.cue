output: {
    type: "k8s-objects"
    properties: objects: [{
        apiVersion: "v1"
        kind: "Secret"
        metadata: name: "grafana-admin"
        stringData: {
            adminUser: parameter.adminUser
            adminPassword: parameter.adminPassword
        }
    }]
}