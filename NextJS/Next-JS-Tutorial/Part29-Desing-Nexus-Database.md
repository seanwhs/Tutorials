# Next.js 16 for Absolute Beginners

# Part 29 — Database Design: Modeling Real-World Systems with PostgreSQL and Prisma

> **Goal of this lesson:** Design the complete database architecture for Nexus CMS, including users, authentication, content, permissions, analytics, auditing, and performance optimization.

---

# Welcome to Database Engineering

Beginners often think:

```text
Application
    |
Database
```

Professional engineers think:

```text
Business Rules
        |
Data Model
        |
Relationships
        |
Constraints
        |
Indexes
        |
Queries
        |
Application
```

Because databases don't store data.

They store **business rules**.

---

# Why Database Design Matters

Consider these two systems:

### Poor Design

```text
posts

id
title
author
category
tags
comments
```

---

### Good Design

```text
Users
Posts
Categories
Tags
Comments
Permissions
AuditLogs
Notifications
Sessions
Media
Analytics
```

---

# The Rule of Database Design

Ask:

> "What things exist in the business?"

Not:

> "What pages exist in the UI?"

---

# Step 1 — Identify Domain Entities

For Nexus CMS, we have:

```text
User

Session

Post

Category

Tag

Comment

Media

Notification

AuditLog

PageView

Role

Permission
```

---

# Visualizing the Domain

```text
                   User
                     |
       +-------------+-------------+
       |             |             |
       V             V             V
     Posts      Comments    Notifications
       |
       +-------------+
       |             |
       V             V
 Categories        Tags
       |
       V
     Media
```

---

# Step 2 — User Model

Users are central.

Create:

```prisma
enum UserRole {

  USER

  AUTHOR

  EDITOR

  ADMIN

}
```

---

```prisma
model User {

  id String
     @id
     @default(uuid())

  email String
        @unique

  password String

  name String?

  avatar String?

  role UserRole
       @default(USER)

  active Boolean
         @default(true)

  createdAt DateTime
            @default(now())

  updatedAt DateTime
            @updatedAt

  posts Post[]

  comments Comment[]

  sessions Session[]

  notifications Notification[]

}
```

---

# Why Store Roles?

Because permissions change.

Bad:

```ts
if (
  email ===
  "boss@company.com"
)
```

Good:

```ts
if (
  user.role ===
  "ADMIN"
)
```

---

# Step 3 — Session Model

Sessions enable authentication.

```prisma
model Session {

  id String
     @id
     @default(uuid())

  token String
        @unique

  expiresAt DateTime

  createdAt DateTime
            @default(now())

  userId String

  user User
       @relation(
         fields: [userId],
         references: [id]
       )

}
```

---

# Visualizing Authentication

```text
Browser
    |
Cookie
    |
Session
    |
User
```

---

# Step 4 — Post Model

The most important entity.

```prisma
enum PostStatus {

  DRAFT

  REVIEW

  PUBLISHED

  ARCHIVED

}
```

---

```prisma
model Post {

  id String
     @id
     @default(uuid())

  slug String
       @unique

  title String

  excerpt String?

  content Json

  status PostStatus
         @default(DRAFT)

  publishedAt DateTime?

  createdAt DateTime
            @default(now())

  updatedAt DateTime
            @updatedAt

  authorId String

  author User
         @relation(
           fields: [authorId],
           references: [id]
         )

  categories PostCategory[]

  tags PostTag[]

  comments Comment[]

  media Media[]

}
```

---

# Why Use JSON?

Because rich text is hierarchical.

Example:

```json
{
  "type": "document",
  "children": [
    {
      "type": "heading",
      "text": "Hello"
    }
  ]
}
```

---

# Step 5 — Categories

A post can have multiple categories.

```prisma
model Category {

  id String
     @id
     @default(uuid())

  name String
       @unique

  slug String
       @unique

  posts PostCategory[]

}
```

---

# Join Table

```prisma
model PostCategory {

  postId String

  categoryId String

  post Post
       @relation(
         fields: [postId],
         references: [id]
       )

  category Category
           @relation(
             fields: [categoryId],
             references: [id]
           )

  @@id([postId, categoryId])

}
```

---

# Visualizing Categories

```text
Posts
   |
Many-to-many
   |
Categories
```

---

# Step 6 — Tags

Tags behave similarly.

```prisma
model Tag {

  id String
     @id
     @default(uuid())

  name String
       @unique

  slug String
       @unique

  posts PostTag[]

}
```

---

```prisma
model PostTag {

  postId String

  tagId String

  post Post
       @relation(
         fields:[postId],
         references:[id]
       )

  tag Tag
      @relation(
        fields:[tagId],
        references:[id]
      )

  @@id([postId, tagId])

}
```

---

# Why Explicit Join Tables?

Because someday you'll need:

```text
Added By

Added Date

Tag Weight
```

---

# Step 7 — Comments

```prisma
model Comment {

  id String
     @id
     @default(uuid())

  content String

  approved Boolean
           @default(false)

  createdAt DateTime
            @default(now())

  postId String

  authorId String

  post Post
       @relation(
         fields:[postId],
         references:[id]
       )

  author User
         @relation(
           fields:[authorId],
           references:[id]
         )

}
```

---

# Comment Workflow

```text
User
   |
Comment
   |
Moderation
   |
Published
```

---

# Step 8 — Media

```prisma
model Media {

  id String
     @id
     @default(uuid())

  filename String

  mimeType String

  size Int

  width Int?

  height Int?

  url String

  createdAt DateTime
            @default(now())

  postId String?

  post Post?
       @relation(
         fields:[postId],
         references:[id]
       )

}
```

---

# Visualizing Media

```text
Storage
    |
Metadata
    |
Database
```

---

# Step 9 — Notifications

```prisma
model Notification {

  id String
     @id
     @default(uuid())

  title String

  body String

  read Boolean
       @default(false)

  createdAt DateTime
            @default(now())

  userId String

  user User
       @relation(
         fields:[userId],
         references:[id]
       )

}
```

---

# Step 10 — Analytics

```prisma
model PageView {

  id String
     @id
     @default(uuid())

  path String

  ip String?

  country String?

  userAgent String?

  createdAt DateTime
            @default(now())

}
```

---

# Step 11 — Audit Logs

Professionals audit everything.

```prisma
model AuditLog {

  id String
     @id
     @default(uuid())

  action String

  entity String

  entityId String

  payload Json?

  createdAt DateTime
            @default(now())

  userId String?

}
```

---

# Example Audit Event

```json
{
  "action": "DELETE_POST",
  "entity": "Post",
  "entityId": "abc123"
}
```

---

# Why Audit Logs?

Because someday someone asks:

```text
Who deleted this post?
```

---

# Step 12 — Database Indexes

Indexes make reads fast.

Example:

```prisma
model Post {

  id String @id

  slug String @unique

  status PostStatus

  publishedAt DateTime?

  @@index([status])

  @@index([publishedAt])

}
```

---

# Visualizing Indexes

Without index:

```text
Search:
100000 rows
```

With index:

```text
Search:
10 rows
```

---

# Composite Indexes

Example:

```prisma
@@index([
  status,
  publishedAt
])
```

---

# Why?

Query:

```sql
SELECT *
FROM posts
WHERE status='PUBLISHED'
ORDER BY publishedAt;
```

becomes very fast.

---

# Step 13 — Cascading Deletes

Suppose:

```text
Delete User
```

Question:

```text
Delete Posts?
Delete Comments?
Delete Sessions?
```

---

# Example

```prisma
@relation(
  onDelete: Cascade
)
```

---

# But Be Careful

```text
Cascade
      |
Delete Everything
```

Sometimes dangerous.

---

# Step 14 — Database Constraints

Example:

```prisma
email String
      @unique
```

---

Prevents:

```text
Duplicate accounts.
```

---

Another example:

```prisma
slug String
     @unique
```

Prevents:

```text
Duplicate URLs.
```

---

# Step 15 — Final Schema Diagram

```text
                   User
                     |
     +---------------+----------------+
     |               |                |
     V               V                V
 Sessions        Posts         Notifications
                     |
          +----------+----------+
          |                     |
          V                     V
     Categories             Tags
          |
          V
      Comments
          |
          V
        Media

AuditLogs

PageViews
```

---

# Database Philosophy

Beginners ask:

```text
What tables do I need?
```

Professionals ask:

```text
What business rules
must the database enforce?
```

---

# Our Database Guarantees

```text
✓ Unique users

✓ Unique slugs

✓ Role permissions

✓ Audit history

✓ Referential integrity

✓ Fast lookups

✓ Data consistency
```

---

# Generate Migration

```bash
npx prisma migrate dev \
--name complete_schema
```

---

# Open Database Studio

```bash
npx prisma studio
```

---

# Verify Tables

```text
✓ User
✓ Session
✓ Post
✓ Category
✓ Tag
✓ PostCategory
✓ PostTag
✓ Comment
✓ Media
✓ Notification
✓ AuditLog
✓ PageView
```

---

# Exercises

## Exercise 1

Add:

```text
Bookmark
```

table.

---

## Exercise 2

Add:

```text
Likes
```

system.

---

## Exercise 3

Add:

```text
Team organizations
```

support.

---

## Exercise 4

Draw the ER diagram.

---

# What You've Learned

You now understand:

✅ entity modeling

✅ relationships

✅ one-to-many

✅ many-to-many

✅ join tables

✅ indexes

✅ constraints

✅ audit logs

✅ analytics

✅ cascading deletes

---

# Mental Model

Beginners think:

```text
Database
    =
Storage
```

Professional engineers think:

```text
Database
    =
Business Rules
      +
Integrity
      +
Performance
      +
History
```

Because databases don't merely store data.

They protect reality.

---

# Part 30 Preview

In the next chapter we'll implement:

# Authentication and Authorization

Including:

```text
✓ Password hashing
✓ Sessions
✓ Cookies
✓ Login
✓ Logout
✓ Registration
✓ Middleware
✓ Route protection
✓ Roles
✓ Permissions
✓ Admin access
✓ Security hardening
```

This is where software engineering becomes security engineering.
