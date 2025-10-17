---

## `plan.md`

```markdown
# 🎯 QX Project Overview

**QX** is a modern certification exam preparation application built with a microservices-like architecture within a monorepo. The project provides comprehensive tools for users to prepare for various certification exams through interactive practice questions, progress tracking, and personalized learning paths.

## 🚀 Project Vision

To create a best-in-class exam preparation platform that is:

-   **Modern:** Built with a cutting-edge technology stack.
-   **Scalable:** Designed to support a large user base.
-   **User-Friendly:** Focused on providing an intuitive and effective learning experience.

## 🌟 Key Features

-   **Interactive Practice Questions:** A large database of questions with detailed explanations.
-   **Progress Tracking:** Personalized dashboards to monitor performance and identify areas for improvement.
-   **Personalized Learning Paths:** Customized study plans based on user performance and goals.
-   **Exam Simulation:** Realistic exam simulations to prepare users for the real thing.

## 🗺️ Project Roadmap

The project is divided into the following phases:

-   **Phase 0: Environment Setup:** Setting up the development environment and project foundation.
-   **Phase 1: Project Foundation:** Building the core project structure and backend/frontend setup.
-   **Phase 2: Core Development:** Implementing the main features of the application.
-   **Phase 3: Deployment:** Deploying the application to a production environment.
-   **Phase 4: Advanced Features:** Adding advanced features and enhancements.

# 🚧 Phase 0: Environment Setup

**Status:** In Progress (Estimated completion: October 2025)

## 🎯 Goals

-   Analyze prerequisites and document requirements.
-   Create a prerequisite verification script.
-   Establish a foundation for atomic and intent-focused documentation.
-   **Set up a robust local Kubernetes development environment using Podman and Kind.**

## 📝 Tasks

-   [ ] **Task 0.1: Prerequisites Analysis**
-   [ ] **Task 0.2: Prerequisite Verification Script** (Will be enhanced to check for Podman, Kind, kubectl, Bun)
-   [ ] **Task 0.3: Project Documentation Foundation**

### 📦 Phase 0.1: Local Kubernetes Environment Setup

**Status:** In Progress (Estimated completion: [Set a realistic short timeframe, e.g., 1 week])

#### 🎯 Goals
-   Automate the setup of a 3-node Kubernetes cluster using Kind.
-   Ensure all core prerequisites (Podman, kubectl, Kind, Bun) are verified and installed.
-   Provide a clear, script-driven workflow for starting and stopping the local environment.

#### 📝 Tasks
-   [ ] **Task 0.1.1: Refine Prerequisite Verification Script**
    *   Enhance `development/scripts/install-prereqs.sh` to explicitly check for `podman`, `kind`, `kubectl`, and `bun` versions.
    *   Add `--dry-run` logic to the script for safer testing.
    *   Ensure the script can install these tools if they are missing (with user confirmation).
-   [ ] **Task 0.1.2: Create Kind Cluster Configuration**
    *   Define a `kind-config.yaml` to specify a 3-node cluster (1 control plane, 2 workers).
-   [ ] **Task 0.1.3: Develop Cluster Management Scripts**
    *   Create `development/scripts/start-kind-cluster.sh`:
        *   Checks if Kind is installed.
        *   Checks if the cluster already exists.
        *   Creates the Kind cluster using the `kind-config.yaml`.
        *   Configures `kubectl` context to use the new cluster.
        *   Deploys a basic test Pod (e.g., Nginx) to verify functionality.
        *   *Optional:* Installs a local ingress controller (like Nginx Ingress) for easier service exposure, if needed early.
    *   Create `development/scripts/stop-kind-cluster.sh`:
        *   Deletes the Kind cluster.
        *   Resets `kubectl` context to default or previous.
-   [ ] **Task 0.1.4: Document Local Dev Workflow for K8s**
    *   Update `README.md` and `development/docs/01_phase_0_environment_setup.md` with clear instructions on how to use the new scripts.
    *   Add troubleshooting tips for common Kind/Podman issues.

#### 📦 Deliverables
-   Enhanced `install-prereqs.sh` script.
-   `kind-config.yaml` for a 3-node cluster.
-   `start-kind-cluster.sh` script.
-   `stop-kind-cluster.sh` script.
-   Updated documentation for local Kubernetes environment setup.

# 🛠️ Technology Stack

## Frontend

-   **Runtime:** Bun 1.1.x
-   **Framework:** React 18.3.1 with TypeScript 5.x
-   **UI Library:** Chakra UI 2.8.2
-   **State Management:** Zustand 4.5.2 + React Query (TanStack Query) 5.31.0
-   **Testing:** Vitest 1.5.0 + React Testing Library 15.0.0

## Backend

-   **Runtime:** Bun 1.1.x
-   **Framework:** Bun's native HTTP server
-   **Database:** PostgreSQL 16.x with Drizzle ORM 0.30.9
-   **Authentication:** JWT (e.g., `jsonwebtoken` 9.0.2) with refresh tokens
-   **Validation:** Zod schemas 3.23.4
-   **Testing:** Bun's built-in test runner

## DevOps

-   **Local Development:** Podman 5.0.x containers
-   **Local K8s:** kind 0.22.0 (Kubernetes in Docker)
-   **K8s CLI:** kubectl 1.29.x
-   **Production:** AWS (EKS 1.29, RDS, ECR)
-   **CI/CD:** GitHub Actions

# 🔄 Development Workflow

## 🌿 Branch Strategy