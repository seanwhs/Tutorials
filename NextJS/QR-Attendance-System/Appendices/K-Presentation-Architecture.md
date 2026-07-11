# Appendix K

# Presentation Architecture

> *"The user interface is the visible surface of a distributed system. Its responsibility is not merely to render data, but to communicate progress, uncertainty, success, and failure in ways that inspire confidence."*

---

# Purpose

The Presentation Layer transforms business capabilities into user experiences.

Within the reference implementation, this responsibility is fulfilled using **Next.js 16 App Router**, **React Server Components**, **Client Components**, and **Server Actions**.

The Presentation Layer does not contain business rules.

Instead, it focuses on:

* Rendering information.
* Collecting user intent.
* Providing responsive feedback.
* Managing transient UI state.
* Recovering gracefully from failures.
* Supporting accessibility and offline operation.

Business behavior remains delegated to the Application Services and Durable Workflow layers.

---

# Design Philosophy

The presentation architecture follows several principles.

* Server-first rendering.
* Progressive enhancement.
* Minimal client JavaScript.
* Optimistic interactions.
* Accessible by default.
* Resilient under poor network conditions.
* Predictable user feedback.
* Framework features over custom infrastructure.

The objective is to produce interfaces that remain fast and reliable regardless of network quality or workload.

---

# Architectural Position

```text
                        Browser
                           │
                           ▼
                  Client Components
                           ▲
                           │
                  Server Components
                           ▲
                           │
                    Server Actions
                           ▲
                           │
                 Application Services
                           ▲
                           │
                  Durable Workflows
```

Presentation initiates business operations but never owns them.

---

# Rendering Strategy

The application adopts a **Server Component-first** architecture.

Pages responsible for displaying event information, schedules, venues, and attendance summaries are rendered on the server.

Examples include:

* Event landing pages.
* Venue details.
* Session schedules.
* Attendance dashboards.
* Administrative reports.

Rendering on the server reduces JavaScript payloads while improving initial load performance.

---

# Client Components

Client Components are introduced only when interactivity requires browser capabilities.

Typical examples include:

* QR scanner.
* Camera access.
* Live attendance counter.
* Theme switcher.
* Interactive charts.
* Form validation.
* Network status indicator.

Everything else remains server-rendered.

---

# Component Hierarchy

The presentation layer is organized into composable components.

```text
App Layout
     │
     ▼
 Event Page
     │
 ┌───┴────────────┐
 ▼                ▼
Header      Attendance Card
                    │
        ┌───────────┴──────────┐
        ▼                      ▼
Check-In Button          Event Status
```

Components communicate through explicit properties rather than shared mutable state.

---

# Server Components

Server Components perform:

* Data retrieval.
* Authorization-aware rendering.
* Static generation where appropriate.
* Metadata generation.
* Initial page composition.

They do not contain client-side event handlers.

---

# Client Components

Client Components manage:

* User interactions.
* Form state.
* Camera access.
* Browser APIs.
* Optimistic updates.
* Offline queue status.

Client-side state remains local and short-lived.

---

# Optimistic User Experience

Attendance is recorded synchronously, but downstream processing continues asynchronously.

The interface therefore acknowledges user intent immediately.

Typical interaction:

```text
Tap Check In

↓

Button Disabled

↓

Spinner Appears

↓

Attendance Accepted

↓

Confirmation Screen

↓

Background Processing Continues
```

The attendee should never wait for analytics or email delivery.

---

> **Production Tip — Design for Perceived Performance**
>
> Users evaluate responsiveness by how quickly the interface acknowledges their action, not by how quickly every background process completes. Persist the critical business state, return immediately, and let workflows handle everything else.

---

# Progressive Enhancement

Every critical interaction should continue functioning even if JavaScript is unavailable or partially loaded.

Examples include:

* Server-rendered forms.
* Native HTML validation.
* Accessible navigation.
* Semantic markup.

JavaScript enhances the experience rather than defining it.

---

# Error Presentation

Failures should be communicated clearly.

Categories include:

| Error          | User Experience       |
| -------------- | --------------------- |
| Validation     | Inline guidance       |
| Authorization  | Access denied page    |
| Business Rule  | Informational message |
| Infrastructure | Retry option          |
| Offline        | Queue locally         |

Users should always understand what happened and what action, if any, they should take.

---

# Loading States

Distributed systems spend much of their time waiting.

The interface should communicate this clearly.

Recommended techniques include:

* Skeleton screens.
* Progress indicators.
* Deferred content.
* Streaming rendering.
* Optimistic placeholders.

Loading should feel intentional rather than accidental.

---

# Accessibility

Accessibility is treated as an engineering requirement.

The presentation layer supports:

* Keyboard navigation.
* Screen readers.
* Semantic HTML.
* ARIA attributes where necessary.
* Color-independent status indicators.
* Logical focus management.

Accessibility improves usability for all users, not only those relying on assistive technologies.

---

# Responsive Design

The application supports:

* Mobile phones.
* Tablets.
* Laptops.
* Desktop displays.
* Large event kiosks.

Layouts adapt using responsive design rather than maintaining separate implementations.

---

# Offline Experience

Connectivity cannot be assumed at large venues.

The interface therefore supports:

* Offline detection.
* Local request queueing.
* Background synchronization.
* Pending attendance indicators.
* Automatic retry after reconnection.

The user experience remains consistent regardless of network quality.

---

# Real-Time Updates

Some interfaces require live information.

Examples include:

* Attendance counters.
* Capacity indicators.
* Organizer dashboards.
* Session occupancy.

The presentation layer receives updates without requiring full page refreshes.

---

# Navigation

Navigation follows task-oriented rather than technology-oriented organization.

Typical journeys include:

```text
Dashboard

↓

Organization

↓

Event

↓

Session

↓

Attendance
```

Users navigate business concepts instead of implementation details.

---

# Observability

Presentation telemetry complements backend monitoring.

Examples include:

* Page load duration.
* Interaction latency.
* Navigation timing.
* Client-side errors.
* Offline events.
* Retry attempts.

Combined with backend telemetry, these metrics provide end-to-end visibility.

---

# Reference Implementation

The implementation accompanying this appendix includes:

* Layout hierarchy.
* Server Components.
* Client Components.
* Shared UI library.
* Form components.
* Dashboard widgets.
* Loading states.
* Error boundaries.
* Accessibility helpers.
* Offline components.

Together, these components define the complete presentation architecture of the attendance platform.

---

# Looking Ahead

The final appendix shifts from implementation to operations.

Building software is only the first step.

Operating software in production requires security, monitoring, testing, deployment, resilience, and continuous improvement.

These operational concerns complete the engineering lifecycle and ensure that the system remains reliable long after it has been deployed.
