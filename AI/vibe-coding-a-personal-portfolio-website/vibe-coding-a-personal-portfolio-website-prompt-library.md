# GSD + Antigravity Prompt Library for Freelance Consulting, Training, and Development

> Drop this file into your project as `PROMPTS.md` or `docs/PROMPTS.md`  
> Use these prompts with OpenCode, Claude Code, or any AI coding agent  
> Tailored for building a React + Sanity freelance commerce platform

---

## Quick Start

```bash
# Install Antigravity Awesome Skills
npm install -g antigravity-awesome-skills

# Or clone the skills library
git clone https://github.com/sickn33/antigravity-awesome-skills
```

### Essential Skills to Invoke

```text
@brainstorming        # Plan before you build
@concise-planning     # Organize tasks clearly
@lint-and-validate    # Keep code clean
@git-pushing          # Save work safely
@systematic-debugging # Fix bugs faster
@frontend-design      # Design UI components
@react-best-practices # Follow React patterns
@react-patterns       # Use React component patterns
@tailwind-patterns    # Style with Tailwind CSS
@seo-audit            # Optimize for search engines
```

### Commerce Skills for Freelance

```text
@conversion-optimization  # Optimize booking and contact flows
@pricing-structure        # Design pricing tiers and packages
@testimonials-integration # Display client quotes effectively
@case-study-structure     # Build case studies with outcomes
@booking-flow             # Design booking and calendar flows
```

---

## Phase 1: Project Initialization

### 1.1 System Intent Definition (Freelance Edition)

```text
Act as a senior software architect and GSD coach.

Use @brainstorming to help me define the system intent for a freelance consultant, trainer, and developer platform built with React and Sanity, vibe coded in OpenCode.

Before proposing any code, ask me the minimum set of questions needed to clarify:
- The job of the site (freelance commerce platform for consulting, training, development)
- The three primary audiences (companies/CEOs for consulting, leaders for training, teams for development)
- The real product (engineering judgment, architectural thinking, problem-solving, teaching, delivery)
- Whether this is a portfolio or a freelance business operating system (definitely the latter)
- The content types that deserve first-class status (Services, Case Studies, Curriculum, Testimonials, Packages, Booking)
- The unique value proposition (consulting and engineering anatomy vs. generic service cards)
- The expected evolution path (blog, courses, labs, research, booking system, pricing tiers)

After I answer, summarize the system intent in a concise architecture brief.
Create PROJECT.md and ROADMAP.md according to GSD initialization.
Do not generate code yet.
```

### 1.2 Create PROJECT.md

```text
Act as a GSD project manager.

Create PROJECT.md with the following structure:

# Project Name
[Your Name] - Freelance Consultant, Trainer, Developer

## System Intent
A freelance engineering commerce platform for consulting, training, and development that expresses expertise, documents outcomes, sells curriculum, and enables booking.

## Tech Stack
- Frontend: React + Next.js App Router
- CMS: Sanity (headless)
- Styling: Tailwind CSS
- AI Tool: OpenCode with GSD + Antigravity skills
- Deployment: Vercel

## Primary Audiences
1. Companies/CEOs (consulting)
2. Enterprise Leaders (training)
3. Product Teams/Engineering Managers (development)

## Content Types
- Service Offering (consulting, training, development)
- Case Study
- Curriculum + Modules + Labs
- Testimonial
- Package + Pricing Tier
- Booking Slot
- Article
- Testimonial

## Success Metrics
- Booking conversion rate
- Contact form submissions
- Curriculum sign-ups
- Service page engagement
- SEO ranking for consulting/training keywords

## Constraints
- Lightweight, laptop-friendly AI solutions
- Fast iteration cycle
- Content-first architecture
- Commerce-enabled from day one

Create this file in the project root.
```

### 1.3 Create ROADMAP.md

```text
Act as a GSD roadmap planner.

Create ROADMAP.md with the following milestones:

# Roadmap: Freelance Commerce Platform

## Milestone 1: System Intent + Content Model
- Define system intent
- Identify content types
- Map relationships
- Create PROJECT.md, ROADMAP.md, CONTEXT.md

## Milestone 2: Sanity Schemas
- Service Offering schema
- Case Study schema
- Curriculum schema
- Testimonial schema
- Package schema
- Booking Slot schema
- Article schema

## Milestone 3: React Components
- ServiceCard component
- CaseStudyAnatomy component
- CurriculumList component
- TestimonialGrid component
- PackagePricing component
- BookingForm component
- Hero section

## Milestone 4: Pages and Routing
- Home page
- Services page
- Case Studies page
- Curriculum page
- Testimonials page
- Packages page
- Booking page
- About page
- Contact page

## Milestone 5: Testing + Deployment
- Lint checks
- Component tests
- Page rendering tests
- Booking flow tests
- Deploy to Vercel

## Milestone 6: Iteration
- Add new services
- Add new courses
- Add new case studies
- Optimize conversion
- SEO improvements

Create this file in the project root.
```

---

## Phase 2: Discuss Phase

### 2.1 Implementation Context

```text
Act as a GSD system engineer.

Use @concise-planning to define the implementation context for my React + Sanity freelance platform.

Based on the system intent from PROJECT.md:
- Create CONTEXT.md with implementation details
- Clarify the folder structure for React components, Sanity schemas, and pages
- Define the editorial workflow in Sanity Studio for services, case studies, and curriculum
- Specify the data model and relationships between services, case studies, testimonials, and packages
- Add commerce fields: pricing, packages, booking slots, contact flows

Prefer architecture over visual design.  
Do not write implementation code unless I ask for it.
```

### 2.2 Create CONTEXT.md

```text
Act as a GSD context engineer.

Create CONTEXT.md with the following structure:

# Implementation Context

## Folder Structure
```
src/
  components/
    services/
      ServiceCard.tsx
      ServiceAnatomy.tsx
    case-studies/
      CaseStudyAnatomy.tsx
      CaseStudyList.tsx
    curriculum/
      CurriculumList.tsx
      ModuleItem.tsx
      LabItem.tsx
    testimonials/
      TestimonialGrid.tsx
      TestimonialCard.tsx
    packages/
      PackagePricing.tsx
      PricingTier.tsx
    booking/
      BookingForm.tsx
      BookingCalendar.tsx
    common/
      Hero.tsx
      Section.tsx
      Button.tsx
  pages/
    index.tsx
    services.tsx
    case-studies.tsx
    curriculum.tsx
    testimonials.tsx
    packages.tsx
    booking.tsx
    about.tsx
    contact.tsx
  schemas/
    service.js
    caseStudy.js
    curriculum.js
    module.js
    lab.js
    testimonial.js
    package.js
    pricingTier.js
    bookingSlot.js
    article.js
  lib/
    sanity.ts
    queries.ts
```

## Sanity Editorial Workflow
- Services: Create service offering with anatomy, pricing, packages
- Case Studies: Create case study with problem, constraints, outcomes
- Curriculum: Create course with modules and labs
- Testimonials: Add client quotes with outcomes
- Packages: Define pricing tiers with features
- Booking: Set available slots and contact flows

## Data Model Relationships
- Service → Case Studies (references)
- Service → Testimonials (references)
- Curriculum → Modules (array)
- Module → Labs (array)
- Package → Pricing Tiers (array)
- Booking → Service (reference)

Create this file in src/context/CONTEXT.md.
```

---

## Phase 3: Plan Phase

### 3.1 XML-Structured Task Plan

```text
Act as a GSD planner.

Use @brainstorming and @concise-planning to produce the plan phase for my React + Sanity freelance platform.

Generate XML-structured task units for each component and schema:

<Task id="sanity-service-schema">
  <Goal>Create Sanity schema for Service Offering</Goal>
  <Deliverables>src/schemas/service.js</Deliverables>
  <Rivals>None</Risks>
  <AcceptanceCriteria>Schema includes fields for problem domain, constraints, architecture approach, tradeoffs, outcomes, lessons learned, pricing, packages</AcceptanceCriteria>
</Task>

<Task id="sanity-case-study-schema">
  <Goal>Create Sanity schema for Case Study</Goal>
  <Deliverables>src/schemas/caseStudy.js</Deliverables>
  <Risks>None</Risks>
  <AcceptanceCriteria>Schema includes fields for problem, constraints, assumptions, architecture, tradeoffs, ADRs, outcomes, lessons learned</AcceptanceCriteria>
</Task>

<Task id="sanity-curriculum-schema">
  <Goal>Create Sanity schema for Curriculum</Goal>
  <Deliverables>src/schemas/curriculum.js, src/schemas/module.js, src/schemas/lab.js</Deliverables>
  <Risks>None</Risks>
  <AcceptanceCriteria>Schema includes fields for target audience, learning objectives, module breakdown, hands-on labs, certification path</AcceptanceCriteria>
</Task>

<Task id="react-service-card">
  <Goal>Create React ServiceCard component</Goal>
  <Deliverables>src/components/services/ServiceCard.tsx</Deliverables>
  <Risks>None</Risks>
  <AcceptanceCriteria>Component displays service anatomy with Tailwind styling, responsive design</AcceptanceCriteria>
</Task>

<Task id="react-case-study-anatomy">
  <Goal>Create React CaseStudyAnatomy component</Goal>
  <Deliverables>src/components/case-studies/CaseStudyAnatomy.tsx</Deliverables>
  <Risks>None</Risks>
  <AcceptanceCriteria>Component displays engineering anatomy with outcomes and lessons learned</AcceptanceCriteria>
</Task>

<Task id="page-services">
  <Goal>Create Services page</Goal>
  <Deliverables>src/pages/services.tsx</Deliverables>
  <Risks>None</Risks>
  <AcceptanceCriteria>Page includes service list, filtering by consulting/training/development, service anatomy cards</AcceptanceCriteria>
</Task>

<Task id="page-booking">
  <Goal>Create Booking page</Goal>
  <Deliverables>src/pages/booking.tsx</Deliverables>
  <Risks>None</Risks>
  <AcceptanceCriteria>Page includes booking form, calendar, contact flows</AcceptanceCriteria>
</Task>

For each task unit, define the goal, deliverables, risks, and acceptance criteria.
Do not collapse phases into one task.  
Keep the work small, explicit, and reviewable.
```

### 3.2 Create PLAN.md

```text
Act as a GSD planner.

Create PLAN.md with the following structure:

# Plan Phase: Freelance Commerce Platform

## Task Units

### M2.1: Sanity Schemas
- sanity-service-schema
- sanity-case-study-schema
- sanity-curriculum-schema
- sanity-testimonial-schema
- sanity-package-schema
- sanity-booking-slot-schema

### M3.1: React Components
- react-service-card
- react-case-study-anatomy
- react-curriculum-list
- react-testimonial-grid
- react-package-pricing
- react-booking-form

### M4.1: Pages
- page-home
- page-services
- page-case-studies
- page-curriculum
- page-testimonials
- page-packages
- page-booking
- page-about
- page-contact

## Execution Waves
Wave 1: Sanity schemas (M2.1)
Wave 2: React components (M3.1)
Wave 3: Pages (M4.1)

## Dependencies
- Schemas before components
- Components before pages
- Pages before testing

Create this file in src/plan/PLAN.md.
```

---

## Phase 4: Execution Phase

### 4.1 Sanity Schema: Service Offering

```text
Act as a GSD execution agent.

Use @react-best-practices to create the Sanity schema for Service Offering.

File: src/schemas/service.js

Requirements:
- Fields: title, slug, serviceType (consulting/training/development), problemDomain, constraints, architectureApproach, tradeoffs, adrs, outcomes, lessonsLearned, pricing, packages, tags, imageUrl
- Use Sanity's latest schema definition syntax
- Add validation for required fields
- Include references to Case Studies and Testimonials
- Add SEO fields (metaTitle, metaDescription)

First explain the schema strategy, then generate the code.
Commit with @git-pushing.
Validate with @lint-and-validate.
```

### 4.2 Sanity Schema: Case Study

```text
Act as a GSD execution agent.

Use @react-best-practices to create the Sanity schema for Case Study.

File: src/schemas/caseStudy.js

Requirements:
- Fields: title, slug, service (reference), problem, constraints, assumptions, architecture, tradeoffs, adrs, outcomes, lessonsLearned, imageUrl, clientName, clientIndustry, timeline
- Use Sanity's latest schema definition syntax
- Add validation for required fields
- Include rich text for architecture and outcomes
- Add SEO fields

First explain the schema strategy, then generate the code.
Commit with @git-pushing.
Validate with @lint-and-validate.
```

### 4.3 Sanity Schema: Curriculum

```text
Act as a GSD execution agent.

Use @react-best-practices to create the Sanity schema for Curriculum.

File: src/schemas/curriculum.js

Requirements:
- Fields: title, slug, targetAudience, learningObjectives, modules (array of references), certificationPath, duration, price, imageUrl, tags
- Use Sanity's latest schema definition syntax
- Add validation for required fields
- Include rich text for learning objectives
- Add SEO fields

First explain the schema strategy, then generate the code.
Commit with @git-pushing.
Validate with @lint-and-validate.
```

### 4.4 React Component: ServiceCard

```text
Act as a GSD execution agent.

Use @react-best-practices and @tailwind-patterns to create the React ServiceCard component.

File: src/components/services/ServiceCard.tsx

Requirements:
- Display service title, type, problem domain, outcomes
- Use Tailwind for styling
- Responsive design (mobile, tablet, desktop)
- TypeScript with proper types
- Import from Sanity content model
- Add hover effects and transitions

First explain the component strategy, then generate the code.
Commit with @git-pushing.
Validate with @lint-and-validate.
```

### 4.5 React Component: CaseStudyAnatomy

```text
Act as a GSD execution agent.

Use @react-best-practices and @tailwind-patterns to create the React CaseStudyAnatomy component.

File: src/components/case-studies/CaseStudyAnatomy.tsx

Requirements:
- Display case study engineering anatomy: problem, constraints, assumptions, architecture, tradeoffs, ADRs, outcomes, lessons learned
- Use Tailwind for styling
- Responsive design
- TypeScript with proper types
- Import from Sanity content model
- Add section dividers and typography

First explain the component strategy, then generate the code.
Commit with @git-pushing.
Validate with @lint-and-validate.
```

### 4.6 Page: Services

```text
Act as a GSD execution agent.

Use @frontend-design and @tailwind-patterns to create the Services page.

File: src/pages/services.tsx

Requirements:
- Display service list with filtering by consulting/training/development
- Use ServiceCard component
- Responsive design
- TypeScript with proper types
- Fetch from Sanity queries
- Add hero section and section dividers

First explain the page strategy, then generate the code.
Commit with @git-pushing.
Validate with @lint-and-validate.
```

### 4.7 Page: Booking

```text
Act as a GSD execution agent.

Use @frontend-design and @tailwind-patterns to create the Booking page.

File: src/pages/booking.tsx

Requirements:
- Display booking form with name, email, service type, date, message
- Add booking calendar component
- Add contact flows (email, phone, social links)
- Use Tailwind for styling
- Responsive design
- TypeScript with proper types
- Add form validation

First explain the page strategy, then generate the code.
Commit with @git-pushing.
Validate with @lint-and-validate.
Use @conversion-optimization to improve the booking flow.
```

---

## Phase 5: Verification Phase

### 5.1 Lint and Validate All Components

```text
Act as a GSD verifier.

Use @lint-and-validate on src/components/ for all React components.

Run:
- ESLint checks
- TypeScript type checks
- Tailwind style validation

Produce a verification report with pass/fail for each component.
```

### 5.2 Debug Booking Form Issues

```text
Act as a GSD debugger.

Use @systematic-debugging to fix the booking form error in the booking page.

Steps:
1. Identify the error
2. Analyze the cause
3. Propose a fix
4. Apply the fix
5. Re-run validation

Produce a debug report with the issue, cause, fix, and result.
```

### 5.3 SEO Audit

```text
Act as a GSD SEO auditor.

Use @seo-audit to optimize the freelance platform for search engines.

Check:
- Meta tags on all pages
- Sitemap.xml
- structured data for services
- Alt text on images
- Page titles
- Heading structure

Produce an SEO report with recommendations.
```

---

## Phase 6: Iteration and Review

### 6.1 GSD Review

```text
Act as a GSD reviewer.

When you run `/gsd:review` (or `/gsd_review` in OpenCode), the workflow:
1. Detects which CLIs are available (opencode and claude)
2. Gathers the phase context (PROJECT.md, ROADMAP.md, PLAN.md, CONTEXT.md)
3. Builds a structured review prompt
4. Invokes all 6 reviewers in parallel

Use this to review the current milestone of my React + Sanity freelance platform.
Evaluate:
- Adherence to system intent (freelance commerce platform for consulting, training, development)
- Quality of content model for services, case studies, curriculum
- Component structure and reusability
- UI consistency and responsiveness
- Editorial workflow in Sanity
- Commerce and booking flows

Output a structured review with recommendations.
```

### 6.2 Conversion Optimization

```text
Act as a conversion optimizer.

Use @conversion-optimization to improve the booking flow and contact forms for higher conversion rates.

Check:
- Form length and complexity
- Button placement and labels
- Trust signals (testimonials, case studies)
- Clear value propositions
- Mobile experience

Produce a conversion report with recommendations.
```

### 6.3 Add New Service

```text
Act as a GSD content engineer.

Use @brainstorming to help me add a new service offering to the platform.

Steps:
1. Define the service type (consulting/training/development)
2. Define the problem domain
3. Define the architecture approach
4. Define the outcomes
5. Create the Sanity schema entry
6. Create the ServiceCard component data

Add the new service to the platform.
Commit with @git-pushing.
Validate with @lint-and-validate.
```

---

## Antigravity Skills Quick Reference

### Essential Commands

```bash
# Invoke a skill in OpenCode
@brainstorming
@concise-planning
@lint-and-validate
@git-pushing
@systematic-debugging
```

### Web Development Commands

```bash
@frontend-design
@react-best-practices
@react-patterns
@tailwind-patterns
@seo-audit
```

### Commerce Commands

```bash
@conversion-optimization
@pricing-structure
@testimonials-integration
@case-study-structure
@booking-flow
```

---

## GSD CLI Commands in OpenCode

```bash
# Initialize new project
/gsd:new-project

# Plan phase
/gsd:plan-phase

# Execute phase
/gsd:execute-phase

# Verify work
/gsd:verify-work

# UI phase
/gsd:ui-phase

# Map codebase
/gsd:map-codebase

# Review milestone
/gsd:review
```

---

## File Structure for Prompt Library

```
docs/
  PROMPTS.md (this file)
  PROJECT.md
  ROADMAP.md
  CONTEXT.md
  PLAN.md

src/
  context/
    CONTEXT.md
  plan/
    PLAN.md
```

---

## Tips for Using This Prompt Library

1. **Start with Phase 1** – Define system intent before writing code
2. **Use GSD phases** – Keep work small, explicit, and reviewable
3. **Invoke Antigravity skills** – Guide the AI's behavior with skills
4. **Commit per task** – Use @git-pushing after each task
5. **Validate per task** – Use @lint-and-validate after each task
6. **Review per milestone** – Use /gsd:review after each milestone
7. **Iterate on structure before aesthetics** – Focus on architecture first

---

## License

This prompt library is part of your freelance commerce platform project.  
Use it for your React + Sanity freelance consulting, training, and development platform.

---

## Contact

Built with:
- React + Next.js App Router
- Sanity CMS
- Tailwind CSS
- OpenCode with GSD + Antigravity skills

System Intent: A freelance engineering commerce platform for consulting, training, and development that expresses expertise, documents outcomes, sells curriculum, and enables booking.
