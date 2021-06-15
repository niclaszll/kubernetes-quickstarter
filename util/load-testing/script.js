import http from "k6/http";
import { check, sleep } from "k6";
import { Rate } from "k6/metrics";

// Scale to 2 VUs over 10s, keep those 2 VUs for 20s and scale down over 10s
export let options = {
  "stages": [
    { "target": 2, "duration": "10s" }, // ramp-up
    { "target": 2, "duration": "20s" }, // steady
    { "target": 0, "duration": "10s" }  // ramp-down
  ]
}

// K6 "Rate" metric for counting Javascript errors during a test run.
var script_errors = Rate("script_errors");

// Wraps a K6 test function with error counting.
function wrapWithErrorCounting(fn) {
  return (data) => {
    try {
      fn(data);
      script_errors.add(0);
    } catch (e) {
      script_errors.add(1);
      throw e;
    }
  }
}

// A very simple test
function simpleTest() {
  let response = http.get("http://nginx.default.svc.cluster.local", { "tags": { "name": "simple-test" } });
  check(response, {
    "200 OK": (r) => r.status === 200,
  });
  sleep(0.5);
}

export default wrapWithErrorCounting(simpleTest);