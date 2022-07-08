output: {
	type: "helm"
	properties: {
		repoType: "helm"
		url:      parameter.repoUrl
		chart:    parameter.chart
        version:  parameter.chartVersion
        targetNamespace: parameter.targetNamespace
        values: {
            image: {
                repository: parameter.imageRepository
                tag: parameter.imageTag
            }
        }
	}
}
