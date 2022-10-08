package context

output: {
	apiVersion: "core.oam.dev/v1beta1"
	kind:       "Application"
	metadata: {
		name:      context.name
		namespace: "vela-system"
	}
	spec: {
		components: [example]
	}
}
