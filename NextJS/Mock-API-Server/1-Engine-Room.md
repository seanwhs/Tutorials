Welcome to Part 1. Every great API starts with a solid foundation. In this phase, we are going to set up our Node environment, define our database schema, and get our core REST engine running.

By the end of this step, you will have a fully functional CRUD (Create, Read, Update, Delete) API without having written a single SQL query or database controller.

Here is how we build the engine room.

1. **Initialize the Workspace:**
First, we need to create our project directory and set up a new Node.js environment. Open your terminal and run the following commands:

```bash
mkdir greymatter-api
cd greymatter-api
npm init -y

```

This creates a `package.json` file with default settings, giving us a clean slate to install our dependencies.


2. **Install Dependencies:** Version precision is critical here.
We need three core packages to run our server. Run this command:

```bash
npm install express cors json-server@0.17.4

```

> **Key insight:** Why `json-server@0.17.4` instead of the latest v1.0 release? The 0.17.x branch exposes its underlying `lowdb` database instance. We will need direct access to that database object in Part 2 when we write custom middleware for complex filtering.


3. **Create the Database:** The data source.
`json-server` works by reading a JSON file and automatically generating REST endpoints based on the top-level keys.

Create a file named `db.json` in the root of your project and paste in this starter data:

```json
{
  "users": [
    { "id": "1", "name": "Sean Wong", "role": "admin" },
    { "id": "2", "name": "Test User", "role": "user" }
  ],
  "products": [
    { "id": "101", "name": "Mechanical Keyboard", "price": 120, "inStock": true, "categoryId": "tech" },
    { "id": "102", "name": "Ergonomic Mouse", "price": 45, "inStock": false, "categoryId": "tech" },
    { "id": "103", "name": "Coffee Beans", "price": 18, "inStock": true, "categoryId": "food" }
  ]
}

```


4. **Create the Backup Snapshot:** Protecting your pristine data.
When you send a `POST`, `PUT`, or `DELETE` request to `json-server`, it **permanently modifies** your `db.json` file. If you are running automated UI tests, your database will quickly become a mess of dummy data.

Immediately make a copy of `db.json` and name it `db-backup.json`.

```bash
cp db.json db-backup.json

```

*Note: If you are on Windows Command Prompt, use `copy db.json db-backup.json`.*

We will use this backup in Part 4 to build an instant "reset button" for our server.


5. **Build the Core Server:** Writing the host environment.
Now we write the code that brings our database to life. Create a file named `server.js` and add the following code:

```javascript
const jsonServer = require('json-server');

// json-server creates an Express server under the hood
const server = jsonServer.create();
const defaultMiddlewares = jsonServer.defaults();
const PORT = process.env.PORT || 3001;

// Tell the router to use our db.json file
const router = jsonServer.router('db.json');

server.use(defaultMiddlewares);

// Mount the router under an /api prefix
// This cleanly separates our data routes from future admin routes
server.use('/api', router);

server.listen(PORT, () => {
  console.log(`🚀 Greymatter API Engine running on http://localhost:${PORT}`);
  console.log(`📡 Test it: http://localhost:${PORT}/api/products`);
});

```


6. **Fire It Up:**
It is time to test the engine. In your terminal, start the server:

```bash
node server.js

```

Open your browser or a tool like Postman and navigate to `http://localhost:3001/api/products`. You should see your JSON array returned perfectly.

You now have a fully functioning REST API. You can `GET /api/users/1`, or send a `POST` request to `/api/products` and watch it automatically save to your `db.json` file.


### The Baseline is Set

We now have a working API, but it's currently behaving like a standard, flawless mock server. It responds instantly and only processes basic queries. In the real world, networks are slow and users want to filter data by custom rules (like finding all products that are currently "in-stock").

In Part 2, we will introduce the Interceptor layer to simulate the chaos and complexity of a real production environment.
