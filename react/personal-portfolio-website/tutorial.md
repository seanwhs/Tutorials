# 🚀 Complete Guide: Build an AI-Focused Portfolio + Blog with React, Tailwind CSS, Sanity CMS & Vercel

## Table of Contents
- [Part 1: Project Setup (Vite + React + Tailwind v4)](#part-1-project-setup)
- [Part 2: Tailwind Fundamentals for Beginners](#part-2-tailwind-fundamentals)
- [Part 3: Building Reusable UI Components](#part-3-building-reusable-ui-components)
- [Part 4: Core Portfolio Sections](#part-4-core-portfolio-sections)
- [Part 5: AI Projects Showcase](#part-5-ai-projects-showcase)
- [Part 6: Blog with Sanity CMS](#part-6-blog-with-sanity-cms)
- [Part 7: Smooth Scrolling & Interactivity](#part-7-smooth-scrolling--interactivity)
- [Part 8: Publishing to GitHub](#part-8-publishing-to-github)
- [Part 9: Deploying to Vercel](#part-9-deploying-to-vercel)

---

## Part 1: Project Setup

### Prerequisites
1. **Node.js** — [nodejs.org](https://nodejs.org) (LTS version)
2. **Visual Studio Code** — [code.visualstudio.com](https://code.visualstudio.com)
3. **VS Code Extensions:**
   - Tailwind CSS IntelliSense
   - ES7+ React snippets

### Step 1: Create Project with Vite
```bash
npm create vite@latest sean-portfolio -- --template react
cd sean-portfolio
npm install
```

### Step 2: Install Tailwind CSS v4
```bash
npm install tailwindcss @tailwindcss/vite
```

### Step 3: Configure Vite
`vite.config.js`:
```js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
})
```

### Step 4: Import Tailwind
`src/index.css`:
```css
@import "tailwindcss";
```

### Step 5: Start Dev Server
```bash
npm run dev
```
Open `http://localhost:5173`

---

## Part 2: Tailwind Fundamentals for Beginners

Tailwind is a **utility-first** CSS framework. Instead of writing CSS files, you add classes directly to your HTML/JSX.

**Example:**
```jsx
// Instead of this CSS:
// .button { background: blue; padding: 10px 20px; border-radius: 8px; }

// You write this:
<button className="bg-blue-600 px-5 py-2.5 rounded-lg text-white font-medium">
  Click Me
</button>
```

**Why it works:** Tailwind scans your files at build time and only includes the CSS you actually use. Your bundle stays tiny. 

### Key Concepts

| Concept | Explanation | Example |
|---------|-------------|---------|
| **Utility Class** | A single-purpose class | `text-center`, `bg-red-500` |
| **Responsive Prefix** | Applies at a screen width | `md:flex` (flex at 768px+) |
| **Hover State** | Applies on mouse hover | `hover:bg-blue-700` |
| **Dark Mode** | Applies in dark mode | `dark:bg-slate-900` |
| **Arbitrary Values** | Custom values in brackets | `w-[100px]`, `text-[#1a1a2e]` |

**Responsive breakpoints (mobile-first):**
- `sm:` — 640px+
- `md:` — 768px+
- `lg:` — 1024px+
- `xl:` — 1280px+

---
## Part 3: Scaffold

**File Structure**

```
src/
├── components/
│   ├── ui/
│   │   ├── Button.jsx
│   │   ├── Card.jsx
│   │   ├── Section.jsx
│   │   └── Badge.jsx
│   └── sections/
│       ├── Navbar.jsx
│       ├── Hero.jsx
│       ├── About.jsx
│       └── Projects.jsx
├── lib/
│   └── sanity.js
└── App.jsx
```

**App.jsx**
`src/App.jsx`:
```
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Navbar from './components/sections/Navbar';
import Hero from './components/sections/Hero';
import About from './components/sections/About';
import Projects from './components/sections/Projects';
import Footer from './components/sections/Footer';

function HomePage() {
  return (
    <>
      <Hero />
      <About />
      <Projects />
      {/* Add <Blog /> here once implemented */}
    </>
  );
}

function App() {
  return (
    <BrowserRouter>
      <div className="antialiased text-slate-900 bg-white">
        <Navbar />
        <Routes>
          <Route path="/" element={<HomePage />} />
          {/* <Route path="/blog/:slug" element={<BlogPost />} /> */}
        </Routes>
        <Footer />
      </div>
    </BrowserRouter>
  );
}

export default App;
```
---

## Part 4: Building Reusable UI Components

Create the folder structure:
```
src/components/
├── ui/           # Primitive components
└── sections/     # Page sections
```

### Button Component
`src/components/ui/Button.jsx`:
```jsx
function Button({ children, variant = 'primary', href, onClick }) {
  const base = "inline-flex items-center justify-center px-6 py-3 rounded-xl font-semibold transition-all duration-200";
  
  const variants = {
    primary: "bg-slate-900 text-white hover:bg-slate-800 hover:shadow-lg hover:-translate-y-0.5",
    secondary: "bg-white text-slate-900 border-2 border-slate-200 hover:border-slate-900",
    outline: "bg-transparent text-slate-900 border-2 border-slate-900 hover:bg-slate-900 hover:text-white",
    ghost: "bg-transparent text-slate-600 hover:text-slate-900 hover:bg-slate-100"
  };

  const classes = `${base} ${variants[variant]}`;

  if (href) return <a href={href} className={classes}>{children}</a>;
  return <button onClick={onClick} className={classes}>{children}</button>;
}

export default Button;
```

### Section Wrapper
`src/components/ui/Section.jsx`:
```jsx
function Section({ children, className = "", id }) {
  return (
    <section id={id} className={`py-20 px-4 sm:px-6 lg:px-8 ${className}`}>
      <div className="max-w-6xl mx-auto">{children}</div>
    </section>
  );
}

export default Section;
```

### Badge Component
`src/components/ui/Badge.jsx`:
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

### Card Component
`src/components/ui/Card.jsx`:
```jsx
function Card({ children, className = "", hover = true }) {
  return (
    <div className={`bg-white rounded-2xl border border-slate-200 p-6 ${hover ? 'hover:shadow-xl hover:-translate-y-1 transition-all duration-300' : ''} ${className}`}>
      {children}
    </div>
  );
}

export default Card;
```

---

## Part 5: Core Portfolio Sections

### Navbar
`src/components/sections/Navbar.jsx`:
```jsx
import { useState } from 'react';

function Navbar() {
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
          <a href="#home" className="text-xl font-bold text-slate-900 tracking-tight">
            Sean Wong
          </a>

          <div className="hidden md:flex items-center space-x-8">
            {links.map((link) => (
              <a key={link.name} href={link.href} className="text-slate-600 hover:text-slate-900 font-medium transition-colors">
                {link.name}
              </a>
            ))}
            <a href="#contact" className="bg-slate-900 text-white px-5 py-2 rounded-lg font-medium hover:bg-slate-800 transition-colors">
              Let's Talk
            </a>
          </div>

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

        {isOpen && (
          <div className="md:hidden py-4 border-t border-slate-100">
            {links.map((link) => (
              <a key={link.name} href={link.href} onClick={() => setIsOpen(false)} className="block py-3 text-slate-600 hover:text-slate-900 font-medium">
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

### Hero Section
`src/components/sections/Hero.jsx`:
```jsx
import Button from '../ui/Button';

function Hero() {
  return (
    <section id="home" className="min-h-screen flex items-center pt-16 bg-gradient-to-br from-slate-50 via-white to-blue-50/30">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="max-w-3xl">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-blue-50 text-blue-700 text-sm font-medium mb-6">
            <span className="w-2 h-2 rounded-full bg-blue-500 animate-pulse" />
            Enterprise Architect → Independent Developer
          </div>
          
          <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-slate-900 leading-tight mb-6">
            Building <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-purple-600">AI-native</span> digital platforms with architectural rigor
          </h1>
          
          <p className="text-lg sm:text-xl text-slate-600 leading-relaxed mb-8 max-w-2xl">
            Decades of enterprise architecture experience, now focused on full-stack development, 
            cloud-native systems, and AI-augmented engineering. I help teams ship faster without shipping fragile.
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

### About Section
`src/components/sections/About.jsx`:
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
              After decades designing systems for global enterprises — from HP and Huawei to Accenture and QuestGlobal — 
              I've pivoted to independent consulting and development. I bring the strategic thinking of an enterprise architect 
              combined with the practical velocity of a full-stack developer.
            </p>
            <p>
              I specialize in modern web platforms using React, Next.js, and cloud-native stacks, augmented with AI tools 
              like VS Code Continue.dev and Opencode CLI. My "vibe coding" approach blends rapid iteration with strong 
              architectural governance — because AI-generated code still needs human judgment.
            </p>
            <p>
              Based in Singapore, I'm passionate about facilitating world-class digital transformation and grooming 
              the next generation of digital leaders through consulting and ACTA-certified technical training.
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

### Footer Section
`src/components/sections/Footer.jsx`:
```jsx
function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="bg-slate-50 border-t border-slate-200 py-12">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col md:flex-row justify-between items-center gap-6">
          {/* Branding */}
          <div>
            <a href="#home" className="text-xl font-bold text-slate-900 tracking-tight">
              Sean Wong
            </a>
            <p className="text-slate-500 text-sm mt-1">
              Enterprise Architect & Independent Developer
            </p>
          </div>

          {/* Copyright */}
          <div className="text-slate-500 text-sm">
            © {currentYear} Sean Wong. All rights reserved.
          </div>

          {/* Social / Links */}
          <div className="flex space-x-6">
            <a href="https://github.com" target="_blank" rel="noreferrer" className="text-slate-400 hover:text-slate-900 transition-colors">
              GitHub
            </a>
            <a href="https://linkedin.com" target="_blank" rel="noreferrer" className="text-slate-400 hover:text-slate-900 transition-colors">
              LinkedIn
            </a>
            <a href="mailto:your-email@example.com" className="text-slate-400 hover:text-slate-900 transition-colors">
              Email
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}

export default Footer;
```

---

## Part 6: AI Projects Showcase

This is where you showcase your AI-integrated projects. Each project card includes the tech stack, AI features, and links to live demos or GitHub.

`src/components/sections/Projects.jsx`:
```jsx
import Section from '../ui/Section';
import Card from '../ui/Card';
import Badge from '../ui/Badge';

function Projects() {
  const projects = [
    {
      title: 'AI-Powered Document Analyzer',
      description: 'An intelligent document processing system that extracts insights from PDFs and images using LLM vision models. Features automated summarization, entity extraction, and semantic search.',
      image: '📄',
      status: 'Live',
      aiFeatures: ['LLM Vision', 'RAG Pipeline', 'Semantic Search'],
      tech: ['Next.js 14', 'OpenAI API', 'Pinecone', 'PostgreSQL', 'Tailwind CSS'],
      demoUrl: '#',
      githubUrl: '#',
      category: 'AI Application'
    },
    {
      title: 'Smart Workflow Automation Platform',
      description: 'A no-code workflow builder with AI-assisted node configuration. Users describe what they want in natural language, and the system generates the workflow graph automatically.',
      image: '⚡',
      status: 'In Development',
      aiFeatures: ['Natural Language to Workflow', 'Auto-Error Recovery', 'Predictive Scheduling'],
      tech: ['React', 'n8n', 'LangChain', 'Appwrite', 'TypeScript'],
      demoUrl: '#',
      githubUrl: '#',
      category: 'Automation'
    },
    {
      title: 'AI Code Review Assistant',
      description: 'A VS Code extension that provides intelligent code reviews, security vulnerability detection, and architectural pattern suggestions using fine-tuned models.',
      image: '🔍',
      status: 'Open Source',
      aiFeatures: ['Security Scanning', 'Pattern Recognition', 'Refactoring Suggestions'],
      tech: ['TypeScript', 'VS Code API', 'Ollama', 'Continue.dev', 'Node.js'],
      demoUrl: '#',
      githubUrl: '#',
      category: 'Developer Tool'
    },
    {
      title: 'Conversational Analytics Dashboard',
      description: 'Real-time analytics platform that processes natural language queries into SQL, generating interactive dashboards without writing a single line of code.',
      image: '📊',
      status: 'Live',
      aiFeatures: ['NL-to-SQL', 'Auto-Visualization', 'Anomaly Detection'],
      tech: ['Next.js', 'Sanity CMS', 'Neon DB', 'Recharts', 'Clerk Auth'],
      demoUrl: '#',
      githubUrl: '#',
      category: 'Data & Analytics'
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
          Each project demonstrates architectural thinking applied to AI-native engineering.
        </p>
      </div>

      <div className="grid md:grid-cols-2 gap-8">
        {projects.map((project) => (
          <Card key={project.title} className="overflow-hidden">
            <div className="flex items-start justify-between mb-4">
              <div className="text-4xl">{project.image}</div>
              <Badge color={project.status === 'Live' ? 'green' : project.status === 'Open Source' ? 'blue' : 'amber'}>
                {project.status}
              </Badge>
            </div>
            
            <div className="mb-3">
              <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">{project.category}</span>
            </div>
            
            <h3 className="text-xl font-bold text-slate-900 mb-3">{project.title}</h3>
            <p className="text-slate-600 leading-relaxed mb-4">{project.description}</p>
            
            <div className="mb-4">
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">AI Features</p>
              <div className="flex flex-wrap gap-2">
                {project.aiFeatures.map((feature) => (
                  <span key={feature} className="text-xs px-2 py-1 bg-purple-50 text-purple-700 rounded-md font-medium">
                    {feature}
                  </span>
                ))}
              </div>
            </div>
            
            <div className="mb-6">
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Tech Stack</p>
              <div className="flex flex-wrap gap-2">
                {project.tech.map((t) => (
                  <span key={t} className="text-xs px-2 py-1 bg-slate-100 text-slate-600 rounded-md">
                    {t}
                  </span>
                ))}
              </div>
            </div>
            
            <div className="flex gap-3 pt-4 border-t border-slate-100">
              <a href={project.demoUrl} className="flex-1 text-center py-2 bg-slate-900 text-white rounded-lg text-sm font-medium hover:bg-slate-800 transition-colors">
                Live Demo
              </a>
              <a href={project.githubUrl} className="flex-1 text-center py-2 border border-slate-200 text-slate-700 rounded-lg text-sm font-medium hover:border-slate-900 hover:text-slate-900 transition-colors">
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

---

## Part 7: Blog with Sanity CMS

Sanity is a headless CMS — you write content in a structured studio, and your React app fetches it via API. This means:
- **No code changes** when publishing new articles
- **Rich text editing** with images, code blocks, and embeds
- **Structured content** — categories, tags, authors, publish dates
- **Future-proof** — redesign your site without migrating content 

### Step 1: Set Up Sanity Studio

Create a separate folder for your Sanity project (best practice: keep CMS and frontend separate):

```bash
# In your project root, create a new folder
mkdir sanity-blog
cd sanity-blog
npm create sanity@latest -- --template clean --create-project "Sean Wong Blog" --dataset production
```

Follow the prompts to create your Sanity project. This will:
- Create a Sanity project in your Sanity.io account
- Set up a local studio
- Configure API keys

### Step 2: Define Your Content Schema
`sanity-blog/schemaTypes/post.ts`:
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
      title: 'Slug',
      type: 'slug',
      options: {
        source: 'title',
        maxLength: 96,
      },
      validation: (Rule) => Rule.required()
    },
    {
      name: 'excerpt',
      title: 'Excerpt',
      type: 'text',
      rows: 3,
      validation: (Rule) => Rule.required().max(300)
    },
    {
      name: 'content',
      title: 'Content',
      type: 'array',
      of: [
        { type: 'block' },           // Rich text paragraphs
        { type: 'image' },            // Images
        { 
          type: 'code',               // Code blocks
          options: { withFilename: true }
        }
      ]
    },
    {
      name: 'coverImage',
      title: 'Cover Image',
      type: 'image',
      options: { hotspot: true }
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
      title: 'Published At',
      type: 'datetime',
      validation: (Rule) => Rule.required()
    },
    {
      name: 'featured',
      title: 'Featured Post',
      type: 'boolean',
      initialValue: false
    }
  ],
  preview: {
    select: {
      title: 'title',
      category: 'category',
      publishedAt: 'publishedAt'
    },
    prepare({ title, category, publishedAt }) {
      return {
        title,
        subtitle: `${category} • ${new Date(publishedAt).toLocaleDateString()}`
      };
    }
  }
}
```

### Step 3: Start Sanity Studio
```bash
cd sanity-blog
npm run dev
```
Open `http://localhost:3333` — this is your content management interface. Create a few sample posts to test with.

### Step 4: Connect Sanity to Your React App

In your **frontend** project (`sean-portfolio`), install the Sanity client:

```bash
npm install @sanity/client @sanity/image-url
```

Create `src/lib/sanity.js`:
```javascript
import { createClient } from '@sanity/client';
import imageUrlBuilder from '@sanity/image-url';

const client = createClient({
  projectId: 'YOUR_PROJECT_ID',      // From sanity.config.ts or Sanity dashboard
  dataset: 'production',
  apiVersion: '2026-06-28',            // Use current date
  useCdn: true,                        // true for production, false for fresh data
});

const builder = imageUrlBuilder(client);

export function urlFor(source) {
  return builder.image(source);
}

export default client;
```

**Find your Project ID:** In your Sanity dashboard (sanity.io/manage), select your project. The ID is in the project settings.

### Step 5: Create Blog Components

**Blog Listing Section** — `src/components/sections/Blog.jsx`:
```jsx
import { useState, useEffect } from 'react';
import Section from '../ui/Section';
import Card from '../ui/Card';
import Badge from '../ui/Badge';
import client from '../../lib/sanity';

function Blog() {
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeCategory, setActiveCategory] = useState('all');

  const categories = [
    { id: 'all', label: 'All Posts' },
    { id: 'opinion', label: 'Opinion' },
    { id: 'tutorial', label: 'Tutorials' },
    { id: 'ai-engineering', label: 'AI Engineering' },
    { id: 'architecture', label: 'Architecture' },
  ];

  useEffect(() => {
    const query = `*[_type == "post"] | order(publishedAt desc) {
      _id,
      title,
      slug,
      excerpt,
      category,
      tags,
      publishedAt,
      featured
    }`;
    
    client.fetch(query).then((data) => {
      setPosts(data);
      setLoading(false);
    });
  }, []);

  const filteredPosts = activeCategory === 'all' 
    ? posts 
    : posts.filter(post => post.category === activeCategory);

  const featuredPost = posts.find(post => post.featured);

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

      {/* Category Filter */}
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

      {/* Featured Post */}
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
                <span>{new Date(featuredPost.publishedAt).toLocaleDateString('en-US', { 
                  year: 'numeric', month: 'long', day: 'numeric' 
                })}</span>
                <span>•</span>
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
                {new Date(post.publishedAt).toLocaleDateString('en-US', { 
                  month: 'short', day: 'numeric' 
                })}
              </span>
            </div>
            <h3 className="text-lg font-bold text-slate-900 mb-2 line-clamp-2">{post.title}</h3>
            <p className="text-slate-600 text-sm leading-relaxed mb-4 line-clamp-3 flex-grow">
              {post.excerpt}
            </p>
            <a 
              href={`/blog/${post.slug.current}`}
              className="text-blue-600 font-medium text-sm hover:text-blue-800 transition-colors inline-flex items-center gap-1"
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

### Step 6: Individual Blog Post Page (Optional Advanced)

For full blog post pages, you'll need a router. Install React Router:

```bash
npm install react-router-dom
```

Update `src/App.jsx` to use routing:

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
import client, { urlFor } from '../../lib/sanity';

function BlogPost() {
  const { slug } = useParams();
  const [post, setPost] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const query = `*[_type == "post" && slug.current == $slug][0] {
      title,
      content,
      coverImage,
      publishedAt,
      category,
      tags
    }`;
    
    client.fetch(query, { slug }).then((data) => {
      setPost(data);
      setLoading(false);
    });
  }, [slug]);

  if (loading) return <div className="pt-32 text-center">Loading...</div>;
  if (!post) return <div className="pt-32 text-center">Post not found</div>;

  return (
    <article className="pt-24 pb-20 px-4 sm:px-6 lg:px-8 max-w-3xl mx-auto">
      <div className="mb-8">
        <span className="text-sm font-medium text-blue-600 uppercase tracking-wider">{post.category}</span>
        <h1 className="text-3xl sm:text-4xl font-bold text-slate-900 mt-2 mb-4">{post.title}</h1>
        <div className="flex items-center gap-4 text-slate-500 text-sm">
          <span>{new Date(post.publishedAt).toLocaleDateString('en-US', { 
            year: 'numeric', month: 'long', day: 'numeric' 
          })}</span>
        </div>
      </div>
      
      {post.coverImage && (
        <img 
          src={urlFor(post.coverImage).width(800).url()} 
          alt={post.title}
          className="w-full rounded-2xl mb-8"
        />
      )}
      
      <div className="prose prose-slate max-w-none">
        <PortableText value={post.content} />
      </div>
    </article>
  );
}

export default BlogPost;
```

Install Portable Text renderer:
```bash
npm install @portabletext/react
```

---

## Part 8: Smooth Scrolling & Interactivity

Install react-scroll for smooth navigation:
```bash
npm install react-scroll
```

Update `Navbar.jsx` links to use smooth scroll. For the router version, use `<Link>` from react-router-dom for blog links and react-scroll for section links.

---

## Part 9: Publishing to GitHub

### Step 1: Create Repository
1. Go to [github.com](https://github.com) → **New repository**
2. Name: `sean-portfolio`
3. Make it **Public**
4. Click **Create repository**

### Step 2: Push Your Code
```bash
git init
git add .
git commit -m "Initial portfolio with AI projects and Sanity blog"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/sean-portfolio.git
git push -u origin main
```

### Step 3: Push Sanity Studio (Separate Repo)
```bash
cd sanity-blog
git init
git add .
git commit -m "Sanity CMS for blog"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/sean-blog-cms.git
git push -u origin main
```

---

## Part 10: Deploying to Vercel

### Frontend Deployment
1. Go to [vercel.com](https://vercel.com) → Sign up with GitHub
2. **Add New Project** → Import `sean-portfolio`
3. **Framework Preset**: Vite
4. **Build Command**: `npm run build`
5. **Output Directory**: `dist`
6. Add environment variables:
   - `VITE_SANITY_PROJECT_ID` = your Sanity project ID
   - `VITE_SANITY_DATASET` = production
7. Click **Deploy**

### Sanity Studio Deployment
1. In your Sanity project folder:
```bash
npm install -g @sanity/cli
sanity deploy
```
This deploys your studio to `https://your-project.sanity.studio`

### Automatic Updates
Every `git push` to your frontend repo triggers a Vercel redeploy. Every new post in Sanity appears instantly on your site.

---

## 🎉 Your AI-Focused Portfolio + Blog is Live!

You now have:
- ✅ Professional portfolio with React + Tailwind CSS + Vite
- ✅ AI Projects showcase with tech stacks and live demos
- ✅ Blog powered by Sanity CMS (write without coding)
- ✅ Category filtering and featured posts
- ✅ Individual blog post pages with rich text
- ✅ Responsive design across all devices
- ✅ Automatic deployment on Vercel

### Next Steps
1. **Add real project screenshots** — Replace emoji placeholders with actual images
2. **Write your first 3 blog posts** — Use Sanity Studio to publish opinion pieces and tutorials
3. **Add a newsletter signup** — Use ConvertKit or Buttondown
4. **Add analytics** — Plausible or Fathom for privacy-friendly tracking
5. **Add comments** — Giscus (GitHub Discussions) or Disqus

### Sanity Content Tips
- Use **code blocks** in Sanity for tutorial posts (syntax highlighting included)
- Add **images** with captions for visual tutorials
- Use **tags** for cross-referencing related topics
- Set **featured** flag for posts you want to highlight

---

**Resources:**
- [Sanity Documentation](https://www.sanity.io/docs)
- [Tailwind CSS v4](https://tailwindcss.com/docs)
- [React Router](https://reactrouter.com)
- [Vercel Deployment](https://vercel.com/kb/guide/deploying-react-with-vercel) 

Welcome to your independent developer journey, Sean! 🚀
