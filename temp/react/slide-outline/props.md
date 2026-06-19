### Slide 1 — Title
**Understanding Props in React: From Basics to Real-World Patterns**  
- Subtitle: Building scalable, composable UI  
- Optional: Your name (Sean Wong), context (React / Next.js training)

***

### Slide 2 — Why Props Matter
- React is about components working together, not in isolation  
- Props enable communication between components  
- Foundation for reusable and scalable UI  

**Example:**
```jsx
const Greeting = ({ name }) => <h1>Hello, {name}</h1>;
<Greeting name="Sean" />
<Greeting name="Alex" />
```

***

### Slide 3 — Learning Goals
- Understand props as inputs and contracts  
- Learn React’s data flow model  
- Apply real-world patterns (children, callbacks, layouts)  
- Build reusable components  

***

### Slide 4 — React as Composition
- UI = combination of small components  
- Example structure:
  App → Header, Sidebar, MainContent  
- Props connect components without tight coupling  

**Example:**
```jsx
function App() {
  return (
    <div>
      <Header title="My App" />
      <Sidebar />
      <MainContent />
    </div>
  );
}
```

***

### Slide 5 — What Are Props?
- Inputs passed into components  
- Define what a component needs  
- Allow reuse with different data  

**Example:**
```jsx
const Greeting = ({ name }) => {
  return <h1>Hello, {name}</h1>;
};

<Greeting name="Sean" />
<Greeting name="Alex" />
```

***

### Slide 6 — Props = Component Contract
- Define expected inputs  
- Make components predictable  
- Encourage reuse without rewriting logic  

**Example:**
```jsx
const Button = ({ label, onClick }) => {
  return <button onClick={onClick}>{label}</button>;
};

<Button label="Save" onClick={() => console.log("Saved")} />
```

***

### Slide 7 — One-Way Data Flow
- Data flows downward (parent → child)  
- Components don’t modify parents directly  
- Keeps apps predictable and easier to debug  

**Visual + Example:**
```jsx
function Parent() {
  const name = "Sean";
  return <Child name={name} />;
}

function Child({ name }) {
  return <h1>Hello, {name}</h1>;
}
```

***

### Slide 8 — Props vs State
- Props: external, read-only  
- State: internal, mutable  

**Example:**
```jsx
const Counter = ({ initialValue }) => {
  const [count, setCount] = useState(initialValue);

  return (
    <button onClick={() => setCount(count + 1)}>
      {count}
    </button>
  );
};
```

***

### Slide 9 — Why Props Are Read-Only
- Prevent unexpected side effects  
- Keep component boundaries clear  
- Changes must happen via state or callbacks  

**Try-to-modify (wrong):**
```jsx
const Counter = ({ count }) => {
  count = count + 1; // ❌ Error: props are read-only
};
```

***

### Slide 10 — Introducing `children`
- Special prop for nested content  
- Enables flexible composition  

**Example:**
```jsx
const Card = ({ title, children }) => (
  <div>
    <h2>{title}</h2>
    {children}
  </div>
);
```

***

### Slide 11 — Without vs With `children`
- Without `children`: fixed structure  
- With `children`: parent controls content  

**Without children:**
```jsx
const Card = ({ title, content }) => (
  <div>
    <h2>{title}</h2>
    <p>{content}</p>
  </div>
);
```

**With children:**
```jsx
const Card = ({ title, children }) => (
  <div>
    <h2>{title}</h2>
    {children}
  </div>
);

<Card title="Profile">
  <p>User bio here</p>
  <button>Edit Profile</button>
</Card>
```

***

### Slide 12 — Composition Over Configuration
- Avoid too many props like title, content, footer  
- Use `children` instead  
- More flexible and scalable design  

**Example:**
```jsx
const Box = ({ children }) => (
  <div className="box">{children}</div>
);

<Box>
  <h3>Title</h3>
  <p>Any content</p>
  <button>Action</button>
</Box>
```

***

### Slide 13 — Reusable Component Example: `ColorfulComponent`
- Props control appearance (color)  
- `children` controls content  
- Default props improve robustness  

**Example:**
```jsx
const ColorfulComponent = ({ color = "blue", children }) => (
  <div style={{ color }}>
    <p>This component is {color}</p>
    {children}
  </div>
);

<ColorfulComponent color="Blue">
  <p>Blue is calming.</p>
</ColorfulComponent>

<ColorfulComponent color="Green">
  <p>Green symbolizes nature.</p>
</ColorfulComponent>
```

***

### Slide 14 — Why This Pattern Matters
- One component → many variations  
- Avoid duplication  
- Easier to maintain  

**Compare:**
```jsx
// ❌ Multiple components
const BlueBox = () => <div style={{ color: "blue" }}>...</div>;
const GreenBox = () => <div style={{ color: "green" }}>...</div>;

// ✅ One reusable component
const ColorfulComponent = ({ color = "blue", children }) => ...
```

***

### Slide 15 — Building Layout Components
- Layout as a wrapper  
- `children` for flexible page structure  

**Example:**
```jsx
const Layout = ({ children }) => (
  <div className="layout">{children}</div>
);

<Layout>
  <header>Header</header>
  <main>Main content</main>
</Layout>
```

***

### Slide 16 — Named Slots Pattern
- Pass components as props (header, sidebar, content)  
- More structured than `children` alone  

**Example:**
```jsx
const DashboardLayout = ({ header, sidebar, content }) => (
  <div>
    <header>{header}</header>
    <div className="body">
      <aside>{sidebar}</aside>
      <main>{content}</main>
    </div>
  </div>
);

<DashboardLayout
  header={<Navbar />}
  sidebar={<Sidebar />}
  content={<Dashboard />}
/>
```

***

### Slide 17 — Real App Benefit
- Decouples layout from content  
- Reusable page structures  
- Scales well in large apps  

***

### Slide 18 — Passing Structured Data
- Props can be grouped into objects  
- Cleaner and more scalable  

**Example:**
```jsx
const UserProfile = ({ name, dob, company, university }) => (
  <div>
    <h1>Name: {name}</h1>
    <p>Date of birth: {dob}</p>
    <p>Company: {company}</p>
    <p>University: {university}</p>
  </div>
);

const userDetails = {
  name: "Mark Zuckerberg",
  dob: "14 May 1984",
  company: "Meta (formerly Facebook)",
  university: "Harvard University"
};
```

***

### Slide 19 — Prop Spreading
- Use `...object` to pass props  
- Cleaner syntax  
- Use carefully to avoid over-passing data  

**Example:**
```jsx
<UserProfile {...userDetails} />
```

***

### Slide 20 — Callback Props
- Props can pass functions  
- Enables interaction  

**Example:**
```jsx
const Input = ({ onChange }) => {
  return <input onChange={(e) => onChange(e.target.value)} />;
};

const App = () => {
  const handleChange = (value) => {
    console.log("New value:", value);
  };

  return <Input onChange={handleChange} />;
};
```

***

### Slide 21 — Props Down, Events Up
- Data flows down  
- Events flow up  
- Core React interaction model  

**Example:**
```jsx
function Parent() {
  const handleClick = () => console.log("Clicked!");
  return <Child onClick={handleClick} />;
}

function Child({ onClick }) {
  return <button onClick={onClick}>Click me</button>;
}
```

***

### Slide 22 — Combining Props and State
- Props define structure/content  
- State controls behavior  

**Example:**
```jsx
const Modal = ({ children }) => {
  const [open, setOpen] = useState(false);

  return (
    <>
      <button onClick={() => setOpen(true)}>Open</button>
      {open && (
        <div className="modal">
          {children}
          <button onClick={() => setOpen(false)}>Close</button>
        </div>
      )}
    </>
  );
};

<Modal>
  <h2>Settings</h2>
  <p>Update your preferences</p>
</Modal>
```

***

### Slide 23 — Real-World Pattern
- Props = what to render  
- State = when/how to render  

**Examples:** Modals, tabs, accordions (same pattern)

***

### Slide 24 — Scaling Challenges
- Prop drilling  
- Too many props  
- Passing unnecessary data  

**Example of prop drilling:**
```jsx
function App() {
  const user = { name: "Sean" };
  return <Page user={user} />;
}

function Page({ user }) {
  return <Profile user={user} />;
}

function Profile({ user }) {
  return <h1>{user.name}</h1>;
}
```

***

### Slide 25 — Best Practices
- Use `children` for flexibility  
- Keep props minimal and explicit  
- Use callbacks for interaction  
- Introduce Context when needed  

**Context alternative:**
```jsx
const UserContext = createContext();

function App() {
  return (
    <UserContext.Provider value={{ name: "Sean" }}>
      <Page />
    </UserContext.Provider>
  );
}

function Profile() {
  const user = useContext(UserContext);
  return <h1>{user.name}</h1>;
}
```

***

### Slide 26 — Type-Safe Props (TypeScript)
- Define prop types  
- Improves reliability and DX  

**Example:**
```tsx
type UserProfileProps = {
  name: string;
  dob: string;
  company: string;
  university: string;
};

const UserProfile = ({
  name,
  dob,
  company,
  university
}: UserProfileProps) => (
  <div>
    <h1>Name: {name}</h1>
    <p>Date of birth: {dob}</p>
    <p>Company: {company}</p>
    <p>University: {university}</p>
  </div>
);
```

***

### Slide 27 — Component Design Checklist
- What comes from outside? → Props  
- What changes internally? → State  
- What should be flexible? → `children`  
- Is the API simple?  

**Example:**
```jsx
const Button = ({ label, onClick, variant = "primary" }) => {
  // Props: label, onClick, variant
  // State: none (pure)
  // Children: none (fixed)
  return <button className={variant} onClick={onClick}>{label}</button>;
};
```

***

### Slide 28 — Mental Model
Props = Configuration  
State = Behavior  
Children = Composition  

***

### Slide 29 — Key Takeaway
- Props define boundaries between components  
- Good prop design = scalable architecture  
- Mastering props = mastering React composition  

***

### Slide 30 — Optional Closing
- Encourage experimentation  
- Apply patterns in real projects  
- Transition to next topic (State, Context, or Patterns)
