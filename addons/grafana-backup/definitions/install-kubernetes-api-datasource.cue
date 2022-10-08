import (
    "vela/op"
    "encoding/yaml"
    "encoding/base64"
)

"install-kubernetes-api-datasource": {
    alias: ""
    annotations: {}
    attributes: podDisruptive: false
    description: "Create Kubernetes API datasource."
    labels: "ui-hidden": "true"
    type: "workflow-step"
}

template: {
    apply: op.#Apply & {
        value: {
            apiVersion: "v1"
            kind: "ServiceAccount"
            metadata: {
                name: parameter.serviceAccountName
                namespace: parameter.namespace
            }
        }
    } @step(1)

    wait: op.#ConditionalWait & {
        continue: apply.value.secrets != _|_ && len(apply.value.secrets) > 0
    } @step(2)

    read: op.#Read & {
        value: {
            apiVersion: "v1"
            kind: "Secret"
            metadata: {
                name: apply.value.secrets[0].name
                namespace: parameter.namespace
            }
        }
    } @step(3)

    decode: op.#Steps & {
        token: base64.Decode(null, read.value.data.token)
        convert: op.#ConvertString & {bt: token}
        kubeToken: convert.str
    } @step(4)

    output: op.#Apply & {
        value: {
            apiVersion: "v1"
            kind: "ConfigMap"
            metadata: {
                name: parameter.outputName
                namespace: parameter.namespace
                labels: "o11y.oam.dev/config": "grafana-datasource"
            }
            data: "kubernetes-api.yaml": yaml.Marshal({
                apiVersion: 1
                datasources: [{
                    type: "marcusolsson-json-datasource"
                    name: "KubernetesAPIServer"
                    url: "https://kubernetes.default"
                    access: "proxy"
                    uid: "kubernetes-api"
                    withCredentials: true
                    jsonData: {
                        tlsSkipVerify: true
                        httpHeaderName1: "Authorization"
                    }
                    secureJsonData: {
                        httpHeaderValue1: "Bearer \(decode.kubeToken)"
                    }
                }]
            })
        }
    } @step(5)

	parameter: {
        serviceAccountName: *"grafana" | string
        namespace: *"o11y-system" | string
        outputName: *"grafana-datasources.kubernetes-api" | string
	}
}
