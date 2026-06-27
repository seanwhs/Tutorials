# 🚀 The Absolute Beginner's Guide: Build Your Portfolio Website with React, Tailwind CSS, Sanity CMS & Vercel

*No coding experience required. We'll build everything step by step.*

---

## Table of Contents
- [Part 0: What We're Building](#part-0-what-were-building)
- [Part 1: Understanding the Basics](#part-1-understanding-the-basics)
- [Part 2: Installing Your Tools](#part-2-installing-your-tools)
- [Part 3: Creating Your First Website](#part-3-creating-your-first-website)
- [Part 4: Understanding React Components](#part-4-understanding-react-components)
- [Part 5: Styling with Tailwind CSS](#part-5-styling-with-tailwind-css)
- [Part 6: Building Your Portfolio Sections](#part-6-building-your-portfolio-sections)
- [Part 7: Adding a Blog with Sanity CMS](#part-7-adding-a-blog-with-sanity-cms)
- [Part 8: Making It Interactive](#part-8-making-it-interactive)
- [Part 9: Publishing to the Internet](#part-9-publishing-to-the-internet)

---

## Part 0: What We're Building

By the end of this tutorial, you will have a **live website** that looks like this:

```
┌─────────────────────────────────────┐
│  Sean Wong        About Projects Blog│
│                                     │
│  Hi, I'm Sean Wong                  │
│  I build AI-native platforms        │
│  [View My Work]  [Read My Blog]     │
│                                     │
│  ──── About Me ────                 │
│  [Your story here...]               │
│                                     │
│  ──── My Projects ────              │
│  ┌─────────┐  ┌─────────┐          │
│  │ Project │  │ Project │          │
│  │  Card   │  │  Card   │          │
│  └─────────┘  └─────────┘          │
│                                     │
│  ──── Latest Blog Posts ────        │
│  ┌─────────┐  ┌─────────┐          │
│  │ Article │  │ Article │          │
│  │  Card   │  │  Card   │          │
│  └─────────┘  └─────────┘          │
│                                     │
│  ──── Get In Touch ────            │
│  [Email Me]  [LinkedIn]            │
│                                     │
│  © 2026 Sean Wong                   │
└─────────────────────────────────────┘
```

**Your website will:**
- Work on phones, tablets, and computers
- Have a blog you can update without writing code
- Load fast and look professional
- Be hosted on the internet for free

---

## Part 1: Understanding the Basics

### What is a Website?
A website is a collection of files that a browser (Chrome, Safari, Firefox) reads and displays. The main types of files are:

| File Type | What It Does | Example |
|-----------|-------------|---------|
| **HTML** | Structure and content | Headings, paragraphs, images |
| **CSS** | Styling and colors | Colors, fonts, spacing, layout |
| **JavaScript** | Interactivity | Buttons, animations, data fetching |

### What is React?
React is a tool created by Facebook that helps developers build websites more easily. Think of it like this:

> **Without React:** You write HTML, CSS, and JavaScript separately. When something changes, you manually update everything.
>
> **With React:** You build small pieces called **components** (like LEGO bricks) and snap them together. When data changes, React automatically updates only the parts that need changing.

**Example of a React component:**
```jsx
function Greeting() {
  return <h1>Hello, I'm Sean!</h1>;
}
```

This looks like HTML mixed with JavaScript. That's called **JSX** — it's a special syntax that makes React easier to write.

### What is Tailwind CSS?
Tailwind is a CSS framework that gives you pre-made classes. Instead of writing:
```css
.button {
  background-color: blue;
  padding: 10px 20px;
  border-radius: 8px;
}
```

You write:
```html
<button class="bg-blue-600 px-5 py-2.5 rounded-lg">
  Click Me
</button>
```

Each class does one thing. You combine them like building blocks.

### What is Sanity CMS?
**CMS** stands for Content Management System. It's a tool for creating and managing content (like blog posts) without writing code.

**"Headless"** means the CMS only handles the content. It doesn't care how your website looks. Your website asks the CMS for content, and the CMS sends it back as data.

**Why this matters:** You can write blog posts in Sanity's editor, and your website automatically shows them. No code changes needed.

```
You write in Sanity → Sanity stores it → Your website fetches it → Visitors see it
```

### What is Vercel?
Vercel is a service that takes your website files and puts them on the internet. It connects to your code (on GitHub) and automatically updates your live website whenever you make changes.

---

## Part 2: Installing Your Tools

You need three free tools on your computer.

### Tool 1: Node.js
Node.js lets your computer run JavaScript code outside of a browser. We need it to build our website.

**To install:**
1. Go to [nodejs.org](https://nodejs.org)
2. Click the big **LTS** button (LTS means "Long Term Support" — it's the stable version)
3. Download and run the installer
4. Keep clicking "Next" until it's done

**To verify it's working:**
Open your terminal (see below) and type:
```bash
node --version
```
You should see something like `v20.15.0`. If you do, Node.js is installed!

### Tool 2: Visual Studio Code (VS Code)
This is where you'll write your code. It's like Microsoft Word, but for code.

**To install:**
1. Go to [code.visualstudio.com](https://code.visualstudio.com)
2. Download for your computer (Windows, Mac, or Linux)
3. Install it

**Recommended extensions (add-ons):**
Once VS Code is open:
1. Click the Extensions icon on the left (looks like four squares)
2. Search for and install:
   - **Tailwind CSS IntelliSense** — suggests Tailwind classes as you type
   - **ES7+ React/Redux/React-Native snippets** — helps write React faster

### Tool 3: A Terminal
A terminal is a text-based way to talk to your computer. You'll use it to run commands.

**How to open:**
- **Windows:** Press `Windows key + R`, type `cmd`, press Enter
- **Mac:** Press `Cmd + Space`, type `Terminal`, press Enter
- **Linux:** Press `Ctrl + Alt + T`

**What you'll see:** A black window with text like `C:\Users\YourName>` or `YourName@computer ~ %`

**Important:** Every time this tutorial says "run a command," type it in the terminal and press Enter.

---

## Part 3: Creating Your First Website

### Step 1: Create the Project
In your terminal, run this command:
```bash
npm create vite@latest sean-portfolio -- --template react
```

**What this does:** Creates a new folder called `sean-portfolio` with all the files needed for a React website.

**What you'll see:** A few questions. Just press Enter to accept the defaults.

### Step 2: Enter Your Project Folder
```bash
cd sean-portfolio
```

`cd` means "change directory" — you're now inside your project folder.

### Step 3: Install Dependencies
Run these commands one by one:
```bash
npm install
npm install tailwindcss @tailwindcss/vite
npm install react-router-dom
npm install @sanity/client @sanity/image-url @portabletext/react
```

**What each does:**
- `npm install` — Installs the basic React files
- `npm install tailwindcss @tailwindcss/vite` — Installs Tailwind CSS
- `npm install react-router-dom` — Installs page navigation
- `npm install @sanity/client @sanity/image-url @portabletext/react` — Installs tools to connect to your blog system

### Step 4: Configure Tailwind CSS
Open your project in VS Code:
1. In VS Code, click **File** → **Open Folder**
2. Find and select the `sean-portfolio` folder
3. Click **Open**

In VS Code, find the file `vite.config.js` and replace everything with:
```js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
  ],
})
```

**What this does:** Tells Vite (our build tool) to use the Tailwind CSS plugin.

Now find `src/index.css` and replace everything with:
```css
@import "tailwindcss";
```

**What this does:** Imports all of Tailwind's styles into your website.

### Step 5: Start Your Website
In your terminal (make sure you're still in the `sean-portfolio` folder), run:
```bash
npm run dev
```

**What you'll see:** Text saying something like `Local: http://localhost:5173/`

Open your browser and go to `http://localhost:5173`

**You should see:** A page that says "count is 0" with a button. This is the default Vite + React starter page.

**To stop the server:** Press `Ctrl + C` in the terminal.

---

## Part 4: Understanding React Components

### What is a Component?
A component is a reusable piece of your website. Think of it like a custom LEGO brick.

**Example:** A button that you use 10 times across your website. Instead of writing the same code 10 times, you write it once as a component and reuse it.

### Your First Component
In VS Code, look at the `src` folder. You'll see:
```
src/
├── App.jsx       ← Main component
├── main.jsx      ← Entry point
└── index.css     ← Styles
```

**Let's clean up and start fresh.**

Open `src/App.jsx` and replace everything with:
```jsx
function App() {
  return (
    <div className="min-h-screen bg-slate-50">
      <h1 className="text-3xl font-bold text-slate-900 p-8">
        Hello, I'm Sean Wong
      </h1>
    </div>
  );
}

export default App;
```

**Save the file** (`Ctrl+S` or `Cmd+S`). Your browser updates automatically!

**Let's understand those Tailwind classes:**
| Class | What It Means |
|-------|---------------|
| `min-h-screen` | Minimum height = full screen height |
| `bg-slate-50` | Background color = very light gray |
| `text-3xl` | Text size = extra large (30px) |
| `font-bold` | Font weight = bold |
| `text-slate-900` | Text color = very dark gray |
| `p-8` | Padding = 32px on all sides |

### Creating a Folder Structure
Let's organize our components. In VS Code:

1. Right-click the `src` folder → **New Folder** → type `components` → press Enter
2. Right-click `components` → **New Folder** → type `ui` → press Enter
3. Right-click `components` → **New Folder** → type `sections` → press Enter

Your structure should look like:
```
src/
├── components/
│   ├── ui/           ← Small reusable pieces
│   └── sections/     ← Big page sections
├── App.jsx
├── main.jsx
└── index.css
```

---

## Part 5: Styling with Tailwind CSS

Before we build sections, let's create our building blocks.

### Building Block 1: Button
Create a new file: `src/components/ui/Button.jsx`

```jsx
function Button({ children, variant = 'primary', href }) {
  // Base styles for all buttons
  const baseClasses = "inline-flex items-center justify-center px-6 py-3 rounded-xl font-semibold transition-all duration-200";
  
  // Different styles for different button types
  const variants = {
    primary: "bg-slate-900 text-white hover:bg-slate-800 hover:shadow-lg",
    secondary: "bg-white text-slate-900 border-2 border-slate-200 hover:border-slate-900",
    outline: "bg-transparent text-white border-2 border-white hover:bg-white hover:text-slate-900"
  };

  // Combine base + variant
  const classes = `${baseClasses} ${variants[variant]}`;

  // If href is provided, make it a link. Otherwise, make it a button.
  if (href) {
    return <a href={href} className={classes}>{children}</a>;
  }

  return <button className={classes}>{children}</button>;
}

export default Button;
```

**How to use it:**
```jsx
<Button>Primary Button</Button>
<Button variant="secondary">Secondary Button</Button>
<Button href="https://google.com">Link Button</Button>
```

### Building Block 2: Section Wrapper
Create: `src/components/ui/Section.jsx`

```jsx
function Section({ children, id, className = "" }) {
  return (
    <section id={id} className={`py-20 px-4 sm:px-6 lg:px-8 ${className}`}>
      <div className="max-w-6xl mx-auto">
        {children}
      </div>
    </section>
  );
}

export default Section;
```

**What those classes do:**
| Class | Meaning |
|-------|---------|
| `py-20` | Padding top and bottom = 80px |
| `px-4` | Padding left and right = 16px |
| `sm:px-6` | At small screens (640px+), padding = 24px |
| `lg:px-8` | At large screens (1024px+), padding = 32px |
| `max-w-6xl` | Maximum width = 1152px |
| `mx-auto` | Center horizontally |

### Building Block 3: Badge
Create: `src/components/ui/Badge.jsx`

```jsx
function Badge({ children, color = "slate" }) {
  const colors = {
    slate: "bg-slate-100 text-slate-700",
    blue: "bg-blue-100 text-blue-700",
    green: "bg-emerald-100 text-emerald-700",
    purple: "bg-purple-100 text-purple-700",
    amber: "bg-amber-100 text-amber-700"
  };

  return (
    <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${colors[color]}`}>
      {children}
    </span>
  );
}

export default Badge;
```

### Building Block 4: Card
Create: `src/components/ui/Card.jsx`

```jsx
function Card({ children, className = "" }) {
  return (
    <div className={`bg-white rounded-2xl border border-slate-200 p-6 hover:shadow-xl hover:-translate-y-1 transition-all duration-300 ${className}`}>
      {children}
    </div>
  );
}

export default Card;
```

---

## Part 6: Building Your Portfolio Sections

Now let's build the big pieces of your website. Each section is a component.

### Section 1: Navigation Bar
Create: `src/components/sections/Navbar.jsx`

```jsx
import { useState } from 'react';

function Navbar() {
  // useState is a React feature that remembers if menu is open or closed
  const [isOpen, setIsOpen] = useState(false);

  const links = [
    { name: 'About', href: '#about' },
    { name: 'Projects', href: '#projects' },
    { name: 'Blog', href: '#blog' },
    { name: 'Contact', href: '#contact' },
  ];

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-white/80 backdrop-blur-md border-b border-slate-200">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo / Name */}
          <a href="#home" className="text-xl font-bold text-slate-900">
            Sean Wong
          </a>

          {/* Desktop Menu (hidden on mobile) */}
          <div className="hidden md:flex items-center space-x-8">
            {links.map((link) => (
              <a key={link.name} href={link.href} className="text-slate-600 hover:text-slate-900 font-medium">
                {link.name}
              </a>
            ))}
            <a href="#contact" className="bg-slate-900 text-white px-5 py-2 rounded-lg font-medium hover:bg-slate-800">
              Let's Talk
            </a>
          </div>

          {/* Mobile Menu Button */}
          <button onClick={() => setIsOpen(!isOpen)} className="md:hidden p-2 text-slate-600">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              {isOpen ? (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              ) : (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              )}
            </svg>
          </button>
        </div>

        {/* Mobile Menu (shown when isOpen is true) */}
        {isOpen && (
          <div className="md:hidden py-4 border-t border-slate-100">
            {links.map((link) => (
              <a key={link.name} href={link.href} onClick={() => setIsOpen(false)} className="block py-3 text-slate-600 font-medium">
                {link.name}
              </a>
            ))}
          </div>
        )}
      </div>
    </nav>
  );
}

export default Navbar;
```

**Key concepts explained:**
- `useState(false)` — Creates a memory cell that starts as `false` (menu closed)
- `setIsOpen(!isOpen)` — Toggles between true and false
- `{isOpen && (...)}` — Only shows the mobile menu if isOpen is true
- `hidden md:flex` — Hidden on mobile, flex layout on medium screens and up

### Section 2: Hero (Top of Page)
Create: `src/components/sections/Hero.jsx`

```jsx
import Button from '../ui/Button';

function Hero() {
  return (
    <section id="home" className="min-h-screen flex items-center pt-16 bg-gradient-to-br from-slate-50 via-white to-blue-50">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="max-w-3xl">
          <p className="text-slate-500 font-medium mb-4 tracking-wide uppercase text-sm">
            Enterprise Architect → Independent Developer
          </p>
          <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-slate-900 leading-tight mb-6">
            Building <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-purple-600">AI-native</span> digital platforms with architectural rigor
          </h1>
          <p className="text-lg sm:text-xl text-slate-600 leading-relaxed mb-8">
            Decades of enterprise architecture experience, now focused on full-stack development, 
            cloud-native systems, and AI-augmented engineering.
          </p>
          <div className="flex flex-col sm:flex-row gap-4">
            <Button href="#projects" variant="primary">View AI Projects</Button>
            <Button href="#blog" variant="secondary">Read the Blog</Button>
          </div>
        </div>
      </div>
    </section>
  );
}

export default Hero;
```

### Section 3: About
Create: `src/components/sections/About.jsx`

```jsx
import Section from '../ui/Section';
import Badge from '../ui/Badge';

function About() {
  const skills = [
    { name: 'React / Next.js', color: 'blue' },
    { name: 'TypeScript', color: 'blue' },
    { name: 'Node.js', color: 'green' },
    { name: 'PostgreSQL / Neon', color: 'green' },
    { name: 'Cloud Architecture', color: 'purple' },
    { name: 'DevSecOps', color: 'purple' },
    { name: 'AI Engineering', color: 'amber' },
    { name: 'System Design', color: 'slate' },
    { name: 'Technical Training', color: 'slate' },
  ];

  return (
    <Section id="about" className="bg-white">
      <div className="grid lg:grid-cols-2 gap-12 items-center">
        <div>
          <h2 className="text-3xl sm:text-4xl font-bold text-slate-900 mb-6">
            From Boardroom Architecture to Hands-On Code
          </h2>
          <div className="space-y-4 text-slate-600 leading-relaxed">
            <p>
              After decades designing systems for global enterprises, I've pivoted to independent 
              consulting and development. I bring strategic thinking combined with practical velocity.
            </p>
            <p>
              I specialize in modern web platforms using React, Next.js, and cloud-native stacks, 
              augmented with AI tools. My approach blends rapid iteration with strong architectural governance.
            </p>
            <p>
              Based in Singapore, I'm passionate about digital transformation and grooming 
              the next generation of digital leaders through consulting and ACTA-certified training.
            </p>
          </div>
        </div>
        <div>
          <h3 className="text-lg font-semibold text-slate-900 mb-4">Tech Stack & Expertise</h3>
          <div className="flex flex-wrap gap-2">
            {skills.map((skill) => (
              <Badge key={skill.name} color={skill.color}>{skill.name}</Badge>
            ))}
          </div>
          
          <div className="mt-8 grid grid-cols-2 gap-4">
            <div className="p-4 bg-slate-50 rounded-xl text-center">
              <div className="text-2xl font-bold text-slate-900">20+</div>
              <div className="text-sm text-slate-500">Years Experience</div>
            </div>
            <div className="p-4 bg-slate-50 rounded-xl text-center">
              <div className="text-2xl font-bold text-slate-900">$100M+</div>
              <div className="text-sm text-slate-500">Projects Delivered</div>
            </div>
            <div className="p-4 bg-slate-50 rounded-xl text-center">
              <div className="text-2xl font-bold text-slate-900">400%</div>
              <div className="text-sm text-slate-500">Performance Gain</div>
            </div>
            <div className="p-4 bg-slate-50 rounded-xl text-center">
              <div className="text-2xl font-bold text-slate-900">ACTA</div>
              <div className="text-sm text-slate-500">Certified Trainer</div>
            </div>
          </div>
        </div>
      </div>
    </Section>
  );
}

export default About;
```

### Section 4: Projects
Create: `src/components/sections/Projects.jsx`

```jsx
import Section from '../ui/Section';
import Card from '../ui/Card';
import Badge from '../ui/Badge';

function Projects() {
  const projects = [
    {
      title: 'AI Document Analyzer',
      description: 'Intelligent PDF and image processing using LLM vision models. Extracts insights, summarizes content, and enables semantic search.',
      status: 'Live',
      aiFeatures: ['LLM Vision', 'RAG Pipeline', 'Semantic Search'],
      tech: ['Next.js', 'OpenAI API', 'Pinecone', 'PostgreSQL'],
      demoUrl: '#',
      githubUrl: '#'
    },
    {
      title: 'Smart Workflow Builder',
      description: 'No-code automation platform with AI-assisted configuration. Describe your workflow in plain English, get a working automation graph.',
      status: 'In Development',
      aiFeatures: ['NL to Workflow', 'Auto-Error Recovery'],
      tech: ['React', 'n8n', 'LangChain', 'Appwrite'],
      demoUrl: '#',
      githubUrl: '#'
    },
    {
      title: 'AI Code Review Assistant',
      description: 'VS Code extension for intelligent code reviews, security scanning, and architectural pattern suggestions.',
      status: 'Open Source',
      aiFeatures: ['Security Scanning', 'Pattern Recognition'],
      tech: ['TypeScript', 'Ollama', 'Continue.dev'],
      demoUrl: '#',
      githubUrl: '#'
    },
    {
      title: 'Conversational Analytics',
      description: 'Ask questions in plain English, get interactive dashboards. Natural language to SQL with auto-visualization.',
      status: 'Live',
      aiFeatures: ['NL-to-SQL', 'Auto-Visualization'],
      tech: ['Next.js', 'Sanity', 'Neon DB', 'Clerk'],
      demoUrl: '#',
      githubUrl: '#'
    }
  ];

  return (
    <Section id="projects" className="bg-slate-50">
      <div className="text-center mb-16">
        <Badge color="purple">AI-Integrated Projects</Badge>
        <h2 className="text-3xl sm:text-4xl font-bold text-slate-900 mt-4 mb-4">
          Projects I'm Building
        </h2>
        <p className="text-lg text-slate-600 max-w-2xl mx-auto">
          Real-world applications combining modern web development with AI capabilities.
        </p>
      </div>

      <div className="grid md:grid-cols-2 gap-8">
        {projects.map((project) => (
          <Card key={project.title}>
            <div className="flex items-start justify-between mb-4">
              <Badge color={project.status === 'Live' ? 'green' : project.status === 'Open Source' ? 'blue' : 'amber'}>
                {project.status}
              </Badge>
            </div>
            
            <h3 className="text-xl font-bold text-slate-900 mb-3">{project.title}</h3>
            <p className="text-slate-600 leading-relaxed mb-4">{project.description}</p>
            
            <div className="mb-4">
              <p className="text-xs font-semibold text-slate-400 uppercase mb-2">AI Features</p>
              <div className="flex flex-wrap gap-2">
                {project.aiFeatures.map((f) => (
                  <span key={f} className="text-xs px-2 py-1 bg-purple-50 text-purple-700 rounded-md font-medium">{f}</span>
                ))}
              </div>
            </div>
            
            <div className="mb-6">
              <p className="text-xs font-semibold text-slate-400 uppercase mb-2">Tech Stack</p>
              <div className="flex flex-wrap gap-2">
                {project.tech.map((t) => (
                  <span key={t} className="text-xs px-2 py-1 bg-slate-100 text-slate-600 rounded-md">{t}</span>
                ))}
              </div>
            </div>
            
            <div className="flex gap-3 pt-4 border-t border-slate-100">
              <a href={project.demoUrl} className="flex-1 text-center py-2 bg-slate-900 text-white rounded-lg text-sm font-medium hover:bg-slate-800">
                Live Demo
              </a>
              <a href={project.githubUrl} className="flex-1 text-center py-2 border border-slate-200 text-slate-700 rounded-lg text-sm font-medium hover:border-slate-900">
                GitHub
              </a>
            </div>
          </Card>
        ))}
      </div>
    </Section>
  );
}

export default Projects;
```

### Section 5: Contact
Create: `src/components/sections/Contact.jsx`

```jsx
import Section from '../ui/Section';
import Button from '../ui/Button';

function Contact() {
  return (
    <Section id="contact" className="bg-slate-900 text-white">
      <div className="text-center max-w-2xl mx-auto">
        <h2 className="text-3xl sm:text-4xl font-bold mb-6">
          Let's Build Something Together
        </h2>
        <p className="text-lg text-slate-300 mb-8">
          Whether you need a modern web platform, cloud architecture guidance, 
          or technical training for your team.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center mb-12">
          <Button href="mailto:your@email.com" variant="primary">📧 Email Me</Button>
          <Button href="https://linkedin.com/in/yourprofile" variant="outline">💼 LinkedIn</Button>
        </div>
        <p className="text-slate-400 text-sm">
          Based in Singapore · Available for remote consulting worldwide
        </p>
      </div>
    </Section>
  );
}

export default Contact;
```

### Section 6: Footer
Create: `src/components/sections/Footer.jsx`

```jsx
function Footer() {
  return (
    <footer className="bg-slate-950 text-slate-500 py-8 text-center text-sm">
      <p>© {new Date().getFullYear()} Sean Wong. Built with React, Tailwind CSS & Vite.</p>
    </footer>
  );
}

export default Footer;
```

### Putting It All Together
Update `src/App.jsx`:
```jsx
import Navbar from './components/sections/Navbar';
import Hero from './components/sections/Hero';
import About from './components/sections/About';
import Projects from './components/sections/Projects';
import Contact from './components/sections/Contact';
import Footer from './components/sections/Footer';

function App() {
  return (
    <div className="antialiased">
      <Navbar />
      <Hero />
      <About />
      <Projects />
      <Contact />
      <Footer />
    </div>
  );
}

export default App;
```

**Check your browser.** You should now see a complete portfolio website!

---

## Part 7: Adding a Blog with Sanity CMS

Now for the exciting part — a blog you can update without touching code.

### What is Sanity?
Sanity is a **headless CMS** (Content Management System). Think of it like WordPress, but without the website part. It only handles your content.

**The flow:**
```
You write in Sanity Studio → Sanity stores your post → Your website fetches it → Visitors read it
```

### Step 1: Create a Sanity Account
1. Go to [sanity.io](https://sanity.io)
2. Click **Get Started** and sign up with your Google or GitHub account
3. Once logged in, you'll see your dashboard

### Step 2: Create a New Sanity Project
In your terminal, create a new folder for your CMS:
```bash
# Make sure you're OUTSIDE your sean-portfolio folder first
cd ..
mkdir sanity-blog
cd sanity-blog
```

Now create a new Sanity project:
```bash
npm create sanity@latest -- --template clean --create-project "Sean Wong Blog" --dataset production
```

**What happens:**
- Sanity creates a project in your account
- Sets up a local "Studio" (the editor interface)
- Generates API keys

### Step 3: Define What a Blog Post Looks Like
In your `sanity-blog` folder, find `schemaTypes/post.ts` and replace it with:

```typescript
export default {
  name: 'post',
  title: 'Blog Post',
  type: 'document',
  fields: [
    {
      name: 'title',
      title: 'Title',
      type: 'string',
      validation: (Rule) => Rule.required().max(100)
    },
    {
      name: 'slug',
      title: 'Slug (URL-friendly name)',
      type: 'slug',
      options: {
        source: 'title',
        maxLength: 96,
      },
      validation: (Rule) => Rule.required()
    },
    {
      name: 'excerpt',
      title: 'Short Summary',
      type: 'text',
      rows: 3,
      validation: (Rule) => Rule.required().max(300),
      description: 'This appears on the blog listing page'
    },
    {
      name: 'content',
      title: 'Article Content',
      type: 'array',
      of: [
        { type: 'block' },           // Normal paragraphs
        { type: 'image' },            // Images
        { 
          type: 'code',               // Code blocks
          options: { withFilename: true }
        }
      ]
    },
    {
      name: 'category',
      title: 'Category',
      type: 'string',
      options: {
        list: [
          { title: 'Opinion', value: 'opinion' },
          { title: 'Tutorial', value: 'tutorial' },
          { title: 'AI Engineering', value: 'ai-engineering' },
          { title: 'Architecture', value: 'architecture' },
          { title: 'Career', value: 'career' }
        ]
      }
    },
    {
      name: 'tags',
      title: 'Tags',
      type: 'array',
      of: [{ type: 'string' }],
      options: { layout: 'tags' }
    },
    {
      name: 'publishedAt',
      title: 'Publish Date',
      type: 'datetime',
      validation: (Rule) => Rule.required()
    },
    {
      name: 'featured',
      title: 'Featured Post?',
      type: 'boolean',
      initialValue: false,
      description: 'Featured posts appear at the top of the blog section'
    }
  ]
}
```

### Step 4: Start Sanity Studio
```bash
npm run dev
```
Open `http://localhost:3333` — this is your content editor!

**Create your first post:**
1. Click **Create new document** → **Blog Post**
2. Fill in the title, slug, excerpt, and content
3. Select a category
4. Set the publish date
5. Click **Publish**

### Step 5: Connect Your Website to Sanity
Go back to your `sean-portfolio` folder.

Create a new file: `src/lib/sanity.js`

```javascript
import { createClient } from '@sanity/client';
import imageUrlBuilder from '@sanity/image-url';

// This connects your website to Sanity
const client = createClient({
  projectId: 'YOUR_PROJECT_ID',      // We'll find this in a moment
  dataset: 'production',
  apiVersion: '2026-06-28',
  useCdn: true,
});

// Helper function for images
const builder = imageUrlBuilder(client);

export function urlFor(source) {
  return builder.image(source);
}

export default client;
```

**How to find your Project ID:**
1. Go to [sanity.io/manage](https://sanity.io/manage)
2. Click on your "Sean Wong Blog" project
3. Look for **Project ID** — it's a short string like `abc123de`
4. Copy it and replace `YOUR_PROJECT_ID` in the code above

### Step 6: Create the Blog Section
Create: `src/components/sections/Blog.jsx`

```jsx
import { useState, useEffect } from 'react';
import Section from '../ui/Section';
import Card from '../ui/Card';
import Badge from '../ui/Badge';
import client from '../../lib/sanity';

function Blog() {
  // useState creates memory for our component
  const [posts, setPosts] = useState([]);        // Stores blog posts
  const [loading, setLoading] = useState(true);  // Tracks if we're loading
  const [error, setError] = useState(null);      // Stores any errors
  const [activeCategory, setActiveCategory] = useState('all');

  const categories = [
    { id: 'all', label: 'All Posts' },
    { id: 'opinion', label: 'Opinion' },
    { id: 'tutorial', label: 'Tutorials' },
    { id: 'ai-engineering', label: 'AI Engineering' },
    { id: 'architecture', label: 'Architecture' },
  ];

  // useEffect runs code when the component first appears
  useEffect(() => {
    // This is the query language Sanity uses (called GROQ)
    const query = `*[_type == "post"] | order(publishedAt desc) {
      _id,
      title,
      slug,
      excerpt,
      category,
      publishedAt,
      featured
    }`;
    
    client.fetch(query)
      .then((data) => {
        setPosts(data);
        setLoading(false);
      })
      .catch((err) => {
        console.error(err);
        setError('Failed to load articles. Please try again later.');
        setLoading(false);
      });
  }, []); // Empty array means "run once when page loads"

  // Filter posts based on selected category
  const filteredPosts = activeCategory === 'all' 
    ? posts 
    : posts.filter(post => post.category === activeCategory);

  const featuredPost = posts.find(post => post.featured);

  // Show loading spinner
  if (loading) {
    return (
      <Section id="blog" className="bg-white">
        <div className="text-center py-20">
          <div className="animate-spin w-8 h-8 border-2 border-slate-900 border-t-transparent rounded-full mx-auto mb-4" />
          <p className="text-slate-500">Loading articles...</p>
        </div>
      </Section>
    );
  }

  // Show error message
  if (error) {
    return (
      <Section id="blog" className="bg-white">
        <div className="text-center py-20 text-red-600">
          {error}
        </div>
      </Section>
    );
  }

  return (
    <Section id="blog" className="bg-white">
      <div className="text-center mb-12">
        <Badge color="blue">Blog</Badge>
        <h2 className="text-3xl sm:text-4xl font-bold text-slate-900 mt-4 mb-4">
          Thoughts on Code, AI & Architecture
        </h2>
        <p className="text-lg text-slate-600 max-w-2xl mx-auto">
          Opinion pieces, coding tutorials, and lessons from decades of building enterprise systems.
        </p>
      </div>

      {/* Category Filter Buttons */}
      <div className="flex flex-wrap justify-center gap-2 mb-12">
        {categories.map((cat) => (
          <button
            key={cat.id}
            onClick={() => setActiveCategory(cat.id)}
            className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
              activeCategory === cat.id
                ? 'bg-slate-900 text-white'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            {cat.label}
          </button>
        ))}
      </div>

      {/* Featured Post (only shown on "All" tab) */}
      {featuredPost && activeCategory === 'all' && (
        <div className="mb-12">
          <Card className="md:flex gap-8 items-center">
            <div className="md:w-1/2 mb-6 md:mb-0">
              <div className="aspect-video bg-gradient-to-br from-blue-100 to-purple-100 rounded-xl flex items-center justify-center text-6xl">
                📝
              </div>
            </div>
            <div className="md:w-1/2">
              <Badge color="amber">Featured</Badge>
              <h3 className="text-2xl font-bold text-slate-900 mt-3 mb-3">{featuredPost.title}</h3>
              <p className="text-slate-600 leading-relaxed mb-4">{featuredPost.excerpt}</p>
              <div className="flex items-center gap-4 text-sm text-slate-500">
                <span>{new Date(featuredPost.publishedAt).toLocaleDateString()}</span>
                <Badge color="blue">{featuredPost.category}</Badge>
              </div>
            </div>
          </Card>
        </div>
      )}

      {/* Post Grid */}
      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
        {filteredPosts.map((post) => (
          <Card key={post._id} className="flex flex-col">
            <div className="aspect-video bg-gradient-to-br from-slate-100 to-slate-200 rounded-xl mb-4 flex items-center justify-center text-4xl">
              📝
            </div>
            <div className="flex items-center gap-2 mb-3">
              <Badge color="blue">{post.category}</Badge>
              <span className="text-xs text-slate-400">
                {new Date(post.publishedAt).toLocaleDateString()}
              </span>
            </div>
            <h3 className="text-lg font-bold text-slate-900 mb-2">{post.title}</h3>
            <p className="text-slate-600 text-sm leading-relaxed mb-4 flex-grow">
              {post.excerpt}
            </p>
            <a 
              href={`/blog/${post.slug.current}`}
              className="text-blue-600 font-medium text-sm hover:text-blue-800"
            >
              Read Article →
            </a>
          </Card>
        ))}
      </div>
    </Section>
  );
}

export default Blog;
```

### Step 7: Add Blog to Your App
Update `src/App.jsx`:
```jsx
import Navbar from './components/sections/Navbar';
import Hero from './components/sections/Hero';
import About from './components/sections/About';
import Projects from './components/sections/Projects';
import Blog from './components/sections/Blog';        // NEW
import Contact from './components/sections/Contact';
import Footer from './components/sections/Footer';

function App() {
  return (
    <div className="antialiased">
      <Navbar />
      <Hero />
      <About />
      <Projects />
      <Blog />                                          // NEW
      <Contact />
      <Footer />
    </div>
  );
}

export default App;
```

**Check your browser!** Your blog posts from Sanity should now appear.

---

## Part 8: Making It Interactive

### Smooth Scrolling
Add this to your `src/index.css`:
```css
@import "tailwindcss";

html {
  scroll-behavior: smooth;
}
```

This makes all anchor links (`#about`, `#projects`, etc.) scroll smoothly instead of jumping instantly.

### Individual Blog Post Pages (Optional but Recommended)
For full articles, we need separate pages. Update `src/App.jsx`:

```jsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Navbar from './components/sections/Navbar';
import Hero from './components/sections/Hero';
import About from './components/sections/About';
import Projects from './components/sections/Projects';
import Blog from './components/sections/Blog';
import Contact from './components/sections/Contact';
import Footer from './components/sections/Footer';
import BlogPost from './components/sections/BlogPost';

function HomePage() {
  return (
    <>
      <Hero />
      <About />
      <Projects />
      <Blog />
      <Contact />
    </>
  );
}

function App() {
  return (
    <BrowserRouter>
      <div className="antialiased">
        <Navbar />
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/blog/:slug" element={<BlogPost />} />
        </Routes>
        <Footer />
      </div>
    </BrowserRouter>
  );
}

export default App;
```

Create `src/components/sections/BlogPost.jsx`:
```jsx
import { useParams } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { PortableText } from '@portabletext/react';
import client from '../../lib/sanity';

function BlogPost() {
  const { slug } = useParams();
  const [post, setPost] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const query = `*[_type == "post" && slug.current == $slug][0] {
      title,
      content,
      publishedAt,
      category
    }`;
    
    client.fetch(query, { slug })
      .then((data) => {
        setPost(data);
        setLoading(false);
      });
  }, [slug]);

  if (loading) return <div className="pt-32 text-center">Loading...</div>;
  if (!post) return <div className="pt-32 text-center">Post not found</div>;

  return (
    <article className="pt-24 pb-20 px-4 max-w-3xl mx-auto">
      <span className="text-sm font-medium text-blue-600 uppercase">{post.category}</span>
      <h1 className="text-3xl sm:text-4xl font-bold text-slate-900 mt-2 mb-4">{post.title}</h1>
      <p className="text-slate-500 text-sm mb-8">
        {new Date(post.publishedAt).toLocaleDateString()}
      </p>
      
      <div className="prose prose-slate max-w-none">
        <PortableText value={post.content} />
      </div>
      
      <a href="/" className="inline-block mt-12 text-blue-600 hover:text-blue-800">
        ← Back to all posts
      </a>
    </article>
  );
}

export default BlogPost;
```

---

## Part 9: Publishing to the Internet

### Step 1: Create a GitHub Account
1. Go to [github.com](https://github.com)
2. Sign up for a free account

### Step 2: Create a Repository
1. Click the **+** icon → **New repository**
2. Name it `sean-portfolio`
3. Make it **Public**
4. Click **Create repository**

### Step 3: Upload Your Code
In your terminal (inside `sean-portfolio`):
```bash
git init
git add .
git commit -m "Initial portfolio website"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/sean-portfolio.git
git push -u origin main
```

**What this does:**
- `git init` — Starts tracking your files
- `git add .` — Selects all files
- `git commit` — Saves a snapshot
- `git remote add origin` — Connects to GitHub
- `git push` — Uploads everything

### Step 4: Deploy to Vercel
1. Go to [vercel.com](https://vercel.com)
2. Sign up with your GitHub account
3. Click **Add New Project**
4. Find `sean-portfolio` and click **Import**
5. In settings:
   - **Framework Preset:** Vite
   - **Build Command:** `npm run build`
   - **Output Directory:** `dist`
6. Add environment variables:
   - `VITE_SANITY_PROJECT_ID` = your Sanity project ID
   - `VITE_SANITY_DATASET` = production
7. Click **Deploy**

**Your website is now live!** Vercel gives you a URL like `sean-portfolio.vercel.app`

### Step 5: Automatic Updates
Whenever you update your code:
```bash
git add .
git commit -m "Updated something"
git push
```
Vercel automatically redeploys!

---

## 🎉 Congratulations!

You built a complete portfolio website with:
- ✅ React components
- ✅ Tailwind CSS styling
- ✅ AI project showcase
- ✅ Blog powered by Sanity CMS
- ✅ Live on the internet

### What to Do Next
1. **Replace placeholder content** — Add your real projects, email, LinkedIn
2. **Write 3 blog posts** — Use Sanity Studio
3. **Add your photo** — Put it in the `public` folder
4. **Buy a custom domain** — In Vercel settings

### Troubleshooting

| Problem | Solution |
|---------|----------|
| `npm run dev` doesn't work | Make sure you're in the `sean-portfolio` folder |
| Changes not showing | Save the file (Ctrl+S) |
| Blog posts not loading | Check your Sanity Project ID |
| Git push fails | Make sure you committed first (`git commit`) |
| Vercel build fails | Check the build logs in Vercel dashboard |

---

**Need help?** The communities for [React](https://react.dev), [Tailwind](https://tailwindcss.com), and [Sanity](https://www.sanity.io) are very beginner-friendly.
