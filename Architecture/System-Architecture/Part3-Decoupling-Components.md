# Part 3: Decoupling Components (Inversion of Control & Dependency Injection)

## 1. The Problem: Frameworks Are Temporary, Business Logic Is Not

In Part 2 we built a pure domain layer: Order, OrderLineItem, Money. Zero imports from React, Next.js, or any database driver. That purity is only valuable if it survives contact with a real application. This part is about the wiring that keeps it pure.

The naive approach couples a Server Action directly to a database client and directly to business rules, all in one file. The Cost of Change problem: to test the business rule you must spin up a database. To swap databases you must hunt through every Server Action. To reuse the rule in a cron job or a CLI script you must duplicate it.

## 2. Inversion of Control and the Dependency Rule

Inversion of Control says: high-level policy (business rules) should not depend on low-level detail (a specific database or framework). Instead, both should depend on an abstraction, and the low-level detail should be plugged into the high-level policy from the outside, not the other way around.

Concretely: the Order domain and the application use case that orchestrates it should declare what they need as an interface (a Port), and the infrastructure layer provides a concrete implementation (an Adapter) that gets handed in, typically at the composition root of the application.

## 3. Defining Ports in the Application Layer

A Port is an interface owned by the application/domain layer, describing a capability it needs, without knowing who provides it.

```ts
// core/ordering/application/ports/OrderRepository.ts
import { Order } from "../../domain/entities/Order";

export interface OrderRepository {
  findById(id: string): Promise<Order | null>;
  save(order: Order): Promise<void>;
}
```

```ts
// core/ordering/application/ports/PaymentGateway.ts
export interface PaymentGateway {
  charge(orderId: string, amountCents: number): Promise<{ success: boolean; transactionId?: string }>;
}
```

```ts
// core/ordering/application/ports/EventPublisher.ts
export interface DomainEvent {
  type: string;
  payload: unknown;
  occurredAt: Date;
}

export interface EventPublisher {
  publish(event: DomainEvent): Promise<void>;
}
```

Notice these live inside core, next to the domain, not inside infrastructure. The direction of ownership matters: the application layer defines the contract; infrastructure must conform to it. This is the Dependency Inversion Principle in its literal form.

## 4. The Use Case (Application Service)

```ts
// core/ordering/application/use-cases/PlaceOrder.ts
import { Order } from "../../domain/entities/Order";
import { OrderRepository } from "../ports/OrderRepository";
import { PaymentGateway } from "../ports/PaymentGateway";
import { EventPublisher } from "../ports/EventPublisher";

export class PlaceOrderUseCase {
  constructor(
    private readonly orders: OrderRepository,
    private readonly payments: PaymentGateway,
    private readonly events: EventPublisher
  ) {}

  async execute(orderId: string): Promise<{ ok: true } | { ok: false; reason: string }> {
    const order = await this.orders.findById(orderId);
    if (!order) return { ok: false, reason: "Order not found" };

    order.place();

    const result = await this.payments.charge(order.id, order.total().toDollars() * 100);
    if (!result.success) {
      return { ok: false, reason: "Payment failed" };
    }

    order.markPaid();
    await this.orders.save(order);

    await this.events.publish({
      type: "OrderPaid",
      payload: { orderId: order.id, customerId: order.customerId },
      occurredAt: new Date(),
    });

    return { ok: true };
  }
}
```

PlaceOrderUseCase imports zero infrastructure. It could run in a Next.js Server Action, a CLI tool, a test file, or a future non-JS service if rewritten line-for-line, because it only speaks in terms of interfaces it does not implement itself.

## 5. Adapters: Where Next.js and the Database Actually Live

```ts
// infrastructure/persistence/InMemoryOrderRepository.ts
import { Order } from "@/core/ordering/domain/entities/Order";
import { OrderRepository } from "@/core/ordering/application/ports/OrderRepository";

const db = new Map<string, Order>();

export class InMemoryOrderRepository implements OrderRepository {
  async findById(id: string): Promise<Order | null> {
    return db.get(id) ?? null;
  }
  async save(order: Order): Promise<void> {
    db.set(order.id, order);
  }
}
```

```ts
// infrastructure/payments/FakePaymentGateway.ts
import { PaymentGateway } from "@/core/ordering/application/ports/PaymentGateway";

export class FakePaymentGateway implements PaymentGateway {
  async charge(orderId: string, amountCents: number) {
    await new Promise((r) => setTimeout(r, 100));
    return { success: true, transactionId: `fake_${orderId}_${Date.now()}` };
  }
}
```

```ts
// infrastructure/events/ConsoleEventPublisher.ts
import { EventPublisher, DomainEvent } from "@/core/ordering/application/ports/EventPublisher";

export class ConsoleEventPublisher implements EventPublisher {
  async publish(event: DomainEvent): Promise<void> {
    console.log(`[event] ${event.type}`, event.payload);
  }
}
```

Each adapter is small, replaceable, and untestable-business-logic-free — there is nothing to unit test here beyond "does it talk to the real thing correctly," which is properly an integration test concern, not a business-rule concern.

## 6. The Composition Root: Wiring It Together

The Composition Root is the one place in the entire application allowed to know about both the abstract Ports and the concrete Adapters simultaneously. In a Next.js app, this is typically a small container module imported only by Server Actions and Route Handlers, never by domain or application code.

```ts
// infrastructure/container.ts
import { InMemoryOrderRepository } from "./persistence/InMemoryOrderRepository";
import { FakePaymentGateway } from "./payments/FakePaymentGateway";
import { ConsoleEventPublisher } from "./events/ConsoleEventPublisher";
import { PlaceOrderUseCase } from "@/core/ordering/application/use-cases/PlaceOrder";

const orderRepository = new InMemoryOrderRepository();
const paymentGateway = new FakePaymentGateway();
const eventPublisher = new ConsoleEventPublisher();

export const placeOrderUseCase = new PlaceOrderUseCase(
  orderRepository,
  paymentGateway,
  eventPublisher
);
```

```ts
// app/actions/place-order.ts
"use server";

import { placeOrderUseCase } from "@/infrastructure/container";

export async function placeOrderAction(orderId: string) {
  const result = await placeOrderUseCase.execute(orderId);
  if (!result.ok) {
    return { error: result.reason };
  }
  return { success: true };
}
```

The Server Action is now a thin translation layer: it takes a framework-shaped input, calls one method on the use case, and returns a framework-shaped output. If Next.js were replaced by Remix, Express, or a CLI tomorrow, only this file and container.ts change. Zero lines in core/ change.

## 7. Why Not a DI Framework Like InversifyJS or tsyringe?

These are free and open-source and valid choices at larger scale. But this series deliberately favors **manual constructor injection with a plain composition root** because:
- Zero magic decorators, zero reflection metadata polyfills, zero framework lock-in on the DI mechanism itself
- The wiring is fully visible and greppable in one file
- It works identically in Server Components, Server Actions, Route Handlers, and standalone scripts
- Cost of Change on the DI approach itself stays near zero — you can always introduce a container library later if wiring complexity grows, without touching core or infrastructure code

This is itself an architectural trade-off worth writing an ADR for — see Part 7.

## 8. Design Exercise

**Step 1:** Define a Port for the Notifications context: `NotificationSender` with a method `send(customerId: string, message: string): Promise<void>`.

**Step 2:** Write two Adapters implementing it: `ConsoleNotificationSender` (for local dev) and a stub `TwilioNotificationSender` (throwing "not implemented" — just the shape).

**Step 3:** Modify `PlaceOrderUseCase` to accept the new port and send a notification after successfully marking the order paid. Update the composition root accordingly.

**Step 4 (the real test):** Without changing anything in core/, swap `ConsoleEventPublisher` for a hypothetical `KafkaEventPublisher` in container.ts only. Confirm in your head (or in a scratch file) that no other file needed to change.

## 9. Solution & Discussion

Step 1-3 mirror the PaymentGateway pattern exactly — that repetition is the point: once the Port/Adapter/Composition-Root pattern is learned once, it applies uniformly to every external capability (payments, notifications, events, persistence), which is exactly why it scales well as a system grows.

Step 4 is the actual architectural payoff, made concrete: swapping infrastructure is a one-file, one-line change specifically because core/ never imported anything from infrastructure/ in the first place. If you find yourself needing to touch core/ to swap an adapter, that's the signal a dependency arrow points the wrong direction, and it should be refactored back through a Port before moving on.

## Up Next

**Part 4 (Data Orchestration)** tackles what happens once Order and StockItem, now living in different aggregates and coordinated only through events, must stay consistent across a real database — including what happens when the "publish an event" step fails halfway through a transaction. That's where the Outbox pattern earns its keep.
