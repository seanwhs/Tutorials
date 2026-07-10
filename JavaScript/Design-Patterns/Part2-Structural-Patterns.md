# Part 2 — Structural Patterns 

## 2.1 Adapter

**Problem:** You have to integrate a third-party library whose interface doesn't match what your application expects.

```javascript
// adapter.js

// Third-party library you don't control — its API shape is fixed.
class LegacyPaymentGateway {
  makePayment(amountInCents, currencyCode) {
    console.log(`Legacy gateway charged ${amountInCents} ${currencyCode} cents`);
    return { status: "SUCCESS", legacyId: "LP-882" };
  }
}

// Your application's expected interface — simple, dollar-based, no currency arg.
class PaymentProcessor {
  pay(amountInDollars) {
    throw new Error("pay() must be implemented");
  }
}

// The Adapter translates YOUR interface into calls the legacy library understands.
// This isolates the "ugly" conversion logic in exactly one place.
class PaymentGatewayAdapter extends PaymentProcessor {
  constructor(legacyGateway) {
    super();
    this.legacyGateway = legacyGateway;
  }

  pay(amountInDollars) {
    // Conversion logic lives here — callers never deal with cents or currency codes.
    const amountInCents = Math.round(amountInDollars * 100);
    const result = this.legacyGateway.makePayment(amountInCents, "USD");

    // Normalize the legacy response shape into your app's expected shape too.
    return {
      success: result.status === "SUCCESS",
      transactionId: result.legacyId,
    };
  }
}

// --- Usage ---
const legacyGateway = new LegacyPaymentGateway();
const processor = new PaymentGatewayAdapter(legacyGateway);

// Your app code only ever talks to the clean `pay(dollars)` interface.
const outcome = processor.pay(49.99);
console.log(outcome); // { success: true, transactionId: 'LP-882' }
```

---

## 2.2 Decorator

**Problem:** You want to add new behavior (logging, caching, validation) to an object without modifying its original class or creating a rigid subclass hierarchy.

```javascript
// decorator.js

// The base component — a plain, simple coffee order calculator.
class Coffee {
  cost() {
    return 4;
  }
  describe() {
    return "Coffee";
  }
}

// Each decorator WRAPS an existing object and adds behavior around it,
// while preserving the same interface (cost/describe) so wrapping is composable.
class MilkDecorator {
  constructor(coffee) {
    this.coffee = coffee; // Wrapped instance — could itself be another decorator.
  }
  cost() {
    return this.coffee.cost() + 0.5;
  }
  describe() {
    return `${this.coffee.describe()} + Milk`;
  }
}

class CaramelDecorator {
  constructor(coffee) {
    this.coffee = coffee;
  }
  cost() {
    return this.coffee.cost() + 0.75;
  }
  describe() {
    return `${this.coffee.describe()} + Caramel`;
  }
}

// --- Usage ---
// Decorators stack: each layer adds cost/description without touching Coffee itself.
let order = new Coffee();
order = new MilkDecorator(order);
order = new CaramelDecorator(order);

console.log(order.describe()); // "Coffee + Milk + Caramel"
console.log(order.cost()); // 5.25

// --- Functional variant (common in real-world JS: middleware/logging) ---
function withLogging(fn) {
  // Returns a NEW function that wraps the original — same idea, no classes needed.
  return function (...args) {
    console.log(`Calling ${fn.name} with`, args);
    const result = fn(...args);
    console.log(`Result:`, result);
    return result;
  };
}

function add(a, b) {
  return a + b;
}

const loggedAdd = withLogging(add);
loggedAdd(2, 3); // Logs call + result, then returns 5
```

---

## 2.3 Facade

**Problem:** A subsystem has many complex, interdependent classes. You want to expose one simple, unified interface to hide that complexity from consumers.

```javascript
// facade.js

// Complex subsystem — three separate low-level services a video upload needs.
class VideoConverter {
  convert(file, format) {
    console.log(`Converting ${file} to ${format}...`);
    return `${file}.${format}`;
  }
}

class ThumbnailGenerator {
  generate(file) {
    console.log(`Generating thumbnail for ${file}...`);
    return `${file}-thumb.jpg`;
  }
}

class CloudStorageUploader {
  upload(file) {
    console.log(`Uploading ${file} to cloud storage...`);
    return `https://cdn.example.com/${file}`;
  }
}

// The Facade exposes ONE method that internally orchestrates all three
// subsystem classes in the correct order. Consumers don't need to know
// conversion must happen before upload, or that thumbnails exist at all.
class VideoUploadFacade {
  constructor() {
    this.converter = new VideoConverter();
    this.thumbnailGenerator = new ThumbnailGenerator();
    this.uploader = new CloudStorageUploader();
  }

  // Single entry point — this IS the simplified interface.
  publish(rawFile) {
    const converted = this.converter.convert(rawFile, "mp4");
    const thumbnail = this.thumbnailGenerator.generate(converted);
    const videoUrl = this.uploader.upload(converted);
    const thumbnailUrl = this.uploader.upload(thumbnail);

    return { videoUrl, thumbnailUrl };
  }
}

// --- Usage ---
// Consumer code is trivial — no knowledge of conversion/thumbnailing/uploading needed.
const uploader = new VideoUploadFacade();
const result = uploader.publish("vacation-clip.mov");

console.log(result);
// { videoUrl: 'https://cdn.example.com/vacation-clip.mov.mp4',
//   thumbnailUrl: 'https://cdn.example.com/vacation-clip.mov.mp4-thumb.jpg' }
```

---

## 2.4 Proxy

**Problem:** You want to control access to an object — adding validation, lazy loading, or caching — without changing the object itself or its callers.

```javascript
// proxy.js

// The "real" object — expensive to call repeatedly (imagine a network request).
class WeatherAPI {
  fetchTemperature(city) {
    console.log(`🌐 Hitting network for ${city}...`);
    // Simulated expensive computation/API call.
    return Math.round(15 + Math.random() * 10);
  }
}

// The native `Proxy` object intercepts operations (like method calls)
// on the target via "traps" — here we use the `get` trap.
function createCachingProxy(target) {
  const cache = new Map();

  return new Proxy(target, {
    get(targetObj, methodName, receiver) {
      const originalMethod = targetObj[methodName];

      // Only wrap functions; pass through plain property access untouched.
      if (typeof originalMethod !== "function") {
        return Reflect.get(targetObj, methodName, receiver);
      }

      return function (...args) {
        const cacheKey = `${methodName}:${JSON.stringify(args)}`;

        if (cache.has(cacheKey)) {
          console.log(`✅ Cache hit for ${cacheKey}`);
          return cache.get(cacheKey);
        }

        // Delegate to the real method only on a cache miss.
        const result = originalMethod.apply(targetObj, args);
        cache.set(cacheKey, result);
        return result;
      };
    },
  });
}

// --- Usage ---
const weatherAPI = new WeatherAPI();
const cachedWeatherAPI = createCachingProxy(weatherAPI);

console.log(cachedWeatherAPI.fetchTemperature("Tokyo")); // Network hit, e.g. 21
console.log(cachedWeatherAPI.fetchTemperature("Tokyo")); // Cache hit, same value
console.log(cachedWeatherAPI.fetchTemperature("Paris")); // Network hit (different args)
```

---

## 2.5 Composite

**Problem:** You have tree-like structures (file systems, UI components, org charts) and want to treat individual items and groups of items through the same interface.

```javascript
// composite.js

// The common interface both leaves (files) and branches (folders) implement.
class FileSystemNode {
  getSize() {
    throw new Error("getSize() must be implemented");
  }
}

// LEAF: a single file — no children, just a fixed size.
class File extends FileSystemNode {
  constructor(name, sizeInKb) {
    super();
    this.name = name;
    this.sizeInKb = sizeInKb;
  }

  getSize() {
    return this.sizeInKb;
  }
}

// COMPOSITE: a folder that can contain files AND other folders.
// It implements the SAME `getSize()` interface, but delegates/aggregates
// over its children — this is what makes leaves and branches interchangeable.
class Folder extends FileSystemNode {
  constructor(name) {
    super();
    this.name = name;
    this.children = [];
  }

  add(node) {
    // `node` can be a File OR another Folder — the caller doesn't care which.
    this.children.push(node);
    return this;
  }

  getSize() {
    // Recursively sums sizes regardless of nesting depth.
    return this.children.reduce((total, child) => total + child.getSize(), 0);
  }
}

// --- Usage ---
const root = new Folder("project");
const src = new Folder("src");
const assets = new Folder("assets");

src.add(new File("index.js", 12)).add(new File("utils.js", 5));
assets.add(new File("logo.png", 340)).add(new File("banner.png", 890));

root.add(src).add(assets).add(new File("README.md", 3));

// Calling getSize() on the root treats the ENTIRE nested tree uniformly —
// no special-casing needed for "is this a file or a folder?"
console.log(`Total size: ${root.getSize()} KB`); // Total size: 1250 KB
```

---

