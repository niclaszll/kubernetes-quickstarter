# Load Testing

## Example: Provide k6 load testing metrics to Prometheus and display them in Grafana

```sh
K6_STATSD_ADDR=prometheus-statsd-exporter.monitoring.svc.cluster.local:9125 k6 run --vus 10 -o statsd --duration 30s script.js
```

## Example: Load test emqx broker

```sh
mqtt-stresser -broker tcp://emqx.mqtt.svc.cluster.local:1883 -num-clients 1000 -num-messages 10 -rampup-delay 0.25s -global-timeout 2000s
```