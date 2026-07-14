Welcome to Part 2. Right now, our API is too perfect. It responds in zero milliseconds, and it only understands basic exact-match queries.

If you build your frontend against a perfect API, your users will experience a broken UI in production. When a real API takes a full second to load, your app will show blank screens instead of loading skeletons. If your frontend needs to filter "in-stock" products or search by a keyword, a basic mock server won't know how to handle it.

In this phase, we are going to build the **Interceptor Layer**. We will create a custom middleware file that catches requests before they hit our database, injecting artificial chaos and custom business logic.

1. **Set Up the Middleware File:** Creating the Interceptor.
In the root of your project, create a new file named `middlewares.js`. This file will intercept every incoming request.

First, let's set up CORS (Cross-Origin Resource Sharing) so our frontend (like a Vite or Next.js app) can actually talk to our server, and outline our basic middleware structure:

```javascript
const cors = require('cors');

// Allow requests from common local frontend ports (Next.js and Vite)
const corsOptions = {
  origin: ['http://localhost:3000', 'http://127.0.0.1:3000', 'http://localhost:5173'],
  credentials: true
};

module.exports = (req, res, next) => {
  // Wrap our custom logic inside the CORS middleware
  cors(corsOptions)(req, res, () => {
    if (res.headersSent) return;

    const respond = () => {
      // We will put our custom routing and filtering here in the next steps
      next();
    };

    // For now, just call respond immediately
    respond();
  });
};

```


2. **Inject Artificial Latency:** Making the UI wait.
Let's add the network simulation. We only want to slow things down in development mode. If we pass a `production` flag later, we want it to run at full speed.

Modify the bottom of `middlewares.js` to look like this:

```javascript
    const respond = () => {
      // Custom routing will go here
      next();
    };

    // In dev mode, add a random delay (200–700ms) to simulate network latency
    if (req.isProduction) {
      respond();
    } else {
      setTimeout(respond, Math.random() * 500 + 200);
    }
  });
};

```

> **Key insight:** This single block of code forces you to build loading states in your frontend. If you don't handle `isLoading`, your UI will noticeably hang for half a second.


3. **Handle Advanced Filtering:** Writing custom business logic.
`json-server` is great at direct matches (e.g., `/products?categoryId=tech`), but it struggles with complex logic. Let's intercept requests to `/api/products` to handle a custom `filter=in-stock` query parameter.

Inside the `respond` function, *before* calling `next()`, add this logic:

```javascript
    const respond = () => {
      // 1. Health check - Always good to have for testing connections
      if (req.url === '/api/health') {
        res.json({ status: 'OK', timestamp: new Date().toISOString() });
        return;
      }

      // 2. Custom route for products
      if (req.method === 'GET' && req.url.startsWith('/api/products')) {
        const url = new URL(req.url, `http://${req.headers.host}`);
        const filterBy = url.searchParams.get('filter');

        // req.db gives us direct access to the lowdb database instance
        let products = [...req.db.get('products').value()];

        // Apply custom business logic
        if (filterBy === 'in-stock') {
          products = products.filter(product => product.inStock);
        }

        // Return our modified data and exit early
        res.json(products);
        return;
      }

      // 3. Format URLs for json-server
      // json-server expects /products, not /api/products
      if (req.url.startsWith('/api')) {
        req.url = req.url.replace('/api', '');
      }

      next();
    };

```


4. **Wire Middleware into the Server:** Connecting the layers.
Our middleware is written, but our engine doesn't know about it yet. We need to update `server.js` to inject the database into the request object and run our interceptor.

Open `server.js` and replace its contents with this updated code:

```javascript
const jsonServer = require('json-server');
const express = require('express');
const middlewares = require('./middlewares');

const server = jsonServer.create();
const defaultMiddlewares = jsonServer.defaults();
const PORT = process.env.PORT || 3001;

// Detect if we passed a "production" argument in the console
const isProduction = process.argv.includes('production');

let currentRouter = jsonServer.router('db.json');

server.use(defaultMiddlewares);

// INJECTION LAYER: 
// Attach the database and the mode flag to every request
// so our middlewares.js file can access them.
server.use((req, res, next) => {
  req.db = currentRouter.db;
  req.isProduction = isProduction;
  next();
});

// Apply our custom interceptor
server.use(middlewares);

// Mount json-server
server.use('/api', (req, res, next) => currentRouter(req, res, next));

server.listen(PORT, () => {
  console.log(`🚀 Greymatter API Engine running on http://localhost:${PORT}`);
});

```


5. **Test the Chaos:**
Restart your server in the terminal:

```bash
node server.js

```

Now, visit `http://localhost:3001/api/products?filter=in-stock` in your browser.
Notice two things:

1. It takes a fraction of a second to load (thanks to our latency simulator).
2. It *only* returns the products where `inStock` is true (thanks to our custom business logic).


### The API is Now Battle-Tested

By adding the Interceptor layer, we've transformed a simple mock server into a realistic network environment. Your frontend will now have to deal with loading times and can execute complex queries just like a real backend.

But we still have one major problem: state management. If we want to test how the UI looks with an empty dataset versus a dataset with 1,000 items, we currently have to stop the server, swap out `db.json`, and restart.

In Part 3, we will fix this by turning our Express shell into an **Orchestrator**, allowing us to upload and swap databases on the fly via Admin endpoints.
