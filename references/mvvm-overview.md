# MVVM Architecture Guide

## Overview

MVVM (Model-View-ViewModel) keeps UI, presentation state, and domain work in separate layers, with SOLID-style boundaries so each piece stays small and testable. This guide explains where to put files, how to name them, and how to structure new features around that split.

---

## Core Principles

### 1. Single Responsibility Principle (SRP)

- Each class/struct should have one reason to change
- Services handle one type of operation
- ViewModels manage state for one view or feature
- Coordinators manage one integration or workflow

### 2. Dependency Inversion Principle (DIP)

- Depend on protocols, not concrete implementations
- Use dependency injection
- Keep high-level modules independent of low-level details

### 3. Separation of Concerns

- **Views**: UI only, no business logic
- **ViewModels**: State management and presentation logic
- **Services**: Business logic and data operations
- **Models**: Data structures only

### 4. Feature-Based Organization

- Group related files by feature, not by type
- Each major feature gets its own top-level module
- Shared utilities go in `Shared/`