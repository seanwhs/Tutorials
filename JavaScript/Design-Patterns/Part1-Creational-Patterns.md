# Part 1 — Creational Patterns 

## 1.1 Singleton

**Problem:** You need exactly one instance of a class shared across your entire application (e.g., a single database connection pool).

```javascript
// singleton.js

class DatabaseConnection {
  // Static property holds the single instance at the class level,
  // so it persists across every import of this module.
  static #instance = null;

  constructor(connectionString) {
    // Guard clause: if an instance already exists, return IT instead
    // of creating a new one. This is the core of the Singleton pattern.
    if (DatabaseConnection.#instance) {
      return DatabaseConnection.#instance;
    }

    this.connectionString = connectionString;
    this.connectedAt = new Date();
    this.queryCount = 0;

    // Cache this newly created instance for all future calls.
    DatabaseConnection.#instance = this;
  }

  query(sql) {
    this.queryCount++;
    console.log(`[Query #${this.queryCount}] Running: ${sql}`);
    return { rows: [], sql };
  }

  static getInstance(connectionString) {
    // Preferred public API — avoids relying on `new` returning a cached object.
    if (!DatabaseConnection.#instance) {
      DatabaseConnection.#instance = new DatabaseConnection(connectionString);
    }
    return DatabaseConnection.#instance;
  }
}

// --- Usage ---
const dbA = DatabaseConnection.getInstance("postgres://localhost/app");
const dbB = DatabaseConnection.getInstance("postgres://ignored/other");

dbA.query("SELECT * FROM users");
dbB.query("SELECT * FROM orders");

console.log(dbA === dbB); // true — same object, queryCount is shared (2)
console.log(dbA.queryCount); // 2
```

**Modern alternative:** In Node.js, ES Modules are singletons by default because they're cached after the first `import`. Prefer exporting a single instantiated object for simple cases:

```javascript
// config.js
class Config {
  constructor() {
    this.env = process.env.NODE_ENV ?? "development";
  }
}
// The module cache guarantees this only runs once per process.
export default new Config();
```

⚠️ **Caveat:** Singletons introduce global state, which harms testability. Prefer dependency injection where possible instead of reaching for Singleton by default.

---

## 1.2 Factory Method

**Problem:** You need to create objects, but the exact class/type to instantiate depends on runtime conditions, and you want to hide that decision logic from the caller.

```javascript
// factory.js

// Each notification type implements the same "shape" (duck typing in JS —
// there's no `interface` keyword, so we rely on consistent method names).
class EmailNotification {
  constructor(to, subject) {
    this.to = to;
    this.subject = subject;
  }
  send() {
    console.log(`📧 Emailing ${this.to}: "${this.subject}"`);
  }
}

class SMSNotification {
  constructor(to, subject) {
    this.to = to;
    this.subject = subject;
  }
  send() {
    console.log(`📱 Texting ${this.to}: "${this.subject}"`);
  }
}

class PushNotification {
  constructor(to, subject) {
    this.to = to;
    this.subject = subject;
  }
  send() {
    console.log(`🔔 Push alert to ${this.to}: "${this.subject}"`);
  }
}

// The Factory centralizes the "which class do I use?" decision.
// Callers never need to know the concrete classes exist.
class NotificationFactory {
  static create(type, to, subject) {
    switch (type) {
      case "email":
        return new EmailNotification(to, subject);
      case "sms":
        return new SMSNotification(to, subject);
      case "push":
        return new PushNotification(to, subject);
      default:
        // Fail loudly on unknown types rather than silently doing nothing.
        throw new Error(`Unknown notification type: ${type}`);
    }
  }
}

// --- Usage ---
const channels = ["email", "sms", "push"];

// Caller code stays identical regardless of which class is instantiated.
channels.forEach((channel) => {
  const notification = NotificationFactory.create(
    channel,
    "user@example.com",
    "Your order has shipped!"
  );
  notification.send();
});
```

---

## 1.3 Builder

**Problem:** An object has many optional configuration fields, and a constructor with 10 positional arguments is unreadable and error-prone.

```javascript
// builder.js

class HttpRequest {
  constructor({ url, method, headers, body }) {
    this.url = url;
    this.method = method;
    this.headers = headers;
    this.body = body;
  }

  execute() {
    console.log(`${this.method} ${this.url}`);
    console.log("Headers:", this.headers);
    console.log("Body:", this.body);
  }
}

class HttpRequestBuilder {
  #url = "";
  #method = "GET";
  #headers = {};
  #body = null;

  setUrl(url) {
    this.#url = url;
    return this; // Returning `this` enables method chaining (fluent API).
  }

  setMethod(method) {
    this.#method = method;
    return this;
  }

  addHeader(key, value) {
    this.#headers[key] = value;
    return this;
  }

  setBody(body) {
    this.#body = body;
    return this;
  }

  build() {
    // Validation happens once, at the final assembly step —
    // not scattered across every setter.
    if (!this.#url) {
      throw new Error("HttpRequestBuilder: url is required");
    }
    return new HttpRequest({
      url: this.#url,
      method: this.#method,
      headers: this.#headers,
      body: this.#body,
    });
  }
}

// --- Usage ---
const request = new HttpRequestBuilder()
  .setUrl("https://api.example.com/users")
  .setMethod("POST")
  .addHeader("Content-Type", "application/json")
  .addHeader("Authorization", "Bearer token123")
  .setBody(JSON.stringify({ name: "Ada Lovelace" }))
  .build();

request.execute();
```

---

## 1.4 Prototype

**Problem:** Creating a new object from scratch is expensive (heavy computation, deep data), so you clone an existing pre-configured instance instead.

```javascript
// prototype.js

class GameCharacter {
  constructor(type, baseStats) {
    this.type = type;
    this.baseStats = baseStats;
    this.inventory = [];
  }

  // `clone()` is the heart of the Prototype pattern: it produces a new
  // independent object without re-running expensive setup logic.
  clone() {
    // structuredClone gives a true deep copy (no shared references),
    // preventing the classic bug where clones mutate the original's arrays.
    const cloned = structuredClone({
      type: this.type,
      baseStats: this.baseStats,
      inventory: this.inventory,
    });
    return Object.assign(new GameCharacter(cloned.type, cloned.baseStats), cloned);
  }
}

// --- Usage ---
// Imagine this took 500ms to build (loading assets, computing stats, etc.)
const orcTemplate = new GameCharacter("Orc", { hp: 120, attack: 18 });
orcTemplate.inventory.push("Rusty Axe");

// Spawning 3 enemies is now instant — no expensive re-initialization.
const orc1 = orcTemplate.clone();
const orc2 = orcTemplate.clone();

orc1.inventory.push("Shield"); // Mutating orc1 does NOT affect orc2 or the template.

console.log(orc1.inventory); // ["Rusty Axe", "Shield"]
console.log(orc2.inventory); // ["Rusty Axe"]
console.log(orcTemplate.inventory); // ["Rusty Axe"] — untouched
```

---

