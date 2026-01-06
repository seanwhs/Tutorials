# Service Mesh Example (Conceptual)

Services communicate via sidecar proxies:


```
[ Service A ] <-> [ Sidecar A ] <-> [ Network ]
[ Service B ] <-> [ Sidecar B ] <-> [ Network ]
```

- Requests are encrypted (mTLS)
- Retries, circuit breaking, traffic shaping handled automatically
- Service code does not implement these concerns
