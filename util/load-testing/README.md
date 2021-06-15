# Load Testing

## Example: Provide k6 load testing metrics to Prometheus and display them in Grafana

```sh
K6_STATSD_ADDR=prometheus-statsd-exporter.monitoring.svc.cluster.local:9125 k6 run --vus 10 -o statsd --duration 30s script.js
```
