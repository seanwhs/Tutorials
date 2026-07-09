# Appendix C: Stripe Test Card & Test Data Reference

Index: "Stripe Tutorial - INDEX (Start Here)".

All of the following only work in **test mode** — they will be rejected in live mode. Use any future expiry date, any 3-digit CVC (4 digits for Amex), and any postal code unless noted otherwise.

## Basic success

| Card number | Behavior |
|---|---|
| 4242 4242 4242 4242 | Succeeds immediately. This is the card used throughout this tutorial. |
| 4000 0566 5566 5556 | Visa (debit), succeeds immediately. |
| 5555 5555 5555 4444 | Mastercard, succeeds immediately. |
| 3782 822463 10005 | American Express, succeeds immediately (4-digit CVC). |

## Declines (useful for testing your error handling from Part 13)

| Card number | Behavior |
|---|---|
| 4000 0000 0000 0002 | Generic decline. |
| 4000 0000 0000 9995 | Decline: insufficient funds. |
| 4000 0000 0000 9987 | Decline: lost card. |
| 4000 0000 0000 0069 | Decline: expired card. |
| 4000 0000 0000 0127 | Decline: incorrect CVC. |

## 3D Secure / authentication challenges

| Card number | Behavior |
|---|---|
| 4000 0025 0000 3155 | Requires 3D Secure authentication (Stripe Checkout will show a test authentication modal — click "Complete" to simulate a successful challenge). |
| 4000 0027 6000 3184 | 3D Secure required, authentication fails if you click "Fail". |

## Subscriptions-specific test cards (Part 11-12)

| Card number | Behavior |
|---|---|
| 4000 0000 0000 0341 | Attaches successfully but fails on the first subscription renewal charge — useful for testing dunning/failed-renewal flows (mentioned as a Phase 2 idea in Part 15). |

## Test Customer Portal / webhook data

- Any Checkout Session or Subscription created with a test card above automatically appears under **Customers** in your Stripe Dashboard (test mode) — https://dashboard.stripe.com/test/customers.
- Use `stripe trigger checkout.session.completed` (Part 9) to fire a synthetic event when you just need to confirm your webhook route responds 200 without doing a full real checkout — remember this synthetic event has fake/empty line item data.
- Full official list (kept up to date by Stripe): https://docs.stripe.com/testing

## Quick reference: what to type at Stripe Checkout

- **Email:** any address, e.g. `test@example.com`.
- **Card number:** pick from the tables above.
- **Expiry:** any future date, e.g. `12/34`.
- **CVC:** any 3 digits (4 for Amex), e.g. `123`.
- **Name / country / postal code:** any values.

## Next

Continue to **Appendix D: Troubleshooting Guide**.
