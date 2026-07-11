# Part 5 – Enterprise Threat Modeling Workshop (Hands-on)

This module is a complete end-to-end practical exercise.

Contents include:

## Module 1 – Scenario Overview

* Business requirements
* Functional requirements
* Non-functional requirements
* Security requirements
* Regulatory requirements
* Architecture assumptions

---

## Module 2 – System Architecture

Build a realistic enterprise architecture including:

* Internet
* CDN
* WAF
* Load Balancer
* API Gateway
* Authentication Service
* Identity Provider
* Microservices
* Kubernetes
* Service Mesh
* Redis Cache
* RabbitMQ
* Object Storage
* PostgreSQL
* SIEM
* Monitoring
* CI/CD Pipeline

Complete architecture diagrams.

---

## Module 3 – Data Flow Diagram Workshop

Students build DFD Level 0

Then

DFD Level 1

Then

DFD Level 2

Exercises include:

* Drawing processes
* Data stores
* Data flows
* Trust boundaries
* Security zones

---

## Module 4 – Asset Discovery Workshop

Identify

* Primary assets
* Secondary assets
* Infrastructure assets
* Secrets
* APIs
* Certificates
* Tokens

Classify assets

Public

Internal

Confidential

Restricted

---

## Module 5 – Threat Agent Analysis

Profile attackers

* Nation State
* Insider
* Script Kiddie
* Ransomware Group
* Hacktivist
* Competitor
* Organized Crime

Create attacker personas.

---

## Module 6 – STRIDE Workshop

Students apply STRIDE to

* Every process
* Every API
* Every data flow
* Every datastore

Generate 100+ threats.

---

## Module 7 – Threat Register

Complete professional register including

* Threat ID
* Description
* Asset
* Component
* STRIDE Category
* Likelihood
* Impact
* Risk
* Owner
* Status

---

## Module 8 – Risk Assessment

Apply

* DREAD
* CVSS
* Risk Matrix

Prioritize remediation.

---

## Module 9 – Mitigation Workshop

Map threats to

* Preventive controls
* Detective controls
* Corrective controls

Produce Security Architecture Decisions.

---

## Module 10 – Executive Presentation

Prepare

* Architecture Review
* Risk Dashboard
* Executive Summary
* Security Roadmap

---

# Part 6 – Threat Modeling for Modern Architectures

Over 20 architecture patterns.

Examples:

## Traditional Three-Tier Architecture

Threats

Mitigations

Case Study

---

## REST APIs

Authentication

Authorization

JWT

OAuth

API Keys

---

## GraphQL

Unique attack vectors

Introspection abuse

Query complexity

Batch attacks

---

## Microservices

Service-to-service authentication

Zero Trust

Service Mesh

Secrets

---

## Kubernetes

Pod escape

RBAC

Admission Controllers

Network Policies

Container Runtime

---

## Docker

Image signing

Image scanning

Rootless containers

---

## Serverless

AWS Lambda

Azure Functions

Google Cloud Functions

Cold starts

IAM

---

## Event-Driven Systems

Kafka

RabbitMQ

Azure Service Bus

Amazon SQS

---

## Cloud Storage

AWS S3

Azure Blob

Google Cloud Storage

Misconfigurations

Public buckets

---

## AI Systems

LLMs

Prompt Injection

Model Theft

Data Poisoning

Model Supply Chain

AI Agents

MCP

---

## IoT

Edge Computing

Smart Devices

Industrial Control Systems

---

## Mobile Applications

Android

iOS

Certificate pinning

Secure storage

Biometrics

---

## Blockchain

Smart contracts

Wallet security

Consensus attacks

---

# Part 7 – Threat Modeling for Cloud (AWS, Azure & GCP)

Dedicated cloud architecture course.

Includes

AWS

Azure

Google Cloud

Topics

IAM

VPC

Security Groups

Network ACL

Private Link

Transit Gateway

API Gateway

Lambda

EKS

AKS

GKE

Cloud SQL

Key Vault

Secrets Manager

CloudTrail

Azure Defender

Security Command Center

---

# Part 8 – DevSecOps Threat Modeling

Threat Modeling inside

GitHub Actions

GitLab CI

Azure DevOps

Jenkins

ArgoCD

FluxCD

Terraform

Ansible

Pulumi

Includes

Pipeline security

Supply chain attacks

SBOM

SLSA

Sigstore

Cosign

Container signing

Policy-as-Code

OPA

Kyverno

---

# Part 9 – Threat Modeling Templates & Toolkit

Ready-to-use templates including:

* Threat Model Report
* STRIDE Worksheet
* DREAD Worksheet
* CVSS Calculator Worksheet
* Risk Register
* Residual Risk Register
* Security Architecture Review Checklist
* DFD Stencils
* Trust Boundary Templates
* Architecture Review Checklist
* Threat Modeling Checklist
* Security Requirements Checklist
* Secure Design Review Checklist
* Executive Reporting Templates

---

# Part 10 – Capstone Project

A comprehensive enterprise case study where participants perform a complete threat modeling engagement.

### Scenario

A multinational financial institution is migrating its legacy banking platform to a cloud-native, Kubernetes-based microservices architecture spanning multiple cloud regions. The environment includes:

* Customer web and mobile applications
* API Gateway
* Identity and Access Management (IAM)
* Microservices
* Event-driven messaging
* Payment processing
* Fraud detection
* Third-party fintech integrations
* Data lake and analytics platform
* DevSecOps CI/CD pipeline
* SIEM and SOC integration

### Participants will:

1. Define the scope and assumptions.
2. Create Level 0, Level 1, and Level 2 Data Flow Diagrams.
3. Identify assets, actors, trust boundaries, and attack surfaces.
4. Apply STRIDE to every DFD component.
5. Build a comprehensive Threat Register.
6. Score threats using DREAD and map relevant implementation issues to CVSS.
7. Select and justify security controls using defense-in-depth principles.
8. Document residual risks and prepare risk acceptance recommendations.
9. Produce executive and technical reports.
10. Present findings to a mock Architecture Review Board.

This capstone brings together all concepts from the preceding modules and mirrors the workflow used in professional enterprise threat modeling engagements.
