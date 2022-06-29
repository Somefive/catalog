output: {
	type: "webservice"
	properties: {
		image: parameter["image"]
		imagePullPolicy: parameter["imagePullPolicy"]
		ports: [{
			port:     8080
			protocol: "TCP"
			expose:   true
		}]
		exposeType: parameter["exposeType"]
	}
	traits:[{
		type: "service-account"
		properties: {
			name: "kube-state-metrics"
			create: true
			privileges: [for p in _clusterPrivileges {
				scope: "cluster"
				{p}
			}]
		}
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

_clusterPrivileges: [{
	apiGroups: ["certificates.k8s.io"]
	resources: ["certificatesigningrequests"]
	verbs: ["list", "watch"]
}, {
    apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["batch"]
    resources: ["cronjobs"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["extensions", "apps"]
    resources: ["daemonsets"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["extensions", "apps"]
    resources: ["deployments"]
    verbs: ["list", "watch"]
}, {
    apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["autoscaling"]
    resources: ["horizontalpodautoscalers"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["extensions", "networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["batch"]
    resources: ["jobs"]
    verbs: ["list", "watch"]
}, {
    apiGroups: [""]
    resources: ["limitranges"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["admissionregistration.k8s.io"]
    resources: ["mutatingwebhookconfigurations"]
    verbs: ["list", "watch"]
}, {
    apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies"]
    verbs: ["list", "watch"]
}, {
    apiGroups: [""]
    resources: ["nodes"]
    verbs: ["list", "watch"]
}, {
    apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["list", "watch"]
}, {
    apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["policy"]
    resources: ["poddisruptionbudgets"]
    verbs: ["list", "watch"]
}, {
    apiGroups: [""]
    resources: ["pods"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["extensions", "apps"]
    resources: ["replicasets"]
    verbs: ["list", "watch"]
}, {
    apiGroups: [""]
    resources: ["replicationcontrollers"]
    verbs: ["list", "watch"]
}, {
    apiGroups: [""]
    resources: ["resourcequotas"]
    verbs: ["list", "watch"]
}, {
    apiGroups: [""]
    resources: ["secrets"]
    verbs: ["list", "watch"]
}, {
    apiGroups: [""]
    resources: ["services"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["apps"]
    resources: ["statefulsets"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["admissionregistration.k8s.io"]
    resources: ["validatingwebhookconfigurations"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["storage.k8s.io"]
    resources: ["volumeattachments"]
    verbs: ["list", "watch"]
}, {
    apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["list", "watch"]
}]