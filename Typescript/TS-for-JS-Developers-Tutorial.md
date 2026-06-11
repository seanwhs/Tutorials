# Tutorial: TypeScript for JavaScript Developers — Massively Expanded Edition

This tutorial bridges JavaScript’s flexibility with TypeScript’s industrial-strength type safety. You’ll evolve from writing code that *might* work to code that is **guaranteed** type-safe. Every concept includes practice exercises with `start.ts` (where you begin) and `final.ts` (the completed solution). We start from absolute fundamentals and scale to advanced patterns used in production React/Next.js apps.

***

## Part 1: The Foundations (The "Why")

### 1.1 What is a Type?

In programming, a **type** is a category that tells the computer what kind of data you’re working with. JavaScript is **dynamically typed** — it figures out types while the program runs.

```javascript
// JavaScript
let data = 10;   // JS thinks data is a number
data = "Hello"; // JS now thinks data is a string

// This flexibility causes "Runtime Fragility"
// Bugs appear only when users run your code
```

TypeScript introduces **Static Typing** — types are defined before you run the code. The compiler checks these definitions, preventing errors before they reach your users.

```typescript
// TypeScript
let data: number = 10;   // data MUST be a number
data = "Hello";          // ❌ Error: Type 'string' is not assignable to type 'number'
```

**Key benefit:** Type errors are caught at **compile-time**, not **runtime**.

***

### 1.2 Why JavaScript Developers Need TypeScript

| Problem in JS | TypeScript Solution |
|---------------|---------------------|
| `undefined` errors | Types catch missing properties |
| Function called with wrong argument | Compiler rejects invalid calls |
| Refactoring is scary | IDE shows all breakages instantly |
| API contracts are implicit | Interfaces make contracts explicit |
| Debugging takes hours | Errors shown before running code |

***

### 1.3 Exercise: Identifying Types (Beginner)

**Objective:** Identify if these variables are `string`, `number`, or `boolean`.

#### `start.ts`
```typescript
// Add the correct type annotation to each variable
const username = "Developer";
const age = 25;
const isOnline = true;

// Test: Try assigning wrong types and see errors
username = 123;   // What happens?
age = "twenty";   // What happens?
isOnline = "yes"; // What happens?
```

#### `final.ts`
```typescript
// Add the correct type annotation to each variable
const username: string = "Developer";
const age: number = 25;
const isOnline: boolean = true;

// Test: Try assigning wrong types and see errors
// username = 123;   // ❌ Error: Type 'number' is not assignable to type 'string'
// age = "twenty";   // ❌ Error: Type 'string' is not assignable to type 'number'
// isOnline = "yes"; // ❌ Error: Type 'string' is not assignable to type 'boolean'

console.log({ username, age, isOnline });
```

***

### 1.4 Exercise: Type Mismatch Detection

**Objective:** Spot the type errors before running the code.

#### `start.ts`
```typescript
function greet(name: string, age: number) {
  return `Hello ${name}, you are ${age} years old`;
}

// These calls have wrong types - can you spot them?
const result1 = greet("Alice", "30");
const result2 = greet(25, 30);
const result3 = greet("Bob");

console.log(result1, result2, result3);
```

#### `final.ts`
```typescript
function greet(name: string, age: number): string {
  return `Hello ${name}, you are ${age} years old`;
}

// ❌ Error: Type 'string' is not assignable to type 'number'
// const result1 = greet("Alice", "30");

// ❌ Error: Type 'number' is not assignable to type 'string'
// const result2 = greet(25, 30);

// ❌ Error: Expected 2 arguments, but got 1
// const result3 = greet("Bob");

// Correct usage
const result1 = greet("Alice", 30);
console.log(result1); // "Hello Alice, you are 30 years old"
```

***

## Part 2: Working with Variables and Functions

### 2.1 Explicit Typing vs. Type Inference

TypeScript is smart. If you assign a value, it **infers** the type automatically. You only need explicit typing when the type isn't obvious.

```typescript
// Inference (no explicit type needed)
let name = "John";        // TypeScript infers: string
let count = 10;           // TypeScript infers: number
let isActive = true;      // TypeScript infers: boolean

// Explicit typing (needed when type isn't obvious)
let value: string;        // Declared but not initialized
value = "now I have a type";

// When re-assignment happens, explicit typing helps
let data: string | number;
data = "hello";
data = 42;                // Both allowed
```

***

### 2.2 Exercise: Inference vs. Explicit Typing

**Objective:** See when inference works and when you need explicit types.

#### `start.ts`
```typescript
// Add explicit types where inference fails

let message;
message = "Welcome";

let numberList;
numberList = [1, 2, 3];

let user;
user = { name: "Alice", age: 25 };

// This will fail - TypeScript can't infer the type
let emptyArray;
emptyArray = [];
emptyArray.push(1);
emptyArray.push("bad");   // Should this be allowed?

console.log(message, numberList, user, emptyArray);
```

#### `final.ts`
```typescript
// Add explicit types where inference fails

let message: string;
message = "Welcome";

let numberList: number[];
numberList = [1, 2, 3];

let user: { name: string; age: number };
user = { name: "Alice", age: 25 };

// Explicit typing prevents bad data
let emptyArray: number[];
emptyArray = [];
emptyArray.push(1);
// emptyArray.push("bad");   // ❌ Error: Type 'string' is not assignable to type 'number'

console.log(message, numberList, user, emptyArray);
```

***

### 2.3 Function Signatures

In JS, you can pass anything to a function. In TS, we define **exactly** what we expect.

```typescript
function calculateTotal(price: number, tax: number): number {
  return price + tax;
}

// ✅ Valid
calculateTotal(100, 10);

// ❌ Invalid
calculateTotal("100", 10);   // Error: string vs number
calculateTotal(100);         // Error: missing argument
```

**Function signature structure:**
```typescript
function functionName(param1: Type1, param2: Type2): ReturnType {
  // implementation
}
```

***

### 2.4 Exercise: Function Type Safety

**Objective:** Add type annotations to functions and catch invalid calls.

#### `start.ts`
```typescript
// Add type annotations to parameters and return types

function multiply(a, b) {
  return a * b;
}

function formatUser(name, age, email) {
  return {
    name: name,
    age: age,
    email: email,
    displayName: name.toUpperCase()
  };
}

function calculateDiscount(price, percentage) {
  const discount = price * (percentage / 100);
  return price - discount;
}

// Test with wrong types
console.log(multiply("5", 3));
console.log(formatUser("Bob", "25", true));
console.log(calculateDiscount(100, "20"));
```

#### `final.ts`
```typescript
// Add type annotations to parameters and return types

function multiply(a: number, b: number): number {
  return a * b;
}

function formatUser(name: string, age: number, email: string): {
  name: string;
  age: number;
  email: string;
  displayName: string;
} {
  return {
    name: name,
    age: age,
    email: email,
    displayName: name.toUpperCase()
  };
}

function calculateDiscount(price: number, percentage: number): number {
  const discount = price * (percentage / 100);
  return price - discount;
}

// ✅ Valid calls
console.log(multiply(5, 3));              // 15
console.log(formatUser("Bob", 25, "bob@email.com"));
console.log(calculateDiscount(100, 20));  // 80

// ❌ Invalid calls (will error)
// console.log(multiply("5", 3));
// console.log(formatUser("Bob", "25", true));
// console.log(calculateDiscount(100, "20"));
```

***

### 2.5 Optional Parameters and Default Values

```typescript
// Optional parameter (using ?)
function greet(name: string, age?: number): string {
  if (age !== undefined) {
    return `Hello ${name}, you are ${age}`;
  }
  return `Hello ${name}`;
}

// Default parameters
function greetWithDefault(name: string, age: number = 18): string {
  return `Hello ${name}, you are ${age}`;
}

greet("Alice");           // ✅ "Hello Alice"
greet("Alice", 25);       // ✅ "Hello Alice, you are 25"
greetWithDefault("Bob");  // ✅ "Hello Bob, you are 18"
```

***

### 2.6 Exercise: Optional and Default Parameters

**Objective:** Handle missing arguments gracefully with types.

#### `start.ts`
```typescript
// Add optional parameters and default values

function createUser(username, email, role) {
  return {
    username,
    email,
    role: role || "user",
    createdAt: new Date()
  };
}

function logMessage(message, level) {
  const levelMap = {
    debug: "[DEBUG]",
    info: "[INFO]",
    warn: "[WARN]",
    error: "[ERROR]"
  };
  return `${levelMap[level] || "[INFO]"} ${message}`;
}

// Test missing arguments
console.log(createUser("alice", "alice@email.com"));
console.log(logMessage("Something happened"));
```

#### `final.ts`
```typescript
function createUser(
  username: string, 
  email: string, 
  role: string = "user"
): {
  username: string;
  email: string;
  role: string;
  createdAt: Date;
} {
  return {
    username,
    email,
    role,
    createdAt: new Date()
  };
}

function logMessage(
  message: string, 
  level: "debug" | "info" | "warn" | "error" = "info"
): string {
  const levelMap = {
    debug: "[DEBUG]",
    info: "[INFO]",
    warn: "[WARN]",
    error: "[ERROR]"
  };
  return `${levelMap[level]} ${message}`;
}

// ✅ Valid calls with missing arguments
console.log(createUser("alice", "alice@email.com"));
// role defaults to "user"
console.log(logMessage("Something happened"));
// level defaults to "info"

// ✅ With all arguments
console.log(createUser("bob", "bob@email.com", "admin"));
console.log(logMessage("Warning!", "warn"));
```

***

## Part 3: Object Blueprints (Interfaces & Type Aliases)

### 3.1 Understanding Interfaces

**Interfaces** define the **shape** of an object. Think of them as a contract that every object must follow.

```typescript
interface Product {
  name: string;
  price: number;
  category?: string;  // Optional property
}

const item: Product = { name: "Laptop", price: 999 };  // ✅ Valid
const badItem: Product = { name: "Mouse" };            // ❌ Error: missing price
```

***

### 3.2 Exercise: Interface Validation

**Objective:** Create interfaces and enforce object structure.

#### `start.ts`
```typescript
// Create an interface for a User object

// Create valid and invalid user objects
const user1 = {
  id: 1,
  name: "Alice",
  email: "alice@email.com"
};

const user2 = {
  id: 2,
  name: "Bob"
  // Missing email
};

const user3 = {
  id: "3",  // Wrong type
  name: "Charlie",
  email: "charlie@email.com"
};

console.log(user1, user2, user3);
```

#### `final.ts`
```typescript
interface User {
  id: number;
  name: string;
  email: string;
  age?: number;  // Optional
}

// ✅ Valid user
const user1: User = {
  id: 1,
  name: "Alice",
  email: "alice@email.com"
};

// ❌ Error: Missing required property 'email'
// const user2: User = {
//   id: 2,
//   name: "Bob"
// };

// ❌ Error: Type 'string' is not assignable to type 'number'
// const user3: User = {
//   id: "3",
//   name: "Charlie",
//   email: "charlie@email.com"
// };

// ✅ With optional property
const user4: User = {
  id: 4,
  name: "David",
  email: "david@email.com",
  age: 30
};

console.log(user1, user4);
```

***

### 3.3 Type Aliases vs. Interfaces

Both define object shapes, but with different use cases:

```typescript
// Type alias - more flexible
type Point = {
  x: number;
  y: number;
};

// Interface - better for extension
interface Rectangle {
  width: number;
  height: number;
}

// Interface can be extended
interface Square extends Rectangle {
  color: string;
}

// Type aliases use union types better
type Status = "pending" | "approved" | "rejected";
```

**When to use:**
- **Interfaces**: Object shapes, especially when you need to extend them
- **Type aliases**: Union types, tuples, complex combinations, primitive aliases

***

### 3.4 Exercise: Interface Extension

**Objective:** Extend interfaces to create specialized types.

#### `start.ts`
```typescript
// Create a base Person interface
// Create Employee interface that extends Person
// Add new properties: employeeId, department

const person = {
  name: "Alice",
  age: 30,
  email: "alice@email.com"
};

const employee = {
  name: "Bob",
  age: 25,
  email: "bob@email.com",
  employeeId: 1001,
  department: "Engineering"
};

console.log(person, employee);
```

#### `final.ts`
```typescript
interface Person {
  name: string;
  age: number;
  email: string;
}

interface Employee extends Person {
  employeeId: number;
  department: string;
  hireDate?: Date;  // Optional
}

// ❌ Error: Person doesn't have employeeId or department
// const person: Employee = {
//   name: "Alice",
//   age: 30,
//   email: "alice@email.com"
// };

// ✅ Valid employee (extends Person)
const employee: Employee = {
  name: "Bob",
  age: 25,
  email: "bob@email.com",
  employeeId: 1001,
  department: "Engineering"
};

// ✅ With optional property
const employee2: Employee = {
  name: "Carol",
  age: 28,
  email: "carol@email.com",
  employeeId: 1002,
  department: "Marketing",
  hireDate: new Date("2024-01-15")
};

console.log(employee, employee2);
```

***

### 3.5 Function Types in Interfaces

Interfaces can define function signatures:

```typescript
interface Calculator {
  add(a: number, b: number): number;
  subtract(a: number, b: number): number;
  multiply(a: number, b: number): number;
}

const basicCalculator: Calculator = {
  add: (a, b) => a + b,
  subtract: (a, b) => a - b,
  multiply: (a, b) => a * b
};
```

***

### 3.6 Exercise: Function Interface

**Objective:** Create an interface for a data fetcher with multiple methods.

#### `start.ts`
```typescript
// Create an interface for APIs with these methods:
// - get(id: number): any
// - create(data: any): any
// - update(id: number, data: any): any
// - delete(id: number): boolean

const userAPI = {
  get: (id) => ({ id, name: "User" }),
  create: (data) => ({ id: 1, ...data }),
  update: (id, data) => ({ id, ...data }),
  delete: (id) => true
};

const productAPI = {
  get: (id) => ({ id, name: "Product", price: 99 }),
  create: (data) => ({ id: 100, ...data }),
  update: (id, data) => ({ id, ...data }),
  delete: (id) => false
};

console.log(userAPI.get(1), productAPI.create({ name: "Laptop" }));
```

#### `final.ts`
```typescript
interface API<T> {
  get(id: number): T;
  create(data: Partial<T>): T;
  update(id: number, data: Partial<T>): T;
  delete(id: number): boolean;
}

interface User {
  id: number;
  name: string;
}

interface Product {
  id: number;
  name: string;
  price: number;
}

const userAPI: API<User> = {
  get: (id): User => ({ id, name: "User" }),
  create: (data): User => ({ id: 1, ...data } as User),
  update: (id, data): User => ({ id, ...data } as User),
  delete: (id): boolean => true
};

const productAPI: API<Product> = {
  get: (id): Product => ({ id, name: "Product", price: 99 }),
  create: (data): Product => ({ id: 100, ...data } as Product),
  update: (id, data): Product => ({ id, ...data } as Product),
  delete: (id): boolean => false
};

// ✅ Type-safe calls
console.log(userAPI.get(1));           // { id: 1, name: "User" }
console.log(productAPI.create({ name: "Laptop", price: 999 }));
console.log(userAPI.delete(5));        // true
```

***

## Part 4: Advanced Pattern Matching

### 4.1 Union Types

Union types allow a value to be one of several types:

```typescript
type UserID = string | number;

const userId1: UserID = 123;      // ✅ number
const userId2: UserID = "abc";    // ✅ string
const userId3: UserID = true;     // ❌ Error: boolean not in union
```

***

### 4.2 Exercise: Union Types

**Objective:** Use union types for flexible but safe inputs.

#### `start.ts`
```typescript
// Create a function that accepts ID as string OR number

function findById(id) {
  if (typeof id === "number") {
    return { type: "number", value: id, label: `ID: ${id}` };
  }
  return { type: "string", value: id, label: `UUID: ${id}` };
}

console.log(findById(123));
console.log(findById("abc-123"));
console.log(findById(true));  // Should this work?
```

#### `final.ts`
```typescript
type UserID = string | number;

function findById(id: UserID): {
  type: "number" | "string";
  value: number | string;
  label: string;
} {
  if (typeof id === "number") {
    return { type: "number", value: id, label: `ID: ${id}` };
  }
  return { type: "string", value: id, label: `UUID: ${id}` };
}

// ✅ Valid calls
console.log(findById(123));           // { type: "number", value: 123, label: "ID: 123" }
console.log(findById("abc-123"));     // { type: "string", value: "abc-123", label: "UUID: abc-123" }

// ❌ Error: boolean not in union type
// console.log(findById(true));
```

***

### 4.3 Discriminated Unions

This is the **professional** way to handle multiple states without endless `if/else` logic.

```typescript
type Status = 
  | { state: 'loading' }
  | { state: 'success'; payload: string }
  | { state: 'error'; message: string };

function handle(status: Status): void {
  if (status.state === 'success') {
    console.log(status.payload); // TS knows 'payload' exists here!
  } else if (status.state === 'error') {
    console.error(status.message); // TS knows 'message' exists here!
  }
  // state === 'loading' handled implicitly
}
```

**Why it's powerful:** TypeScript uses the `state` property (the **discriminator**) to narrow down which properties are available.

***

### 4.4 Exercise: Discriminated Union for API State

**Objective:** Replace boolean flags with a discriminated union.

#### `start.ts`
```typescript
// BAD: Boolean soup - hard to track valid combinations
interface APIState {
  isLoading: boolean;
  isError: boolean;
  isSuccess: boolean;
  data?: any;
  error?: any;
}

const state1: APIState = { isLoading: true, isError: false, isSuccess: false };
const state2: APIState = { isLoading: false, isError: true, isSuccess: true, data: {...}, error: {...} };
// What if isLoading=true AND isSuccess=true? Invalid but allowed!

function processState(state: APIState) {
  if (state.isLoading) {
    return "Loading...";
  }
  if (state.isSuccess) {
    return `Data: ${state.data}`;
  }
  if (state.isError) {
    return `Error: ${state.error}`;
  }
}

console.log(processState(state1), processState(state2));
```

#### `final.ts`
```typescript
// GOOD: Discriminated union - mutually exclusive states
type APIState<T> = 
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: string };

const state1: APIState<null> = { status: 'loading' };
const state2: APIState<{ id: number }> = { 
  status: 'success', 
  data: { id: 123 } 
};
const state3: APIState<null> = { 
  status: 'error', 
  error: 'Network failed' 
};

function processState(state: APIState<unknown>): string {
  switch (state.status) {
    case 'idle':
      return "Ready";
    case 'loading':
      return "Loading...";
    case 'success':
      return `Data: ${JSON.stringify(state.data)}`;
    case 'error':
      return `Error: ${state.error}`;
  }
}

console.log(processState(state1));  // "Loading..."
console.log(processState(state2));  // "Data: {"id":123}"
console.log(processState(state3));  // "Error: Network failed"

// ❌ Impossible to have invalid state combinations
// const badState: APIState<null> = { status: 'loading', data: {...} }; // Error
```

***

### 4.5 Type Guards

Type guards let you check types manually:

```typescript
function isString(value: unknown): value is string {
  return typeof value === "string";
}

function process(value: string | number) {
  if (isString(value)) {
    return value.toUpperCase(); // TS knows it's string here
  }
  return value * 2; // TS knows it's number here
}
```

***

### 4.6 Exercise: Custom Type Guard

**Objective:** Create a type guard for date objects.

#### `start.ts`
```typescript
// Create a type guard to check if value is a Date

function processDate(value: Date | string | number) {
  // How do we safely access Date methods?
  if (value instanceof Date) {
    return value.getFullYear();
  }
  if (typeof value === "string") {
    return new Date(value).getFullYear();
  }
  return new Date(value).getFullYear();
}

console.log(processDate(new Date("2024-01-15")));
console.log(processDate("2023-05-20"));
console.log(processDate(1673827200000));
```

#### `final.ts`
```typescript
// Type guard signature: function isType(value: unknown): value is Type
function isDate(value: unknown): value is Date {
  return value instanceof Date;
}

function processDate(value: Date | string | number): number {
  if (isDate(value)) {
    // TS now knows value is Date
    return value.getFullYear();
  }
  if (typeof value === "string") {
    return new Date(value).getFullYear();
  }
  return new Date(value).getFullYear();
}

// ✅ Safe type access
console.log(processDate(new Date("2024-01-15")));  // 2024
console.log(processDate("2023-05-20"));            // 2023
console.log(processDate(1673827200000));           // 2023

// Type guard usage
const mixed: unknown = new Date();
if (isDate(mixed)) {
  console.log(mixed.getFullYear()); // TS knows mixed is Date
}
```

***

### 4.7 The `never` Type and Exhaustiveness

The `never` type represents values that never occur. Use it to ensure **exhaustive** switch statements:

```typescript
type Shape = "circle" | "square" | "triangle";

function area(shape: Shape): number {
  switch (shape) {
    case "circle": return 3.14;
    case "square": return 100;
    case "triangle": return 50;
    default:
      throw new Error(`Unhandled shape: ${shape}`); // Type is 'never'
  }
}

// If you add "rectangle" to Shape but forget the switch case:
// TypeScript errors: Type 'never' is not assignable to type 'number'
```

***

### 4.8 Exercise: Exhaustive Switch with `never`

**Objective:** Ensure all cases are handled.

#### `start.ts`
```typescript
type HttpMethod = "GET" | "POST" | "PUT" | "DELETE";

function handleMethod(method: HttpMethod): string {
  switch (method) {
    case "GET": return "Read data";
    case "POST": return "Create data";
    case "PUT": return "Update data";
    // Missing DELETE - should error!
    default: return "Unknown";
  }
}

console.log(handleMethod("GET"), handleMethod("POST"));
```

#### `final.ts`
```typescript
type HttpMethod = "GET" | "POST" | "PUT" | "DELETE";

function handleMethod(method: HttpMethod): string {
  switch (method) {
    case "GET": return "Read data";
    case "POST": return "Create data";
    case "PUT": return "Update data";
    case "DELETE": return "Delete data"; // ✅ Must add all cases
    default:
      // Type of method here is 'never' - all cases covered
      throw new Error(`Unhandled method: ${method}`);
  }
}

console.log(handleMethod("GET"));   // "Read data"
console.log(handleMethod("POST"));  // "Create data"
console.log(handleMethod("DELETE")); // "Delete data"

// ❌ If you remove DELETE case, TypeScript errors
```

***

## Part 5: Building a Resilient API Layer

### 5.1 The AbortController Pattern

Real-world apps must handle **canceled network requests** effectively.

```typescript
async function fetchData(url: string, signal?: AbortSignal): Promise<unknown> {
  return await fetch(url, { signal });
}

// Usage with AbortController
const controller = new AbortController();

fetchData("https://api.example.com/data", controller.signal)
  .then(data => console.log(data))
  .catch(err => {
    if (err.name === "AbortError") {
      console.log("Request canceled");
    }
  });

// Cancel after 5 seconds
setTimeout(() => controller.abort(), 5000);
```

***

### 5.2 Exercise: Cancellable API Request

**Objective:** Implement a cancellable fetch with proper typing.

#### `start.ts`
```typescript
// Create a cancellable fetch function

function fetchWithCancel(url, timeoutMs) {
  const controller = new AbortController();
  
  const timeout = setTimeout(() => {
    controller.abort();
  }, timeoutMs);
  
  return fetch(url, { signal: controller.signal })
    .then(res => res.json())
    .then(data => {
      clearTimeout(timeout);
      return data;
    })
    .catch(err => {
      clearTimeout(timeout);
      throw err;
    });
}

fetchWithCancel("https://api.example.com/data", 3000)
  .then(data => console.log(data))
  .catch(err => console.error("Failed:", err));
```

#### `final.ts`
```typescript
interface FetchResult<T> {
  data: T;
  canceled: boolean;
}

async function fetchWithCancel<T>(
  url: string, 
  timeoutMs: number,
  signal?: AbortSignal
): Promise<FetchResult<T>> {
  const controller = new AbortController();
  
  const timeout = setTimeout(() => {
    controller.abort();
  }, timeoutMs);
  
  // Merge signals if provided
  const mergedSignal = signal 
    ? AbortSignal.any([controller.signal, signal])
    : controller.signal;
  
  try {
    const res = await fetch(url, { signal: mergedSignal });
    clearTimeout(timeout);
    
    if (res.status === 404) {
      throw new Error("Not found");
    }
    
    const data = await res.json() as T;
    return { data, canceled: false };
  } catch (err) {
    clearTimeout(timeout);
    
    if (err instanceof Error && err.name === "AbortError") {
      return { data: null as T, canceled: true };
    }
    
    throw err;
  }
}

// ✅ Usage
fetchWithCancel<{ id: number; name: string }>(
  "https://api.example.com/user/1", 
  3000
)
  .then(result => {
    if (result.canceled) {
      console.log("Request canceled");
    } else {
      console.log(result.data.name); // TS knows data has 'name'
    }
  })
  .catch(err => console.error("Failed:", err));
```

***

### 5.3 Error Handling with Typed Errors

```typescript
class APIError extends Error {
  constructor(
    public message: string,
    public statusCode: number,
    public code: string
  ) {
    super(message);
  }
}

async function safeFetch<T>(url: string): Promise<T | APIError> {
  try {
    const res = await fetch(url);
    if (!res.ok) {
      return new APIError(res.statusText, res.status, "API_ERROR");
    }
    return await res.json() as T;
  } catch (err) {
    return new APIError(err instanceof Error ? err.message : "Unknown", 500, "NETWORK_ERROR");
  }
}
```

***

### 5.4 Exercise: Typed Error Handler

**Objective:** Create a typed error handling system.

#### `start.ts`
```typescript
// Create error classes for different failure types

function fetchData(url) {
  return fetch(url)
    .then(res => {
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}`);
      }
      return res.json();
    })
    .catch(err => {
      console.error("Error:", err.message);
      return null;
    });
}

fetchData("https://api.example.com/data");
```

#### `final.ts`
```typescript
enum ErrorType {
  NETWORK = "NETWORK_ERROR",
  HTTP = "HTTP_ERROR",
  PARSE = "PARSE_ERROR",
  AUTH = "AUTH_ERROR"
}

class TypedError extends Error {
  constructor(
    public message: string,
    public type: ErrorType,
    public statusCode?: number
  ) {
    super(message);
  }
}

async function fetchData<T>(url: string): Promise<T | TypedError> {
  try {
    const res = await fetch(url);
    
    if (!res.ok) {
      const type = res.status === 401 
        ? ErrorType.AUTH 
        : ErrorType.HTTP;
      return new TypedError(
        res.statusText,
        type,
        res.status
      );
    }
    
    try {
      const data = await res.json() as T;
      return data;
    } catch (err) {
      return new TypedError(
        "Failed to parse JSON",
        ErrorType.PARSE
      );
    }
  } catch (err) {
    return new TypedError(
      err instanceof Error ? err.message : "Network failed",
      ErrorType.NETWORK
    );
  }
}

// ✅ Usage with type checking
const result = await fetchData<{ id: number }>("https://api.example.com/user");

if (result instanceof TypedError) {
  console.error(`[${result.type}] ${result.message}`);
  if (result.statusCode) {
    console.error(`Status: ${result.statusCode}`);
  }
} else {
  console.log(result.id); // TS knows result is T here
}
```

***

## Part 6: Gradual Migration from JavaScript to TypeScript

### 6.1 Configuring the Bridge

Use these settings in `tsconfig.json` to allow JS and TS to coexist during migration:

```json
{
  "compilerOptions": {
    "allowJs": true,    // Allows .js files to exist
    "checkJs": false,   // Keeps checks loose until ready
    "allowImportingTsExtensions": true,
    "module": "ESNext",
    "target": "ES2020"
  }
}
```

***

### 6.2 Exercise: Migration Strategy

**Objective:** Set up a mixed JS/TS project.

#### `start.ts`
```typescript
// Create a tsconfig.json for gradual migration
// Settings needed:
// - Allow .js files
// - Disable strict checks initially
// - Set module system
// - Enable type checking gradually
```

#### `final.ts`
```typescript
// tsconfig.json content (save as file):
{
  "compilerOptions": {
    "allowJs": true,
    "checkJs": false,
    "allowImportingTsExtensions": true,
    "module": "ESNext",
    "target": "ES2020",
    "moduleResolution": "bundler",
    "strict": false,
    "skipLibCheck": true,
    "esModuleInterop": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}

// Migration lifecycle:
// 1. Rename: math.js → math.ts
// 2. Annotate: Add types to function parameters
// 3. Enable: "checkJs": true for .js files
// 4. Strict: Enable "strict": true for full safety
```

***

### 6.3 The Conversion Lifecycle

1. **Rename**: `math.js` → `math.ts`
2. **Annotate**: Add types to parameters
3. **Strict**: Enable `"checkJs": true` once ready for full safety

```typescript
// Step 1: Original JS
function add(a, b) {
  return a + b;
}

// Step 2: Add parameter types
function add(a: number, b: number) {
  return a + b;
}

// Step 3: Add return type
function add(a: number, b: number): number {
  return a + b;
}
```

***

## Part 7: React State Management with TypeScript

### 7.1 Complex `useState`

When your state is an object or array, define an **interface** for the shape.

```typescript
interface FormState {
  email: string;
  password: string;
  isSubscribed: boolean;
  errors: {
    email?: string;
    password?: string;
  };
}

const [form, setForm] = useState<FormState>({
  email: "",
  password: "",
  isSubscribed: false,
  errors: {}
});

// Update with type safety
setForm(prev => ({
  ...prev,
  email: "new@email.com"
}));
```

***

### 7.2 Exercise: Typed Form State

**Objective:** Create a fully typed form state manager.

#### `start.ts`
```typescript
import { useState } from "react";

// Create a form state for user registration
// Fields: name, email, password, age
// Include error tracking

function RegistrationForm() {
  const [form, setForm] = useState({
    name: "",
    email: "",
    password: "",
    age: "",
    errors: {}
  });

  const updateField = (field: string, value: string) => {
    setForm({ ...form, [field]: value });
  };

  return (
    <form>
      <input value={form.name} onChange={e => updateField("name", e.target.value)} />
      <input value={form.email} onChange={e => updateField("email", e.target.value)} />
      <input value={form.password} onChange={e => updateField("password", e.target.value)} />
      <input value={form.age} onChange={e => updateField("age", e.target.value)} />
    </form>
  );
}
```

#### `final.ts`
```typescript
import { useState } from "react";

interface RegistrationFormState {
  name: string;
  email: string;
  password: string;
  age: string;
  errors: {
    name?: string;
    email?: string;
    password?: string;
    age?: string;
  };
}

function RegistrationForm() {
  const [form, setForm] = useState<RegistrationFormState>({
    name: "",
    email: "",
    password: "",
    age: "",
    errors: {}
  });

  // Type-safe field update
  const updateField = <K extends keyof RegistrationFormState>(
    field: K, 
    value: string
  ) => {
    setForm(prev => ({
      ...prev,
      [field]: value
    }));
  };

  // Type-safe error update
  const setError = (field: string, message: string) => {
    setForm(prev => ({
      ...prev,
      errors: { ...prev.errors, [field]: message }
    }));
  };

  const validate = () => {
    const errors: RegistrationFormState["errors"] = {};
    
    if (!form.name.trim()) errors.name = "Name required";
    if (!form.email.includes("@")) errors.email = "Invalid email";
    if (form.password.length < 8) errors.password = "8+ chars required";
    if (!form.age || Number(form.age) < 18) errors.age = "18+ required";
    
    setForm(prev => ({ ...prev, errors }));
    return Object.keys(errors).length === 0;
  };

  return (
    <form>
      <input
        value={form.name}
        onChange={e => updateField("name", e.target.value)}
        placeholder="Name"
      />
      {form.errors.name && <span>{form.errors.name}</span>}
      
      <input
        value={form.email}
        onChange={e => updateField("email", e.target.value)}
        placeholder="Email"
      />
      {form.errors.email && <span>{form.errors.email}</span>}
      
      <input
        value={form.password}
        onChange={e => updateField("password", e.target.value)}
        placeholder="Password"
        type="password"
      />
      {form.errors.password && <span>{form.errors.password}</span>}
      
      <input
        value={form.age}
        onChange={e => updateField("age", e.target.value)}
        placeholder="Age"
        type="number"
      />
      {form.errors.age && <span>{form.errors.age}</span>}
      
      <button type="button" onClick={validate}>Submit</button>
    </form>
  );
}
```

***

### 7.3 State Machines with Discriminated Unions

Avoid **"Boolean Soup"** (`isLoading`, `isError`, `isSuccess`) using Discriminated Unions.

```typescript
type RemoteData<T> = 
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };

function useRemoteData<T>(fetcher: () => Promise<T>): RemoteData<T> {
  const [state, setState] = useState<RemoteData<T>>({ status: 'idle' });

  useEffect(() => {
    setState({ status: 'loading' });
    fetcher()
      .then(data => setState({ status: 'success', data }))
      .catch(error => setState({ status: 'error', error }));
  }, [fetcher]);

  return state;
}
```

***

### 7.4 Exercise: Remote Data State Machine

**Objective:** Implement a typed remote data fetcher.

#### `start.ts`
```typescript
import { useState, useEffect } from "react";

// Create a RemoteData type for API states
// Use it in a custom hook that fetches data

function useUserData(userId: number) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    setLoading(true);
    fetch(`https://api.example.com/users/${userId}`)
      .then(res => res.json())
      .then setData)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [userId]);

  return { data, loading, error };
}
```

#### `final.ts`
```typescript
import { useState, useEffect } from "react";

type RemoteData<T> = 
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: string };

interface User {
  id: number;
  name: string;
  email: string;
}

function useUserData(userId: number): RemoteData<User> {
  const [state, setState] = useState<RemoteData<User>>({ status: 'idle' });

  useEffect(() => {
    if (userId === 0) {
      setState({ status: 'idle' });
      return;
    }

    setState({ status: 'loading' });

    fetch(`https://api.example.com/users/${userId}`)
      .then(res => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json() as Promise<User>;
      })
      .then(data => setState({ status: 'success', data }))
      .catch(error => setState({ 
        status: 'error', 
        error: error.message 
      }));
  }, [userId]);

  return state;
}

// ✅ Usage with exhaustive handling
function UserProfile(userId: number) {
  const state = useUserData(userId);

  switch (state.status) {
    case 'idle':
      return <div>Select a user</div>;
    case 'loading':
      return <div>Loading...</div>;
    case 'success':
      return (
        <div>
          <h1>{state.data.name}</h1>
          <p>{state.data.email}</p>
        </div>
      );
    case 'error':
      return <div>Error: {state.error}</div>;
  }
}
```

***

### 7.5 Typing Complex `useReducer`

`useReducer` centralizes state transition logic, ideal for complex workflows.

```typescript
type Action = 
  | { type: 'INCREMENT' }
  | { type: 'SET_VALUE'; payload: number }
  | { type: 'RESET' };

function reducer(state: number, action: Action): number {
  switch (action.type) {
    case 'INCREMENT': return state + 1;
    case 'SET_VALUE': return action.payload;
    case 'RESET': return 0;
    default: return state;
  }
}

const [count, dispatch] = useReducer(reducer, 0);

dispatch({ type: 'INCREMENT' });
dispatch({ type: 'SET_VALUE', payload: 10 });
```

***

### 7.6 Exercise: Typed useReducer for Cart

**Objective:** Build a shopping cart with useReducer.

#### `start.ts`
```typescript
import { useReducer } from "react";

// Create a cart reducer with actions:
// - ADD_ITEM: { name, price, quantity }
// - REMOVE_ITEM: itemId
// - UPDATE_QUANTITY: { itemId, quantity }
// - CLEAR_CART

function cartReducer(state, action) {
  switch (action.type) {
    case 'ADD_ITEM':
      return [...state, action.item];
    case 'REMOVE_ITEM':
      return state.filter(item => item.id !== action.itemId);
    default:
      return state;
  }
}

function Cart() {
  const [cart, dispatch] = useReducer(cartReducer, []);
  
  return (
    <div>
      {cart.map(item => <div>{item.name} - ${item.price}</div>)}
    </div>
  );
}
```

#### `final.ts`
```typescript
import { useReducer } from "react";

interfaceCartItem {
  id: number;
  name: string;
  price: number;
  quantity: number;
}

type CartAction = 
  | { type: 'ADD_ITEM'; item: CartItem }
  | { type: 'REMOVE_ITEM'; itemId: number }
  | { type: 'UPDATE_QUANTITY'; itemId: number; quantity: number }
  | { type: 'CLEAR_CART' };

function cartReducer(state: CartItem[], action: CartAction): CartItem[] {
  switch (action.type) {
    case 'ADD_ITEM':
      const existing = state.find(item => item.id === action.item.id);
      if (existing) {
        return state.map(item =>
          item.id === action.item.id
            ? { ...item, quantity: item.quantity + action.item.quantity }
            : item
        );
      }
      return [...state, action.item];
    
    case 'REMOVE_ITEM':
      return state.filter(item => item.id !== action.itemId);
    
    case 'UPDATE_QUANTITY':
      return state.map(item =>
        item.id === action.itemId
          ? { ...item, quantity: action.quantity }
          : item
      );
    
    case 'CLEAR_CART':
      return [];
    
    default:
      return state;
  }
}

function Cart() {
  const [cart, dispatch] = useReducer(cartReducer, []);

  const addItem = () => {
    dispatch({
      type: 'ADD_ITEM',
      item: { id: 1, name: "Laptop", price: 999, quantity: 1 }
    });
  };

  const removeItem = (id: number) => {
    dispatch({ type: 'REMOVE_ITEM', itemId: id });
  };

  const updateQuantity = (id: number, quantity: number) => {
    dispatch({ type: 'UPDATE_QUANTITY', itemId: id, quantity });
  };

  const clearCart = () => {
    dispatch({ type: 'CLEAR_CART' });
  };

  const total = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);

  return (
    <div>
      <button onClick={addItem}>Add Laptop</button>
      <button onClick={clearCart}>Clear</button>
      
      {cart.map(item => (
        <div key={item.id}>
          {item.name} - ${item.price} × {item.quantity}
          <button onClick={() => updateQuantity(item.id, item.quantity + 1)}>+</button>
          <button onClick={() => updateQuantity(item.id, item.quantity - 1)}>-</button>
          <button onClick={() => removeItem(item.id)}>Remove</button>
        </div>
      ))}
      
      <strong>Total: ${total}</strong>
    </div>
  );
}
```

***

### 7.7 Context API with Null-Check Pattern

Initialize Context with `null` and create a custom hook to enforce usage within a Provider.

```typescript
interface UserContextType {
  user: { id: number; name: string };
  setUser: (user: { id: number; name: string }) => void;
}

const UserContext = createContext<UserContextType | null>(null);

function useUser(): UserContextType {
  const context = useContext(UserContext);
  if (!context) {
    throw new Error("useUser must be used within UserProvider");
  }
  return context;
}
```

***

## Part 8: Scalable State - Zustand & Redux Toolkit

### 8.1 Zustand (The Minimalist)

Zustand is hooks-first and exceptionally easy to type.

```typescript
interface CounterStore {
  count: number;
  increment: () => void;
  decrement: () => void;
}

const useStore = create<CounterStore>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
}));

// Usage
function Counter() {
  const { count, increment, decrement } = useStore();
  return (
    <div>
      <p>{count}</p>
      <button onClick={increment}>+</button>
      <button onClick={decrement}>-</button>
    </div>
  );
}
```

***

### 8.2 Exercise: Typed Zustand Store

**Objective:** Create a user management store with Zustand.

#### `start.ts`
```typescript
import { create } from "zustand";

// Create a store for managing users
// Actions: addUser, removeUser, updateUser, getUsers

const userStore = create((set, get) => ({
  users: [],
  addUser: (user) => set({ users: [...get().users, user] }),
  removeUser: (id) => set({ users: get().users.filter(u => u.id !== id) }),
  updateUser: (id, updates) => 
    set({ 
      users: get().users.map(u => u.id === id ? { ...u, ...updates } : u) 
    }),
  getUsers: () => get().users
}));
```

#### `final.ts`
```typescript
import { create } from "zustand";

interface User {
  id: number;
  name: string;
  email: string;
}

interface UserStore {
  users: User[];
  addUser: (user: User) => void;
  removeUser: (id: number) => void;
  updateUser: (id: number, updates: Partial<User>) => void;
  getUsers: () => User[];
  getUserById: (id: number) => User | undefined;
}

const useUserStore = create<UserStore>((set, get) => ({
  users: [],
  
  addUser: (user) => 
    set((state) => ({ users: [...state.users, user] })),
  
  removeUser: (id) => 
    set((state) => ({ users: state.users.filter(u => u.id !== id) })),
  
  updateUser: (id, updates) => 
    set((state) => ({
      users: state.users.map(u => u.id === id ? { ...u, ...updates } : u)
    })),
  
  getUsers: () => get().users,
  
  getUserById: (id) => get().users.find(u => u.id === id)
}));

// ✅ Usage in component
function UserList() {
  const { users, addUser, removeUser, updateUser } = useUserStore();

  const testUser: User = { id: 1, name: "Alice", email: "alice@email.com" };

  return (
    <div>
      <button onClick={() => addUser(testUser)}>Add User</button>
      
      {users.map(user => (
        <div key={user.id}>
          {user.name} - {user.email}
          <button onClick={() => updateUser(user.id, { name: "Updated" })}>Update</button>
          <button onClick={() => removeUser(user.id)}>Remove</button>
        </div>
      ))}
    </div>
  );
}
```

***

### 8.3 Redux Toolkit (The Enterprise Standard)

RTK enforces the **Slice** pattern, separating state definition from logic.

```typescript
import { createSlice } from "@reduxjs/toolkit";

const counterSlice = createSlice({
  name: "counter",
  initialState: { count: 0 },
  reducers: {
    increment: (state) => { state.count += 1; },
    decrement: (state) => { state.count -= 1; },
    reset: (state) => { state.count = 0; },
  },
});

export const { increment, decrement, reset } = counterSlice.actions;
export default counterSlice.reducer;
```

***

### 8.4 Exercise: Typed Redux Slice

**Objective:** Create a product inventory slice with Redux Toolkit.

#### `start.ts`
```typescript
import { createSlice } from "@reduxjs/toolkit";

// Create a product inventory slice
// State: products array
// Actions: addProduct, removeProduct, updatePrice, getProducts

const productSlice = createSlice({
  name: "products",
  initialState: { products: [] },
  reducers: {
    addProduct: (state, action) => {
      state.products.push(action.payload);
    },
    removeProduct: (state, action) => {
      state.products = state.products.filter(p => p.id !== action.payload);
    }
  }
});
```

#### `final.ts`
```typescript
import { createSlice, PayloadAction } from "@reduxjs/toolkit";

interface Product {
  id: number;
  name: string;
  price: number;
  quantity: number;
}

interface ProductState {
  products: Product[];
}

const productSlice = createSlice({
  name: "products",
  initialState: { products: [] } as ProductState,
  reducers: {
    addProduct: (state, action: PayloadAction<Product>) => {
      state.products.push(action.payload);
    },
    
    removeProduct: (state, action: PayloadAction<number>) => {
      state.products = state.products.filter(p => p.id !== action.payload);
    },
    
    updatePrice: (state, action: PayloadAction<{ id: number; price: number }>) => {
      state.products = state.products.map(p =>
        p.id === action.payload.id ? { ...p, price: action.payload.price } : p
      );
    },
    
    updateQuantity: (state, action: PayloadAction<{ id: number; quantity: number }>) => {
      state.products = state.products.map(p =>
        p.id === action.payload.id ? { ...p, quantity: action.payload.quantity } : p
      );
    },
    
    getProducts: (state) => state.products,
    
    getTotalInventory: (state) => {
      return state.products.reduce((sum, p) => sum + p.price * p.quantity, 0);
    }
  }
});

export const {
  addProduct,
  removeProduct,
  updatePrice,
  updateQuantity,
  getProducts,
  getTotalInventory
} = productSlice.actions;

export default productSlice.reducer;

// ✅ Usage in React component
function ProductInventory() {
  const products = useAppSelector(getProducts);
  const total = useAppSelector(getTotalInventory);
  
  const dispatch = useAppDispatch();

  const testProduct: Product = { id: 1, name: "Laptop", price: 999, quantity: 5 };

  return (
    <div>
      <button onClick={() => dispatch(addProduct(testProduct))}>Add Product</button>
      <p>Total Inventory: ${total}</p>
      
      {products.map(product => (
        <div key={product.id}>
          {product.name} - ${product.price} × {product.quantity}
          <button onClick={() => dispatch(updatePrice({ id: product.id, price: product.price + 10 })}}>
            Update Price
          </button>
          <button onClick={() => dispatch(updateQuantity({ id: product.id, quantity: product.quantity + 1 })}}>
            + Quantity
          </button>
          <button onClick={() => dispatch(removeProduct(product.id))}>Remove</button>
        </div>
      ))}
    </div>
  );
}
```

***

### 8.5 Comparison Table

| Feature | Zustand | Redux Toolkit |
|---------|---------|---------------|
| **Complexity** | Low | High |
| **Philosophy** | Unopinionated | Opinionated (Flux) |
| **Boilerplate** | Minimal | Moderate |
| **Type Safety** | Excellent | Excellent |
| **Best For** | Mid-sized apps | Large-scale enterprise |
| **Hooks** | First-class | Required via `useSelector` |
| **Middleware** | Simple | Rich (thunks, sagas) |
| **Learning Curve** | Low | Moderate |

***

### 8.6 Pro-Tips for State Libraries

- **Use `useShallow`** in Zustand: Prevent unnecessary re-renders when selecting state
- **RTK Query**: Use for API states (loading/caching) to eliminate manual `useState` boilerplate
- **Selector Pattern**: Always use selector functions to decouple components from store structure

```typescript
// Zustand with useShallow
import { useShallow } from "zustand/react/shallow";

const count = useStore(useShallow((state) => state.count));
```

```typescript
// RTK Query for API
import { createApiQuery } from "@reduxjs/toolkit/query";

export const api = createApiQuery({
  baseQuery: fetchBaseQuery({ baseUrl: "/api" }),
  endpoints: (build) => ({
    getUsers: build.query({ query: () => "/users" }),
    createUser: build.mutation({ query: (data) => ({ url: "/users", method: "POST", body: data }) }),
  }),
});
```

***

## Part 9: Final Capstone Exercise

### 9.1 Objective: Create a Robust User Service

Build a complete user management service with:
- Typed interfaces
- API layer with error handling
- State management
- Cancelable requests

***

#### `start.ts`
```typescript
// Create a User service with these features:
// 1. User interface
// 2. API functions (get, create, update, delete)
// 3. Error handling
// 4. State management with discriminated union
// 5. Cancelable requests

interface User {
  id: number;
  name: string;
  email: string;
}

// Start building
```

#### `final.ts`
```typescript
// ============================================
// 1. TYPES & INTERFACES
// ============================================

interface User {
  id: number;
  name: string;
  email: string;
  createdAt?: Date;
}

type UserAPIState = 
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: User[] }
  | { status: 'user'; data: User }
  | { status: 'error'; error: string };

enum ErrorType {
  NETWORK = "NETWORK_ERROR",
  HTTP = "HTTP_ERROR",
  AUTH = "AUTH_ERROR",
  NOT_FOUND = "NOT_FOUND"
}

class APIError extends Error {
  constructor(
    public message: string,
    public type: ErrorType,
    public statusCode?: number
  ) {
    super(message);
  }
}

// ============================================
// 2. API LAYER
// ============================================

async function fetchData<T>(
  url: string, 
  signal?: AbortSignal
): Promise<T | APIError> {
  try {
    const res = await fetch(url, { signal });
    
    if (!res.ok) {
      const type = res.status === 401 
        ? ErrorType.AUTH 
        : res.status === 404 
          ? ErrorType.NOT_FOUND 
          : ErrorType.HTTP;
      return new APIError(res.statusText, type, res.status);
    }
    
    return await res.json() as T;
  } catch (err) {
    return new APIError(
      err instanceof Error ? err.message : "Network failed",
      ErrorType.NETWORK
    );
  }
}

async function fetchWithCancel<T>(
  url: string, 
  timeoutMs: number
): Promise<{ data: T | APIError; canceled: boolean }> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  
  try {
    const data = await fetchData<T>(url, controller.signal);
    clearTimeout(timeout);
    return { data, canceled: false };
  } catch (err) {
    clearTimeout(timeout);
    if (err instanceof Error && err.name === "AbortError") {
      return { data: null as T, canceled: true };
    }
    throw err;
  }
}

// ============================================
// 3. USER SERVICE
// ============================================

class UserService {
  private baseUrl: string;

  constructor(baseUrl: string = "https://api.example.com") {
    this.baseUrl = baseUrl;
  }

  async getUsers(signal?: AbortSignal): Promise<User[] | APIError> {
    return fetchData<User[]>(`${this.baseUrl}/users`, signal);
  }

  async getUser(id: number, signal?: AbortSignal): Promise<User | APIError> {
    return fetchData<User>(`${this.baseUrl}/users/${id}`, signal);
  }

  async createUser(
    user: Partial<User>, 
    signal?: AbortSignal
  ): Promise<User | APIError> {
    return fetchData<User>(`${this.baseUrl}/users`, signal);
  }

  async updateUser(
    id: number, 
    user: Partial<User>,
    signal?: AbortSignal
  ): Promise<User | APIError> {
    return fetchData<User>(`${this.baseUrl}/users/${id}`, signal);
  }

  async deleteUser(id: number, signal?: AbortSignal): Promise<boolean | APIError> {
    const result = await fetchData(`${this.baseUrl}/users/${id}`, signal);
    if (result instanceof APIError) return result;
    return true;
  }

  // Cancelable version
  async getUsersCancelable(
    timeoutMs: number = 5000
  ): Promise<{ data: User[] | APIError; canceled: boolean }> {
    return fetchWithCancel<User[]>(`${this.baseUrl}/users`, timeoutMs);
  }
}

// ============================================
// 4. STATE MANAGEMENT
// ============================================

import { create } from "zustand";

interface UserStore {
  state: UserAPIState;
  users: User[];
  fetchUsers: () => Promise<void>;
  selectUser: (id: number) => Promise<void>;
  addUser: (user: Partial<User>) => Promise<void>;
  deleteUser: (id: number) => Promise<void>;
  error: string | null;
}

const useUserStore = create<UserStore>((set, get) => ({
  state: { status: 'idle' },
  users: [],
  error: null,

  fetchUsers: async () => {
    set({ state: { status: 'loading' }, error: null });
    const service = new UserService();
    const result = await service.getUsers();
    
    if (result instanceof APIError) {
      set({ 
        state: { status: 'error', error: result.message },
        error: result.message
      });
    } else {
      set({ 
        state: { status: 'success', data: result },
        users: result
      });
    }
  },

  selectUser: async (id: number) => {
    set({ state: { status: 'loading' }, error: null });
    const service = new UserService();
    const result = await service.getUser(id);
    
    if (result instanceof APIError) {
      set({ 
        state: { status: 'error', error: result.message },
        error: result.message
      });
    } else {
      set({ state: { status: 'user', data: result } });
    }
  },

  addUser: async (user: Partial<User>) => {
    const service = new UserService();
    const result = await service.createUser(user);
    
    if (result instanceof APIError) {
      set({ error: result.message });
    } else {
      set({ users: [...get().users, result] });
    }
  },

  deleteUser: async (id: number) => {
    const service = new UserService();
    const result = await service.deleteUser(id);
    
    if (result instanceof APIError) {
      set({ error: result.message });
    } else {
      set({ users: get().users.filter(u => u.id !== id) });
    }
  }
}));

// ============================================
// 5. REACT COMPONENT
// ============================================

import { useState, useEffect } from "react";

function UserManagement() {
  const { state, users, fetchUsers, addUser, deleteUser } = useUserStore();
  const [newUserName, setNewUserName] = useState("");
  const [cancelController, setCancelController] = useState<AbortController | null>(null);

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleAddUser = async () => {
    await addUser({ name: newUserName, email: `${newUserName}@email.com` });
    setNewUserName("");
  };

  const handleCancel = () => {
    if (cancelController) {
      cancelController.abort();
    }
  };

  switch (state.status) {
    case 'idle':
      return <div>Select an action</div>;
    
    case 'loading':
      return (
        <div>
          <p>Loading...</p>
          <button onClick={handleCancel}>Cancel</button>
        </div>
      );
    
    case 'success':
      return (
        <div>
          <h1>Users</h1>
          <input 
            value={newUserName}
            onChange={e => setNewUserName(e.target.value)}
            placeholder="New user name"
          />
          <button onClick={handleAddUser}>Add User</button>
          
          {users.map(user => (
            <div key={user.id}>
              {user.name} - {user.email}
              <button onClick={() => deleteUser(user.id)}>Delete</button>
            </div>
          ))}
        </div>
      );
    
    case 'error':
      return <div>Error: {state.error}</div>;
    
    default:
      // Type safety: this should never happen (type is 'never')
      throw new Error(`Unhandled state: ${state}`);
  }
}

// ============================================
// 6. USAGE EXAMPLES
// ============================================

// Basic usage
const userService = new UserService("https://api.example.com");

// Get all users
const usersResult = await userService.getUsers();
if (usersResult instanceof APIError) {
  console.error(`Failed: ${usersResult.message}`);
} else {
  console.log(`Found ${usersResult.length} users`);
}

// Cancelable request
const { data, canceled } = await userService.getUsersCancelable(3000);
if (canceled) {
  console.log("Request was canceled");
} else if (data instanceof APIError) {
  console.error(`Error: ${data.message}`);
} else {
  console.log(data);
}

// React component usage
// <UserManagement />

// ============================================
// 7. TESTING THE SERVICE
// ============================================

// Mock test
async function testUserService() {
  const service = new UserService();
  
  // Test error handling
  const errorResult = await service.getUser(99999);
  if (errorResult instanceof APIError) {
    console.log(`✓ Error handling works: ${errorResult.type}`);
  }
  
  // Test cancelable request
  const cancelTest = await service.getUsersCancelable(100);
  if (cancelTest.canceled) {
    console.log("✓ Cancelable requests work");
  }
  
  // Test state management
  const { state, fetchUsers, users } = useUserStore();
  console.log(`Initial state: ${state.status}`);
  
  await fetchUsers();
  console.log(`After fetch: ${state.status}`);
  console.log(`Users loaded: ${users.length}`);
}

// testUserService();
```

***

## Part 10: Pro-Tips for TypeScript Success

### 10.1 Avoid `any` — It's the "Off Switch" for Safety

```typescript
// ❌ BAD: Disables all type checking
function process(data: any) {
  return data.whatever.nested.property; // No errors, but might crash
}

// ✅ GOOD: Use `unknown` when type is uncertain
function process(data: unknown) {
  if (typeof data === "object" && data !== null) {
    // Type guard needed before accessing properties
    const obj = data as Record<string, unknown>;
    return obj.whatever;
  }
}

// ✅ BETTER: Use type guards
function isUser(data: unknown): data is User {
  return typeof data === "object" && data !== null && "name" in data;
}
```

***

### 10.2 Exercise: Replace `any` with Proper Types

#### `start.ts`
```typescript
// Replace all `any` types with proper type annotations

function processData(data: any): any {
  return data.map((item: any) => item.name);
}

function createAPI(url: any, config: any): any {
  return { url, config, fetch: () => {} };
}

function handleEvent(event: any) {
  console.log(event.target.value);
}
```

#### `final.ts`
```typescript
// Replace all `any` types with proper type annotations

interface DataItem {
  name: string;
  id: number;
}

function processData(data: DataItem[]): string[] {
  return data.map(item => item.name);
}

interface APIConfig {
  timeout?: number;
  headers?: Record<string, string>;
}

interface API {
  url: string;
  config: APIConfig;
  fetch: () => Promise<void>;
}

function createAPI(url: string, config: APIConfig): API {
  return { url, config, fetch: async () => {} };
}

function handleEvent(event: { target: { value: string } }) {
  console.log(event.target.value);
}

// ✅ All types are now explicit and safe
const items: DataItem[] = [{ name: "Item 1", id: 1 }];
const names = processData(items); // string[]

const api = createAPI("/users", { timeout: 5000 }); // API
```

***

### 10.3 Exhaustiveness Checking

Use the `never` type in switch statements to ensure every possible case is covered:

```typescript
type Method = "GET" | "POST" | "PUT" | "DELETE";

function handle(method: Method): string {
  switch (method) {
    case "GET": return "Read";
    case "POST": return "Create";
    case "PUT": return "Update";
    case "DELETE": return "Delete";
    default:
      // TypeScript knows this is 'never' - all cases covered
      throw new Error(`Unhandled method: ${method}`);
  }
}

// If you add "PATCH" to Method but forget the switch:
// ERROR: Type 'never' is not assignable to type 'string'
```

***

### 10.4 Exercise: Exhaustive Type Handler

#### `start.ts`
```typescript
type PaymentStatus = "pending" | "completed" | "failed";

function getStatusMessage(status: PaymentStatus): string {
  switch (status) {
    case "pending": return "Payment pending";
    case "completed": return "Payment completed";
    // Missing "failed" case - should error!
    default: return "Unknown";
  }
}
```

#### `final.ts`
```typescript
type PaymentStatus = "pending" | "completed" | "failed";

function getStatusMessage(status: PaymentStatus): string {
  switch (status) {
    case "pending": return "Payment pending";
    case "completed": return "Payment completed";
    case "failed": return "Payment failed"; // ✅ Must add all cases
    default:
      // Type is 'never' here - TypeScript ensures all cases are handled
      throw new Error(`Unhandled status: ${status}`);
  }
}

console.log(getStatusMessage("pending"));
console.log(getStatusMessage("completed"));
console.log(getStatusMessage("failed"));
```

***

### 10.5 IDE Feedback is Your Best Teacher

Your IDE underlines code in red for type errors. **Hover over it** — the error message explains your type mismatch in detail.

Common IDE hints:
- "Type 'string' is not assignable to type 'number'" → Wrong type
- "Property 'name' does not exist on type 'User'" → Missing property
- "Expected 2 arguments, but got 1" → Missing parameter
- "Type 'undefined' is not assignable" → Need null check

***

### 10.6 Utility Types for Common Patterns

```typescript
// Partial: Make all properties optional
type PartialUser = Partial<User>; // { id?: number; name?: string; email?: string }

// Required: Make all properties required
type RequiredUser = Required<PartialUser>; // Back to full User

// Pick: Select specific properties
type UserName = Pick<User, "name" | "email">; // { name: string; email: string }

// Omit: Exclude properties
type UserWithoutID = Omit<User, "id">; // { name: string; email: string }

// Readonly: Make properties immutable
type ReadonlyUser = Readonly<User>;

// Record: Map-like type
type UserMap = Record<number, User>; // { [key: number]: User }
```

***

### 10.7 Exercise: Utility Types

#### `start.ts`
```typescript
interface User {
  id: number;
  name: string;
  email: string;
  age: number;
}

// Create these types manually (tedious):
// 1. UserUpdate - all properties optional
// 2. UserDisplay - only name and email
// 3. UserInternal - id and age, exclude name and email
```

#### `final.ts`
```typescript
interface User {
  id: number;
  name: string;
  email: string;
  age: number;
}

// ✅ Use utility types instead

// 1. UserUpdate - all properties optional
type UserUpdate = Partial<User>;

// 2. UserDisplay - only name and email
type UserDisplay = Pick<User, "name" | "email">;

// 3. UserInternal - id and age, exclude name and email
type UserInternal = Omit<User, "name" | "email">;

// 4. UserMap - record type
type UserMap = Record<number, User>;

// Usage
const update: UserUpdate = { name: "New Name" }; // Only name provided
const display: UserDisplay = { name: "Alice", email: "alice@email.com" };
const internal: UserInternal = { id: 1, age: 30 };

const users: UserMap = {
  1: { id: 1, name: "Alice", email: "alice@email.com", age: 30 }
};
```

***

## Final Checklist: Your TypeScript Journey

✅ **Understand types**: Static vs dynamic typing  
✅ **Annotate variables**: Explicit types vs inference  
✅ **type functions**: Parameters and return types  
✅ **Create interfaces**: Object blueprints  
✅ **Use union types**: Multiple type possibilities  
✅ **Master discriminated unions**: State machines  
✅ **Handle errors**: Typed error classes  
✅ **Migration strategy**: Gradual JS → TS  
✅ **React state**: Typed useState, useReducer, Context  
✅ **State libraries**: Zustand, Redux Toolkit  
✅ **Pro tips**: Avoid `any`, exhaustiveness, IDE feedback  

***

## Next Steps

1. **Practice daily**: Complete 1-2 exercises from this tutorial
2. **Refactor existing code**: Convert your JS projects to TypeScript
3. **Read TypeScript docs**: https://typescriptlang.org/docs
4. **Join communities**: TypeScript Discord, Reddit r/typescript
5. **Build real projects**: Apply types to production code

**Remember**: TypeScript isn't about restricting you — it's about **empowering** you to write safer, more maintainable code with confidence. The compiler is your teammate, catching bugs before they reach users.
