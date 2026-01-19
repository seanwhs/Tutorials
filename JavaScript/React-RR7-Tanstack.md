# **Production-Grade React Architecture: Integrated Tutorial**

This guide teaches **enterprise-grade frontend architecture** using **React, React Router 7 (RR7), and TanStack Query (TSQ)**. By the end, you’ll have a **User Management Application** that is:

* Fast, deterministic, and free of unnecessary loading spinners
* Architected for scalability and correctness
* Fully integrated with router-driven data orchestration, permissions, and error boundaries

We cover **core principles, setup, routing, caching, mutations, optimistic updates, nested routes, permissions, and error containment**, all in a single linear tutorial.

---

## **1️⃣ Core Principles**

* **UI = f(State)**
* **State = f(Navigation)**
* **Navigation orchestrates data**
* Router + Cache = Source of Truth
* Components = Pure Rendering

**Mental Model:**

```
User Intent (URL)
   ↓
Router → Loader → Cache → React Component
```

> Components never fetch server data directly; they only render what's guaranteed to exist in cache.

---

## **2️⃣ Setup**

```bash
npm create vite@latest rr7-tsq-app -- --template react-ts
cd rr7-tsq-app
npm install react-router-dom@latest @tanstack/react-query@latest
```

**Project Structure:**

```
src/
├── lib/queryClient.ts
├── features/users/{types,queries,mutations}
├── features/auth/{permissions,queries}
├── routes/{loaders,actions,ErrorBoundary,Pages...}
└── main.tsx
```

> Features define **data contracts**, routes orchestrate **lifecycle**, components **render only**.

---

## **3️⃣ QueryClient: Single Source of Truth**

```ts
import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,      // 5 minutes
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});
```

---

## **4️⃣ Query Contracts**

```ts
// types.ts
export interface User {
  id: string;
  name: string;
  email: string;
}

// queries.ts
export const userQuery = (id: string) => ({
  queryKey: ['users', id] as const,
  queryFn: async () => fetch(`/api/users/${id}`).then(r => r.json()),
});
```

> Keys must match between **loaders** and **components** to prevent cache duplication.

---

## **5️⃣ Loaders & Pre-Warm Strategy**

```ts
export const createUserLoader = (queryClient: QueryClient) => async ({ params }) =>
  queryClient.ensureQueryData(userQuery(params.userId!));
```

**Loader → Component Flow:**

```
User clicks /users/42
   ↓
Router matches route
   ↓
Loader executes
   ↓
Cache ensured
   ↓
Component renders
```

---

## **6️⃣ Router Setup**

```tsx
const router = createBrowserRouter([
  { path: '/', element: <UserListPage />, errorElement: <ErrorBoundary /> },
  {
    path: '/users/:userId',
    loader: createUserLoader(queryClient),
    element: <UserDetailPage />,
    errorElement: <ErrorBoundary />,
  },
]);
```

**Lifecycle ASCII:**

```
User click
   ↓
Router matches
   ↓
Loader runs → ensureQueryData
   ↓
Cache updated
   ↓
Component renders
```

---

## **7️⃣ Synchronous Rendering**

```tsx
const { data: user } = useQuery(userQuery(userId!));
return <>{user.name}</>;
```

> No spinners, effects, or conditional rendering required — loader guarantees data.

---

## **8️⃣ Optimistic Mutations**

```ts
const previousUser = queryClient.getQueryData(['users', userId]);
queryClient.setQueryData(['users', userId], { ...previousUser, ...updates });

try {
  await updateUser(userId, updates);
} catch {
  queryClient.setQueryData(['users', userId], previousUser); // rollback
}

queryClient.invalidateQueries(['users']);
```

**Optimistic UI Flow:**

```
Form submit
   ↓
Snapshot cache
   ↓
Optimistic update
   ↓
Server mutation
   ↓
Success → cache valid
Fail → rollback
   ↓
Re-render components
```

---

## **9️⃣ Nested Parallel Loaders**

```
/users/:userId
 ├─ UserProfileLoader
 ├─ UserActivityLoader
 └─ UserPermissionsLoader
```

```
Parent Loader
  |--> Child A Loader
  |--> Child B Loader
  |--> Child C Loader
Render children when ready
```

> No waterfall; independent datasets load simultaneously.

---

## **🔟 Auth & Permissions**

```
Route → Auth Loader → Permission Loader → Render if allowed
```

Unauthorized users are **never shown the route**.

---

## **1️⃣1️⃣ Error Boundaries per Route Depth**

```
RootError
  └─ UsersError
       └─ UserNotFound
            └─ ActivityError
```

> Errors bubble **only to their boundary**, leaving the rest of the UI functional.

---

## **1️⃣2️⃣ Failure Modes**

| Violation                        | Symptom                    |
| -------------------------------- | -------------------------- |
| Component fetches directly       | Spinners, double fetch     |
| Mismatched query keys            | Cache misses, stale UI     |
| Mutations outside router actions | Navigation desync          |
| Auth checks in components        | Flash of protected content |
| Global-only error boundary       | Entire app crashes         |

---

## ✅ **Final Mental Model**

```
URL
 ↓
Router (Lifecycle)
 ↓
Loaders (Orchestration)
 ↓
TanStack Cache (Source-of-Truth)
 ↓
React Components (Pure Rendering)
```

> Once internalized, this architecture allows **predictable, maintainable, and high-performance applications**.

