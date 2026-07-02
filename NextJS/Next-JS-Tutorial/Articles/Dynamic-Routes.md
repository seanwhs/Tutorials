# Mastering Dynamic Routing in Next.js (App Router)

In modern web applications, hardcoding pages does not scale. Whether you are building a blog, SaaS dashboard, or e-commerce platform, your UI needs to respond dynamically to data and URLs.

The Next.js App Router solves this elegantly through Dynamic Route Segments, enabling you to map URL patterns directly to your file system while keeping your code declarative and scalable.

### What Are Dynamic Route Segments?

Dynamic route segments let a single page handle multiple URLs by capturing parts of the path as parameters.

Instead of creating separate files like:

- /blog/post-1  
- /blog/post-2  
- /blog/post-3  

You define a single dynamic route:

- /src/app/blog/[slug]/page.js  

This maps to:

- /blog/:slug  

When a user visits:

- /blog/my-first-post  

Next.js extracts:

- { slug: "my-first-post" }  

This value becomes available to your page, allowing you to fetch and render the correct content.

### Basic Implementation

In the App Router, dynamic params are passed automatically via the params prop.

Example:

```javascript
// src/app/blog/[slug]/page.js

export default function BlogPost({ params }) {
  const { slug } = params;

  return (
    <article>
      <h1>Blog Post: {slug}</h1>
      {/* Fetch your data here using the slug */}
    </article>
  );
}
```

In real-world usage, this component is typically a Server Component, which means you can fetch data directly inside it:

```javascript
export default async function BlogPost({ params }) {
  const post = await getPostBySlug(params.slug);

  return (
    <article>
      <h1>{post.title}</h1>
      <p>{post.content}</p>
    </article>
  );
}
```

### Static Generation with generateStaticParams

If your content is known at build time (e.g., from a CMS), you can pre-render dynamic routes using generateStaticParams:

```javascript
export async function generateStaticParams() {
  const posts = await getAllPosts();

  return posts.map(post => ({
    slug: post.slug,
  }));
}
```

This enables Static Site Generation (SSG), improving performance and SEO while still using dynamic routes.

### Nested and Advanced Routing

Dynamic segments can be composed to model more complex URL structures:

- /app/blog/[category]/[slug]/page.js → /blog/tech/nextjs-routing  
- /app/docs/[...slug]/page.js → Catch-all routes for docs systems  
- /app/shop/[[...slug]]/page.js → Optional catch-all routes  

Examples:

- [...slug] matches multiple segments: /docs/react/hooks/use-effect  
- [[...slug]] also matches the base path: /docs  

This is especially useful for documentation sites, file explorers, or deeply nested content systems.

### Key Takeaways

- File-based routing defines your URL structure; square brackets create dynamic segments.  
- params provides access to route variables inside your page or layout.  
- Dynamic routes work seamlessly with Server Components for direct data fetching.  
- generateStaticParams enables pre-rendering for better performance.  
- Catch-all routes unlock flexible, hierarchical content systems.  

### Why This Pattern Matters

Dynamic routing in Next.js is not just about convenience. It is tightly integrated into the framework’s rendering model:

- Supports SSR, SSG, and streaming out of the box  
- Eliminates manual route configuration  
- Aligns URL structure with your data model  
- Scales naturally as your application grows  

Instead of thinking in terms of “routes,” you think in terms of “data + structure.” The file system becomes a reflection of your application’s domain, which is a powerful mental model for building large-scale apps.
