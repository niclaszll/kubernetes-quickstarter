# Load Testing

## Provide k6 load testing metrics to Prometheus and display them in Grafana

Deploy [Prometheus StatsD Exporter](https://github.com/hahow/prometheus-statsd-exporter):

```sh
helm install prometheus-statsd-exporter hahow/prometheus-statsd-exporter -n monitoring --set service.type=NodePort
```

Get IP and port of the `prometheus-statsd-exporter` service and run the k6 load test:

```sh
docker run -e K6_STATSD_ADDR=<NODE_IP_>:<NODEPORT> -i loadimpact/k6 run --vus 10 -o statsd --duration 30s - <home/vagrant/src/load-testing/k6/script.js
```

Import [Grafana dashboard](https://grafana.com/grafana/dashboards/13861) (Dashboard ID: 13861).

TODO: fix K6 Request Name annotation in Grafana (via mapping-config?)

## Load Testing the MQTT Broker

For example:
```sh
docker run --rm inovex/mqtt-stresser -broker tcp://192.168.99.149:1883 -num-clients 100 -num-messages 500
```

Import the MQTT Dashboard under `/grafana-dashboards/` in Grafana to view some MQTT specific metrics.
