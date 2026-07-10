# Part 2: Designing the Core (Domain-Driven Design Basics)

## 1. Why Domain-Driven Design?

Domain-Driven Design (DDD, Eric Evans) is not about UML diagrams or ceremony, it is about making the code's vocabulary match the business's vocabulary. When a business stakeholder says "an order can't be shipped until it's paid," the Cost of Change is lowest when your code has an Order class with a ship method that literally enforces that rule, rather than that rule being implicit logic scattered across three API routes and a database trigger.

The core insight: business logic that is explicit and named costs little to change. Business logic that is implicit, buried in conditionals spread across the UI, the API layer, and the database, costs enormously to change, because you must first rediscover it before you can safely modify it.

## 2. Bounded Contexts

A Bounded Context is a boundary within which a specific model and its terminology are consistent and unambiguous. The same word can, and often should, mean different things in different contexts.

For Northwind Orders, "Product" means different things to different parts of the system:

- **Catalog Context:** Product has description, price, images, category
- **Inventory Context:** StockItem has SKU, quantityOnHand, reorderThreshold
- **Ordering Context:** OrderLineItem has SKU, quantityOrdered, priceAtTimeOfOrder

The OrderLineItem references the catalog Product by SKU only, never by object reference, and it triggers a reservation against the Inventory StockItem.

Why not one giant Product model shared everywhere? Because "Product" in Catalog changes for marketing reasons, new photos, new descriptions, at a completely different cadence than "Product" in Inventory, where stock counts change every transaction, or "Product" in Ordering, where the price must be frozen at time of purchase so an order's line-item price does not retroactively change if the catalog price changes tomorrow. Sharing one model couples three unrelated rates of change, a classic Cost of Change trap.

**Context Map, how contexts communicate:**

- Ordering → Catalog: Customer/Supplier relationship, reads product info read-only
- Ordering → Inventory: Customer/Supplier relationship, reserves stock
- Ordering → Payments: Customer/Supplier relationship, requests a charge
- Payments → Ordering: Published Language, emits a PaymentSucceeded event
- Ordering → Notifications: Published Language, emits an OrderShipped event

The Published Language relationships matter: Payments and Notifications never call into Ordering's internal model. They only understand well-defined event shapes. This is what allows Ordering's internal representation to change freely without breaking Payments or Notifications, directly reducing Cost of Change across context boundaries.

## 3. Entities vs. Value Objects

An Entity has a persistent identity that survives changes to its attributes. Two Orders with identical line items are still different orders if they have different IDs. A Value Object has no identity, it is defined entirely by its attributes, and two Value Objects with the same attributes are interchangeable.

Money is the canonical Value Object example. Getting this distinction right matters for Cost of Change because Value Objects can be freely replaced, cached, and compared with equality checks, while Entities require identity-aware handling everywhere (equality by ID, not by field comparison).

```ts
// core/ordering/domain/value-objects/Money.ts
export class Money {
  private readonly cents: number;
  private readonly currency: string;

  private constructor(cents: number, currency: string) {
    this.cents = cents;
    this.currency = currency;
  }

  static fromDollars(dollars: number, currency = "USD"): Money {
    if (dollars < 0) throw new Error("Money cannot be negative");
    return new Money(Math.round(dollars * 100), currency);
  }

  add(other: Money): Money {
    this.assertSameCurrency(other);
    return new Money(this.cents + other.cents, this.currency);
  }

  multiply(factor: number): Money {
    return new Money(Math.round(this.cents * factor), this.currency);
  }

  equals(other: Money): boolean {
    return this.cents === other.cents && this.currency === other.currency;
  }

  toDollars(): number {
    return this.cents / 100;
  }

  private assertSameCurrency(other: Money) {
    if (this.currency !== other.currency) {
      throw new Error(`Currency mismatch: ${this.currency} vs ${other.currency}`);
    }
  }
}
```

Notice: no `id` field. No setters. Every operation returns a *new* Money instance (immutability). This is deliberate — Value Objects should be impossible to mutate accidentally, which eliminates an entire category of bugs where two parts of the system hold "the same" object and one silently mutates it out from under the other.

## 4. Entities

```ts
// core/ordering/domain/entities/OrderLineItem.ts
import { Money } from "../value-objects/Money";

export class OrderLineItem {
  constructor(
    public readonly sku: string,
    public readonly quantity: number,
    public readonly priceAtTimeOfOrder: Money // frozen — never re-fetched from Catalog
  ) {
    if (quantity <= 0) throw new Error("Quantity must be positive");
  }

  lineTotal(): Money {
    return this.priceAtTimeOfOrder.multiply(this.quantity);
  }
}
```

```ts
// core/ordering/domain/entities/Order.ts
import { Money } from "../value-objects/Money";
import { OrderLineItem } from "./OrderLineItem";

export type OrderStatus = "Draft" | "Placed" | "Paid" | "Shipped" | "Cancelled";

export class Order {
  private _status: OrderStatus = "Draft";
  private readonly _lineItems: OrderLineItem[] = [];

  constructor(public readonly id: string, public readonly customerId: string) {}

  get status(): OrderStatus {
    return this._status;
  }

  get lineItems(): readonly OrderLineItem[] {
    return this._lineItems;
  }

  addLineItem(item: OrderLineItem): void {
    if (this._status !== "Draft") {
      throw new Error("Cannot modify an order that has already been placed");
    }
    this._lineItems.push(item);
  }

  place(): void {
    if (this._lineItems.length === 0) {
      throw new Error("Cannot place an empty order");
    }
    this._status = "Placed";
  }

  markPaid(): void {
    if (this._status !== "Placed") {
      throw new Error(`Cannot mark paid from status ${this._status}`);
    }
    this._status = "Paid";
  }

  ship(): void {
    if (this._status !== "Paid") {
      throw new Error("Cannot ship an order that has not been paid");
    }
    this._status = "Shipped";
  }

  total(): Money {
    return this._lineItems.reduce(
      (sum, item) => sum.add(item.lineTotal()),
      Money.fromDollars(0)
    );
  }
}
```

This is the payoff of DDD: the rule "an order cannot ship without being paid" now lives in exactly one place — `Order.ship()` — instead of being re-implemented (and potentially re-implemented *incorrectly*) in every API route, cron job, and admin panel that might try to ship an order.

## 5. Aggregates and the Aggregate Root

An Aggregate is a cluster of entities and value objects that are treated as a single consistency unit. The Aggregate Root is the only entity within the cluster that outside code is allowed to reference directly. In our example, `Order` is the Aggregate Root; `OrderLineItem` only exists and only makes sense in the context of its parent Order, and nothing outside the Order should hold a direct reference to a "bare" OrderLineItem.

**Rule of thumb:** anything that must be transactionally consistent together belongs in the same aggregate. Anything that can tolerate eventual consistency belongs in a different aggregate, linked by ID reference only, and updated via domain events (this is exactly the Published Language pattern from the Context Map above, and it is also the seed of Part 4's Outbox pattern).

Why does Inventory's StockItem live in a *different* aggregate from Order, even though placing an order needs to reserve stock? Because Order and StockItem have different consistency requirements and different failure domains — a payment failure shouldn't roll back a stock reservation transaction, and a warehouse re-count shouldn't lock order placement. Keeping them as separate aggregates, coordinated by events, is what allows Part 5's resilience patterns (retries, circuit breakers) to apply cleanly to the boundary between them.

## 6. Design Exercise

**Scenario:** Extend the Northwind Orders domain to support **discount codes** applied at checkout.

**Step 1:** Is `DiscountCode` an Entity or a Value Object? Justify using the identity test: does a `DiscountCode` need a persistent identity that survives changes to its own attributes, or is it fully defined by its data (code string, percentage, expiry)?

**Step 2:** Does the discount calculation belong on the `Order` aggregate, or in a separate domain service? (Hint: if it needs information beyond what a single aggregate holds — e.g., "has this customer used this code before across all their past orders" — it cannot be a pure method on one aggregate.)

**Step 3:** Draw the updated Context Map: does a `Promotions` bounded context need to exist? What is its Published Language?

## 7. Solution & Discussion

**Step 1:** `DiscountCode` is best modeled as a **Value Object** for its *representation* (code, percentage, expiry are just data, two codes with identical fields are interchangeable) but the *validity check* ("has this code already been redeemed, is it within its usage limit") requires an Entity elsewhere (a `PromotionRedemption` record) because that has a persistent history that must be tracked over time.

**Step 2:** The discount calculation, if it only needs the Order's own line items and a given percentage, can be a pure method on `Order` (e.g., `applyDiscount(code: DiscountCode)`). But the *validity check* ("is this code still valid, has this customer already used it") requires querying redemption history across all orders — that's beyond what one Order aggregate can know. This belongs in a **Domain Service** (`PromotionService`) that both aggregates depend on via injected ports (a direct preview of Part 3's Dependency Injection).

**Step 3:** Yes — a `Promotions` bounded context should exist, owning `DiscountCode` definitions and `PromotionRedemption` history. Its Published Language toward Ordering is a `DiscountValidated { code, percentageOff }` response to a validation request, and toward Ordering it also emits `DiscountRedeemed { orderId, code }` as a domain event once an order using that code is successfully placed. Notice this creates a two-way relationship, but it's still decoupled: Ordering never reads Promotions' internal redemption table directly.

## Up Next

**Part 3 (Decoupling Components)** takes these domain models — pure TypeScript classes with zero framework imports — and wires them into a real Next.js application using Inversion of Control and Dependency Injection, so the `core/` library you just designed never needs to know that Next.js (or React, or SQLite) exists.

