# Part VI — Advanced Panel: Templates, Reactive Programming, Param, Custom Components, and Enterprise Dashboard Architecture

# Lesson 6.6 — Custom Panel Components, JavaScript Integration, ESM Components, and Extending Panel Beyond Python

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand why custom components exist.
> * Learn how Panel communicates with JavaScript.
> * Understand the Panel ↔ Bokeh ↔ Browser architecture.
> * Build custom Panel components.
> * Understand ESM (ECMAScript Module) components.
> * Integrate third-party JavaScript libraries.
> * Create professional financial visualizations.
> * Understand frontend/backend separation.
> * Learn how modern UI frameworks extend themselves.
> * Think like a framework engineer rather than a framework user.

---

# Introduction

Throughout this tutorial, we've used built-in Panel widgets:

```python
pn.widgets.Button()

pn.widgets.Select()

pn.widgets.FloatSlider()

pn.indicators.Number()
```

Eventually, however, every serious developer encounters this problem:

> What if the widget I need doesn't exist?

Suppose we want:

* a Bloomberg-style heatmap
* a TradingView chart
* a Level-II order book
* a market depth ladder
* a candlestick replay widget
* a real-time order flow visualization

Panel does not provide these.

So what do we do?

---

# The Answer

Professional developers do not ask:

> Which widget should I use?

They ask:

> How do I build the widget myself?

---

# Understanding The Stack

Many people think:

```text
Panel

↓

Browser
```

This is incorrect.

The actual architecture is:

```text
Python

↓

Panel

↓

Bokeh

↓

JavaScript

↓

Browser
```

---

# Visualizing The Architecture

```text
Application Code

↓

Panel

↓

Bokeh Model

↓

JSON Protocol

↓

WebSocket

↓

BokehJS

↓

Browser DOM
```

---

# Why Bokeh Matters

Panel itself does not render widgets.

Instead:

```text
Panel

↓

Creates Bokeh Objects

↓

Bokeh Renders Browser UI
```

---

# Example

When we write:

```python
slider = pn.widgets.FloatSlider()
```

internally:

```text
Panel Widget

↓

Bokeh Model

↓

JSON

↓

Browser Widget
```

---

# Why Is This Important?

Because:

> If we can create Bokeh models, we can create Panel components.

---

# Understanding Frontend vs Backend

Our SGX application actually consists of:

---

## Backend

```text
Python

APIs

Analytics

State

Business Logic
```

---

## Frontend

```text
HTML

CSS

JavaScript

Browser Rendering
```

---

# Visualizing

```text
Backend

↓

JSON

↓

Frontend
```

---

# Why JavaScript Exists

Python cannot do:

* DOM manipulation
* browser rendering
* animations
* GPU graphics
* browser events

JavaScript performs these tasks.

---

# Example

Suppose we build:

```text
Real-Time SGX Heatmap
```

The browser may need:

```text
60 FPS Animation
```

Python cannot efficiently perform this.

JavaScript can.

---

# Understanding Custom Components

A custom component contains:

```text
Python Model

+

JavaScript View

+

Synchronization Layer
```

---

# Visualizing

```text
Python Object

↓

Serialize

↓

JavaScript Component

↓

Browser
```

---

# Why Build Custom Components?

Examples:

| Requirement                | Built-In Widget? |
| -------------------------- | ---------------- |
| TradingView Chart          | ❌                |
| Order Book Ladder          | ❌                |
| Market Heatmap             | ❌                |
| Candlestick Replay         | ❌                |
| Portfolio Treemap          | ❌                |
| Market Depth Visualization | ❌                |

---

# Example: Bloomberg Heatmap

Suppose we want:

```text
SGX Heatmap

DBS      +2.1%

UOB      -1.4%

OCBC     +0.8%
```

with:

* animations
* transitions
* hover effects
* GPU acceleration

---

# Traditional Approach

```python
pn.GridBox(...)
```

This quickly becomes:

```text
Painful
```

---

# Better Approach

Build:

```text
SGXHeatmapComponent
```

---

# Understanding ESM

ESM means:

> ECMAScript Modules.

---

# Traditional JavaScript

Old JavaScript:

```javascript
function calculate() {

}
```

Everything lived globally.

---

# Modern JavaScript

Modern JavaScript uses:

```javascript
export function calculate() {

}
```

and:

```javascript
import {

    calculate

} from "./module.js"
```

---

# Why ESM Matters

Benefits:

* modularity
* encapsulation
* reuse
* maintainability
* performance

---

# Panel Supports ESM Components

This means:

```text
Python

↓

Panel

↓

JavaScript Modules

↓

Browser
```

---

# Simplest ESM Component

Example:

```python
import panel as pn

class HelloWorld(
    pn.custom.JSComponent
):
    pass
```

---

# What Happens?

Panel creates:

```text
Python Object

↓

JavaScript Component

↓

Browser Element
```

---

# Understanding JSComponent

A JSComponent contains:

```text
Python

+

JavaScript

+

Synchronization
```

---

# Visualizing

```text
JSComponent

├── Python State
├── JavaScript View
└── Browser DOM
```

---

# Example Structure

```text
components/

└── sgx_heatmap/

    ├── component.py

    ├── component.js

    └── styles.css
```

---

# Python Side

Example:

```python
import param
import panel as pn

class HeatMap(

    pn.custom.JSComponent
):

    data = param.List()
```

---

# JavaScript Side

Example:

```javascript
export function render({

    model,

    el

}) {

    el.innerHTML =

        "SGX Heatmap"
}
```

---

# Visualizing

```text
Python Data

↓

Serialize

↓

JavaScript Render

↓

Browser DOM
```

---

# Understanding Properties

Suppose:

```python
heatmap.data = prices
```

changes.

Panel performs:

```text
Python

↓

JSON

↓

JavaScript

↓

Update DOM
```

automatically.

---

# Example

Python:

```python
heatmap.data = [

    "D05",

    "U11"
]
```

---

# Browser Receives

```javascript
model.data
```

---

# Why This Is Powerful

We can build:

* custom charts
* custom widgets
* custom visualizations
* custom interactions

using Python.

---

# Example: TradingView Integration

Suppose we want:

```text
TradingView Widget
```

---

# Architecture

```text
Python

↓

Symbol

↓

TradingView JS

↓

Browser Chart
```

---

# Example

```python
class TradingViewChart(

    pn.custom.JSComponent
):

    symbol = param.String()
```

---

# JavaScript

```javascript
new TradingView.widget({

    symbol:

        model.symbol
})
```

---

# Visualizing

```text
Python Symbol

↓

TradingView

↓

Interactive Chart
```

---

# Example: SGX Market Depth Widget

Suppose we want:

```text
BUY

41.20

5000
```

and:

```text
SELL

41.25

6000
```

displayed as:

```text
Order Ladder
```

---

# Architecture

```text
Python Order Book

↓

JS Component

↓

Animated Visualization
```

---

# Third-Party Libraries

Panel can integrate with:

* D3.js
* Plotly.js
* ECharts
* Three.js
* TradingView
* Chart.js
* Leaflet
* Cytoscape

---

# Example

```text
Python

↓

Panel

↓

D3.js

↓

Browser
```

---

# Why D3 Matters

D3 provides:

* animation
* SVG rendering
* interaction
* visualization

---

# Example: Market Treemap

```text
Finance

├── DBS
├── UOB
└── OCBC
```

with:

* color
* size
* animation

---

# Example Architecture

```text
Market Data

↓

Python

↓

Panel

↓

D3

↓

Treemap
```

---

# Understanding State Synchronization

Suppose:

```python
price = 41
```

becomes:

```python
price = 42
```

---

# Synchronization Pipeline

```text
Python

↓

Serialize

↓

WebSocket

↓

JavaScript

↓

DOM Update
```

---

# Browser Events

Suppose user clicks:

```text
BUY
```

---

# Event Pipeline

```text
Browser

↓

JavaScript

↓

WebSocket

↓

Python

↓

Callback
```

---

# Two-Way Synchronization

```text
Python

↕

WebSocket

↕

JavaScript
```

---

# Example: Live SGX Dashboard

```text
SGX API

↓

Python

↓

Panel

↓

TradingView

↓

Browser
```

---

# Why Custom Components Matter

Suppose your company requires:

```text
Bloomberg Terminal Clone
```

There is no package called:

```bash
pip install bloomberg-terminal
```

Someone must build it.

---

# Component Packaging

Professional organizations build:

```text
company_components/

├── charts/
├── heatmaps/
├── tables/
├── indicators/
├── analytics/
└── trading/
```

---

# Example

```text
components/

├── sgx_heatmap
├── sgx_orderbook
├── sgx_tradingview
├── sgx_portfolio
└── sgx_news
```

---

# Testing Components

Custom components require testing.

---

# Python Tests

```python
assert heatmap.data
```

---

# JavaScript Tests

```javascript
expect(

    component.data

).toBeTruthy()
```

---

# Why Testing Matters

Custom components contain:

```text
Python

+

JavaScript

+

Synchronization
```

which creates:

```text
Three Failure Points
```

---

# Performance Considerations

Poorly written components can cause:

* browser freezes
* memory leaks
* excessive network traffic
* slow rendering

---

# Example

Bad:

```text
1000 Updates

Per Second
```

---

# Better:

```text
10 Batched Updates

Per Second
```

---

# Enterprise Architecture

Large organizations build:

```text
Applications

↓

Templates

↓

Views

↓

Components

↓

JS Components

↓

Browser
```

---

# Real Bloomberg Architecture

Conceptually:

```text
Bloomberg Terminal

├── Charts
├── Order Books
├── News
├── Analytics
├── Portfolios
├── Messaging
└── Market Data
```

where every item is:

```text
A Component
```

---

# Thinking Like A Framework Engineer

Beginners ask:

> Which widget should I use?

Intermediate developers ask:

> Which library should I install?

Framework engineers ask:

> What abstraction should I create?

Because frameworks themselves are built from:

```text
Components

+

State

+

Synchronization
```

---

# The Hidden Secret

Eventually every large application discovers:

> The framework is not enough.

At that point:

```text
Application Developer

↓

Framework Extender

↓

Framework Designer
```

becomes the natural progression.

---

# Teacher's Notes

> One of the most important realizations in software engineering is that every framework eventually becomes insufficient for a sufficiently ambitious application. Professional engineers distinguish themselves by their ability to extend frameworks rather than merely consume them.
>
> Another important lesson is that modern frontend engineering is fundamentally about managing synchronization between multiple execution environments: Python, JavaScript, browsers, servers, and users.

---

# Common Mistakes

## ❌ Mistake 1

Thinking Panel eliminates JavaScript.

---

## ❌ Mistake 2

Ignoring browser performance.

---

## ❌ Mistake 3

Creating giant monolithic components.

---

## ❌ Mistake 4

Sending excessive data over WebSockets.

---

## ❌ Mistake 5

Treating custom components as "advanced widgets."

---

# Summary

In this lesson, you learned:

* Panel sits on top of Bokeh.
* Custom components extend Panel.
* JavaScript performs browser rendering.
* ESM provides modular frontend architecture.
* JSComponent bridges Python and JavaScript.
* Third-party JavaScript libraries integrate with Panel.
* State synchronization drives custom components.
* Enterprise systems build component libraries.
* Performance and testing become critical.
* Framework engineering begins when framework usage ends.

You now understand how professional developers extend Panel beyond its built-in capabilities.

---

# Exercises

## Exercise 1 — Design An SGX Heatmap Component

Design a component containing:

* stock symbols
* market capitalization
* percentage change
* color mapping
* animations

---

## Exercise 2 — Design An Order Book Component

Design:

```text
BUY PRICE | SELL PRICE
```

including:

* bid depth
* ask depth
* animations
* updates

---

## Exercise 3 — Design A Component Library

Create a component hierarchy for:

```text
SGX Professional Trading Terminal
```

including:

* charts
* heatmaps
* order books
* portfolios
* alerts
* analytics
* news

---

# Coming Up Next

In **Lesson 6.7 — Performance Engineering: Caching, Memoization, Virtualization, Asynchronous Updates, and Scaling Panel Applications**, we'll learn how professional Panel applications handle millions of data points, thousands of widgets, real-time market streams, asynchronous processing, caching layers, and performance optimization techniques used in enterprise financial systems.
