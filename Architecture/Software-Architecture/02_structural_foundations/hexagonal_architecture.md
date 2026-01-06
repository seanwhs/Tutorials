# Hexagonal Architecture (Ports & Adapters)

## Definition

Business logic is at the core and interacts with the outside world via **ports** and **adapters**.


    [ UI / Agent ]
          |
    +-----v-----+
    |   Port    |


+-------+-----------+-------+
| Business Logic |
+-------+-----------+-------+
| Port |
+-----^-----+
|
[ DB / API / Vector ]


## Benefits

- Supports rapid substitution of technology layers
- Prevents business logic from being tightly coupled to infrastructure
