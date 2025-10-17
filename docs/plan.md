# 🎯 QX Project Overview

**QX** is a modern certification exam preparation application built with a microservices-like architecture within a monorepo. The project provides comprehensive tools for users to prepare for various certification exams through interactive practice questions, progress tracking, and personalized learning paths.

## 🚀 Project Vision

To create a best-in-class exam preparation platform that is:

- **Modern:** Built with a cutting-edge technology stack.
- **Scalable:** Designed to support a large user base.
- **User-Friendly:** Focused on providing an intuitive and effective learning experience.

## 🌟 Key Features

- **Interactive Practice Questions:** A large database of questions with detailed explanations.
- **Progress Tracking:** Personalized dashboards to monitor performance and identify areas for improvement.
- **Personalized Learning Paths:** Customized study plans based on user performance and goals.
- **Exam Simulation:** Realistic exam simulations to prepare users for the real thing.

## 🗺️ Project Roadmap

The project is divided into the following phases:

- **Phase 0: Environment Setup:** Setting up the development environment and project foundation.
- **Phase 1: Project Foundation:** Building the core project structure and backend/frontend setup.
- **Phase 2: Core Development:** Implementing the main features of the application.
- **Phase 3: Deployment:** Deploying the application to a production environment.
- **Phase 4: Advanced Features:** Adding advanced features and enhancements.

# 🚧 Phase 0: Environment Setup

**Status:** In Progress (Estimated completion: October 2025)

## 🎯 Goals

- Analyze prerequisites and document requirements.
- Create a prerequisite verification script.
- Establish a foundation for atomic and intent-focused documentation.

## 📝 Tasks

- [ ] **Task 0.1:** Prerequisites Analysis
- [ ] **Task 0.2:** Prerequisite Verification Script
- [ ] **Task 0.3:** Project Documentation Foundation

##  deliverables

- Prerequisite verification script.
- A set of atomic and intent-focused documentation.

# 🛠️ Technology Stack

## Frontend

- **Runtime:** Bun 1.2.23+
- **Framework:** React 19 with TypeScript 5
- **UI Library:** Chakra UI 2.x
- **State Management:** Zustand + React Query
- **Testing:** Vitest + React Testing Library

## Backend

- **Runtime:** Bun 1.2.23+
- **Framework:** Bun's native HTTP server
- **Database:** PostgreSQL 17 with Drizzle ORM
- **Authentication:** JWT with refresh tokens
- **Testing:** Bun's built-in test runner

## DevOps

- **Local Development:** Podman containers
- **Local K8s:** kind (Kubernetes in Docker)
- **Production:** AWS (EKS, RDS, ECR)
- **CI/CD:** GitHub Actions

# 🔄 Development Workflow

## 🌿 Branch Strategy

```
main                    ← Production-ready code
├── develop            ← Integration branch
├── feature/*          ← Feature branches
├── fix/*              ← Bug fix branches
└── release/*          ← Release preparation
```

## 📝 Issue Management

1. **Feature Requests:** Create GitHub issue with `feature/` label
2. **Bug Reports:** Create issue with `bug/` label and reproduction steps
3. **Technical Debt:** Create issue with `tech-debt/` label

## 🔄 Pull Request Process

1. Create feature branch from `develop`
2. Implement changes with tests
3. Submit PR to `develop` branch
4. Automated checks must pass
5. Code review required (minimum 1 reviewer)
6. Merge after approval

# 🚨 Risk Management

## ⚠️ Technical Risks

- **Database Migration:** Complex schema changes in production
- **Performance:** Scaling to handle peak user loads
- **Security:** Authentication and data protection
- **Dependencies:** Third-party service availability

## 🛡️ Mitigation Strategies

- **Database:** Staging environment for migration testing
- **Performance:** Load testing and monitoring
- **Security:** Regular security audits and penetration testing
- **Dependencies:** Vendor risk assessment and backup plans

# 📋 Prerequisites

This document outlines the prerequisites for developing and running the QX project.

## 🛠️ Core Tools

- **[Podman](https://podman.io/):** For container management.
- **[kind](https://kind.sigs.k8s.io/):** For running a local Kubernetes cluster.
- **[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/):** For interacting with the Kubernetes cluster.
- **[Bun](https://bun.sh/):** As the JavaScript runtime and package manager.

## 💻 Development Environment

A Linux-based environment is recommended for development. The verification script will be designed for Linux.

# 📅 Phase 1: Project Foundation

**Status:** Not Started (Estimated start: October 2025)

## 🎯 Goals

- Create the project directory structure.
- Initialize the backend project with Bun.
- Initialize the frontend project with Vite.

## 📝 Tasks

- [ ] **Task 1.1: Create Project Directory Structure**
- [ ] **Task 1.2: Initialize Backend Project**
- [ ] **Task 1.3: Initialize Frontend Project**

# 📚 QX Project Documentation

This directory contains the project documentation for the QX project, organized into atomic and intent-focused documents.

## 📄 Documents

- [**00 - Project Overview**](./00_project_overview.md): A high-level summary of the project.
- [**01 - Phase 0: Environment Setup**](./01_phase_0_environment_setup.md): A detailed plan for the current phase.
- [**02 - Technology Stack**](./02_technology_stack.md): A document outlining the technical requirements.
- [**03 - Development Workflow**](./03_development_workflow.md): A guide to the development process.
- [**04 - Risk Management**](./04_risk_management.md): A document outlining potential risks and mitigation strategies.
