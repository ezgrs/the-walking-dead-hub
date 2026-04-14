## Project architecture

This project follows a [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
style separation of concerns. The codebase is organized into five
main layers, each with a distinct responsibility and dependency direction.

### 📁 domain

It represents the core of the system and is responsible for:

- Defining the business model and entities
- Expressing domain rules and concepts
- Declaring interfaces required by the domain

This layer is independent of frameworks, infrastructure, and external systems.

### 📁 infrastructure

It contains all external system implementations and is responsible for:
- Implementing interfaces defined in the domain layer
- Handling external concerns such as databases, APIs, file systems, caching, and third-party services
- Providing concrete implementations for application dependencies

This layer depends on domain abstractions but not the opposite.

### 📁 application/services

It contains the use cases of the system and is responsible for:

- Orchestrating business workflows
- Coordinating domain objects and infrastructure services through interfaces
- Defining how the system behaves from a functional perspective

This layer does not contain infrastructure details or external system implementations.

### 📁 api

It's the entry point of the application and is responsible for:

- Handling HTTP requests or external interface calls
- Translating incoming data into application-level inputs
- Calling application services
- Returning responses to the outside world

This layer does not contain no business logic.

### 📁 scripts

It contains standalone execution utilities and is responsible for:

- Running one-off tasks
- Performing maintenance or initialization operations
- Executing application workflows outside of the API context

This layer uses the application layer directly.
