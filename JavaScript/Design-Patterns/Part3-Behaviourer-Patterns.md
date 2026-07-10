# Part 3 — Behavioral Patterns

## 3.1 Observer

**Problem:** One object (the "subject") changes state, and multiple dependent objects ("observers") need to be notified automatically — without the subject knowing who they are ahead of time.

```javascript
// observer.js

class EventEmitter {
  #listeners = new Map(); // eventName -> Set of callback functions

  on(eventName, callback) {
    if (!this.#listeners.has(eventName)) {
      this.#listeners.set(eventName, new Set());
    }
    this.#listeners.get(eventName).add(callback);

    // Returning an unsubscribe function is a modern convenience pattern —
    // avoids callers needing to keep a reference to `callback` just to remove it later.
    return () => this.#listeners.get(eventName)?.delete(callback);
  }

  emit(eventName, payload) {
    // Subject doesn't know or care WHAT the observers do with the data.
    this.#listeners.get(eventName)?.forEach((callback) => callback(payload));
  }
}

// --- Real-world example: a stock ticker with multiple independent watchers ---
class StockTicker extends EventEmitter {
  setPrice(symbol, price) {
    this.emit("price-change", { symbol, price });
  }
}

// --- Usage ---
const ticker = new StockTicker();

// Observer 1: a dashboard widget
const unsubscribeDashboard = ticker.on("price-change", ({ symbol, price }) => {
  console.log(`📊 Dashboard: ${symbol} is now $${price}`);
});

// Observer 2: a price-alert system, completely decoupled from the dashboard
ticker.on("price-change", ({ symbol, price }) => {
  if (price > 100) console.log(`🚨 Alert: ${symbol} exceeded $100!`);
});

ticker.setPrice("AAPL", 105); // Both observers fire independently
unsubscribeDashboard();       // Dashboard stops listening
ticker.setPrice("AAPL", 110); // Only the alert observer fires now
```

---

## 3.2 Strategy

**Problem:** You have multiple interchangeable algorithms for the same task (e.g., calculating shipping cost), and you want to swap between them at runtime without `if/else` chains scattered through your code.

```javascript
// strategy.js

// Each strategy is just a function with a consistent signature —
// in JS, functions-as-strategies are simpler than class hierarchies.
const shippingStrategies = {
  standard: (weightKg) => weightKg * 2.5,
  express: (weightKg) => weightKg * 5 + 10,
  overnight: (weightKg) => weightKg * 8 + 25,
};

class ShippingCalculator {
  constructor(strategy) {
    // The algorithm is INJECTED, not hardcoded — this is the core of Strategy.
    this.strategy = strategy;
  }

  setStrategy(strategy) {
    // Swappable at runtime — same calculator, different behavior.
    this.strategy = strategy;
  }

  calculate(weightKg) {
    return this.strategy(weightKg);
  }
}

// --- Usage ---
const calculator = new ShippingCalculator(shippingStrategies.standard);
console.log(calculator.calculate(4)); // 10 (standard)

calculator.setStrategy(shippingStrategies.express);
console.log(calculator.calculate(4)); // 30 (express)

calculator.setStrategy(shippingStrategies.overnight);
console.log(calculator.calculate(4)); // 57 (overnight)

// --- Real-world variant: choosing strategy based on runtime condition ---
function getBestStrategy(deadlineInDays) {
  if (deadlineInDays <= 1) return shippingStrategies.overnight;
  if (deadlineInDays <= 3) return shippingStrategies.express;
  return shippingStrategies.standard;
}

const urgentCalculator = new ShippingCalculator(getBestStrategy(1));
console.log(urgentCalculator.calculate(2)); // 41 (overnight picked automatically)
```

---

## 3.3 Command

**Problem:** You want to encapsulate an action (and its parameters) as a standalone object, so it can be queued, logged, undone, or executed later — decoupled from whoever triggered it.

```javascript
// command.js

// Receiver — the object that actually performs the work.
class TextDocument {
  constructor() {
    this.content = "";
  }
  insert(text) {
    this.content += text;
  }
  delete(count) {
    this.content = this.content.slice(0, -count);
  }
}

// Each Command encapsulates: (1) what to do, and (2) how to undo it.
class InsertTextCommand {
  constructor(document, text) {
    this.document = document;
    this.text = text;
  }
  execute() {
    this.document.insert(this.text);
  }
  undo() {
    // Undo logic is paired with execute logic in the SAME object —
    // this locality makes undo/redo systems tractable.
    this.document.delete(this.text.length);
  }
}

// The Invoker keeps a history stack — it doesn't know what commands DO,
// only that they're executable/undoable.
class CommandManager {
  #history = [];

  execute(command) {
    command.execute();
    this.#history.push(command); // Track for potential undo.
  }

  undoLast() {
    const command = this.#history.pop();
    if (command) command.undo();
  }
}

// --- Usage ---
const doc = new TextDocument();
const manager = new CommandManager();

manager.execute(new InsertTextCommand(doc, "Hello"));
manager.execute(new InsertTextCommand(doc, ", World!"));
console.log(doc.content); // "Hello, World!"

manager.undoLast();
console.log(doc.content); // "Hello"

manager.undoLast();
console.log(doc.content); // ""
```

---

## 3.4 Iterator

**Problem:** You have a custom collection and want consumers to loop over it (`for...of`) without exposing its internal storage structure.

```javascript
// iterator.js

class TaskQueue {
  #tasks = [];

  addTask(task) {
    this.#tasks.push(task);
    return this;
  }

  // Implementing Symbol.iterator makes this object work with `for...of`,
  // spread syntax, Array.from(), and destructuring — all "for free".
  [Symbol.iterator]() {
    let index = 0;
    const tasks = this.#tasks; // Closure captures the private data safely.

    return {
      next() {
        // The iterator protocol: return { value, done } each call.
        if (index < tasks.length) {
          return { value: tasks[index++], done: false };
        }
        return { value: undefined, done: true };
      },
    };
  }

  // A generator function is a much shorter way to achieve the same protocol —
  // `function*` automatically implements next()/done for you.
  *byPriority() {
    const sorted = [...this.#tasks].sort((a, b) => b.priority - a.priority);
    for (const task of sorted) {
      yield task; // Pauses here and resumes on the next `.next()` call.
    }
  }
}

// --- Usage ---
const queue = new TaskQueue()
  .addTask({ name: "Fix bug", priority: 2 })
  .addTask({ name: "Deploy", priority: 3 })
  .addTask({ name: "Write docs", priority: 1 });

// Works because of Symbol.iterator — internal #tasks array stays private.
for (const task of queue) {
  console.log(`Task: ${task.name}`);
}

// Using the generator-based custom iteration order:
for (const task of queue.byPriority()) {
  console.log(`Priority ${task.priority}: ${task.name}`);
}
// Priority 3: Deploy
// Priority 2: Fix bug
// Priority 1: Write docs
```

---

## 3.5 State

**Problem:** An object's behavior needs to change entirely based on its internal state (e.g., an order can't be "shipped" before it's "paid"), and you want to avoid giant `if/else`/`switch` blocks scattered across every method.

```javascript
// state.js

// Each state is an object implementing the SAME method names,
// but with behavior specific to that state.
class PendingState {
  pay(order) {
    console.log("💳 Payment received.");
    order.setState(order.states.paid); // Transition to the next state.
  }
  ship(order) {
    // Invalid transition — the state itself enforces the business rule.
    console.log("❌ Cannot ship — order not paid yet.");
  }
}

class PaidState {
  pay(order) {
    console.log("⚠️ Already paid.");
  }
  ship(order) {
    console.log("📦 Order shipped.");
    order.setState(order.states.shipped);
  }
}

class ShippedState {
  pay(order) {
    console.log("⚠️ Already paid and shipped.");
  }
  ship(order) {
    console.log("⚠️ Already shipped.");
  }
}

class Order {
  constructor() {
    // Pre-instantiate all possible states once, reused across transitions.
    this.states = {
      pending: new PendingState(),
      paid: new PaidState(),
      shipped: new ShippedState(),
    };
    this.currentState = this.states.pending;
  }

  setState(state) {
    this.currentState = state;
  }

  // Order.pay()/ship() simply DELEGATE to whatever the current state defines —
  // Order itself contains zero conditional logic about what's "allowed".
  pay() {
    this.currentState.pay(this);
  }
  ship() {
    this.currentState.ship(this);
  }
}

// --- Usage ---
const order = new Order();
order.ship(); // ❌ Cannot ship — order not paid yet.
order.pay();  // 💳 Payment received.
order.ship(); // 📦 Order shipped.
order.ship(); // ⚠️ Already shipped.
```

---

## 3.6 Mediator

**Problem:** Many objects need to communicate with each other, but direct references between all of them create a tangled web of dependencies. A mediator centralizes that communication.

```javascript
// mediator.js

// The Mediator — the ONLY object that knows about all participants.
// Participants never talk to each other directly.
class ChatRoom {
  #users = new Map();

  register(user) {
    this.#users.set(user.name, user);
    user.chatRoom = this; // Give the user a reference back to the mediator only.
  }

  // Central routing logic — could include logging, filtering, rate-limiting, etc.
  send(message, fromUserName, toUserName) {
    const recipient = this.#users.get(toUserName);
    if (!recipient) {
      console.log(`⚠️ User ${toUserName} not found.`);
      return;
    }
    recipient.receive(message, fromUserName);
  }

  broadcast(message, fromUserName) {
    for (const [name, user] of this.#users) {
      if (name !== fromUserName) user.receive(message, fromUserName);
    }
  }
}

// Participants only know about the Mediator — NOT about each other.
class ChatUser {
  constructor(name) {
    this.name = name;
    this.chatRoom = null; // Set during registration.
  }

  send(message, toUserName) {
    // Delegates routing entirely to the mediator.
    this.chatRoom.send(message, this.name, toUserName);
  }

  broadcast(message) {
    this.chatRoom.broadcast(message, this.name);
  }

  receive(message, fromUserName) {
    console.log(`[${this.name}] received from ${fromUserName}: "${message}"`);
  }
}

// --- Usage ---
const chatRoom = new ChatRoom();
const alice = new ChatUser("Alice");
const bob = new ChatUser("Bob");
const carol = new ChatUser("Carol");

// Every user registers with the mediator — no direct references between users exist.
chatRoom.register(alice);
chatRoom.register(bob);
chatRoom.register(carol);

alice.send("Hey Bob, got a minute?", "Bob");
// [Bob] received from Alice: "Hey Bob, got a minute?"

bob.send("Sure, what's up?", "Alice");
// [Alice] received from Bob: "Sure, what's up?"

carol.broadcast("Standup in 5 minutes!");
// [Alice] received from Carol: "Standup in 5 minutes!"
// [Bob] received from Carol: "Standup in 5 minutes!"

alice.send("Hi Dave", "Dave");
// ⚠️ User Dave not found.
```

**Why this matters:** Adding a 4th user (`Dave`) requires zero changes to `Alice`, `Bob`, or `Carol` — only a `chatRoom.register(dave)` call. Without a mediator, every user would need direct references to every other user, creating O(n²) coupling.

---

Part 3 is now fully complete: **3.1 Observer, 3.2 Strategy, 3.3 Command, 3.4 Iterator, 3.5 State, 3.6 Mediator** — all with full runnable code and usage demos delivered above (this message + the previous one together contain the complete Part 3).

