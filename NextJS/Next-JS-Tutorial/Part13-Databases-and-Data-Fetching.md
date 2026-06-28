# Next.js 16 for Absolute Beginners

# Part 13 — Databases and Data Fetching: Building Real Applications

> **Goal of this lesson:** Learn how real Next.js applications store and retrieve data using databases, understand where database code belongs, and build a professional data access layer.

---

# Up Until Now We've Been Cheating

Most of our examples looked like this:

```tsx
const posts = [
    {
        id: 1,
        title: "Hello",
    },
];
```

Or:

```tsx
await fetch(
    "https://jsonplaceholder.typicode.com/posts"
);
```

These are useful for learning.

But real applications use databases.

Examples:

```text
Instagram
    ↓
Database

Netflix
    ↓
Database

Amazon
    ↓
Database

GitHub
    ↓
Database
```

---

# What Is a Database?

A database is simply:

```text
A system that stores data.
```

Example:

```text
Users
Posts
Comments
Orders
Products
Invoices
```

---

# Visualizing a Database

```text
Database
    |
    +--- Users
    |
    +--- Posts
    |
    +--- Comments
```

---

# The Most Common Database for Next.js

The most common stack today is:

```text
Next.js
    +
PostgreSQL
    +
Prisma
```

Why?

Because:

* PostgreSQL is powerful
* Prisma is beginner friendly
* Both work extremely well with Next.js

---

# Installing Prisma

Create a project:

```bash
npm install prisma @prisma/client
```

Initialize:

```bash
npx prisma init
```

This creates:

```text
prisma/

    schema.prisma

.env
```

---

# Understanding schema.prisma

Open:

```text
prisma/schema.prisma
```

Example:

```prisma
generator client {
    provider =
        "prisma-client-js"
}

datasource db {
    provider =
        "postgresql"

    url =
        env("DATABASE_URL")
}
```

---

# Creating Our First Table

Let's create users.

```prisma
model User {

    id Int
        @id
        @default(autoincrement())

    name String

    email String
        @unique

    createdAt DateTime
        @default(now())

}
```

---

# Visualizing the Table

```text
User

+----+------+-------+
| id | name | email |
+----+------+-------+
| 1  | Sean | x@y   |
| 2  | John | z@y   |
+----+------+-------+
```

---

# Creating Posts

```prisma
model Post {

    id Int
        @id
        @default(autoincrement())

    title String

    body String

    published Boolean
        @default(false)

    createdAt DateTime
        @default(now())

}
```

---

# Running Database Migration

Create tables:

```bash
npx prisma migrate dev
```

This generates:

```text
SQL
      ↓
Database Tables
```

---

# Generating the Prisma Client

Run:

```bash
npx prisma generate
```

Now we get:

```text
Type-safe
database API
```

---

# Creating a Database Client

Create:

```text
lib/db.ts
```

```tsx
import {
    PrismaClient
} from "@prisma/client";

export const db =
    new PrismaClient();
```

---

# Our First Query

```tsx
import { db }
    from "@/lib/db";

const users =
    await db.user.findMany();
```

---

# Visualizing a Query

```text
Next.js
     |
     V

Prisma
     |
     V

PostgreSQL
     |
     V

Rows
```

---

# Finding One User

Example:

```tsx
const user =
    await db.user.findUnique({

        where: {
            id: 1,
        },

    });
```

Result:

```json
{
    "id":1,
    "name":"Sean",
    "email":"test@test.com"
}
```

---

# Creating Data

Example:

```tsx
await db.user.create({

    data: {

        name:
            "Sean",

        email:
            "test@test.com",

    },

});
```

---

# Updating Data

Example:

```tsx
await db.user.update({

    where: {
        id: 1,
    },

    data: {
        name:
            "Sean Wong",
    },

});
```

---

# Deleting Data

Example:

```tsx
await db.user.delete({

    where: {
        id: 1,
    },

});
```

---

# CRUD Operations

Every application eventually becomes:

```text
Create
Read
Update
Delete
```

Or:

```text
CRUD
```

---

# Where Should Database Code Go?

Beginners often do this:

```tsx
export default async function Page() {

    const users =
        await db.user.findMany();

    return (
        <div>
            {users.length}
        </div>
    );
}
```

This works.

But it doesn't scale.

---

# The Professional Pattern

Create:

```text
lib/

    users.ts

    posts.ts

    comments.ts
```

---

# Example User Repository

Create:

```text
lib/users.ts
```

```tsx
import { db }
    from "./db";

export async function getUsers() {

    return db.user.findMany();

}
```

---

# Then Use It

```tsx
import {
    getUsers
} from "@/lib/users";

export default async function Page() {

    const users =
        await getUsers();

    return (
        <div>
            {users.length}
        </div>
    );
}
```

---

# Why Is This Better?

Bad:

```text
Page
   |
Database
```

Good:

```text
Page
   |
Repository
   |
Database
```

---

# Visualizing the Architecture

```text
React Component
        |
        V

Data Layer
        |
        V

Database
```

---

# Adding Cache Components

Remember Next.js 16 caching?

Example:

```tsx
import {
    cacheLife,
    cacheTag,
} from "next/cache";

import { db }
    from "./db";

export async function getUsers() {

    "use cache";

    cacheLife("hours");

    cacheTag("users");

    return db.user.findMany();

}
```

---

# Now Our Architecture Looks Like This

```text
React
    |
Cached Data Layer
    |
Database
```

This is the preferred Next.js 16 architecture.

---

# Parallel Data Fetching

Bad:

```tsx
const users =
    await getUsers();

const posts =
    await getPosts();

const comments =
    await getComments();
```

Visualized:

```text
Users
     ↓
Posts
     ↓
Comments
```

---

# Better

```tsx
const [
    users,
    posts,
    comments,
] = await Promise.all([
    getUsers(),
    getPosts(),
    getComments(),
]);
```

Visualized:

```text
Users ----+
          |
Posts ----+---- Execute Together
          |
Comments -+
```

Always fetch independent data in parallel.

---

# Database Relationships

Real databases contain relationships.

Example:

```text
User
   |
   +---- Posts
```

---

# Prisma Relationship Example

```prisma
model User {

    id Int
        @id
        @default(autoincrement())

    name String

    posts Post[]

}
```

---

```prisma
model Post {

    id Int
        @id
        @default(autoincrement())

    title String

    userId Int

    user User
        @relation(
            fields: [userId],
            references: [id]
        )

}
```

---

# Visualizing Relationships

```text
User
   |
   +--- Post
   |
   +--- Post
   |
   +--- Post
```

---

# Loading Related Data

Example:

```tsx
const users =
    await db.user.findMany({

        include: {
            posts: true,
        },

    });
```

Result:

```json
[
    {
        "id":1,
        "name":"Sean",
        "posts":[
            {},
            {}
        ]
    }
]
```

---

# Transactions

Suppose:

```text
Transfer Money
```

Steps:

```text
Subtract Account A
Add Account B
```

If step two fails:

```text
Money disappears.
```

Bad.

---

# Transactions Fix This

Example:

```tsx
await db.$transaction([

    db.account.update({
        where: {
            id: 1,
        },
        data: {
            balance: {
                decrement: 100,
            },
        },
    }),

    db.account.update({
        where: {
            id: 2,
        },
        data: {
            balance: {
                increment: 100,
            },
        },
    }),

]);
```

---

# Visualizing Transactions

```text
Operation A
      |
Operation B
      |
      +--- Success
      |
      +--- Rollback
```

Everything succeeds.

Or nothing succeeds.

---

# Server Actions + Database

This is where Next.js becomes powerful.

Example:

```tsx
"use server";

import { db }
    from "@/lib/db";

import {
    revalidateTag
} from "next/cache";

export async function createPost(
    formData: FormData
) {

    await db.post.create({

        data: {

            title:
                String(
                    formData.get(
                        "title"
                    )
                ),

        },

    });

    revalidateTag(
        "posts"
    );
}
```

---

# Visualizing Full Stack Next.js

```text
Browser
     |
Server Action
     |
Database
     |
Cache Invalidated
     |
Fresh UI
```

No REST API.

No GraphQL.

No JSON serialization.

---

# Error Handling

Never do:

```tsx
await db.user.create();
```

without protection.

Instead:

```tsx
try {

    await db.user.create({
        data: user,
    });

} catch (error) {

    console.error(
        error
    );

}
```

---

# Production Folder Structure

```text
app/

    actions/

components/

lib/

    db.ts

    users.ts
    posts.ts
    comments.ts

prisma/

    schema.prisma
```

---

# The Repository Pattern

Large applications often use:

```text
Repository
```

Example:

```tsx
export class UserRepository {

    async getAll() {
        return db.user.findMany();
    }

    async getById(id: number) {
        return db.user.findUnique({
            where: { id },
        });
    }

    async create(data: any) {
        return db.user.create({
            data,
        });
    }

}
```

---

# Visualizing Enterprise Architecture

```text
React
    |
Server Actions
    |
Repositories
    |
Database
```

---

# The Professional Rule

Never let:

```text
UI
```

talk directly to:

```text
Database
```

Always insert:

```text
A data layer
```

between them.

---

# Exercises

## Exercise 1

Create:

```prisma
User
```

with:

```text
id
name
email
createdAt
```

---

## Exercise 2

Create:

```prisma
Post
```

with:

```text
title
body
published
```

---

## Exercise 3

Create:

```text
lib/posts.ts
```

containing:

```tsx
getPosts()
createPost()
deletePost()
```

---

## Exercise 4

Add:

```tsx
"use cache";
cacheLife("hours");
cacheTag("posts");
```

to:

```tsx
getPosts()
```

---

# What You've Learned

You now understand:

✅ databases

✅ PostgreSQL

✅ Prisma

✅ CRUD operations

✅ repository pattern

✅ relationships

✅ transactions

✅ cached data layers

✅ professional application architecture

---

# Mental Model

Stop thinking:

```text
Pages
     |
Database
```

Start thinking:

```text
Pages
     |
Components
     |
Server Actions
     |
Repositories
     |
Database
```

This layered architecture is the foundation of nearly every professional Next.js application.

---

# Part 14 Preview

In the next chapter we'll learn:

# Authentication and Authorization

Including:

* login systems
* sessions
* cookies
* JWTs
* authentication providers
* protecting routes
* middleware
* role-based access control (RBAC)
* building a complete authentication system

This is where our applications become multi-user systems.
