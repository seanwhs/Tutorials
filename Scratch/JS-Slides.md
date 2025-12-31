Here are the finalized slides for each module, broken down individually from **Module 5 through Module 9**. Each module includes "Deep Dive" theory followed by the corresponding "Interactive Challenge" to ensure students apply the architectural concepts immediately.

---

### **Module 5: Memory, Scope & Engine Mechanics**

**Slide 32: Deep Dive — The Stack vs. The Heap**

* **The Stack:** Stores static data (primitives: numbers, booleans). It uses LIFO (Last-In-First-Out) logic for ultra-fast access.
* **The Heap:** Stores dynamic data (objects, arrays). Variables in the stack hold a "pointer" (memory address) to the heap.
* **Pass-by-Reference:** Copying an object variable only copies the pointer. Both variables now point to the same data in the heap.

**Slide 33: Challenge — Memory Management**

* **Scenario:** You create a `user` object. You set `admin = user`. You change `admin.role = 'Super'`.
* **The Problem:** Why is the original `user.role` now 'Super'?
* **The Task:** Implement a "Deep Copy" using `structuredClone()` or the Spread Operator to ensure the original user remains unchanged.

**Slide 34: Deep Dive — Execution Context & The TDZ**

* **Hoisting:** Engine allocates memory for declarations before execution.
* **The Temporal Dead Zone (TDZ):** `let` and `const` are hoisted but uninitialized. Accessing them before the line of declaration triggers a `ReferenceError`.
* **Global vs. Local:** Avoiding global pollution by utilizing block-level scope.

**Slide 35: Challenge — The Temporal Dead Zone**

* **Task:** You are given a script where `console.log(price)` occurs before `let price = 10`.
* **The Fix:** Refactor the code into a functional block to utilize lexical scoping and eliminate the "access before initialization" error.

---

### **Module 6: Advanced Asynchronous Behavior**

**Slide 36: Deep Dive — The Event Loop & Task Queues**

* **Single Threaded:** JS can only do one thing at a time.
* **Microtasks (Priority):** Promises and `await` go here. The loop drains this queue entirely before moving on.
* **Macrotasks:** `setTimeout`, `setInterval`, and DOM events. These wait for the stack and microtasks to clear.

**Slide 37: Challenge — Event Loop Prioritization**

* **Scenario:** Predict the output of this sequence: `console.log('A')`, `setTimeout(() => console.log('B'), 0)`, and `Promise.resolve().then(() => console.log('C'))`.
* **The Task:** Explain why 'C' prints before 'B' despite the 0ms timer.

**Slide 38: Deep Dive — Web Workers (Multi-threading)**

* **Concurrency:** Offloading heavy calculations (data processing, complex math) to a background thread.
* **Main Thread Safety:** Keeping the UI thread free to handle clicks and animations at 60fps.
* **Messaging:** Using `postMessage` to send data back and forth without sharing memory.

**Slide 39: Challenge — Off-Main-Thread Processing**

* **Scenario:** A data-filtering loop takes 3 seconds and freezes the user's browser.
* **The Task:** Move the filtering logic into a `worker.js`. Implement the listener in `main.js` to receive the sorted data without a UI freeze.

---

### **Module 7: Programming Paradigms (OOP vs. FP)**

**Slide 40: Deep Dive — Prototypal Inheritance**

* **The Prototype Chain:** Objects link to others via `[[Prototype]]`.
* **Classes (ES6):** Syntactic sugar over prototypes. Use `extends` for inheritance and `super()` to access parent constructors.
* **Encapsulation:** Using `#private` fields to hide internal logic.

**Slide 41: Challenge — Prototypal Inheritance**

* **Task:** Build a "Vehicle" architecture. Create a base `Vehicle` class and a `ElectricCar` subclass.
* **Requirement:** Ensure the `ElectricCar` correctly inherits methods from `Vehicle` while adding its own `chargeBattery` method.

**Slide 42: Deep Dive — Functional Programming & Immutability**

* **Pure Functions:** Same input = Same output. No side effects.
* **Declarative Data:** Using `.map()`, `.filter()`, and `.reduce()` to transform data arrays.
* **Immutability:** Never changing an existing array; always returning a new one.

**Slide 43: Challenge — Closures & Private State**

* **Goal:** Create a "Secure Vault."
* **Task:** Write a function `createVault(secret)`. It must return an object with a `viewSecret` method, but the `secret` variable itself must be unreachable from the global scope.

---

### **Module 8: System Design & Performance**

**Slide 44: Deep Dive — The Observer Pattern**

* **Decoupling:** Allowing multiple components to react to a single state change without being directly connected.
* **Usage:** The foundation of modern reactive frameworks (React, Vue) and Event Listeners.

**Slide 45: Challenge — The Singleton Pattern**

* **Scenario:** You need a single "Theme Manager" that persists across every page of your app.
* **The Task:** Implement a Class that, no matter how many times it is instantiated, always returns the same single instance from memory.

**Slide 46: Deep Dive — Execution Control (Debounce/Throttle)**

* **Debouncing:** Waiting for the user to "stop" (e.g., typing in a search bar).
* **Throttling:** Limiting how many times a function fires (e.g., scrolling or resizing).
* **Efficiency:** Drastically reduces unnecessary API calls and layout repaints.

**Slide 47: Challenge — Debounce Implementation**

* **Task:** Attach a "Search" function to an input field.
* **Requirement:** Implement a debounce wrapper so the search function only executes after the user has stopped typing for 500ms.

---

### **Module 9: Security, Testing & DX**

**Slide 48: Deep Dive — Security (XSS & CSRF)**

* **XSS (Cross-Site Scripting):** Malicious scripts injected via `innerHTML`.
* **Sanitization:** Using `textContent` and sanitization libraries to strip dangerous tags.
* **Tokens:** Storing JWTs in `HttpOnly` cookies to prevent access by JS-based attacks.

**Slide 49: Challenge — Security Audit**

* **Scenario:** You are given a code snippet: `document.body.innerHTML = "Welcome " + urlParam;`.
* **The Task:** Identify why this is dangerous and refactor it to use `textContent` for safety.

**Slide 50: Deep Dive — Unit Testing & Mocking**

* **Isolation:** Testing a single function without needing the whole browser or a real database.
* **Jest/Vitest:** Popular tools for running assertions (`expect(sum(1,2)).toBe(3)`).
* **Mocks:** Creating "fake" API responses to test how your UI handles success and failure.

**Slide 51: Challenge — Unit Testing a Pure Function**

* **Task:** Write a pure function `calculateTax(price, rate)`.
* **Requirement:** Write three test cases: one for a standard 10% tax, one for a 0% rate, and one to handle an invalid (string) input.

---
Building on the established structure, here are the detailed slides for the final architectural and assessment modules, continuing from **Slide 52** through to the **Capstone Project**.

---

### **Module 10: Advanced System Architecture (Slides 52–55)**

**Slide 52: Deep Dive — SOLID Principles in JS**

* **Single Responsibility:** A function should do one thing (e.g., `calculateTax`) and not handle UI updates.
* **Open/Closed:** Use inheritance or composition to add features without modifying existing, tested code.
* **Liskov Substitution:** Subclasses (like `ElectricCar`) must be able to replace their parent (`Vehicle`) without breaking the app.
* **Interface Segregation:** Don't force a class to implement methods it doesn't need.
* **Dependency Inversion:** High-level logic should depend on abstractions, not low-level helper scripts.

**Slide 53: Challenge — Dependency Inversion**

* **Scenario:** Your `UserAuth` class is hard-coded to use `localStorage`.
* **The Task:** Refactor the class to accept a `storageEngine` as a parameter. This allows you to swap `localStorage` for `sessionStorage` or a `database` without changing the `UserAuth` logic.

**Slide 54: Deep Dive — Centralized State Management**

* **Prop Drilling:** The "Spaghetti" problem where data is passed through 5 layers of components just to reach the footer.
* **The Store Pattern:** A single object in the **Memory Heap** that acts as the "Source of Truth" for the entire application.
* **Reactivity:** When the Store changes, only the components "watching" that specific slice of data will re-render.

**Slide 55: Challenge — The Notification Store**

* **Goal:** Build a global alert system.
* **The Task:** Create a `NotificationStore` object. Implement an `addAlert()` method that adds a message to an array and a `subscribers` list that notifies the UI whenever a new alert arrives.

---

### **Module 11: Performance & Professional Deployment (Slides 56–58)**

**Slide 56: Deep Dive — Execution Control (Debounce vs. Throttle)**

* **Debouncing:** Useful for Search Bars. It resets a timer every time a key is pressed; the search only fires when the user *stops* typing.
* **Throttling:** Useful for Scrolling. It ensures a function fires only once every 100ms, regardless of how fast the user scrolls.
* **Impact:** Prevents "Main Thread Blocking" and reduces unnecessary server load.

**Slide 57: Challenge — Scroll Progress Tracker**

* **Scenario:** You want to show a progress bar at the top of the page as the user scrolls.
* **The Task:** Implement a **Throttled** scroll listener. Why is throttling better than a raw listener for this specific use case?

**Slide 58: Deep Dive — Code Splitting & ESM**

* **Bundling:** Combining hundreds of files into one.
* **The Problem:** Huge bundles take forever to download on mobile networks.
* **Dynamic Imports:** Using `import('./module.js').then()` to load code *only* when the user clicks a specific button or navigates to a new route.

---

### **Module 12: Professional DX & Security (Slides 59–62)**

**Slide 59: Deep Dive — Universal JS (Node.js vs. Browser)**

* **The Runtime:** Browsers have `window` and `document`. Node.js has `process` and `fs` (File System).
* **Cross-Platform Logic:** Writing "Isomorphic" code (like data validation) that can run on both the client and the server.

**Slide 60: Deep Dive — Scaling with TypeScript**

* **Interfaces:** Defining a "Contract" for your data. If an API returns an object missing a required property, TypeScript flags the error before you even hit "Save."
* **Generics:** Creating reusable functions that work with multiple types while maintaining strict safety.

**Slide 61: Deep Dive — CI/CD & Professional Deployment**

* **The Pipeline:** 1. Linting -> 2. Unit Testing -> 3. Build/Minification -> 4. Deployment.
* **Environment Variables:** Using `.env` files to ensure your private API keys never end up on GitHub.

**Slide 62: Challenge — Environment Security Audit**

* **Task:** You are given a script with an API Key hard-coded: `const key = "12345-ABC"`.
* **The Fix:** Move the key to a `.env` file and refactor the code to use `process.env.API_KEY`, ensuring the key is stripped during the build process.

---

### **Module 13: The Final Knowledge Check (Slides 63–64)**

**Slide 63: Knowledge Check — Core Mechanics Review**

* **The Stack:** Explain why primitives are "passed by value."
* **The Heap:** Explain why objects are "passed by reference."
* **The Event Loop:** If a `while` loop runs forever, why does the `setTimeout` never fire?

**Slide 64: Knowledge Check — Patterns & Performance Review**

* **FP vs. OOP:** Which paradigm is better for "State Management" and why? (Hint: Immutability).
* **Security:** Why is `textContent` the industry standard for preventing XSS?
* **Performance:** Define "Layout Thrashing" and how `requestAnimationFrame` prevents it.

---

### **Module 14: The Capstone (Slide 65)**

**Slide 65: Final Capstone Project Roadmap — The Real-Time Dashboard**

* **The Objective:** Build a "Live Crypto/Stock Tracker" from scratch.
* **Technical Requirements:**
1. **Architecture:** Use the **Observer Pattern** to update the UI when new prices arrive via WebSocket.
2. **Data Modeling:** Use **Classes** to handle each currency's data.
3. **Logic:** Use **Pure Functions** (`filter/reduce`) to show the "Top 5 Gainers."
4. **Performance:** Implement **Debouncing** on the search/filter input.
5. **Quality:** Write at least two **Unit Tests** for your price calculation logic.


* **The Goal:** Prove you can bridge the gap from writing "scripts" to designing "scalable systems."

---

**This concludes the 65-slide Masterclass. Would you like the sample code for the Capstone Project (Slide 65) to provide as a solution key for your students?**
