# 12-Factor App

The 12-Factor App methodology provides a **baseline for cloud-native and AI-enabled systems**.

## Core Principles

1. **Single Codebase, Many Deployments**
2. **Explicit Dependency Isolation**
3. **Environment-Based Configuration**
4. **Attached Resources**
5. **Disposability**



+-------------------+

Application
Business Logic
+---------+---------+
      |


Env / Config
|
+---------v---------+
| DB | Cache | LLM |
+-------------------+


> Systems that violate these principles fail operationally before they reach scale.
