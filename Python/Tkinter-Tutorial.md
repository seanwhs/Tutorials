# ⚛️ Tkinter Tutorial – Python GUI Development 

This tutorial teaches you how to build **desktop GUI applications in Python** using Tkinter, Python’s standard GUI library. It covers:

* Core widgets and layout management
* Event handling and state management (`StringVar` / `IntVar`)
* Menus, dialogs, and Canvas graphics
* Object-oriented design for scalable apps
* A **full-featured Master GUI App example**

---

## **1. Introduction to Tkinter**

Tkinter is **Python’s built-in GUI toolkit**. It allows developers to create interactive desktop applications with windows, buttons, input fields, and graphical elements.

**Capabilities of Tkinter:**

* Create windows, frames, and containers
* Use widgets like `Label`, `Button`, `Entry`, `Checkbutton`, `Radiobutton`
* Build menus, dialogs, and message boxes
* Draw graphics using `Canvas`

**Advantages:**

* Pre-installed with Python (no extra packages needed)
* Cross-platform (Windows, macOS, Linux)
* Lightweight, easy to learn, and highly customizable
* Event-driven design for interactive apps

---

## **2. Creating Your First Tkinter Window**

```python
import tkinter as tk

root = tk.Tk()  # Initialize main window
root.title("My First Tkinter App")
root.geometry("400x300")  # width x height

root.mainloop()  # Start event loop
```

**Explanation:**

* `tk.Tk()` → creates the main window
* `title()` → sets the window title
* `geometry()` → defines the window size
* `mainloop()` → keeps the app running and handles user events

> `mainloop()` continuously listens for interactions such as clicks or keyboard input.

---

## **3. Adding Widgets**

### **3.1 Labels**

```python
label = tk.Label(root, text="Hello, Tkinter!", font=("Arial", 16))
label.pack(pady=20)
```

* `Label` shows text or images.
* `pack()` arranges widgets vertically (or horizontally).
* `pady` adds vertical padding.

---

### **3.2 Buttons**

```python
def say_hello():
    label.config(text="Hello, World!")

button = tk.Button(root, text="Click Me", command=say_hello)
button.pack()
```

* `command` assigns a function executed when clicked.
* `label.config()` updates the widget dynamically.

---

### **3.3 Entry Fields**

```python
entry = tk.Entry(root)
entry.pack(pady=10)

def show_input():
    label.config(text=f"You typed: {entry.get()}")

tk.Button(root, text="Submit", command=show_input).pack()
```

* `entry.get()` retrieves user input from the field.

---

## **4. Layout Management**

Tkinter provides three layout managers:

### **4.1 Pack**

Stacks widgets vertically or horizontally.

```python
tk.Label(root, text="Top").pack(side="top")
tk.Label(root, text="Bottom").pack(side="bottom")
tk.Label(root, text="Left").pack(side="left")
tk.Label(root, text="Right").pack(side="right")
```

### **4.2 Grid**

Places widgets in rows and columns.

```python
tk.Label(root, text="Username:").grid(row=0, column=0, padx=5, pady=5)
tk.Entry(root).grid(row=0, column=1, padx=5, pady=5)
tk.Label(root, text="Password:").grid(row=1, column=0, padx=5, pady=5)
tk.Entry(root, show="*").grid(row=1, column=1, padx=5, pady=5)
```

### **4.3 Place**

Absolute positioning.

```python
tk.Label(root, text="Absolute").place(x=50, y=100)
```

> Avoid mixing layout managers in the same container.

---

## **5. Frames – Grouping Widgets**

```python
frame = tk.Frame(root, bg="lightblue", bd=2, relief="sunken")
frame.pack(padx=10, pady=10, fill="both", expand=True)

tk.Label(frame, text="Inside Frame").pack(pady=10)
tk.Button(frame, text="Click Me").pack()
```

* `bd` → border width
* `relief` → border style (`sunken`, `raised`)
* `fill="both"` & `expand=True` → resizable frame

---

## **6. Checkbuttons & Radiobuttons**

### **6.1 Checkbuttons (Multiple Selection)**

```python
var1 = tk.IntVar()
check = tk.Checkbutton(root, text="Option 1", variable=var1)
check.pack()

def show_check():
    label.config(text=f"Checked: {var1.get()}")

tk.Button(root, text="Check", command=show_check).pack()
```

* `IntVar()` stores 0 or 1.

---

### **6.2 Radiobuttons (Single Selection)**

```python
choice = tk.StringVar(value="A")
tk.Radiobutton(root, text="Option A", variable=choice, value="A").pack()
tk.Radiobutton(root, text="Option B", variable=choice, value="B").pack()

def show_choice():
    label.config(text=f"Selected: {choice.get()}")

tk.Button(root, text="Select", command=show_choice).pack()
```

* Radiobuttons share the same variable to enforce single selection.

---

## **7. Menus**

```python
menu_bar = tk.Menu(root)
root.config(menu=menu_bar)

file_menu = tk.Menu(menu_bar, tearoff=0)
file_menu.add_command(label="Open")
file_menu.add_command(label="Save")
file_menu.add_separator()
file_menu.add_command(label="Exit", command=root.quit)
menu_bar.add_cascade(label="File", menu=file_menu)
```

* `tearoff=0` disables detachable menus.
* `add_cascade` adds top-level menus.

---

## **8. Messagebox**

```python
from tkinter import messagebox

def show_message():
    messagebox.showinfo("Info", "Hello, this is a message!")

tk.Button(root, text="Show Message", command=show_message).pack()
```

* Types: `showinfo`, `showwarning`, `showerror`, `askyesno`.

---

## **9. Canvas – Graphics & Drawing**

```python
canvas = tk.Canvas(root, width=300, height=200, bg="white")
canvas.pack(pady=10)

canvas.create_line(0, 0, 300, 200, fill="blue", width=2)
canvas.create_rectangle(50, 50, 150, 100, fill="red")
canvas.create_oval(160, 50, 250, 120, fill="green")
canvas.create_text(150, 150, text="Tkinter Canvas", font=("Arial", 14))
```

* Coordinates `(x0, y0, x1, y1)` define shapes.

---

## **10. Event Handling & Bindings**

```python
def on_click(event):
    label.config(text=f"Clicked at ({event.x}, {event.y})")

canvas.bind("<Button-1>", on_click)  # Left click
canvas.bind("<Motion>", lambda e: label.config(text=f"Mouse at ({e.x},{e.y})"))
```

* `<Button-1>` → left mouse click
* `<Motion>` → mouse movement

---

## **11. Object-Oriented Tkinter Apps**

```python
class MyApp:
    def __init__(self, root):
        self.root = root
        root.title("Class-based Tkinter App")
        self.label = tk.Label(root, text="Hello!", font=("Arial", 16))
        self.label.pack(pady=20)
        tk.Button(root, text="Click Me", command=self.say_hello).pack()

    def say_hello(self):
        self.label.config(text="Button Clicked!")

root = tk.Tk()
app = MyApp(root)
root.mainloop()
```

* Encapsulates widgets and logic for maintainability and scalability.

---

## **12. Master GUI App Example**

A full-featured app combining all concepts:

```python
import tkinter as tk
from tkinter import messagebox, ttk

class MasterApp:
    def __init__(self, root):
        self.root = root
        root.title("Tkinter Master GUI App")
        root.geometry("600x500")

        # ----- Menu -----
        menu_bar = tk.Menu(root)
        root.config(menu=menu_bar)
        file_menu = tk.Menu(menu_bar, tearoff=0)
        file_menu.add_command(label="About", command=self.show_about)
        file_menu.add_separator()
        file_menu.add_command(label="Exit", command=root.quit)
        menu_bar.add_cascade(label="File", menu=file_menu)

        # ----- Frames -----
        self.top_frame = tk.Frame(root, bd=2, relief="sunken")
        self.top_frame.pack(padx=10, pady=10, fill="x")
        self.middle_frame = tk.Frame(root)
        self.middle_frame.pack(padx=10, pady=10, fill="x")
        self.bottom_frame = tk.Frame(root, bd=2, relief="ridge")
        self.bottom_frame.pack(padx=10, pady=10, fill="both", expand=True)

        # ----- Top Frame: Entry + Label + Button -----
        tk.Label(self.top_frame, text="Enter Name:").pack(side="left")
        self.name_var = tk.StringVar()
        tk.Entry(self.top_frame, textvariable=self.name_var).pack(side="left", padx=5)
        tk.Button(self.top_frame, text="Greet", command=self.greet).pack(side="left", padx=5)

        # ----- Middle Frame: Checkbuttons + Radiobuttons -----
        self.cb_var1 = tk.IntVar()
        self.cb_var2 = tk.IntVar()
        tk.Checkbutton(self.middle_frame, text="Option 1", variable=self.cb_var1).pack(side="left", padx=5)
        tk.Checkbutton(self.middle_frame, text="Option 2", variable=self.cb_var2).pack(side="left", padx=5)
        self.rb_var = tk.StringVar(value="A")
        tk.Radiobutton(self.middle_frame, text="Choice A", variable=self.rb_var, value="A").pack(side="left", padx=5)
        tk.Radiobutton(self.middle_frame, text="Choice B", variable=self.rb_var, value="B").pack(side="left", padx=5)
        tk.Button(self.middle_frame, text="Show Choices", command=self.show_choices).pack(side="left", padx=5)

        # ----- Bottom Frame: Canvas + Treeview -----
        self.canvas = tk.Canvas(self.bottom_frame, width=400, height=200, bg="white")
        self.canvas.pack(pady=10)
        self.canvas.create_rectangle(50, 50, 150, 100, fill="red")
        self.canvas.create_oval(200, 50, 300, 150, fill="green")
        self.canvas.bind("<Button-1>", self.canvas_click)

        self.tree = ttk.Treeview(self.bottom_frame, columns=("Name", "Option"), show="headings")
        self.tree.heading("Name", text="Name")
        self.tree.heading("Option", text="Option")
        self.tree.pack(pady=10, fill="x")

    # ----- Methods -----
    def greet(self):
        name = self.name_var.get()
        if name:
            messagebox.showinfo("Greeting", f"Hello, {name}!")
        else:
            messagebox.showwarning("Warning", "Please enter a name.")

    def show_choices(self):
        checked = []
        if self.cb_var1.get(): checked.append("Option 1")
        if self.cb_var2.get(): checked.append("Option 2")
        messagebox.showinfo("Selections", f"Checked: {', '.join(checked) or 'None'}\nRadiobutton: {self.rb_var.get()}")
        self.tree.insert("", "end", values=(self.name_var.get(), ", ".join(checked) or "None"))

    def show_about(self):
        messagebox.showinfo("About", "Tkinter Master GUI App v1.0")

    def canvas_click(self, event):
        self.canvas.create_oval(event.x-5, event.y-5, event.x+5, event.y+5, fill="blue")

# Run app
root = tk.Tk()
app = MasterApp(root)
root.mainloop()
```

**Key Features:**

* Menu bar with **About** and **Exit**
* Top frame: Entry, Label, and Greet button
* Middle frame: Checkbuttons, Radiobuttons, and dynamic feedback
* Bottom frame: Interactive Canvas + Treeview
* Event-driven programming (`command` + `bind`)
* Integrated state management with `StringVar` / `IntVar`

---

## **13. Best Practices**

* Use **Frames** to logically group widgets
* Prefer **grid** for forms and **pack** for stacking
* Use **class-based design** for scalable apps
* Separate **UI setup** and **logic methods**
* Leverage `StringVar` / `IntVar` for dynamic state
* Test layouts and interactions early

---

## **14. Tkinter App Architecture & Lifecycle**

### **1. App Structure**

```
MasterApp (Class-based)
├── root (Tk)
├── Frames
│   ├── top_frame → Entry, Label, Greet Button
│   ├── middle_frame → Checkbuttons, Radiobuttons, Show Choices Button
│   └── bottom_frame → Canvas, Treeview
├── Variables → name_var, cb_var1, cb_var2, rb_var
├── Methods → greet(), show_choices(), canvas_click(), show_about()
└── Menu Bar → File → About, Exit
```

### **2. Event & State Flow**

```
User Interaction
      │
      ▼
Event Handling Layer → Calls methods (greet, show_choices, canvas_click, show_about)
      │
      ▼
Application State → StringVar / IntVar, Canvas shapes, Treeview data
      │
      ▼
UI Update Layer → Labels update, Treeview rows added, Canvas drawn, Messageboxes shown
      │
      ▼
User sees results
```

### **3. Lifecycle Step-by-Step**

1. Type name & click "Greet" → `greet()` → Messagebox
2. Select checkboxes/radiobuttons → `show_choices()` → updates Treeview & shows selection
3. Click canvas → `canvas_click()` → draws shapes dynamically
4. Click menu → `show_about()` → shows app info
5. Variables propagate automatically to linked widgets

---

## **15. Architecture Diagram (ASCII)**

```
                 ┌────────────── MasterApp ──────────────┐
                 │ root window, frames, variables, methods│
                 └───────────────┬───────────────────────┘
                                 │
                         ┌───────▼────────┐
                         │     Menu Bar    │
                         │ File → About/Exit│
                         └───────┬────────┘
                                 │
                         ┌───────▼────────┐
                         │    Top Frame    │
                         │ Entry, Greet Btn│
                         └───────┬────────┘
                                 │
                         ┌───────▼────────┐
                         │ Middle Frame    │
                         │ Checkbuttons,   │
                         │ Radiobuttons,   │
                         │ Show Choices Btn│
                         └───────┬────────┘
                                 │
                         ┌───────▼────────┐
                         │ Bottom Frame    │
                         │ Canvas, Treeview│
                         └───────┬────────┘
                                 │
                         ┌───────▼────────┐
                         │ Event Handling │
                         │ → method calls │
                         └───────┬────────┘
                                 │
                         ┌───────▼────────┐
                         │ Application    │
                         │ State (Vars)   │
                         └───────┬────────┘
                                 │
                         ┌───────▼────────┐
                         │ UI Update Layer│
                         │ Labels, Canvas │
                         │ Treeview, Msg  │
                         └───────┬────────┘
                                 │
                         ┌───────▼────────┐
                         │ User Interaction│
                         └────────────────┘
```

---

✅ **Key Takeaways:**

* **Class-based design** improves structure and maintainability
* **Frames** separate layout logically
* **Event-driven programming** ensures responsiveness
* **State variables (`StringVar` / `IntVar`)** enable reactive updates
* **Canvas & Treeview** showcase interactive graphics and tables
* Lifecycle mirrors **web dashboard patterns**: Event → State → Render → Feedback

---

