## Layer architecture

The `domain` layer represents the core business logic of the system. It is completely independent from external frameworks, infrastructure, and application workflows. 

This layer is split into two main sections.

### 📁 models

It contains the core business entities of the system and is responsible for:

- Representing the fundamental concepts of the domain
- Holding domain state and structure
- Encapsulating business meaning in data form

These models are framework-agnostic and do not depend on external systems or implementation details.

### 📁 interfaces

It defines the contracts required by the domain and application layers and is responsible for:
- Declaring abstractions for external dependencies
- Defining input/output contracts for core operations
- Enabling dependency inversion so implementations can live in infrastructure

These interfaces describe *what the system needs*, not *how it is implemented*.
