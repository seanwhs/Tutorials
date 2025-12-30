# ⚡ TypeScript Architecture & Design Patterns Tutorial

---

## **1. Introduction**

TypeScript is **JavaScript with strong typing**, offering:

* **Static type-checking** → Avoid runtime errors.
* **Interfaces & Types** → Define clear contracts.
* **OOP Support** → Classes, inheritance, abstract classes.
* **Enhanced IDE Experience** → Autocomplete, refactoring, inline docs.

**Why TypeScript Architecture Matters:**

* Scalability – clean separation of concerns.
* Maintainability – strongly-typed contracts between modules.
* Reusability – consistent patterns across codebase.
* Safety – catch errors at compile-time.

---

### **1.1 Core Principles of Architecture**

1. **Layered Architecture:** Separate **presentation**, **business logic**, **data access**, and **infrastructure**.
2. **Modularity:** Independent modules for features or services.
3. **Dependency Inversion:** High-level modules should not depend on low-level modules; depend on abstractions.
4. **Single Responsibility:** Each class/module does **one thing well**.
5. **DRY:** Avoid repeating logic; reuse via services, utilities, and patterns.

---

## **2. TypeScript Frontend Architecture (React Example)**

### **2.1 Core Concepts**

* **Components:** Functional or Class-based React components.
* **Props & State:** Typed interfaces for props & state.
* **Hooks:** `useState<T>()`, `useReducer<T>()`, `useEffect()`.
* **Context / Redux:** Global state management.
* **Service Layer:** API calls wrapped in strongly typed functions.
* **Utility / Helper Layer:** Pure functions for reusable logic.

---

### **2.2 Recommended Project Structure**

```
my-app/
├── public/
├── src/
│   ├── components/
│   │   ├── BookList.tsx
│   │   ├── BookForm.tsx
│   │   └── Header.tsx
│   ├── context/
│   │   └── AppContext.tsx
│   ├── hooks/
│   │   └── useFetch.ts
│   ├── services/
│   │   └── apiService.ts
│   ├── utils/
│   │   └── dateUtils.ts
│   ├── App.tsx
│   └── index.tsx
└── package.json
```

---

### **2.3 TypeScript Patterns in Frontend**

| Pattern              | Usage / Example                                           |
| -------------------- | --------------------------------------------------------- |
| **Observer**         | EventEmitter for cross-component updates                  |
| **Adapter / Facade** | Wrap API calls with typed interfaces                      |
| **Strategy**         | Select algorithm dynamically (e.g., sort/filter strategy) |
| **Singleton**        | Single instance of context provider or service            |
| **Factory**          | Dynamic creation of components/services                   |
| **Command / Action** | Encapsulate state updates as objects for undo/redo        |

---

### **2.4 Example: Typed API Service**

```ts
// services/apiService.ts
import axios from 'axios';

export interface Book {
  id: number;
  title: string;
  author: string;
  publishedDate: string;
}

const API_URL = 'http://localhost:8000/api/books/';

export const getBooks = async (): Promise<Book[]> => {
  const response = await axios.get<Book[]>(API_URL);
  return response.data;
};

export const createBook = async (book: Omit<Book, 'id'>): Promise<Book> => {
  const response = await axios.post<Book>(API_URL, book);
  return response.data;
};
```

---

## **3. Backend Layer: Node.js + TypeScript**

### **3.1 Recommended Structure**

```
backend/
├── src/
│   ├── controllers/
│   │   └── bookController.ts
│   ├── models/
│   │   └── book.ts
│   ├── routes/
│   │   └── bookRoutes.ts
│   ├── services/
│   │   └── bookService.ts
│   ├── utils/
│   │   └── errorHandler.ts
│   ├── app.ts
│   └── server.ts
└── package.json
```

---

### **3.2 Layered Architecture**

```
+---------------------+
| Controllers         | <- HTTP request handling
+---------------------+
| Services            | <- Business logic
+---------------------+
| Models / Repositories | <- DB abstraction (ORM / raw queries)
+---------------------+
| Database            | <- PostgreSQL / MongoDB / MySQL
+---------------------+
| Utilities           | <- Error handling, logging, helpers
+---------------------+
```

---

### **3.3 Patterns in Backend**

| Layer      | Pattern / Concept          | Example                      |
| ---------- | -------------------------- | ---------------------------- |
| Controller | Command / Template Method  | Encapsulate HTTP actions     |
| Service    | Facade / Strategy          | Business logic orchestration |
| Model      | Active Record / Repository | ORM model methods            |
| Database   | Singleton                  | DB connection pool           |
| Utilities  | Observer / Decorator       | Logging, validation          |

---

### **3.4 Example: Service + Controller**

**BookService.ts**

```ts
import { Book } from '../models/book';

export class BookService {
  private books: Book[] = [];

  getAll(): Book[] {
    return this.books;
  }

  create(book: Book): Book {
    this.books.push(book);
    return book;
  }
}
```

**BookController.ts**

```ts
import { Request, Response } from 'express';
import { BookService } from '../services/bookService';

const bookService = new BookService();

export const getBooks = (req: Request, res: Response) => {
  res.json(bookService.getAll());
};

export const createBook = (req: Request, res: Response) => {
  const book = bookService.create(req.body);
  res.status(201).json(book);
};
```

---

## **4. Full-Stack Flow**

**Frontend ↔ Backend ↔ DB:**

```
React Component
    |
Service / Adapter Layer
    |
Typed API Call (Axios)
    |
Express / Controller (Node TS)
    |
Service Layer / Business Logic
    |
Repository / Model (ORM)
    |
Database (Postgres / Mongo)
```

---

## **5. Advanced TypeScript Patterns**

1. **Singleton:** One instance of Logger, DB connection, or Service.
2. **Observer:** Event-driven updates for UI or backend notifications.
3. **Factory:** Dynamic creation of services or components.
4. **Strategy:** Swappable algorithms for sorting/filtering/validation.
5. **Facade / Adapter:** Wrap complex APIs or DB calls.
6. **Command:** Encapsulate actions for undo/redo.
7. **Decorator:** Add logging, caching, or validation dynamically.

---

### **5.1 Example: Singleton Logger**

```ts
export class Logger {
  private static instance: Logger;
  private constructor() {}

  static getInstance() {
    if (!Logger.instance) Logger.instance = new Logger();
    return Logger.instance;
  }

  log(message: string) {
    console.log(`[LOG]: ${message}`);
  }
}

// Usage
const logger = Logger.getInstance();
logger.log('Server started');
```

---

## **6. Best Practices**

* Always type **props, state, responses, and requests**.
* Use **services** for business logic, not controllers/components.
* Use **interfaces** and **types** for contracts.
* Organize **layered architecture**: Controller → Service → Model → DB.
* Apply **design patterns** to reduce boilerplate and increase scalability.
* Keep **frontend and backend decoupled** through typed API contracts.

---

## **7. Summary Mind Map**

```
User / Client
    |
React Component Layer (Typed Props/State)
    |
Service Layer / Adapter (Typed API Calls)
    |
Backend Controller (Command / Template)
    |
Backend Service Layer (Facade / Strategy)
    |
Repository / Model (ORM / Repository)
    |
Database
```

---

This **TypeScript architecture tutorial** integrates:

* **Frontend with React + TS**
* **Backend with Node.js + Express + TS**
* **Full-stack layered flow**
* **Core design patterns** (Singleton, Observer, Factory, Strategy, Adapter, Command, Decorator)

---
