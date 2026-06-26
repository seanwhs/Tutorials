# Part VI — Advanced Panel: Templates, Reactive Programming, Param, Custom Components, and Enterprise Dashboard Architecture

# Lesson 6.4 — Panel Templates: FastListTemplate, MaterialTemplate, BootstrapTemplate, and Professional Dashboard Layout Architecture

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand why templates exist.
> * Learn the difference between layouts and templates.
> * Master FastListTemplate.
> * Master MaterialTemplate.
> * Master BootstrapTemplate.
> * Build professional dashboard navigation systems.
> * Design enterprise dashboard layouts.
> * Implement themes and branding.
> * Organize large dashboard applications.
> * Think like a dashboard architect rather than a dashboard developer.

---

# Introduction

Throughout this tutorial, we've built dashboards using:

```python
pn.Column()

pn.Row()

pn.GridBox()
```

For example:

```python
dashboard = pn.Column(
    header,
    controls,
    chart,
    table
)
```

This works.

But eventually, every dashboard developer encounters a problem.

---

# The Problem

Suppose management asks:

> Build a Bloomberg Terminal for SGX.

Suddenly, our dashboard requires:

* header
* navigation
* sidebar
* user profile
* watchlist
* analytics
* alerts
* market news
* charts
* portfolio views
* settings
* themes

Our code becomes:

```python
pn.Column(
    pn.Row(...),
    pn.Row(...),
    pn.Row(...),
    pn.Row(...),
    pn.Row(...),
    pn.Row(...)
)
```

Very quickly:

```text
Chaos
```

results.

---

# Why Layouts Don't Scale

Basic layouts answer:

> Where should components go?

But enterprise dashboards require:

* branding
* navigation
* authentication
* sidebars
* menus
* themes
* responsiveness
* application structure

---

# This Is Why Templates Exist

Templates answer:

> How should the entire application be organized?

---

# Visualizing The Difference

## Layout

```text
Chart

Table

Button
```

---

## Template

```text
Application

├── Header
├── Sidebar
├── Main Area
├── Footer
└── Navigation
```

---

# Real Applications Use Templates

Examples:

* Bloomberg Terminal
* TradingView
* Interactive Brokers
* Yahoo Finance
* SGX Trading Portal

all use:

```text
Application Templates
```

---

# Panel Templates

Panel provides several templates:

| Template          | Style                  |
| ----------------- | ---------------------- |
| FastListTemplate  | Modern                 |
| MaterialTemplate  | Google Material Design |
| BootstrapTemplate | Bootstrap Framework    |
| FastGridTemplate  | Grid Layout            |
| GoldenTemplate    | Research Dashboards    |
| ReactTemplate     | React-style Apps       |

---

# The Simplest Template

```python
import panel as pn

template = pn.template.FastListTemplate(
    title="SGX Dashboard"
)

template.servable()
```

---

# What Happens?

Panel creates:

```text
Browser

↓

Professional Web Application
```

automatically.

---

# Visualizing FastListTemplate

```text
┌──────────────────────┐
│ Header               │
├─────────┬────────────┤
│ Sidebar │ Main Area  │
│         │            │
│         │            │
└─────────┴────────────┘
```

---

# Why FastListTemplate Is Popular

Benefits:

* responsive
* modern
* fast
* lightweight
* production-ready

---

# Creating Our First SGX Template

```python
import panel as pn

pn.extension()

template = pn.template.FastListTemplate(

    title="SGX Market Monitor"
)
```

---

# Adding Sidebar Components

```python
template.sidebar.append(

    pn.widgets.Select(
        name="Stock"
    )
)
```

---

# Adding Main Content

```python
template.main.append(

    price_chart
)
```

---

# Visualizing

```text
┌──────────────────────────┐
│ SGX Market Monitor       │
├──────────┬───────────────┤
│ Sidebar  │ Price Chart   │
│          │               │
│          │               │
└──────────┴───────────────┘
```

---

# Building A Professional SGX Dashboard

Sidebar:

```text
Watchlist

Portfolio

Alerts

Analytics

Settings
```

Main:

```text
Charts

Tables

Indicators

News
```

---

# Example

```python
template.sidebar.extend([

    watchlist,

    portfolio,

    alerts
])
```

---

```python
template.main.extend([

    chart,

    indicators,

    news
])
```

---

# FastListTemplate Regions

FastListTemplate provides:

```text
Header

Sidebar

Main
```

---

# Architecture

```text
Template

├── Header
├── Sidebar
└── Main
```

---

# Understanding Material Design

Google introduced:

> Material Design.

Principles include:

* consistency
* simplicity
* hierarchy
* accessibility
* responsiveness

---

# MaterialTemplate

Example:

```python
template = pn.template.MaterialTemplate(

    title="SGX Dashboard"
)
```

---

# Visual Appearance

```text
Google

↓

Gmail

↓

Material Design

↓

Panel MaterialTemplate
```

---

# Material Layout

```text
┌──────────────────────┐
│ Toolbar              │
├─────────┬────────────┤
│ Menu    │ Content    │
│         │            │
└─────────┴────────────┘
```

---

# Why Material Design Works

Humans prefer interfaces with:

* visual consistency
* predictable navigation
* clear hierarchy

---

# Understanding Bootstrap

Bootstrap is:

> The world's most popular CSS framework.

---

# BootstrapTemplate

Example:

```python
template = pn.template.BootstrapTemplate(

    title="SGX Dashboard"
)
```

---

# Bootstrap Philosophy

Bootstrap emphasizes:

* grids
* responsiveness
* consistency
* enterprise applications

---

# Bootstrap Layout

```text
Container

↓

Rows

↓

Columns

↓

Components
```

---

# Comparing Templates

| Feature        | Fast | Material | Bootstrap |
| -------------- | ---- | -------- | --------- |
| Modern         | ✅    | ✅        | ✅         |
| Enterprise     | ✅    | ✅        | ✅         |
| Lightweight    | ✅    | Medium   | Medium    |
| Customizable   | High | Medium   | Very High |
| Learning Curve | Easy | Easy     | Medium    |

---

# Which Template Should We Use?

For financial dashboards:

```text
FastListTemplate
```

is usually the best choice.

---

# Why?

Because financial dashboards require:

* speed
* information density
* responsiveness
* scalability

---

# Understanding Headers

Headers contain:

* branding
* logos
* user profile
* notifications
* search
* menus

---

# Example

```python
header = pn.pane.Markdown(

    "# SGX Trading Terminal"
)
```

---

# Visualizing

```text
┌─────────────────────────┐
│ SGX Trading Terminal    │
└─────────────────────────┘
```

---

# Understanding Sidebars

Sidebars contain:

* navigation
* filters
* controls
* watchlists
* settings

---

# Example

```python
sidebar = [

    stock_selector,

    portfolio,

    alerts
]
```

---

# Understanding Main Areas

The main area contains:

* charts
* analytics
* tables
* dashboards

---

# Example

```python
main = [

    price_chart,

    news_table,

    indicators
]
```

---

# Dashboard Navigation

Professional systems contain multiple views.

Example:

```text
Dashboard

Portfolio

Analytics

Alerts

Settings
```

---

# Navigation Architecture

```text
Application

├── Dashboard
├── Portfolio
├── Analytics
├── Alerts
└── Settings
```

---

# Tabs

Example:

```python
tabs = pn.Tabs(

    ("Dashboard", dashboard),

    ("Portfolio", portfolio),

    ("Analytics", analytics)
)
```

---

# Visualizing

```text
Dashboard | Portfolio | Analytics
```

---

# Why Tabs Matter

Tabs provide:

* separation
* organization
* scalability

---

# Responsive Design

Modern dashboards run on:

* desktop
* laptop
* tablet
* mobile

---

# Responsive Layout

Desktop:

```text
Sidebar | Main
```

---

# Mobile:

```text
Sidebar

↓

Main
```

---

# Why Responsiveness Matters

Users increasingly access dashboards from:

* phones
* tablets
* hybrid devices

---

# Themes

Panel supports:

```text
Light Theme

Dark Theme
```

---

# Example

```python
template = pn.template.FastListTemplate(

    theme="dark"
)
```

---

# Why Financial Systems Prefer Dark Themes

Examples:

* Bloomberg
* TradingView
* Interactive Brokers

prefer:

```text
Dark Interfaces
```

because they:

* reduce eye strain
* improve contrast
* improve focus

---

# Adding Corporate Branding

Example:

```python
template = pn.template.FastListTemplate(

    title="SGX Analytics",

    logo="logo.png"
)
```

---

# Enterprise Branding

Applications typically include:

```text
Company Logo

Colors

Fonts

Icons

Themes
```

---

# Understanding Application Architecture

Small dashboards:

```text
One File
```

---

# Large dashboards:

```text
Application

├── templates
├── views
├── models
├── services
├── analytics
├── components
└── assets
```

---

# Example Project Structure

```text
sgx_dashboard/

├── app.py
├── templates/
├── views/
├── models/
├── services/
├── analytics/
├── components/
├── assets/
└── tests/
```

---

# Separating Views

Example:

```text
views/

├── market_view.py
├── portfolio_view.py
├── alerts_view.py
└── analytics_view.py
```

---

# Separating Components

```text
components/

├── charts.py
├── tables.py
├── widgets.py
└── indicators.py
```

---

# Separating Services

```text
services/

├── sgx_api.py
├── news_service.py
├── analytics_service.py
└── portfolio_service.py
```

---

# Why Separation Matters

Without separation:

```text
5000-Line app.py
```

results.

---

# Example Enterprise Architecture

```text
User

↓

Template

↓

Views

↓

Components

↓

Reactive Models

↓

Services

↓

APIs
```

---

# Building Our SGX Terminal

```text
SGX Terminal

├── Market Dashboard
├── Portfolio Dashboard
├── Alert Dashboard
├── Analytics Dashboard
├── News Dashboard
└── Settings Dashboard
```

---

# Visualizing The Final System

```text
┌─────────────────────────────┐
│ Header                      │
├──────────┬──────────────────┤
│ Sidebar  │ Dashboard Tabs   │
│          ├──────────────────┤
│          │ Charts           │
│          │ Analytics        │
│          │ Tables           │
│          │ News             │
└──────────┴──────────────────┘
```

---

# Thinking Like A Dashboard Architect

Beginners ask:

> Where should I place this chart?

Intermediate developers ask:

> Which layout should I use?

Dashboard architects ask:

> What is the information architecture of this application?

Because dashboards are not:

```text
Collections Of Widgets
```

They are:

```text
Information Systems
```

---

# Teacher's Notes

> One of the biggest mistakes beginners make is thinking templates are merely cosmetic. Templates actually define the application's information architecture, navigation model, and user experience.
>
> Another important lesson is that enterprise dashboard engineering is primarily an information organization problem rather than a visualization problem.

---

# Common Mistakes

## ❌ Mistake 1

Building everything with `pn.Column()`.

---

## ❌ Mistake 2

Creating giant dashboard files.

---

## ❌ Mistake 3

Ignoring navigation architecture.

---

## ❌ Mistake 4

Mixing business logic with UI code.

---

## ❌ Mistake 5

Treating dashboards as pages instead of applications.

---

# Summary

In this lesson, you learned:

* Templates organize entire applications.
* Layouts and templates solve different problems.
* FastListTemplate is ideal for financial dashboards.
* MaterialTemplate implements Material Design.
* BootstrapTemplate leverages Bootstrap architecture.
* Templates provide navigation and structure.
* Professional dashboards require information architecture.
* Themes and branding improve usability.
* Enterprise applications separate views and services.
* Dashboard engineering is fundamentally information architecture.

You now understand how professional Panel applications are structured.

---

# Exercises

## Exercise 1 — Design An SGX Terminal

Design the information architecture for:

```text
SGX Trading Terminal
```

Include:

* navigation
* sidebar
* main views
* dashboards

---

## Exercise 2 — Compare Templates

Compare:

* FastListTemplate
* MaterialTemplate
* BootstrapTemplate

Discuss:

* usability
* maintainability
* enterprise suitability

---

## Exercise 3 — Enterprise Project Structure

Design a repository structure for:

```text
SGX Professional Analytics Platform
```

Include:

* templates
* views
* models
* services
* analytics
* components
* assets

---

# Coming Up Next

In **Lesson 6.5 — Building Reusable Panel Components: Composite Widgets, Custom Views, Encapsulation, and Component-Oriented Dashboard Architecture**, we will learn how to stop building dashboards as pages and start building them as reusable component systems, similar to React components, Vue components, and enterprise UI frameworks.
