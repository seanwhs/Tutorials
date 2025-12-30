# **Full-Stack Starter Template (Node Edition)**

---

## **1. Project Structure Overview**

```
fullstack-app/
├── backend/
│   ├── src/
│   │   ├── controllers/
│   │   │   └── userController.ts
│   │   ├── services/
│   │   │   └── userService.ts
│   │   ├── repositories/
│   │   │   └── userRepository.ts
│   │   ├── models/
│   │   │   └── userModel.ts
│   │   ├── routes/
│   │   │   └── userRoutes.ts
│   │   ├── app.ts
│   │   └── server.ts
│   ├── package.json
│   └── tsconfig.json
├── web/
│   ├── src/
│   │   ├── components/
│   │   │   └── UserList.tsx
│   │   ├── context/
│   │   │   └── UserContext.tsx
│   │   ├── hooks/
│   │   │   └── useUserService.ts
│   │   ├── services/
│   │   │   └── userService.ts
│   │   ├── App.tsx
│   │   └── index.tsx
│   ├── package.json
│   └── tsconfig.json
├── mobile/
│   ├── src/
│   │   ├── components/
│   │   │   └── UserList.tsx
│   │   ├── context/
│   │   │   └── UserContext.tsx
│   │   ├── hooks/
│   │   │   └── useUserService.ts
│   │   ├── services/
│   │   │   └── userService.ts
│   │   └── App.tsx
│   ├── package.json
│   └── tsconfig.json
└── README.md
```

---

## **2. Backend (Node.js + Express + TS + Prisma)**

### **2.1 Install Dependencies**

```bash
cd backend
npm init -y
npm install express prisma @prisma/client cors body-parser
npm install -D typescript ts-node nodemon @types/node @types/express
npx prisma init
```

### **2.2 Prisma User Model**

`backend/prisma/schema.prisma`

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id    Int     @id @default(autoincrement())
  name  String
  email String  @unique
}
```

Run migration:

```bash
npx prisma migrate dev --name init
```

---

### **2.3 Repository Layer**

`backend/src/repositories/userRepository.ts`

```ts
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

export class UserRepository {
  async getAll() {
    return prisma.user.findMany();
  }

  async getById(id: number) {
    return prisma.user.findUnique({ where: { id } });
  }

  async create(data: { name: string; email: string }) {
    return prisma.user.create({ data });
  }

  async update(id: number, data: { name?: string; email?: string }) {
    return prisma.user.update({ where: { id }, data });
  }

  async delete(id: number) {
    return prisma.user.delete({ where: { id } });
  }
}
```

---

### **2.4 Service Layer (Facade / Adapter)**

`backend/src/services/userService.ts`

```ts
import { UserRepository } from "../repositories/userRepository";

export class UserService {
  private repo = new UserRepository();

  async listUsers() {
    return this.repo.getAll();
  }

  async getUser(id: number) {
    return this.repo.getById(id);
  }

  async createUser(name: string, email: string) {
    return this.repo.create({ name, email });
  }

  async updateUser(id: number, data: { name?: string; email?: string }) {
    return this.repo.update(id, data);
  }

  async deleteUser(id: number) {
    return this.repo.delete(id);
  }
}
```

---

### **2.5 Controller Layer**

`backend/src/controllers/userController.ts`

```ts
import { Request, Response } from "express";
import { UserService } from "../services/userService";

const service = new UserService();

export const getAllUsers = async (_req: Request, res: Response) => {
  const users = await service.listUsers();
  res.json(users);
};

export const getUserById = async (req: Request, res: Response) => {
  const user = await service.getUser(Number(req.params.id));
  res.json(user);
};

export const createUser = async (req: Request, res: Response) => {
  const { name, email } = req.body;
  const newUser = await service.createUser(name, email);
  res.json(newUser);
};

export const updateUser = async (req: Request, res: Response) => {
  const { id } = req.params;
  const data = req.body;
  const updated = await service.updateUser(Number(id), data);
  res.json(updated);
};

export const deleteUser = async (req: Request, res: Response) => {
  const { id } = req.params;
  await service.deleteUser(Number(id));
  res.json({ message: "Deleted" });
};
```

---

### **2.6 Routes**

`backend/src/routes/userRoutes.ts`

```ts
import { Router } from "express";
import {
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
} from "../controllers/userController";

const router = Router();

router.get("/", getAllUsers);
router.get("/:id", getUserById);
router.post("/", createUser);
router.put("/:id", updateUser);
router.delete("/:id", deleteUser);

export default router;
```

---

### **2.7 App Setup**

`backend/src/app.ts`

```ts
import express from "express";
import cors from "cors";
import bodyParser from "body-parser";
import userRoutes from "./routes/userRoutes";

const app = express();
app.use(cors());
app.use(bodyParser.json());

app.use("/api/users", userRoutes);

export default app;
```

`backend/src/server.ts`

```ts
import app from "./app";

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Backend server running on port ${PORT}`);
});
```

---

## **3. Web Frontend (React + TS)**

### **3.1 Service Layer (Adapter)**

`web/src/services/userService.ts`

```ts
const API_URL = "http://localhost:5000/api/users";

export const getUsers = async () => {
  const res = await fetch(API_URL);
  return res.json();
};

export const createUser = async (name: string, email: string) => {
  const res = await fetch(API_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name, email }),
  });
  return res.json();
};
```

---

### **3.2 Hook**

`web/src/hooks/useUserService.ts`

```ts
import { useEffect, useState } from "react";
import { getUsers } from "../services/userService";

export const useUserService = () => {
  const [users, setUsers] = useState<any[]>([]);

  const fetchUsers = async () => {
    const data = await getUsers();
    setUsers(data);
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  return { users, fetchUsers };
};
```

---

### **3.3 Component Example**

`web/src/components/UserList.tsx`

```tsx
import React from "react";
import { useUserService } from "../hooks/useUserService";

export const UserList: React.FC = () => {
  const { users } = useUserService();

  return (
    <div>
      <h2>User List</h2>
      <ul>
        {users.map((u) => (
          <li key={u.id}>
            {u.name} ({u.email})
          </li>
        ))}
      </ul>
    </div>
  );
};
```

---

### **3.4 App.tsx**

```tsx
import React from "react";
import { UserList } from "./components/UserList";

function App() {
  return (
    <div>
      <h1>Fullstack App Web</h1>
      <UserList />
    </div>
  );
}

export default App;
```

---

## **4. Mobile Frontend (React Native + TS)**

Use the **same service layer and hook structure** as Web.

`mobile/src/components/UserList.tsx` example:

```tsx
import React from "react";
import { View, Text, FlatList } from "react-native";
import { useUserService } from "../hooks/useUserService";

export const UserList = () => {
  const { users } = useUserService();

  return (
    <View style={{ padding: 20 }}>
      <Text style={{ fontSize: 24 }}>Users</Text>
      <FlatList
        data={users}
        keyExtractor={(item) => item.id.toString()}
        renderItem={({ item }) => (
          <Text>
            {item.name} ({item.email})
          </Text>
        )}
      />
    </View>
  );
};
```

---

### ✅ **Key Features**

* **Backend:** Full CRUD with layered architecture (Controller → Service → Repository → Database)
* **Web Frontend:** React + TypeScript, service adapter pattern, hooks for state
* **Mobile Frontend:** React Native + TypeScript, shared services/hooks
* **Design Patterns:** Adapter, Facade, Observer (hooks), Repository
* **Cross-platform:** Shared logic for API communication


