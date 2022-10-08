import (
    "encoding/json"
    "strings"
    "list"
    "strconv"
)

"grafana-dashboards-official": {
    alias: ""
    annotations: {}
    attributes: podDisruptive: false
    description: "Build grafana dashboards."
    labels: "ui-hidden": "true"
    type: "trait"
}

template: {
	parameter: {
        dashboards: [...{
            title: string
            variables: *[] | [...#VariableArgs]
            panelGroups: [...#PanelGroupArgs]
            ...
        }]
        name: string
        namespace: *"o11y-system" | string
    }
    dashboards: [for q in [for p in parameter.dashboards {#CreateDashboard & {inputs: p}}] {q.outputs}]
    outputs: "grafana-dashboards.\(parameter.namespace).\(parameter.name)": {
        apiVersion: "v1"
        kind: "ConfigMap"
        metadata: {
            name: "grafana-dashboards.\(parameter.name)"
            namespace: parameter.namespace
            labels: "o11y.oam.dev/config": "grafana-dashboard-model"
        }
        data: {
            for dashboard in dashboards {
                "\(dashboard.uid).json": json.Marshal(dashboard)
            }
        }
    }

    #VariableArgs: {
        type: string
        ...
    }

    VariableCreators: {
        "Prometheus": #CreatePrometheusDatasourceVariable
        "PrometheusQuery": #CreatePrometheusQueryVariable
        "RateInterval": #CreateRateIntervalVariable
    }

    #BaseVariable: {
        inputs: {
            default?: string
            ...
        }
        outputs: {
            if inputs.default != _|_ {
                current: {
                    selected: true
                    text: inputs.default
                    value: inputs.default
                }
            }
            ...
        }
    }

    #CreatePrometheusDatasourceVariable: #BaseVariable & {
        inputs: {...}
        outputs: {
            name: "datasource"
            label: "Data Source"
            type: "datasource"
            query: "prometheus"
        }
    }

    #CreatePrometheusQueryVariable: #BaseVariable & {
        inputs: {
            name: string
            label?: string
            query?: string
            ...
        }
        outputs: {
            type: "query"
            name: inputs.name
            if inputs.label != _|_ {
                label: inputs.label
            }
            if inputs.label == _|_ && name !~ "^.*_.*$" {
                label: strings.ToTitle(name)
            }
            query: {
                if inputs.query != _|_ {
                    query: inputs.query
                }
                if inputs.query == _|_ {
                    query: "label_values(up, \(name))"
                }
                refId: "StandardVariableQuery"
            }
            refresh: 1
            datasource: uid: "${datasource}"
        }
    }

    #CreateRateIntervalVariable: {
        inputs: {
            query: *"3m,5m,10m,30m" | string
            ...
        }
        outputs: {
            type: "interval"
            name: "rate_interval"
            label: "Rate"
            query: inputs.query
        }
    }

    #CreateDashboard: {
        inputs: {
            title: string
            variables: [...#VariableArgs]
            groups: [...{...}]
            time: {
                from: *"now-1h" | string
                to: *"now" | string
            }
            ...
        }
        outputs: {
            title: inputs.title
            uid: strings.Replace(strings.ToLower(title), " ", "-", -1)
            time: inputs.time
            templating: list: [for q in [for p in inputs.variables {VariableCreators["\(p.type)"] & {inputs: p}}] {q.outputs}]
            panels: [for q in [for group in inputs.panelGroups {#PanelGroup & {inputs: group}}] for panel in q.outputs {panel}]
        }
    }

    #PanelGroupArgs: {
        items: [...#PanelArgs]
        offset: *[0, 0] | [number, number]
    }

    #PanelGroup: {
        inputs: #PanelGroupArgs
        _offset: inputs.offset
        outputs: [for panel in [for item in inputs.items {PanelCreators["\(item.type)"] & {
            inputs: {offset: _offset, item}
        }}] {panel.outputs}]
    }

    #BasePanel: {
        inputs: {
            title: string
            size?: [number, number]
            loc: *[0, 0] | [number, number]
            offset: *[0, 0] | [number, number]
            ...
        }
        outputs: {
            title: inputs.title
            gridPos: {
                x: inputs.loc[0] + inputs.offset[0]
                y: inputs.loc[1] + inputs.offset[1]
                w: *6 | number
                h: *8 | number
                if inputs.size != _|_ {
                    w: inputs.size[0]
                    h: inputs.size[1]
                }
            }
            ...
        }
    }

    #PanelArgs: {
        type: string
        ...
    }

    PanelCreators: {
        "Row": #CreateRow
        "PromMetricsGraph": #CreatePromMetricsGraph
    }

    #CreateRow: #BasePanel & {
        inputs: {...}
        outputs: {
            type: "row"
            gridPos: {w: 24, h: 1}
        }
    }

    #PromGraphPanel: #BasePanel & {
        outputs: type: "graph"
        outputs: datasource: {
            uid: "${datasource}"
            type: "prometheus"
        }
    }

    #CreatePromMetricsGraph: #PromGraphPanel & {
        inputs: {
            metrics: [...{
                expr: string
                legendFormat: *"" | string
            }]
            unit: *"short" | string
            yAxis: *"" | string
            legend?: {
                alignAsTable: *true | bool
                rightSide: *false | bool
                avg: *true | bool
                current: *true | bool
                max: *false | bool
                min: *false | bool
                total: *false | bool
                sort: *"avg" | string
                sortDesc: *true | bool
                values: *true | bool
            }
            ...
        }
        outputs: {
            targets: [for metric in inputs.metrics {
                expr: metric.expr
                legendFormat: metric.legendFormat
                range: true
            }]
            if inputs.unit != "short" || inputs.yAxis != "" {
                yaxes: [{
                    format: inputs.unit
                    logBase: 1
                    show: true
                    if inputs.yAxis != "" {label: inputs.yAxis}
                }, {
                    format: inputs.unit
                    logBase: 1
                    show: true
                }]
            }
            if inputs.legend != _|_ {legend: inputs.legend}
        }
    }


    #Dashboard: {
        uid: string
        title: string
        description?: string
        tags?: [...string]
        style?: "dark" | "light"
        timezone?: "browser" | "utc"
        editable?: bool
        hideControls?: bool
        graphTooltip?: 0 | 1 | 2
        panels: *[] | [...#BasePanel]
        time: {
            from: *"now-1h" | string
            to: *"now" | string
        }
        timepicker?: {
            time_options?: [...{...}]
            refresh_intervals: *["5s", "10s", "30s", "1m", "5m", "15m", "30m", "1h", "2h", "1d"] | [...string]
        }
        templating?: {
            enable: *true | bool
            list: *[] | [...#Variable]
        }
        annotations?: list: [...{...}]
        refresh: *"30s" | string
        links?: [...{...}]
    }

    #Variable: {
        name: string
        label: string
        allFormat?: "wildcard" | "glob" | "regex" | "pipe" | string
        current?: {
            selected: *true | bool
            text: string | [...string]
            value: string | [...string]
        }
        datasource?: {
            type: string
            uid: string
        }
        includeAll?: bool
        multi?: bool
        multiFormat?: string
        type: *"query" | "custom" | "interval" | "datasource" | string
        refresh?: number
        definition?: string
        query: string | {
            query: string
            refId: *"StandardVariableQuery" | string
        }
        options?: [...{
            selected: *false | bool
            text: string
            value: string
        }]
        ...
    }

    #TemplatingVariable: {
        name: string
        label?: string
        promql?: string
    }

    #PanelParams: {
        title: string
        size: *[6, 8] | [number, number]
        pos: [number, number]
        promql?: [...{
            name?: string
            raw?: string
            metrics: string
            filter?: string
            ignoreDashboardFilter?: true
            sumBy?: [...string]
            rate: *false | bool
            quantiles: *[] | [...number]
            quantile_avg: *false | bool
        }]
        row?: collapsed: *false | true
        graph?: {
            yFormat: *"short" | string
            yLabel: *"" | string
            yMin: *"0" | string
            legendTable: *[] | [...string]
            rightSide?: true
            sortBy: *"avg" | string
        }
        unit?: string
        stat?: {
            plain: *false | bool
        }
        gauge?: true
        table?: true
        transformations?: [...{...}]
        overrides?: [...{...}]
    }

    #DashboardTemplate: {
        title: string
        uid: strings.Replace(strings.ToLower(title), " ", "-", -1)
        description: *"" | string
        time: {
            from: *"now-1h" | string
            to: *"now" | string
        }
        refresh: *"30s" | string
        defaultVariables?: [string]: string
        prometheusTemplating: *[] | [...string]
        variables: *[] | [...#TemplatingVariable]

        _datasourceType: *"prometheus" | string
        _datasourceTemplating: {
            type: "datasource"
            name: "datasource"
            label: "Data Source"
            query: _datasourceType
        }
        _rateIntervalTemplating: {
            type: "interval"
            name: "rate_interval"
            label: "Rate"
            query: "3m,5m,10m,30m"
        }
        _autoGeneratedTemplating: *[] | [...{...}]
        _dashboardFilter: strings.Join([for key in prometheusTemplating {"\(key)=~\"$\(key)\""}], ",")
        if _datasourceType == "prometheus" {
            _autoGeneratedTemplating: [for key in prometheusTemplating {
                type: "query"
                name: key
                if strings.Contains(key, "_") {
                    label: key
                }
                if !strings.Contains(key, "_") {
                    label: strings.ToTitle(key)
                }
                query: {
                    query: "label_values(up, \(key))"
                    refId: "StandardVariableQuery"
                }
                refresh: 1
                datasource: uid: "${datasource}"
            }]
        }        
        _templatings: [_datasourceTemplating] + _autoGeneratedTemplating + [for var in variables {
            name: var.name
            if var.label != _|_ {
                label: var.label
            }
            if var.label == _|_ {
                label: strings.ToTitle(name)
            }
            if var.promql != _|_ {
                query: {
                    query: var.promql
                    refId: "StandardVariableQuery"
                }
                refresh: 1
                datasource: uid: "${datasource}"
            }
        }] + [_rateIntervalTemplating]
        templating: list: [for _templating in _templatings {
            _templating
            if defaultVariables != _|_ && defaultVariables[_templating.name] != _|_ {
                current: {
                    selected: true
                    text: defaultVariables[_templating.name]
                    value: defaultVariables[_templating.name]
                }
            }
        }]

        _datasource: {
            uid: "${datasource}"
            type: _datasourceType
        }

        panelParams: [...#PanelParams]
        panels: [for idx, param in panelParams {
            title: param.title
            if param.transformations != _|_ {
                transformations: param.transformations
            }
            if param.overrides != _|_ {
                fieldConfig: overrides: param.overrides
            }

            if param.promql != _|_ {
                type: *"graph" | string
                if param.unit != _|_ {
                    fieldConfig: defaults: unit: param.unit
                }
                if param.stat != _|_ {
                    type: "stat"
                    if param.stat.plain {
                        options: graphMode: "none"
                        options: colorMode: "none"
                    }
                }
                if param.gauge != _|_ {
                    type: "gauge"
                    fieldConfig: defaults: {
                        color: mode: "thresholds"
                        unit: "percentunit"
                        min: 0
                        max: 1
                        thresholds: steps: [{
                            color: "green"
                            value: null
                        }, {
                            color: "yellow"
                            value: 0.6
                        }, {
                            color: "red"
                            value: 0.8
                        }]
                    }
                }
                if param.table != _|_ {
                    type: "table"
                }
                datasource: _datasource
                _targets: [for query in param.promql {
                    _filter: "{" + strings.Join([for f in [{
                        if query.ignoreDashboardFilter == _|_ {filter: _dashboardFilter}
                    }, {
                        if query.filter != _|_ {filter: query.filter}
                    }] if f.filter != _|_ {f.filter}], ",") + "}"
                    filteredMetrics: "\(query.metrics)\(_filter)"
                    ratedMetrics: *"" | string
                    if query.rate {
                        ratedMetrics: "rate(\(filteredMetrics)[$rate_interval])"
                    }
                    if !query.rate {
                        ratedMetrics: filteredMetrics
                    }
                    sumedMetrics: *"" | string
                    _legendFormat: *"" | string
                    if query.name != _|_ {
                        _legendFormat: query.name
                    }
                    if query.sumBy != _|_ {
                        _sumBy: strings.Join(query.sumBy, ",")
                        sumedMetrics: "sum(\(ratedMetrics)) by (\(_sumBy))"
                        if len(query.sumBy) > 0 {
                            _legendFormat: strings.Join([for key in query.sumBy {"{{\(key)}}"}], " ")
                        }
                    }
                    if query.sumBy == _|_ {
                        sumedMetrics: ratedMetrics
                    }
                    if len(query.quantiles) == 0 && !query.quantile_avg {
                        outputs: [{
                            if query.raw != _|_ {
                                expr: query.raw
                            }
                            if query.raw == _|_ {
                                expr: sumedMetrics
                            }
                            legendFormat: _legendFormat
                            range: true
                        }]
                    }
                    if query.quantile_avg {
                        outputs: [{
                            _sumBy: *"" | string
                            legendFormat: *"avg" | string
                            if query.name != _|_ {
                                legendFormat: query.name
                            }
                            if query.sumBy != _|_ && query.name == _|_ {
                                _sumBy_: strings.Join(query.sumBy, ",")
                                _sumBy: " by (\(_sumBy_))"
                                legendFormat: strings.Join([for key in query.sumBy {"{{\(key)}}"}], " ")
                            }
                            expr: "sum(rate(\(query.metrics)_sum\(_filter)[$rate_interval]))\(_sumBy) / sum(rate(\(query.metrics)_count\(_filter)[$rate_interval]))\(_sumBy)"
                            range: true
                        }]
                    }
                    if len(query.quantiles) > 0 {
                        outputs: [for q in query.quantiles {
                            _q: strconv.FormatInt(q, 10)
                            expr: "histogram_quantile(0.\(_q), sum(rate(\(query.metrics)_bucket\(_filter)[$rate_interval])) by (le))"
                            legendFormat: "p\(_q)"
                            range: true
                        }] + [{
                            expr: "sum(rate(\(query.metrics)_sum\(_filter)[$rate_interval])) / sum(rate(\(query.metrics)_count\(_filter)[$rate_interval]))"
                            legendFormat: "avg"
                            range: true
                        }]
                    }
                }]
                targets: [for target in _targets for output in target.outputs {
                    output
                    if param.table != _|_ { format: "table" }
                }]
            }
            _isRow: param.promql == _|_
            if _isRow {
                type: "row"
            }
            gridPos: {
                x: param.pos[0]
                y: param.pos[1]
                if _isRow {
                    w: 24
                    h: 1
                }
                if !_isRow {
                    w: param.size[0]
                    h: param.size[1]
                }
            }
            if param.graph != _|_ {
                yaxes: [{
                    format: param.graph.yFormat
                    if param.graph.yLabel != "" {
                        label: param.graph.yLabel
                    }
                    if param.graph.yMin != "" {
                        min: param.graph.yMin
                    }
                    logBase: 1
                    show: true
                }, {
                    format: param.graph.yFormat
                    logBase: 1
                    show: true
                }]
                if len(param.graph.legendTable) > 0 {
                    legend: {
                        alignAsTable: true
                        rightSide: param.size[0] > 6 || param.graph.rightSide != _|_
                        for key in ["avg", "current", "max", "min", "total"] {
                            "\(key)": list.Contains(param.graph.legendTable, key)
                        }
                        sort: param.graph.sortBy
                        sortDesc: true
                        values: true
                    }
                }
            }
        }]
    }
}

