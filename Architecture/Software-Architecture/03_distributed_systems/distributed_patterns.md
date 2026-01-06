# Essential Distributed Patterns

## CQRS

```
Command ---> [ Write Model ] ---> SQL
Query ---> [ Read Model ] ---> Index / Cache
```

## Saga (Distributed Transactions)

```
Order -> Payment -> Shipping
| |
|<-- Compensate if fail
```

## Circuit Breaker

```
Service A --> [ Circuit ] --> Service B
X
(Open / Fail Fast)
```
I can continue populating the remaining directories (04_cloud_native/, 05_data_systems/, 06_ai_edge/,
