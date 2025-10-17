# QX Project

## 🎯 Project Overview

**QX** is a modern certification exam preparation application built with a microservices-like architecture within a monorepo. The project provides comprehensive tools for users to prepare for various certification exams through interactive practice questions, progress tracking, and personalized learning paths.

## 🛠️ Technology Stack

### Frontend

| Category | Technology |
|---|---|
| **Runtime** | Bun 1.3.0 |
| **Framework** | React 19.x |
| **UI Library** | Chakra UI 3.27.1 |
| **State Management** | Zustand + React Query |
| **Routing** | React Router 7.9.3 |
| **Form Handling** | React Hook Form with Zod validation |
| **Testing** | Vitest + React Testing Library |
| **Bundling** | Vite 5.x |

### Backend

| Category | Technology |
|---|---|
| **Runtime** | Bun 1.3.0 |
| **Framework** | Bun's native HTTP server |
| **Database** | PostgreSQL 18 with Drizzle ORM 0.44.6 |
| **Authentication** | JWT with refresh tokens |
| **Validation** | Zod schemas |
| **Testing** | Bun's built-in test runner |

### DevOps

| Category | Technology |
|---|---|
| **Local Development** | Podman 5.6.2 containers |
| **Local K8s** | kind 0.30.0 |
| **Production** | AWS (EKS, RDS, ECR) |
| **CI/CD** | GitHub Actions |

## 🚀 Getting Started

### Prerequisites

- Bun 1.3.0
- Podman 5.6.2
- kubectl 1.34.1
- kind 0.30.0

It is recommended to use the provided script to install the required tools:

```bash
sudo bash development/scripts/install-prereqs.sh
```

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/securexai/qx.git
    cd qx
    ```

2.  **Install dependencies:**
    ```bash
    # Install backend dependencies
    cd backend
    bun install

    # Install frontend dependencies
    cd ../frontend
    bun install
    ```

## 🔄 Development Workflow

### Branch Strategy

```
main                    ← Production-ready code
├── develop            ← Integration branch
├── feature/*          ← Feature branches
├── fix/*              ← Bug fix branches
└── release/*          ← Release preparation
```

### Pull Request Process

1. Create feature branch from `develop`
2. Implement changes with tests
3. Submit PR to `develop` branch
4. Automated checks must pass
5. Code review required (minimum 1 reviewer)
6. Merge after approval

## 🧪 Testing with Podman

To test the `install-prereqs.sh` script in a clean, isolated environment without affecting your local system, you can use a disposable Podman container. The following command will run the script in a read-only mount, ensuring that no changes are made to your local repository:

```bash
podman run --rm -it -v "$PWD:/workspace:ro" ubuntu:24.04 bash -c "apt-get update -qq && apt-get install -y -qq curl unzip bc && bash /workspace/development/scripts/install-prereqs.sh --dry-run"
```

### Command Breakdown

*   `podman run`: Runs a new container.
*   `--rm`: Automatically removes the container when it exits.
*   `-it`: Runs the container in interactive mode with a pseudo-TTY.
*   `-v "$PWD:/workspace:ro"`: Mounts the current directory into the container at `/workspace` in read-only mode (`ro`).
*   `ubuntu:24.04`: The container image to use.
*   `bash -c "..."`: Executes a series of commands inside the container:
    1.  `apt-get update -qq`: Updates the package lists.
    2.  `apt-get install -y -qq curl unzip bc`: Installs the required dependencies.
    3.  `bash /workspace/development/scripts/install-prereqs.sh --dry-run`: Runs the installation script in dry-run mode.

## 📅 Next Steps

### Immediate Actions (This Week)

1. **Analyze prerequisites and document requirements**
2. **Create prerequisite verification script**
3. **Establish documentation foundation**

### Short-term Goals (Next 2 Weeks)

1. **Create project directory structure**
2. **Initialize backend project with Bun**
3. **Initialize frontend project with Vite**
