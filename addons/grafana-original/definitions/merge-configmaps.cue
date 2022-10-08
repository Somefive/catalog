import (
    "vela/op"
)

"merge-configmaps": {
    alias: ""
    annotations: {}
    attributes: podDisruptive: false
    description: "Merge multiple ConfigMap data based on labels."
    labels: "ui-hidden": "true"
    type: "workflow-step"
}

template: {
    configmaps: op.#List & {
        resource: {
            apiVersion: "v1"
            kind:       "ConfigMap"
        }
        filter: {
            if parameter.sourceNamespace != _|_ {
                namespace: parameter.sourceNamespace
            }
            matchingLabels: parameter.sourceLabels
        }
    } @step(1)

    apply: op.#Apply & {
        value: {
            apiVersion: "v1"
            kind: "ConfigMap"
            metadata: {
                name: parameter.targetName
                if parameter.targetNamespace != _|_ {
                    namespace: parameter.targetNamespace
                }
                if parameter.targetNamespace == _|_ {
                    namespace: context.namespace
                }
            }
            data: {
                for cm in configmaps.list.items {
                    for k, v in cm.data {
                        "\(cm.metadata.namespace).\(cm.metadata.name).\(k)": v
                    }
                }
                ...
            }
        }
    } @step(2)

	parameter: {
        sourceLabels: [string]: string
        sourceNamespace?: string
        targetName: string
        targetNamespace?: string
	}
}
