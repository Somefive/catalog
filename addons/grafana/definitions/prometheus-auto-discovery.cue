import (
    "vela/op"
    "vela/ql"
    "encoding/yaml"
    "strconv"
    "strings"
)

"prometheus-auto-discovery": {
    alias: ""
    annotations: {}
    attributes: podDisruptive: false
    description: "Discover prometheus datasource from prometheus-server addon for grafana."
    labels: "ui-hidden": "true"
    type: "workflow-step"
}

template: {
    resources: ql.#CollectServiceEndpoints & {
        app: {
            name: parameter.addonName
            namespace: parameter.addonNamespace
            filter: {}
        }
    } @step(1)
    status: {
        endpoints: *[] | [...{...}]
        if resources.err == _|_ && resources.list != _|_ {
            endpoints: [for ep in resources.list if ep.endpoint.port == parameter.port {
                title: strings.ToTitle(parameter.type)
                name: "\(title):\(ep.cluster)"
                portStr: strconv.FormatInt(ep.endpoint.port, 10)
                if ep.cluster == "local" && ep.ref.kind == "Service" {
                    url: "http://\(ep.ref.name).\(ep.ref.namespace):\(portStr)"
                }
                if ep.cluster != "local" || ep.ref.kind != "Service" {
                    url: "http://\(ep.endpoint.host):\(portStr)"
                }
            }]
        }
    }
    apply: op.#Apply & {
        value: {
            apiVersion: "v1"
            kind: "ConfigMap"
            metadata: {
                name: parameter.outputName
                namespace: parameter.namespace
                labels: "o11y.oam.dev/config": "grafana-datasource"
            }
            data: "\(parameter.type).yaml": yaml.Marshal({
                apiVersion: 1
                datasources: [for ep in (status.endpoints + parameter.extraEndpoints) {
                    type: parameter.type
                    name: ep.name
                    url: ep.url
                    access: "proxy"
                }]
            })
        }
    } @step(2)
	parameter: {
        namespace: *"o11y-system" | string
        addonName: *"addon-prometheus-server" | string
        addonNamespace: *"vela-system" | string
        extraEndpoints: *[] | [...{
            name: string
            url: string
        }]
        port: *9090 | int
        type: *"prometheus" | string
        outputName: *"grafana-datasources.prometheus" | string
	}
}
