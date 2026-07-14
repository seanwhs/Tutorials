Welcome to the Bonus Track.

For standard web development, running `npm run dev` in your terminal is perfectly fine. But what happens if you want to ship this API directly to your users?

If you are taking a modern web frontend—like a React application—and packaging it into a native Windows executable using wrappers like Tauri or Electron, you cannot ask your users to open a command prompt and type `node server.js`. Your desktop application needs to start the backend silently in the background when the app opens, and kill it cleanly when the app closes.

To do this, we need to treat our API as a **Child Process**. We are going to build a `ServerLauncher` class that programmatically controls our Express server, pipes its output, and prevents "zombie processes" from eating up system memory.

1. **Create the ServerLauncher Class:** The process manager.
We will use Node's native `child_process` module to spawn our API in the background.

Create a new file named `ServerLauncher.js` and add this code:

```javascript
const { spawn } = require('child_process');
const path = require('path');

class ServerLauncher {
  constructor(options = {}) {
    this.scriptPath = options.scriptPath || path.join(__dirname, 'server.js');
    this.port = options.port || process.env.PORT || 3001;
    this.mode = options.mode || 'dev';
    this.process = null;
    this._listeners = new Map();
  }

  // Start the server as a forked Node process
  launch() {
    if (this.process) {
      console.log('Server is already running');
      return;
    }

    const args = [this.scriptPath];
    if (this.mode === 'production') args.push('production');

    // spawn() runs the process in the background.
    // We pipe the stdio so we can read the server's console.logs
    this.process = spawn('node', args, {
      stdio: ['ignore', 'pipe', 'pipe'],
      env: { ...process.env, PORT: String(this.port) }
    });

    // Listen for standard output (console.log)
    this.process.stdout.on('data', data => {
      const lines = data.toString().split('\n').filter(Boolean);
      lines.forEach(line => {
        console.log(`[Background API] ${line}`);
        this._emit('stdout', line);
      });
    });

    // Listen for standard error (console.error)
    this.process.stderr.on('data', data => {
      const text = data.toString();
      console.error(`[Background API Error] ${text}`);
      this._emit('stderr', text);
    });

    this.process.on('exit', (code, signal) => {
      console.log(`Background API exited (code=${code}, signal=${signal})`);
      this.process = null;
      this._emit('exit', { code, signal });
    });

    console.log(`Launching background server on port ${this.port}...`);
    return this;
  }

```


2. **Add Graceful Shutdown Logic:** Preventing zombie processes.
If your Tauri or Electron app crashes or closes abruptly, the Node server might keep running in the background, locking up port 3001. We need a method to gracefully kill it.

Add these methods inside your `ServerLauncher` class, right below `launch()`:

```javascript
  // Gracefully stop the server
  stop() {
    if (!this.process) return;
    
    // SIGTERM asks the process to shut down cleanly
    this.process.kill('SIGTERM');
    
    // If it's still alive after 3 seconds, force kill it with SIGKILL
    setTimeout(() => {
      if (this.process) {
        console.log('Force killing background API...');
        this.process.kill('SIGKILL');
        this.process = null;
      }
    }, 3000);
  }

  isRunning() {
    return this.process !== null && this.process.exitCode === null;
  }

  // Simple event emitter pattern
  on(event, fn) {
    if (!this._listeners.has(event)) this._listeners.set(event, []);
    this._listeners.get(event).push(fn);
    return this;
  }

  _emit(event, data) {
    const handlers = this._listeners.get(event) || [];
    handlers.forEach(fn => fn(data));
  }
}

module.exports = ServerLauncher;

```


3. **Write a Run Script:** Testing the programmatic controller.
Let's test our new class. Imagine this next script is the main process of your desktop application.

Create a file named `run.js`:

```javascript
const ServerLauncher = require('./ServerLauncher');

// Initialize the launcher in production mode (no artificial latency)
const api = new ServerLauncher({ mode: 'production', port: 3001 });

api.on('exit', ({ code }) => {
  console.log(`API shut down safely with code ${code}.`);
});

// 1. Launch the server
api.launch();

// 2. Simulate closing the desktop application after 5 seconds
setTimeout(() => {
  console.log('Simulating application close...');
  api.stop();
}, 5000);

```


4. **Run the Simulation:**
In your terminal, execute the test script:

```bash
node run.js

```

Watch the console. You will see the main process start the server, pipe the startup logs to your terminal prefixed with `[Background API]`, wait five seconds, and then gracefully terminate the server.


### Series Complete

You have now built a professional-grade mock environment.

Whether you are spinning it up in the terminal to develop a web dashboard, using the Admin routes to inject state during automated UI tests, or embedding it via the `ServerLauncher` into a standalone `.exe`, the Greymatter API provides a rock-solid foundation that behaves exactly like a real production system.
