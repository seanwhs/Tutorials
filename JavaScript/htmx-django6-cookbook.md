# 🥘 HTMX + Django 6 Cookbook: 20+ Patterns for Real-World Apps

> Server-driven interactivity made simple — minimal JavaScript, maximal productivity, progressive enhancement.

---

## **1. Load Content on Click**

**Use case:** Load a section dynamically without refreshing the page.

```html
<button hx-get="{% url 'load-comments' %}" hx-target="#comments" hx-swap="innerHTML">
    Load Comments
</button>
<div id="comments"></div>
```

```python
def load_comments(request):
    comments = Comment.objects.all()
    return render(request, "partials/comments_list.html", {"comments": comments})
```

**Best practice:** Use partial templates for fragments.
**Pitfall:** Returning a full HTML page breaks the swap.

---

## **2. Submit Form Without Page Reload**

```html
<form hx-post="{% url 'add-comment' %}" hx-target="#comments" hx-swap="beforeend">
    {% csrf_token %}
    <input type="text" name="text" placeholder="Add a comment">
    <button type="submit">Submit</button>
</form>
```

```python
def add_comment(request):
    text = request.POST.get("text")
    comment = Comment.objects.create(text=text)
    return render(request, "partials/comment_item.html", {"comment": comment})
```

**Best practice:** Return only the new item fragment.
**Pitfall:** Missing CSRF token breaks POST requests.

---

## **3. Infinite Scrolling / Pagination**

```html
<div id="posts" hx-get="{% url 'posts-page' page=1 %}" hx-trigger="revealed" hx-swap="afterend"></div>
```

```python
from django.core.paginator import Paginator

def posts_page(request, page):
    posts = Post.objects.all()
    paginator = Paginator(posts, 5)
    page_obj = paginator.get_page(page)
    return render(request, "partials/posts_list.html", {"posts": page_obj})
```

**Best practice:** Render only the next batch.
**Pitfall:** Re-rendering the full page resets scroll position.

---

## **4. Live Search / Filtering**

```html
<input type="text" hx-get="{% url 'search-posts' %}" hx-trigger="keyup changed delay:500ms" hx-target="#results">
<div id="results"></div>
```

```python
from django.db.models import Q

def search_posts(request):
    q = request.GET.get("q", "")
    results = Post.objects.filter(Q(title__icontains=q) | Q(body__icontains=q))
    return render(request, "partials/posts_list.html", {"posts": results})
```

**Best practice:** Debounce input with `delay:500ms`.
**Pitfall:** Returning a full page instead of a fragment breaks dynamic filtering.

---

## **5. Delete Item With HTMX**

```html
<button hx-get="{% url 'delete-comment' comment.id %}" hx-target="#comment-{{ comment.id }}" hx-swap="delete">
    Delete
</button>
```

```python
def delete_comment(request, pk):
    Comment.objects.filter(pk=pk).delete()
    return HttpResponse(status=204)
```

**Best practice:** Use `hx-swap="delete"` for smooth removal.
**Pitfall:** Targeting the wrong element removes unintended content.

---

## **6. HTMX Redirect After Action**

```python
response = HttpResponse()
response['HX-Redirect'] = '/dashboard/'
return response
```

**Best practice:** Use `HX-Redirect` for post-action navigation.
**Pitfall:** Standard 302 redirects break `hx-post` swaps.

---

## **7. Toggle Visibility (Collapse / Expand)**

```html
<button hx-get="{% url 'toggle-details' item.id %}" hx-target="#details-{{ item.id }}" hx-swap="innerHTML">
    Show Details
</button>
<div id="details-{{ item.id }}"></div>
```

**Best practice:** Render only the detail section dynamically.
**Pitfall:** Swapping outerHTML may replace the button itself.

---

## **8. Inline Editing (Edit in Place)**

```html
<span hx-get="{% url 'edit-comment' comment.id %}" hx-target="#comment-text-{{ comment.id }}" hx-swap="outerHTML">
    {{ comment.text }}
</span>
```

```python
def edit_comment(request, pk):
    comment = Comment.objects.get(pk=pk)
    return render(request, "partials/edit_comment_form.html", {"comment": comment})
```

**Best practice:** Keep a reusable partial for edit forms.
**Pitfall:** Forgetting `hx-swap="outerHTML"` embeds the form inside the text span.

---

## **9. Form Validation Feedback**

```html
<form hx-post="{% url 'add-comment' %}" hx-target="#form-errors" hx-swap="innerHTML">
    {% csrf_token %}
    {{ form.as_p }}
    <div id="form-errors"></div>
    <button type="submit">Submit</button>
</form>
```

```python
def add_comment(request):
    form = CommentForm(request.POST)
    if form.is_valid():
        form.save()
        return render(request, "partials/comment_item.html", {"comment": form.instance})
    return render(request, "partials/form_errors.html", {"form": form})
```

**Best practice:** Return only validation errors to the target.
**Pitfall:** Returning the full page breaks dynamic swapping.

---

## **10. Modal Dialog With HTMX**

```html
<button hx-get="{% url 'open-modal' %}" hx-target="#modal" hx-trigger="click">
    Open Modal
</button>
<div id="modal"></div>
```

**Best practice:** Keep modal container outside main content.
**Pitfall:** Swapping innerHTML can destroy event listeners.

---

## **11. Server-Rendered Tabs**

```html
<ul class="tabs">
    <li hx-get="{% url 'tab-content' 'tab1' %}" hx-target="#tab-panel" hx-swap="innerHTML">Tab 1</li>
    <li hx-get="{% url 'tab-content' 'tab2' %}" hx-target="#tab-panel" hx-swap="innerHTML">Tab 2</li>
</ul>
<div id="tab-panel"></div>
```

**Best practice:** Render only tab content dynamically.
**Pitfall:** Returning the full page breaks tabs.

---

## **12. Pagination Links (Server-Side)**

```html
<a hx-get="{% url 'posts-page' page=page_obj.next_page_number %}" hx-target="#posts" hx-swap="afterend">Next</a>
```

**Best practice:** Preserve current query parameters in links.
**Pitfall:** Standard `<a>` without `hx-get` reloads the full page.

---

## **13. Conditional Rendering (Show/Hide Sections)**

```html
<div hx-get="{% url 'load-section' %}" hx-target="#section" hx-swap="innerHTML"></div>
```

**Best practice:** Server-side rendering ensures light DOM.
**Pitfall:** Hiding via JS keeps heavy HTML in the DOM.

---

## **14. Server-Side Sorting**

```html
<th hx-get="{% url 'sort-posts' 'title' %}" hx-target="#posts" hx-swap="innerHTML">Title</th>
```

**Best practice:** Swap only the table body.
**Pitfall:** Sorting full page causes layout jumps.

---

## **15. Nested HTMX Requests**

```html
<div hx-get="{% url 'parent-item' item.id %}" hx-target="#child-items" hx-swap="innerHTML"></div>
```

**Best practice:** Avoid deep nested swaps; keep fragments shallow.
**Pitfall:** Over-nesting causes redundant server calls.

---

## **16. CSRF in AJAX Forms**

```html
<script>
    document.body.addEventListener('htmx:configRequest', (event) => {
        event.detail.headers['X-CSRFToken'] = '{{ csrf_token }}';
    });
</script>
```

**Best practice:** Always include CSRF for POST, PATCH, DELETE requests.
**Pitfall:** Missing token results in 403 errors.

---

## **17. HTMX + Async Views (Django 6)**

```python
async def async_posts(request):
    posts = await Post.objects.all()
    return render(request, "partials/posts_list.html", {"posts": posts})
```

**Best practice:** Use async ORM queries for high throughput.
**Pitfall:** Sync code blocks the async loop.

---

## **18. History & Push URLs**

```html
<button hx-get="{% url 'load-item' item.id %}" hx-target="#content" hx-push-url="/item/{{ item.id }}">
    View Item
</button>
```

**Best practice:** Supports browser back/forward navigation.
**Pitfall:** Forgetting `hx-push-url` breaks history.

---

## **19. Client-Side Event Hooks**

```html
<div hx-get="/endpoint" hx-on="htmx:afterSwap: console.log('Swap done!')"></div>
```

**Best practice:** Use for analytics or triggering JS events.
**Pitfall:** Inline JS can become messy; prefer delegation.

---

## **20. Partial Page Refresh / Polling**

```html
<div hx-get="{% url 'live-stats' %}" hx-trigger="every 5s" hx-swap="innerHTML"></div>
```

**Best practice:** Poll for live updates without websockets.
**Pitfall:** Polling too frequently can overload the server.

---

## ✅ Advanced Patterns

* WebSocket fallback with Django Channels
* `hx-select` to update child elements within swapped content
* `hx-boost` to auto-transform links/forms
* Progressive enhancement: app remains usable with JS disabled

---

## 📂 Recommended Directory Layout

```
myapp/
├─ templates/
│  ├─ myapp/
│  │  ├─ base.html
│  │  ├─ index.html
│  │  └─ partials/
│  │     ├─ posts_list.html
│  │     ├─ comment_item.html
│  │     ├─ form_errors.html
│  │     └─ edit_comment_form.html
├─ views.py
├─ urls.py
├─ models.py
```

---

## 📊 Interactive Mermaid Reference Map

```mermaid
flowchart TD
    subgraph LEGEND[Legend]
        GET["hx-get / GET requests"]
        POST["hx-post / POST requests"]
        DELETE["hx-delete / Delete requests"]
        POLL["Polling / Interval updates"]
        ASYNC["Async view / Django 6"]
        REDIRECT["HX-Redirect / Redirect after action"]
    end

    style GET fill:#cce5ff,stroke:#004085,stroke-width:1px
    style POST fill:#d4edda,stroke:#155724,stroke-width:1px
    style DELETE fill:#f8d7da,stroke:#721c24,stroke-width:1px
    style POLL fill:#fff3cd,stroke:#856404,stroke-width:1px
    style ASYNC fill:#e2e3e5,stroke:#383d41,stroke-width:1px
    style REDIRECT fill:#d1ecf1,stroke:#0c5460,stroke-width:1px

    A[User Action]:::ASYNC

    A -->|Click| B[Load Content]:::GET
    A -->|Form Submit| C[Submit Form]:::POST
    A -->|Scroll Revealed| D[Infinite Scroll / Pagination]:::GET
    A -->|Input Keyup| E[Live Search / Filter]:::GET
    A -->|Click Delete| F[Delete Item]:::DELETE
    A -->|Post Success| G[Redirect / HX-Redirect]:::REDIRECT
    A -->|Click| H[Toggle Visibility / Collapse]:::GET
    A -->|Click| I[Inline Edit]:::GET
    A -->|Form Submit| J[Validation Feedback]:::POST
    A -->|Click| K[Open Modal]:::GET
    A -->|Click| L[Server-Rendered Tabs]:::GET
    A -->|Click| M[Pagination Links]:::GET
    A -->|Click| N[Conditional Render Section]:::GET
    A -->|Click| O[Server-Side Sorting]:::GET
    A -->|Click| P[Nested HTMX Requests]:::GET
    A -->|Form Submit / POST| Q[CSRF Handling]:::POST
    A -->|Async Call| R[Async Views / HTMX]:::ASYNC
    A -->|Click| S[Push URL / Browser History]:::GET
    A -->|Swap Complete| T[Client-Side Event Hooks]:::GET
    A -->|Every Interval| U[Partial Page Refresh / Polling]:::POLL

    B -->|hx-target| V[Partial Template]:::GET
    C -->|hx-target| V
    D -->|hx-target| V
    E -->|hx-target| V
    F -->|hx-target| V
    G -->|HX-Redirect| V
    H -->|hx-target| V
    I -->|hx-target / hx-swap="outerHTML"| V
    J -->|hx-target / hx-swap="innerHTML"| V
    K -->|hx-target| V
    L -->|hx-target| V
    M -->|hx-target / hx-swap="afterend"| V
    N -->|hx-target| V
    O -->|hx-target| V
    P -->|hx-target| V
    Q -->|CSRF Token| V
    R -->|async view| V
    S -->|hx-push-url| V
    T -->|hx-on="htmx:afterSwap"| V
    U -->|hx-trigger="every Xs"| V

    click B callback "Load only the fragment, not full page. Avoid layout shifts."
    click C callback "Always include CSRF token. Return new fragment only."
    click D callback "Use paginator and swap only next batch."
    click E callback "Debounce input. Return filtered fragment only."
    click F callback "Use hx-swap='delete' to remove element smoothly."
    click G callback "Use HX-Redirect header, avoid 302 in hx-post."
    click I callback "Use outerHTML to replace editable text."
    click U callback "Polling intervals should be reasonable to avoid server overload."
```

