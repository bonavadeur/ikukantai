kubectl patch configmap otel-collector-config -n metrics --type='merge' -p='{
  "metadata": {
    "annotations": {
      "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"data\":{\"collector.yaml\":\"receivers:\\n  opencensus:\\n    endpoint: \\\"0.0.0.0:55678\\\"\\n\\nexporters:\\n  debug:\\n  prometheus:\\n    endpoint: \\\"0.0.0.0:8889\\\"\\nextensions:\\n  health_check:\\n  pprof:\\n  zpages:\\nservice:\\n  extensions: [health_check, pprof, zpages]\\n  pipelines:\\n    metrics:\\n      receivers: [opencensus]\\n      processors: []\\n      exporters: [prometheus]\"},\"kind\":\"ConfigMap\",\"metadata\":{\"annotations\":{},\"name\":\"otel-collector-config\",\"namespace\":\"metrics\"}}"
    }
  }
}'

kubectl patch configmap otel-collector-config -n metrics --type='merge' -p='{
  "data": {
    "collector.yaml": "receivers:\n  opencensus:\n    endpoint: \"0.0.0.0:55678\"\n\nexporters:\n  debug:\n  prometheus:\n    endpoint: \"0.0.0.0:8889\"\nextensions:\n  health_check:\n  pprof:\n  zpages:\nservice:\n  extensions: [health_check, pprof, zpages]\n  pipelines:\n    metrics:\n      receivers: [opencensus]\n      processors: []\n      exporters: [prometheus]"
  }
}'