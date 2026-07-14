Welcome to Part 3. We have a working REST engine and a middleware interceptor simulating real network conditions.

But right now, our database is static. If you want to test how your UI handles an "empty state" (like a brand new account with no products) versus a "heavy state" (an account with 10,000 products), you have to manually stop the Node process, edit `db.json`, and restart the server.

If you are writing automated UI tests or relying on state-caching tools like TanStack Query, restarting the backend constantly is a massive bottleneck.

In this phase, we are going to build the **Orchestrator**. We will expose special Admin routes that allow us to upload a completely new dataset into the server's memory, hot-swapping the database on the fly without ever dropping the connection.

1. **Add Core Node Modules:** Preparing the file system.
To overwrite our database file programmatically, we need to bring in Node's built-in file system modules, as well as a body parser to handle large JSON uploads.

Open `server.js` and add these new imports at the very top, right below the others:

```javascript
const fs = require('fs');
const path = require('path');
const express = require('express'); // We need Express directly now

```


2. **Create the Swap Function:** The magic trick.
`json-server` holds its routing logic in a single instance. In Part 1, we declared `let currentRouter = jsonServer.router('db.json');`.

Because we used `let` instead of `const`, we can simply overwrite this variable with a new router instance pointing to freshly written data. Add this function above your middleware injection:

```javascript
// Replace the active json-server router with a new dataset
function swapRouter(filePath) {
  const resolved = path.resolve(filePath);
  currentRouter = jsonServer.router(resolved);
}

```


3. **Define the Admin Upload Route:** Bypassing the interceptor.
We need an endpoint that accepts a JSON payload, writes it to `db.json`, and triggers our `swapRouter` function.

**Crucial routing rule:** We must define this route *before* `server.use(middlewares)`. We do not want our Admin routes to be subjected to the artificial network latency we built in Part 2!

Add this code right below your `swapRouter` function:

```javascript
// Set up parsing for potentially massive database uploads
const jsonBodyParser = express.json({ limit: '10mb' });

// Admin Route: Upload a new JSON payload to replace the active dataset
server.post('/admin/upload', jsonBodyParser, (req, res) => {
  try {
    const data = req.body;
    if (!data || typeof data !== 'object') {
      return res.status(400).json({ error: 'Invalid JSON payload' });
    }
    
    const dbPath = path.join(__dirname, 'db.json');
    
    // 1. Overwrite the physical file
    fs.writeFileSync(dbPath, JSON.stringify(data, null, 2), 'utf-8');
    
    // 2. Hot-swap the router in memory
    swapRouter(dbPath);
    
    res.json({ 
      ok: true, 
      message: 'Dataset loaded successfully',
      entities: Object.keys(data) 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

```


4. **The Complete Server Code:** Reviewing the Orchestrator.
Let's look at how the entire `server.js` file comes together. Notice how the Admin route sits safely above the Interceptor layer.

```javascript
const jsonServer = require('json-server');
const express = require('express');
const fs = require('fs');
const path = require('path');
const middlewares = require('./middlewares');

const server = jsonServer.create();
const defaultMiddlewares = jsonServer.defaults();
const PORT = process.env.PORT || 3001;
const isProduction = process.argv.includes('production');

let currentRouter = jsonServer.router('db.json');

function swapRouter(filePath) {
  const resolved = path.resolve(filePath);
  currentRouter = jsonServer.router(resolved);
}

server.use(defaultMiddlewares);

// --- ORCHESTRATOR LAYER (Admin Routes) ---
const jsonBodyParser = express.json({ limit: '10mb' });

server.post('/admin/upload', jsonBodyParser, (req, res) => {
  try {
    const data = req.body;
    if (!data || typeof data !== 'object') {
      return res.status(400).json({ error: 'Invalid payload' });
    }
    const dbPath = path.join(__dirname, 'db.json');
    fs.writeFileSync(dbPath, JSON.stringify(data, null, 2), 'utf-8');
    swapRouter(dbPath);
    res.json({ ok: true, entities: Object.keys(data) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- INJECTION LAYER ---
server.use((req, res, next) => {
  req.db = currentRouter.db;
  req.isProduction = isProduction;
  next();
});

// --- INTERCEPTOR LAYER (Delays & Custom Logic) ---
server.use(middlewares);

// --- ENGINE LAYER (json-server REST APIs) ---
server.use('/api', (req, res, next) => currentRouter(req, res, next));

server.listen(PORT, () => {
  console.log(`🚀 Greymatter API Orchestrator running on http://localhost:${PORT}`);
});

```


5. **Test the Hot-Swap:**
Restart your server (`node server.js`).

Now, use a tool like Postman, Insomnia, or a simple `fetch` script in your browser console to send a `POST` request to `http://localhost:3001/admin/upload` with this JSON body:

```json
{
  "products": [],
  "users": [ { "id": "999", "name": "Hot Swapped User" } ]
}

```

Without restarting the server, navigate to `http://localhost:3001/api/users`. You will immediately see the new data. You just dynamically changed your entire backend state!


### The Ultimate Testing Sandbox

By implementing the Orchestrator layer, your frontend test suites can now take full control of the backend. Before a test runs, it can POST a specific dataset to `/admin/upload`, ensuring your UI is tested against the exact state it requires, without dealing with complex database seeding.

But there is one final piece missing. What happens when your UI tests are done, or when you've completely ruined the data while clicking around locally?

In Part 4, we will build the "Reset Button"—a fast, bulletproof way to restore your API back to its pristine default state.
