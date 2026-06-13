# Part 4: Prompt Library  
*Exact Prompts for OpenCode + GSD + Antigravity to Build Your React + Sanity Portfolio*

***

## How to Use This Prompt Library

This library is designed to maintain your **architectural integrity** while leveraging AI for speed. Use these prompts **in order**, following the **GSD (Get Stuff Done) rhythm** established in Part 3.

### Prompt Structure

Each prompt follows this format:

```
ROLE: [Expert persona to invoke]
CONTEXT: [What the AI needs to know]
TASK: [What to build]
CONSTRAINTS: [Antigravity rules to enforce]
OUTPUT: [Expected deliverable]
VALIDATION: [How to verify success]
```

This ensures:
- **Full context** (prevents hallucination)  
- **Single focus** (30-minute sprint)  
- **Antigravity compliance** (lightweight code)  
- **Clear verification** (GSD success criteria)

### Workflow

```
1. Select Phase → Select Prompt
2. Copy prompt into OpenCode
3. Run: opencode plan --task "[prompt task]"
4. Review plan → Adjust if needed
5. Run: opencode build
6. Review code → Ask "Explain like an architect" if unclear
7. Commit with documentation
8. Move to next prompt
```

### Rhythm

- **Each prompt = 30-minute sprint** (GSD)
- **Each commit = documented** (OpenCode)
- **Each component = minimal** (Antigravity)

***

## Phase 1: The Foundation (Sanity Schema)

### Prompt 1.1: Complete Schema Generation

```markdown
ROLE: Senior Software Architect

CONTEXT:
I am building a freelance engineering commerce platform with React and Sanity.
Per the business architecture (Part 2), I need to establish the "Single Source of Truth."
This is the Content Plane — all business truth lives in Sanity, not React.
I will use GSD (Get Stuff Done) for 30-minute atomic sprints.
I will use Antigravity principles: no premature abstraction, component minimalism, state locality.

TASK:
Design a Sanity CMS schema for the following content types in TypeScript:

1. 'Service' (productized offerings):
   - title (string, required, min 3, max 100 chars)
   - slug (slug, auto-generated from title)
   - price (number, required, min 0) — Price in USD
   - scopeArray (array of strings) — What's included
   - deliveryTimeframe (string) — e.g., "3 weeks"
   - idealClient (text) — Who should buy this?
   - ctaType (string, enum: "contact", "book", "hire")
   - ctaLink (url) — Required if ctaType !== "contact"
   - ctaText (string) — e.g., "Book Now"

2. 'Project' (proof of capability):
   - title (string, required)
   - slug (slug, auto-generated)
   - client (string)
   - techStack (array of strings)
   - description (text) — Brief overview
   - resultMetrics (array of objects with metric, value, impact)
   - caseStudy (reference to CaseStudy document)
   - testimonial (reference to Testimonial document)
   - duration (string)

3. 'Inquiry' (lead capture):
   - name (string, required)
   - email (email, required)
   - projectDetails (text, required) — What does client want?
   - budgetRange (string, enum: "low", "medium", "high", "enterprise")
     - low: "< $1,000"
     - medium: "$1,000 - $5,000"
     - high: "$5,000 - $20,000"
     - enterprise: "$20,000+"
   - serviceInterest (reference to Service document, optional)
   - timeline (string, optional)

CONSTRAINTS:
- All fields must have clear descriptions explaining business intent
- All required fields must have validation (Rule => Rule.required())
- No magic values — explain why each field type is chosen
- Use TypeScript-compatible types
- Include preview config for Sanity Studio
- Add comments: "Price in USD. NEVER hardcode in React components. Always fetch from Sanity."
- Use enum options with clear titles
- Include validation for conditional fields (e.g., ctaLink required when ctaType is "book")

OUTPUT:
Complete TypeScript files:
1. sanity/schema/service.ts
2. sanity/schema/project.ts
3. sanity/schema/inquiry.ts
4. sanity/schema/index.ts (assembly)

VALIDATION:
- All schemas load in Sanity Studio without errors
- All required fields show validation warnings when empty
- Preview displays title + key business field (price for Service, client for Project)
- TypeScript compiles without errors
- No "any" types used
```

**OpenCode command**:
```bash
opencode plan --task "Generate complete Sanity schemas for Service, Project, Inquiry with validation"
opencode build
```

***

### Prompt 1.2: TypeScript Types from Schema

```markdown
ROLE: TypeScript Expert

CONTEXT:
I've generated Sanity schemas for Service, Project, and Inquiry.
Per Antigravity: "Use strict TypeScript types for all Sanity queries."
This prevents "undefined" runtime errors that plague AI-generated code.

TASK:
Create src/types/sanity.ts with TypeScript interfaces that match my Sanity schemas:

1. Service interface (matches service schema)
2. Project interface (matches project schema)
3. Inquiry interface (matches inquiry schema)
4. Slug type: { current: string }
5. ResultMetric type: { metric: string; value: string; impact?: string }

Each interface must:
- Use exact field names from Sanity schema
- Mark optional fields with "?"
- Use correct types (string, number, boolean, arrays, objects)
- Include JSDoc comments explaining purpose
- No "any" types — use unknown or specific types
- No undefined types — use optional "?" or union types

CONSTRAINTS:
- Export all types
- Add JSDoc for each interface
- Include preview type for Sanity Studio
- Keep file organized by content type

OUTPUT:
src/types/sanity.ts with complete TypeScript interfaces

VALIDATION:
- All interfaces match Sanity schema fields exactly
- No "any" types in file
- TypeScript compiles without errors
- Can be imported in components without errors
- Optional fields marked correctly
```

**OpenCode command**:
```bash
opencode plan --task "Create TypeScript interfaces matching Sanity schemas"
opencode build
```

***

### Prompt 1.3: Schema Assembly & Config

```markdown
ROLE: Sanity CMS Expert

CONTEXT:
I have individual schemas for Service, Project, and Inquiry.
Now I need to assemble them into a complete Sanity configuration.

TASK:
Create:

1. sanity/schema/index.ts that:
   - Imports all schema types (Service, Project, Inquiry)
   - Exports them as a single array
   - Includes type exports for TypeScript

2. sanity/config.ts that:
   - Configures Sanity project with projectId and dataset
   - Uses environment variables for credentials
   - Includes TypeScript-safe config
   - Handles missing env vars with errors

CONSTRAINTS:
- Use ES6 imports/exports
- Add JSDoc comments explaining each schema's purpose
- Environment variables must be typed (not string)
- Include error handling for missing env vars
- Add comments explaining why each configuration option is chosen

OUTPUT:
1. sanity/schema/index.ts (schema assembly)
2. sanity/config.ts (project configuration)

VALIDATION:
- All schemas import without errors
- Environment variables are typed
- Missing env vars throw readable errors
- TypeScript compiles without errors
- Sanity Studio loads with schemas
```

**OpenCode command**:
```bash
opencode plan --task "Assemble schemas into index.ts and create Sanity config"
opencode build
```

***

## Phase 2: The Bridge (React Data Fetching)

### Prompt 2.1: Sanity Client Utility

```markdown
ROLE: React/Next.js Expert

CONTEXT:
I need to connect Sanity to React without polluting my components.
Per Antigravity: "State Locality — if state can live in Sanity, it stays in Sanity."
This utility is the ONLY place that calls Sanity API.

TASK:
Create a modular Sanity client utility for my project:

1. src/lib/sanity.ts with:
   - createClient function using sanity-presentation
   - fetchServices() function returning ServiceQueryResult
   - fetchProjects() function returning ProjectQueryResult
   - fetchInquiries() function returning InquiryQueryResult
   - Use TypeScript-safe query() method (not raw fetch)
   - Handle environment variables safely with types
   - Use async/await pattern
   - Include query strings as GROQ template literals

2. Custom hooks:
   - useServices() — returns { data, loading, error }
   - useProjects() — returns { data, loading, error }
   - useInquiries() — returns { data, loading, error }

Each hook must:
- Return data with strict TypeScript interfaces derived from schema
- Handle loading, error, and data states appropriately
- Use React's useState and useEffect
- Include cleanup (abort controller if needed)

CONSTRAINTS:
- Use strict TypeScript types for query results
- No "any" types
- Include JSDoc comments explaining each function
- Add error handling for missing env vars
- No global state (useState only per hook)
- Keep utility under 150 lines
- Add comments: "This is the ONLY place that calls Sanity API"

OUTPUT:
1. src/lib/sanity.ts (client + fetch functions)
2. src/hooks/useServices.ts
3. src/hooks/useProjects.ts
4. src/hooks/useInquiries.ts

VALIDATION:
- All functions return typed results
- TypeScript compiles without errors
- Can be imported in components without errors
- Missing env vars throw readable errors
- Queries execute without TypeScript errors
- Hooks handle loading/error states correctly
```

**OpenCode command**:
```bash
opencode plan --task "Create Sanity client utility with GROQ queries and custom hooks"
opencode build
```

***

### Prompt 2.2: GROQ Query Definitions

```markdown
ROLE: GROQ Query Expert

CONTEXT:
I need well-defined GROQ queries for fetching data from Sanity.
Per OpenCode: "Document every decision."

TASK:
Create src/lib/sanity-queries.ts with GROQ query constants:

1. SERVICE_QUERY — fetch single service by slug
2. ALL_SERVICES_QUERY — fetch all services
3. PROJECT_QUERY — fetch single project by slug
4. ALL_PROJECTS_QUERY — fetch all projects with caseStudy and testimonial references
5. INQUIRY_QUERY — fetch single inquiry
6. ALL_INQUIRIES_QUERY — fetch all inquiries

Each query must:
- Use GROQ template literals
- Include all required fields from schema
- Handle nested references (caseStudy, testimonial, serviceInterest)
- Include comments explaining what fields are fetched

CONSTRAINTS:
- Use meaningful query names
- Add JSDoc comments for each query
- Include field selection comments
- Keep file under 100 lines
- No inline queries in components — use these constants

OUTPUT:
src/lib/sanity-queries.ts with GROQ query constants

VALIDATION:
- All queries are valid GROQ
- TypeScript compiles without errors
- Queries fetch all needed fields
- References resolved correctly
- File is organized and readable
```

**OpenCode command**:
```bash
opencode plan --task "Create GROQ query constants for all content types"
opencode build
```

***

## Phase 3: The Experience (UI Components)

### Prompt 3.1: ServiceCard Component

```markdown
ROLE: Frontend Engineer

CONTEXT:
I need to build "Antigravity" components — lightweight, focused, single-purpose.
Per Part 2: "Price MUST live in Sanity, NEVER hardcoded in React."
This component's one job: render Service data.

TASK:
Build a clean, performant React component for displaying a single 'Service' card:

src/components/ServiceCard.tsx with:
- Display: title, price ($), scopeArray (as badges), deliveryTimeframe, idealClient
- CTA button based on ctaType:
  - "contact" → links to /contact
  - "book" → calls Stripe checkout API (will be implemented later)
  - "hire" → links to /contact with service pre-selected
- Show CTA text from ctaText field
- Use Tailwind CSS for styling (responsive)
- Accept a service object as prop based on Sanity schema
- Keep component logic pure: only presentation, not data fetching

CONSTRAINTS:
- Accept Service type from types/sanity.ts
- CRITICAL: price comes from service.price (NOT hardcoded)
- Handle ctaType routing with conditional logic
- Use Tailwind classes (no inline styles)
- Keep under 80 lines
- Add JSDoc comments
- Add comment: "Price from Sanity — NEVER hardcoded"
- Component does ONE thing: render service data

OUTPUT:
src/components/ServiceCard.tsx

VALIDATION:
- Displays price from Sanity data (verify in code)
- CTA button routes correctly based on ctaType
- All fields display safely (no errors if undefined)
- Responsive design works (mobile + desktop)
- TypeScript compiles without errors
- No hardcoded prices
- No data fetching in component
```

**OpenCode command**:
```bash
opencode plan --task "Create ServiceCard component with Tailwind CSS and dynamic CTA"
opencode build
```

***

### Prompt 3.2: ProjectGrid Component

```markdown
ROLE: React Component Expert

CONTEXT:
I need to render projects from Sanity in the Projects page.
Per Antigravity: "Component Minimalism — if a component doesn't do one thing, split it."
ProjectGrid's one job: fetch projects + render ProjectCard components.

TASK:
Create src/components/ProjectGrid.tsx with:
- Use useProjects() hook from src/hooks/useProjects.ts
- Map projects to ProjectCard components
- Handle loading state (return ProjectGridSkeleton)
- Handle empty state (show "No projects yet" message with icon)
- Use TypeScript types (Project[] from types/sanity.ts)
- Use Tailwind CSS for grid layout (responsive: 1 col mobile, 3 cols desktop)

CONSTRAINTS:
- NO business logic (prices, scope, etc. stay in Sanity)
- NO data fetching (use hook)
- Use Tailwind classes from global styles
- Keep under 80 lines
- Add JSDoc comments
- Component does ONE thing: display project grid

OUTPUT:
src/components/ProjectGrid.tsx

VALIDATION:
- Displays projects from hook
- Shows skeleton during loading
- Shows empty message if no projects
- Responsive grid works (mobile + desktop)
- TypeScript compiles without errors
- No "any" types used
- No data fetching in component
```

**OpenCode command**:
```bash
opencode plan --task "Create ProjectGrid component using useProjects hook"
opencode build
```

***

### Prompt 3.3: ProjectCard Component

```markdown
ROLE: UI Design Expert

CONTEXT:
I need a card component to display individual projects.
Per Antigravity: "Component Minimalism — one responsibility (render project data)."

TASK:
Create src/components/ProjectCard.tsx with:
- Display: title, client, techStack badges (inline), resultMetrics (first 2 only)
- Link to project detail page (using Next.js Link)
- Show testimonial clientName if available (truncate quote to 50 chars)
- Show duration if available
- Use Tailwind CSS for card, badge, grid layout
- Responsive: full width mobile, card grid desktop

CONSTRAINTS:
- Accept Project type from types/sanity.ts
- Handle optional fields (caseStudy, testimonial, duration) safely
- NO business logic — just render data from Sanity
- Use Next.js Link for navigation (not href)
- Keep under 70 lines
- Add JSDoc comments
- Truncate long text (techStack to 5 items, quote to 50 chars)

OUTPUT:
src/components/ProjectCard.tsx

VALIDATION:
- Displays all required fields
- Shows optional fields safely (no errors if undefined)
- Link navigates to detail page
- Responsive design works
- TypeScript compiles without errors
- No inline styles
- Text truncation works correctly
```

**OpenCode command**:
```bash
opencode plan --task "Create ProjectCard with Tailwind CSS and text truncation"
opencode build
```

***

### Prompt 3.4: ServicesPage Component

```markdown
ROLE: Page Component Expert

CONTEXT:
I need to render productized services from Sanity.
Per Part 2, this is the "Storefront" — where clients see what I sell.

TASK:
Create src/components/ServicesPage.tsx with:
- Use useServices() hook from src/hooks/useServices.ts
- Map services to ServiceCard components
- Handle loading state (return ServicesSkeleton)
- Handle empty state (show "No services yet" message)
- Add page title and description at top
- Use Tailwind CSS for layout

CONSTRAINTS:
- NO business logic in component
- NO data fetching (use hook)
- Use Tailwind classes from global styles
- Keep under 80 lines
- Add JSDoc comments

OUTPUT:
src/components/ServicesPage.tsx

VALIDATION:
- Displays services from hook
- Shows loading/empty states
- Page title and description display
- Responsive layout works
- TypeScript compiles without errors
- No "any" types used
```

**OpenCode command**:
```bash
opencode plan --task "Create ServicesPage component using useServices hook"
opencode build
```

***

### Prompt 3.5: Loading Skeletons

```markdown
ROLE: UX Design Expert

CONTEXT:
I need loading skeletons for data fetching.
Per Antigravity: "Handle loading states gracefully."

TASK:
Create:

1. src/components/ServiceCardSkeleton.tsx — displays skeleton service card
   - Placeholder title, price, scope badges, CTA button
   - Use Tailwind CSS animation (animate-pulse)

2. src/components/ProjectGridSkeleton.tsx — displays 3 skeleton project cards
   - Each with placeholder title, client, techStack
   - Use Tailwind CSS animation

3. src/components/InquiryFormSkeleton.tsx — displays skeleton form
   - Placeholder input fields, textarea, button
   - Use Tailwind CSS animation

CONSTRAINTS:
- Use Tailwind animate-pulse for skeleton effect
- Keep each under 30 lines
- Match real component structure
- No inline styles
- Add JSDoc comments

OUTPUT:
1. src/components/ServiceCardSkeleton.tsx
2. src/components/ProjectGridSkeleton.tsx
3. src/components/InquiryFormSkeleton.tsx

VALIDATION:
- Skeletons display during loading
- Animation works smoothly (pulse effect)
- Match real component structure
- Responsive design works
- TypeScript compiles without errors
```

**OpenCode command**:
```bash
opencode plan --task "Create loading skeletons with Tailwind animate-pulse"
opencode build
```

***

## Phase 4: The Commerce Hook (Transactional Logic)

### Prompt 4.1: InquiryForm Component

```markdown
ROLE: React Form Expert

CONTEXT:
I need a contact form for lead capture.
Per Part 2, this is the "Hook" — transitioning browser → client.
Per Antigravity: "State Locality — form state in component, not global."

TASK:
Create src/components/InquiryForm.tsx with:

1. State management:
   - formData: { name, email, phone, budgetRange, projectDetails, serviceInterest, timeline }
   - status: 'idle' | 'submitting' | 'success' | 'error'
   - error: string

2. Validation:
   - name (required, min 2 chars)
   - email (required, valid email format)
   - projectDetails (required, min 20 chars)
   - Show validation errors inline

3. Submit handler:
   - Calls /api/inquiry POST endpoint
   - Set status to 'submitting'
   - On success: set status to 'success'
   - On failure: set status to 'error', set error message

4. UI:
   - Success message on submit
   - Error message on failure
   - Loading state during submit (disable button, show spinner)
   - Use Tailwind CSS for styling

CONSTRAINTS:
- Use useState for all state (no Redux/Zustand)
- Validate before submit
- Use Tailwind classes from global styles
- Keep under 120 lines
- Add JSDoc comments
- TypeScript types for all state
- Component does ONE thing: handle inquiry form

OUTPUT:
src/components/InquiryForm.tsx

VALIDATION:
- Form validates required fields correctly
- Submit calls API endpoint
- Shows success/error states
- Loading state prevents duplicate submits
- Validation errors display inline
- TypeScript compiles without errors
- No global state used
```

**OpenCode command**:
```bash
opencode plan --task "Create InquiryForm with validation, state management, and API call"
opencode build
```

***

### Prompt 4.2: State Machine for Commerce Flow

```markdown
ROLE: System Architect

CONTEXT:
I need to handle the conversion flow for a 'Service'.
When a user clicks 'Book Consultation' on a Service card, I need to manage the state transition from:
'Browsing' → 'Inquiry' → 'Payment Initiation' → 'Confirmed'

Per OpenCode: "Prevent AI from creating monolithic, hard-to-maintain code."
Per Antigravity: "Focus on clean separation between UI state and server-side actions."

TASK:
Outline a React state machine or logic flow for the commerce flow:

1. Create src/lib/commerce-state.ts with:
   - CommerceState type: 'browsing' | 'inquiry' | 'payment-initiation' | 'confirmed' | 'error'
   - CommerceContext type with:
     - state: CommerceState
     - service: Service | null
     - inquiryData: Inquiry | null
     - checkoutUrl: string | null
     - error: string | null
   - Functions:
     - startInquiry(service: Service): sets state to 'inquiry'
     - submitInquiry(data: Inquiry): sets state to 'payment-initiation', calls /api/inquiry
     - initPayment(): sets state to 'payment-initiation', calls /api/stripe/checkout
     - confirmPayment(url: string): sets state to 'confirmed', stores checkoutUrl
     - handleError(error: string): sets state to 'error'

2. Create src/hooks/useCommerceFlow.ts with:
   - useReducer for state management
   - Actions: START_INQUIRY, SUBMIT_INQUIRY, INIT_PAYMENT, CONFIRM_PAYMENT, HANDLE_ERROR
   - Return: state + action dispatchers

CONSTRAINTS:
- Focus on clean separation: UI state vs server actions
- Use useReducer (not multiple useState)
- No global state libraries
- Include JSDoc comments
- Keep state logic under 100 lines
- Actions are explicit and named
- Error handling is built in

OUTPUT:
1. src/lib/commerce-state.ts (state types + functions)
2. src/hooks/useCommerceFlow.ts (reducer + hook)

VALIDATION:
- State transitions are explicit
- All 5 states are reachable
- Error handling works
- TypeScript compiles without errors
- No monolithic code
- Clean separation between UI and server
```

**OpenCode command**:
```bash
opencode plan --task "Create commerce flow state machine with useReducer"
opencode build
```

***

### Prompt 4.3: Stripe Checkout Integration

```markdown
ROLE: Payment Integration Expert

CONTEXT:
I need to connect ServiceCard to Stripe checkout.
Per Prompt 3.1, ctaType="book" calls Stripe API.
Per Part 2, this is the Transactional Plane.

TASK:
Modify src/components/ServiceCard.tsx to integrate Stripe:

1. Add state:
   - checkoutLoading: boolean
   - checkoutError: string | null

2. Add function:
   - handleBookClick(): 
     - Set checkoutLoading to true
     - Call /api/stripe/checkout with { serviceId: service.slug }
     - On success: redirect to checkout URL (window.location.href)
     - On failure: set checkoutError, set checkoutLoading to false

3. Modify CTA button:
   - When ctaType === "book", call handleBookClick
   - Show loading spinner during checkout creation
   - Show error message if checkout fails

CONSTRAINTS:
- Use useState for checkout loading/error (local state)
- Fetch returns { url: string }
- Use window.location.href for redirect
- Keep component under 90 lines
- Add comment explaining Stripe flow
- Error handling is built in

OUTPUT:
Modified src/components/ServiceCard.tsx

VALIDATION:
- "book" CTA calls Stripe API
- Redirects to checkout URL on success
- Shows loading spinner during checkout creation
- Shows error message on failure
- "contact" and "hire" still work correctly
- TypeScript compiles without errors
- No global state used
```

**OpenCode command**:
```bash
opencode plan --task "Modify ServiceCard to call Stripe checkout for book CTA"
opencode build
```

***

### Prompt 4.4: API Route for Inquiry

```markdown
ROLE: API Design Expert

CONTEXT:
I need an API endpoint to handle form submission.
Per Part 2, this feeds into the Transactional Plane (CRM/email tool).

TASK:
Create app/api/inquiry/route.ts with:

1. POST handler:
   - Accept { name, email, phone, budgetRange, projectDetails, serviceInterest, timeline }
   - Validate required fields (name, email, projectDetails)
   - Send to external CRM/email tool (e.g., Resend, Formspree, custom webhook)
   - Return { success: true } on success
   - Return { success: false, error: string } on failure

2. TypeScript types:
   - InquiryRequest type for request body
   - InquiryResponse type for response

3. Error handling:
   - Validate input before sending
   - Handle external API errors
   - Add CORS headers if needed

CONSTRAINTS:
- Use Next.js 14+ API route pattern
- Validate input before sending
- Handle external API errors gracefully
- Add CORS headers
- Keep under 100 lines
- Add JSDoc comments

OUTPUT:
app/api/inquiry/route.ts

VALIDATION:
- POST request accepts form data
- Validation rejects missing required fields
- External API call succeeds/fails correctly
- Returns proper JSON response
- Error messages are clear
- TypeScript compiles without errors
```

**OpenCode command**:
```bash
opencode plan --task "Create /api/inquiry POST route with validation and CRM integration"
opencode build
```

***

## Pro-Tips for "Vibe Coding" Success

### The "Architectural Review" Prompt

At the end of every block of generated code, paste it back to the AI and say:

```markdown
ROLE: Senior Software Architect

CONTEXT:
I am applying an architectural audit to this code.
I need to verify it follows my established architecture:
- Content Plane (Sanity) → Experience Plane (React)
- No business logic in React components
- State locality (no global state unless required)
- Component minimalism (one responsibility per component)

TASK:
Review this code and identify:

1. Points of tight coupling (where should I decouple?)
2. Ways to make this more modular (can I split this?)
3. Data flow verification (does it follow Content-to-Experience plane?)
4. Potential bugs or edge cases (what could break?)
5. Performance issues (is this efficient?)

Code to review:
[Insert generated code here]

CONSTRAINTS:
- Be specific (point to exact lines)
- Suggest concrete improvements
- Verify architectural compliance
- Identify risks

OUTPUT:
Architectural audit report with:
- Coupling issues
- Modularity suggestions
- Data flow verification
- Bug risks
- Performance concerns

VALIDATION:
- All 5 areas covered
- Specific line references
- Concrete improvement suggestions
- Clear architectural verdict
```

**When to use**: After every major component or utility generation.

***

### The "OpenCode" Documentation Prompt

```markdown
ROLE: Technical Writer

CONTEXT:
Per OpenCode: "Document every decision, dependency, and AI-generated prompt within the codebase."
I need to create a README.md entry for this module.

TASK:
Create a brief README.md entry for this module that explains:

1. Purpose: What does this module do?
2. Dependencies: What does it depend on?
3. Constraints: What should I be aware of when modifying it?
4. Usage: How do I use this module?
5. Testing: How do I test this module?
6. Future Changes: What should I consider before modifying?

Module: [Insert module name/file path]
Code:
[Insert code here]

CONSTRAINTS:
- Keep under 200 words
- Use clear headings
- Include code examples if needed
- Be specific about constraints

OUTPUT:
README.md section for this module

VALIDATION:
- All 6 sections covered
- Clear and concise
- Includes usage examples
- Constraints are explicit
```

**When to use**: After creating every new file or module.

**Example**: Add to your module's top comment:

```typescript
/**
 * ServiceCard Component
 * 
 * Purpose: Display service data from Sanity (title, price, scope, CTA)
 * Dependencies: types/sanity.ts (Service type), Tailwind CSS
 * Constraints: 
 *   - Price MUST come from Sanity (service.price), never hardcoded
 *   - No data fetching — use useServices() hook
 *   - One responsibility: render service data
 * Usage: <ServiceCard service={service} />
 * Testing: Verify price displays from Sanity data
 * Future Changes: Add promo badge? Keep under 90 lines
 */
```

***

### The "Explain Like an Architect" Prompt

```markdown
ROLE: Senior Software Architect

CONTEXT:
I don't understand what AI generated in this code.
Per OpenCode: "If you don't understand what AI wrote, do not commit it."

TASK:
Explain this code like an architect:

[Insert code here]

Cover:
1. What does this component/module do? (purpose)
2. What data does it receive? (inputs)
3. What does it render or return? (outputs)
4. What state does it manage? (internal state)
5. What are the edge cases? (null, empty, errors)
6. Are there any potential bugs? (risks)
7. Does it follow my architecture? (Content → Experience plane)

CONSTRAINTS:
- Use plain language (no jargon)
- Explain business intent, not just code
- Point out architectural decisions
- Identify potential issues
- Be specific (reference exact lines)

OUTPUT:
Architectural explanation covering all 7 points

VALIDATION:
- Explanation is clear
- All 7 points covered
- Identifies issues
- Uses plain language
- References specific lines
```

**When to use**: When code is unclear before committing.

***

## Using the Prompt Library

### Example Workflow: Building Services Page

```bash
# 1. Foundation: Service Schema
opencode plan --task "Generate Service Sanity schema with pricing and CTA fields"
opencode build

# 2. Bridge: TypeScript Types
opencode plan --task "Create TypeScript interfaces matching Sanity schemas"
opencode build

# 3. Bridge: Sanity Client + Hooks
opencode plan --task "Create Sanity client utility with GROQ queries and custom hooks"
opencode build

# 4. Experience: ServiceCard
opencode plan --task "Create ServiceCard component with Tailwind CSS and dynamic CTA"
opencode build

# 5. Experience: ServicesPage
opencode plan --task "Create ServicesPage component using useServices hook"
opencode build

# 6. Commerce: Stripe Integration
opencode plan --task "Modify ServiceCard to call Stripe checkout for book CTA"
opencode build

# 7. Documentation
# Add to ServiceCard.tsx:
# "OpenCode Documentation Prompt" → Generate README section

# 8. Architectural Review
# Paste ServiceCard.tsx back to AI:
# "Architectural Review Prompt" → Get audit report

# 9. Verify
gsd verify --criteria playbook/success-criteria.md
```

**Total time**: ~3.5 hours (7 sprints × 30 minutes)

***

## Closing Perspective

You now have the **complete vibe coding series**:

| Part | Purpose | Key Output |
|------|---------|------------|
| **Part 1** | Philosophy | Why AI fails without architecture |
| **Part 2** | Business Architecture | Three-plane commerce platform model |
| **Part 3** | Implementation System | OpenCode + GSD + Antigravity workflow |
| **Part 4** | Prompt Library | 18 production-ready prompts + 3 pro-tips |

This system:
- Prevents black box syndrome (OpenCode transparency)  
- Enforces 30-minute sprints (GSD rhythm)  
- Minimizes cognitive overhead (Antigravity principles)  
- Provides exact prompts for every task (Prompt Library)  
- Maintains architectural integrity (Architectural Review prompt)  
- Documents every decision (OpenCode Documentation prompt)  
- Explains unclear code (Explain Like an Architect prompt)  

**You are ready to build your platform.**

Start with **Prompt 1.1** (Foundation).  
Execute one sprint at a time.  
Document every decision.  
Verify after each phase.  
Review architecture before committing.

The architecture precedes the prompt.  
The intent precedes the architecture.

Now execute.
