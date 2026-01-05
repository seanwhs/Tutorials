# The C4 Model: Visualizing Microservices Architecture in a Digital Banking System

The **C4 Model** provides a structured, hierarchical way to visualize software architecture. By breaking down the system into four distinct levels, this model allows software engineers, architects, and even non-technical stakeholders to understand the components, relationships, and overall design of a system. In this tutorial, we'll explore the **C4 Model** through a practical example—a **Microservices-based Digital Banking System** that uses **Django Rest Framework (DRF)** for the backend and **MySQL** as the database.

We'll discuss each level of the C4 model and illustrate the concepts using **architectural documents**, **ASCII diagrams**, and **Python code snippets**. By the end of this tutorial, you will have a comprehensive understanding of how to document a modern microservices architecture using the C4 Model.

---

## Table of Contents

1. **Introduction to the C4 Model**
2. **Level 1: System Context**
3. **Level 2: Containers**
4. **Level 3: Components**
5. **Level 4: Code**
6. **Summary and Next Steps**

---

## 1. Introduction to the C4 Model

The **C4 Model** is a framework for visualizing the architecture of software systems. Developed by **Simon Brown**, it divides the system into four levels of abstraction. Each level serves a different purpose and is aimed at different audiences, ranging from high-level stakeholders to developers who work on the actual codebase.

### Levels of the C4 Model:

1. **Level 1: System Context**
   A high-level diagram showing how the system interacts with external users and systems.

2. **Level 2: Containers**
   A zoomed-in view that breaks the system into **deployable units**, such as web apps, databases, and services.

3. **Level 3: Components**
   Further zoom into each container, breaking it down into **logical components** like microservices, modules, and APIs.

4. **Level 4: Code**
   The most granular level, where we focus on the **specific implementation** of classes, functions, and methods.

In this tutorial, we will use a **Digital Banking System** as an example. The system is built using **Microservices architecture** with **Django Rest Framework (DRF)** for the backend, **MySQL** as the database, and various other components like authentication, payments, and account services.

---

## 2. Level 1: System Context

At **Level 1**, we begin by examining the **entire system** as a "black box." This is the most abstract level of the C4 model, where we focus on **who interacts with the system** and **how** they interact. This level provides an overview of the system's environment, external users, and other systems with which the system communicates.

### Key Elements at Level 1:

* **External Users**: People or systems that interact with the system (e.g., customers, admin users, third-party services).
* **External Systems**: Other services or databases that the system relies on (e.g., external APIs, payment gateways, legacy systems).

### Example: Digital Banking System

In our **Digital Banking System**, we consider the following:

* **Customers** who access the system via mobile or web apps.
* **Credit Rating Service** to fetch the user’s credit score.
* **Payment Gateway** to process transactions and payments.

#### ASCII Diagram

```
          +----------------------------+
          |    Digital Banking System  |    
          |         (Microservices)     |  
          +----------------------------+
                     ^         ^
                     |         |
        +------------+         +-------------+    
        |                          |  
  +-------------+             +--------------+  
  |  Customer   |             |  Credit Score |  
  |  (User)     |             |  Service      |  
  +-------------+             +--------------+  
                     |           
                     v        
           +---------------------+  
           |  Payment Gateway    |  
           |  Service            |  
           +---------------------+  
```

### Explanation:

* **Customers (Users)**: Customers interact with the **Digital Banking System** through the **Mobile App** or **Web Application**.
* **Credit Score Service**: The system integrates with an external service to fetch the user’s credit score.
* **Payment Gateway Service**: This service allows the system to interact with external payment processors for transactions.

This high-level view shows how external users and systems interact with the Digital Banking System.

---

## 3. Level 2: Containers

At **Level 2**, we break the system down into **containers**. A container represents a **deployable unit**—an application, service, or database. This level shows the internal structure of the system, focusing on how different containers interact and what each container’s role is in the system.

### Key Elements at Level 2:

* **Web Application**: A front-end application that allows users to interact with the system.
* **Mobile Application**: A mobile version of the app for customer interactions.
* **Microservices**: Backend services (such as authentication, account management, and payment processing).
* **Database**: A relational database (in our case, **MySQL**) where all user and transaction data is stored.

### Example: Digital Banking System

In the **Digital Banking System**, the core containers would be:

* **Web Application** (React)
* **Mobile Application** (iOS/Android)
* **Authentication Service** (DRF)
* **Account Service** (DRF)
* **Transaction Service** (DRF)
* **MySQL Database** (for storing user and transaction data)
* **Payment Gateway** (external service)

#### ASCII Diagram

```
+---------------------------------------------------------------+
|                Digital Banking System (Microservices)         |
| +-----------------+  +-----------------+  +-----------------+ |
| | Web App        |  | Mobile App      |  | MySQL Database  | |
| | (React)        |  | (iOS/Android)   |  | (User & Data)   | |
| +-----------------+  +-----------------+  +-----------------+ |
|        ^                   ^                    ^           |
|        |                   |                    |           |
| +------------------+  +-----------------+  +---------------------+
| | Auth Service     |  | Account Service |  | Transaction Service |
| | (DRF API)        |  | (DRF API)       |  | (DRF API)           |
| +------------------+  +-----------------+  +---------------------+
|        ^                   ^                      |            |
|        |                   |                      v            |
| +-------------------+  +---------------------+  +--------------------+
| | External Payment  |  | External Credit API |  |   Legacy Mainframe  |
| | Gateway Service   |  | (Check Credit Score)|  | (Transaction Data)  |
| +-------------------+  +---------------------+  +--------------------+
+---------------------------------------------------------------+
```

### Explanation:

* **Web App** and **Mobile App** provide the interface for users to interact with the system.
* **Authentication Service (DRF)** handles user authentication and JWT token generation.
* **Account Service (DRF)** manages user account data such as balances and transaction history.
* **Transaction Service (DRF)** processes and tracks financial transactions.
* **MySQL Database** stores the system's data.
* **External Payment Gateway** interacts with third-party services for transaction processing.
* **External Credit API** is used to fetch credit score information for customers.

This level defines the **major building blocks** of the system and how they interact.

---

## 4. Level 3: Components

At **Level 3**, we zoom into a specific container and break it down into **components**. Components are the logical building blocks within each container. They represent individual services, APIs, or modules that make up the container’s functionality.

### Key Elements at Level 3:

* **Modules**: Subsystems or logical parts of a container.
* **APIs**: Services exposed by a container to interact with other containers or external systems.
* **Services**: A component’s internal logic that handles specific tasks.

### Example: Authentication Service (DRF)

For example, let's zoom into the **Auth Service**, which is a **DRF-based microservice** that handles user authentication. We can break it down into components like:

* **Sign-up Component**: Handles user registration.
* **Login Component**: Manages user login and token generation.
* **Password Reset Component**: Handles forgotten password requests.
* **Database Adapter**: Manages interactions with the **MySQL Database**.

#### ASCII Diagram

```
+--------------------------------------------+
|             Auth Service                   |
| +---------------------+  +----------------+ |
| | Sign-up Component   |  | Login Component | |
| | (Handles registration) | (Handles login) | |
| +---------------------+  +----------------+ |
| +---------------------+  +----------------+ |
| | Password Reset      |  | DB Adapter      | |
| | (Handles reset)     |  | (MySQL access)  | |
| +---------------------+  +----------------+ |
+--------------------------------------------+
```

### Explanation:

* **Sign-up Component**: Handles user registration by validating the data and storing it in the database.
* **Login Component**: Validates the user credentials and generates JWT tokens for further requests.
* **Password Reset Component**: Manages user password reset functionality.
* **Database Adapter**: Interacts with the **MySQL database** to manage user data.

---

## 5. Level 4: Code

At **Level 4**,


we look at the **code level**—focusing on the specific implementation of classes, methods, and functions. This level is for developers who need to understand how the components are built and structured in code.

### Key Elements at Level 4:

* **Classes**: Object-oriented representations of entities or services.
* **Methods/Functions**: Code that implements specific functionality.
* **Attributes**: Data associated with a class or service.

### Example: Login Component in DRF

Here’s an example of the **Login Component** in **DRF** that handles user login and token generation.

#### Python Code (DRF)

```python
# views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken

class LoginView(APIView):
    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')

        # Authenticate user
        user = authenticate(username=username, password=password)
        if user is not None:
            # Generate JWT token
            refresh = RefreshToken.for_user(user)
            return Response({
                'access_token': str(refresh.access_token),
                'refresh_token': str(refresh)
            }, status=status.HTTP_200_OK)
        else:
            return Response({
                'error': 'Invalid credentials'
            }, status=status.HTTP_401_UNAUTHORIZED)
```

### Explanation:

* **LoginView**: A DRF `APIView` that handles the POST request for user login.
* It uses Django’s `authenticate` method to verify user credentials.
* If authentication is successful, it generates **JWT tokens** and returns them to the user.

---

## 6. Summary and Next Steps

In this tutorial, we've walked through the **C4 Model** using a **Microservices-based Digital Banking System**. We’ve illustrated the model with **ASCII diagrams** and **Python code snippets** to show how each level of the model works in a real-world scenario.

### Summary:

* **Level 1 (System Context)**: We examined the system’s high-level interactions with external users and systems.
* **Level 2 (Containers)**: We broke down the system into containers (microservices, databases, etc.).
* **Level 3 (Components)**: We zoomed into a container (Auth Service) and explored its internal components.
* **Level 4 (Code)**: We looked at how the login functionality is implemented in code using DRF.

### Next Steps:

* Consider creating detailed architectural diagrams for each level using tools like **PlantUML** or **Mermaid**.
* Expand on other microservices, such as **Account Service** or **Transaction Service**.
* Integrate more advanced features like **logging**, **caching**, and **monitoring** into your system’s architecture.

With this understanding of the C4 Model, you can now effectively communicate the architecture of your microservices-based systems.
