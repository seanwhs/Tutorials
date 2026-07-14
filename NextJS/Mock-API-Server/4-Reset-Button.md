Welcome to Part 4. If you have been following along and testing your API with `POST`, `PUT`, or `DELETE` requests, you've probably noticed a side effect: `json-server` permanently mutates your `db.json` file.

While this auto-saving feature is great for quick prototyping, it becomes a nightmare for ongoing development. If you delete all your products to test an empty state, or flood the database with dummy test users, your pristine starting data is gone forever.

In this phase, we are going to build the **Reset Button**. It's a dead-simple utility script that instantly wipes away your local mutations and restores the database to a known, clean state.

1. **Create the Reset Script:** Writing the utility.
In Part 1, we made a copy of our original database and named it `db-backup.json`. We are now going to write a Node script that copies that backup over our mutated active database.

In the root of your project, create a new file named `reset.js` and add the following code:

```javascript
const fs = require('fs');
const source = 'db-backup.json';
const dest = 'db.json';

// Safety check: ensure the backup file actually exists
if (!fs.existsSync(source)) {
  console.error(`❌ Error: ${source} not found.`);
  console.error('Before running reset, copy your pristine db.json to db-backup.json first.');
  process.exit(1);
}

// Overwrite the active dataset with the backup snapshot
fs.copyFileSync(source, dest);
console.log('✅ Database successfully reset to initial state.');

```


2. **Update package.json:** Creating a shortcut.
While you could run `node reset.js` every time, it is much cleaner to integrate this into your npm scripts alongside your server start command.

Open your `package.json` file and locate the `"scripts"` section. Update it to look like this:

```json
"scripts": {
  "start": "node server.js",
  "dev": "node server.js",
  "prod": "node server.js production",
  "reset": "node reset.js"
}

```

> **Key insight:** We added a `prod` script that passes the `production` argument. Remember our middleware from Part 2? Running `npm run prod` will bypass the artificial network latency!


3. **Test the Cycle:** Mutate, reset, verify.
Let's prove that it works.

1. Make sure your server is running (`npm run dev`).
2. Open your browser console or a tool like Postman and send a `DELETE` request to remove a user:

```javascript
fetch('http://localhost:3001/api/users/1', { method: 'DELETE' })

```

3. Visit `http://localhost:3001/api/users` to verify the user is gone. Open your `db.json` file in your code editor—the user is physically missing from the file.
4. Now, open a second terminal window and hit the reset button:

```bash
npm run reset

```

5. Refresh your browser at `/api/users`. The user is back. Your database is perfectly clean again.


### The Core Engine is Complete

Congratulations! You have successfully built the Greymatter API. You now have a custom, resilient mock backend that:

* Generates REST endpoints automatically.
* Simulates real-world network latency.
* Handles custom business logic through an Interceptor layer.
* Can be hot-swapped on the fly using Admin routes.
* Can be instantly reset to a pristine state.

For 95% of frontend developers, this is exactly where you stop. You can drop these files into a `mocks/` folder in any React, Next.js, or Vue project and have an elite local development environment.

But for the remaining 5%—those who want to package this API into a native desktop app using Tauri or Electron—we have one final challenge.
