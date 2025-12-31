# MVVM Architecture Guide

## Overview

Maestro follows a strict MVVM (Model-View-ViewModel) architecture with clear separation of concerns, adhering to SOLID principles. This guide will help you understand where to place files, how to name them, and how to structure new features.

## Table of Contents
1. [Core Principles](#core-principles)
2. [Module Structure](#module-structure)
3. [File Naming Conventions](#file-naming-conventions)
4. [Where Things Go](#where-things-go)
5. [Common Patterns](#common-patterns)
6. [Adding New Features](#adding-new-features)
7. [Integration Patterns](#integration-patterns)

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
