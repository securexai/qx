# QX Project

## 🎯 Project Overview

**QX** is a modern certification exam preparation application built with a microservices-like architecture within a monorepo. The project provides comprehensive tools for users to prepare for various certification exams through interactive practice questions, progress tracking, and personalized learning paths.

## 🛠️ Technology Stack

### Frontend

| Category | Technology | Latest Stable Version (as of mid-2024) |
|---|---|---|
| **Runtime** | Bun | 1.1.x |
| **Package Manager** | Bun / pnpm | latest |
| **Framework** | React | 18.3.1 |
| **UI Library** | Chakra UI | 2.8.2 |
| **State Management** | Zustand | 4.5.2 |
| **Data Fetching** | React Query (TanStack Query) | 5.31.0 |
| **Routing** | React Router | 6.23.0 |
| **Form Handling** | React Hook Form | 7.51.3 |
| **Validation** | Zod | 3.23.4 |
| **Testing** | Vitest | 1.5.0 |
| **Testing** | React Testing Library | 15.0.0 |
| **Bundling** | Vite | 5.2.x |

### Backend

| Category | Technology | Latest Stable Version (as of mid-2024) |
|---|---|---|
| **Runtime** | Bun | 1.1.x |
| **Framework** | Bun's native HTTP server | (Integrated with Bun) |
| **Database** | PostgreSQL | 16.x |
| **ORM** | Drizzle ORM | 0.30.9 |
| **Authentication** | JWT | (Library dependent, e.g., `jsonwebtoken` 9.0.2) |
| **Validation** | Zod | 3.23.4 |
| **Testing** | Bun's built-in test runner | (Integrated with Bun) |

### DevOps

| Category | Technology | Latest Stable Version (as of mid-2024) |
|---|---|---|
| **Local Development** | Podman | 5.0.x |
| **Local K8s** | kind | 0.22.0 |
| **K8s CLI** | kubectl | 1.29.x |
| **Cloud Provider** | AWS (EKS, RDS, ECR) | (EKS 1.29 is latest stable cluster version) |
| **CI/CD** | GitHub Actions | (Latest workflow syntax) |

## 🚀 Getting Started

### Prerequisites

- Bun 1.1.x
- Podman 5.0.x
- kubectl 1.29.x
- kind 0.22.0

It is recommended to use the provided script to install the required tools:

```bash
sudo bash scripts/install-prereqs.sh
```

## 📚 Documentation

- **[PNPM_FEASIBILITY_ANALYSIS.md](PNPM_FEASIBILITY_ANALYSIS.md)** - Analysis of using pnpm vs Bun for package management
- **[docs/pnpm-implementation-guide.md](docs/pnpm-implementation-guide.md)** - Implementation guide for Phase 1 React setup