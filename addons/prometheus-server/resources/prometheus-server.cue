output: {
    if parameter.externalName == "" {
        prometheusServer
    }
    if parameter.externalName != "" {
        prometheusExternal
    }
}
prometheusServer: {
	type: "webservice"
	properties: {
		image: parameter["image"]
		imagePullPolicy: parameter["imagePullPolicy"]
        livenessProbe: {
            httpGet: {
                path: "/-/health"
                port: 9090
            }
        }
        readinessProbe: {
            httpGet: {
                path: "/-/ready"
                port: 9090
            }
        }
        exposeType: parameter.serviceType
        ports: [{
            expose: parameter.serviceType != ""
            name: "http"
            port: 9090
        }]
        volumeMounts: emptyDir: [{
            name: "storage-volume"
            mountPath: "/data"
        }]
        volumeMounts: configMap: [{
            name: "bootconfig-volume"
            cmName: "prometheus-server"
            mountPath: "/etc/bootconfig"
        }]
	}
	traits:[{
        type: "init-container"
        properties: {
            name: "init-config"
            image: "curlimages/curl"
            args: ["sh", "-c", ##"""
                NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
                KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
                DEPLOYNAME=$(echo $HOSTNAME | sed -r 's/(.+)-[^-]+-[^-]+/\1/g')
                curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
                        https://kubernetes.default/apis/apps/v1/namespaces/$NAMESPACE/deployments/$DEPLOYNAME \
                    | grep "\"app.oam.dev/cluster\"" | sed -r 's/.+:\s+"(.*)",/\1/g' > /etc/config/cluster.name \
                && CLS=$(cat /etc/config/cluster.name) \
                && CLUSTER="${CLS:-local}" \
                && echo "cluster: $CLUSTER" \
                && sed s/\$CLUSTER/$CLUSTER/g /etc/bootconfig/prometheus.yml > /etc/config/prometheus.yml
                """##]
            mountName: "config-volume"
            appMountPath: "/etc/config"
            initMountPath: "/etc/config"
            extraVolumeMounts: [{
                name: "bootconfig-volume"
                mountPath: "/etc/bootconfig"
            }]
        }
    }, {
		type: "service-account"
		properties: {
            name: "prometheus-server"
			create: true
			privileges: [for p in _clusterPrivileges {
				scope: "cluster"
				{p}
			}]
		}
	}, {
        type: "resource"
        properties: {
            cpu: parameter["cpu"]
            memory: parameter["memory"]
        }
    }]
}

_clusterPrivileges: [{
    apiGroups: [""]
    resources: ["nodes", "nodes/proxy", "nodes/metrics", "services", "endpoints", "pods", "ingresses", "configmaps"]
    verbs: ["get", "list", "watch"]
}, {
    apiGroups: ["extensions", "networking.k8s.io"]
    resources: ["ingresses/status", "ingresses"]
    verbs: ["get", "list", "watch"]
}, {
    nonResourceURLs: ["/metrics"]
    verbs: ["get"]
}, {
    apiGroups: ["apps"]
    resources: ["deployments"]
    resourceNames: ["prometheus-server"]
    verbs: ["get"]
}]

prometheusExternal: {
    type: "k8s-objects"
    properties: objects: [{
        apiVersion: "v1"
        kind:       "Service"
        metadata: name: "prometheus-server"
        spec: {
            type: "ExternalName"
            externalName: parameter.externalName
        }
    }]
}