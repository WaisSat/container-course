# Container Fundamentals Course

A hands-on course covering Docker and Kubernetes fundamentals, from "what is a container" to GitOps deployments.

---

## Course Overview

**Format:** 8 weeks × 3 hours each  
**Prerequisites:** Basic Linux command line, some Python experience  
**Environment:** GitHub Codespaces (recommended) or Rocky Linux 8 VM  

### What You'll Learn

| Phase | Weeks | Focus |
|-------|-------|-------|
| **Containerization** | 1-3 | Build, run, and optimize Docker containers |
| **Orchestration** | 4-6 | Deploy to Kubernetes, networking, security |
| **Operations** | 7-8 | Helm, Kustomize, GitOps with ArgoCD |

### Outcomes

By the end of this course, you'll be able to:

- Build production-quality container images
- Deploy applications to Kubernetes
- Implement networking and security policies
- Use Helm and Kustomize for configuration management
- Set up GitOps pipelines with ArgoCD

---

## Getting Started

### Option 1: GitHub Codespaces (Recommended)

1. Fork this repository
2. Click **Code** → **Codespaces** → **Create codespace on main**
3. Wait for setup to complete (~2-3 minutes)
4. Verify: `docker run hello-world`

### Option 2: Local VM

See [Week 1 Installation Guide](./week-01/INSTALL-DOCKER.md) for Docker CE setup on Rocky Linux 8.

---

## Course Structure

### Week 1: Container Fundamentals
📁 [week-01/](./week-01/)

- What containers are and why they exist
- Running and exploring containers
- Building your first Dockerfile
- Pushing to Docker Hub and GHCR

### Week 2: Dockerfile Mastery
📁 week-02/ *(coming soon)*

- Layer caching and optimization
- Multi-stage builds
- Security scanning
- Image size reduction

### Week 3: Compose & Local Development
📁 week-03/ *(coming soon)*

- Multi-container applications
- Service discovery
- Volumes and persistence
- Development workflows

### Week 4: Kubernetes Architecture
📁 week-04/ *(coming soon)*

- Control plane components
- Pods, Deployments, Services
- kubectl fundamentals
- Rolling updates

### Week 5: Configuration & State
📁 week-05/ *(coming soon)*

- ConfigMaps and Secrets
- PersistentVolumeClaims
- StatefulSets
- 12-factor app principles

### Week 6: Networking & Security
📁 week-06/ *(coming soon)*

- Service discovery and DNS
- Ingress controllers
- NetworkPolicies
- Pod security

### Week 7: Helm & Kustomize
📁 week-07/ *(coming soon)*

- Helm charts and values
- Kustomize bases and overlays
- When to use which

### Week 8: GitOps & Capstone
📁 week-08/ *(coming soon)*

- GitOps principles
- ArgoCD deployment
- Capstone project

---

## Hands-On Practice

Each week includes:

- **Labs** - Guided exercises in the course content
- **Gym Exercises** - Practice scenarios in `container-gym/`

The gym uses "Jerry scenarios" - you fix broken infrastructure created by a well-meaning but chaotic teammate. This builds debugging skills through discovery.

---

## Assessment

| Component | Weight |
|-----------|--------|
| Gym Completions | 30% |
| Lab Participation | 20% |
| Discovery Questions | 10% |
| Capstone Project | 40% |

---

## Resources

### Documentation
- [Docker Docs](https://docs.docker.com/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Helm Docs](https://helm.sh/docs/)

### Cheat Sheets
- [Docker CLI Cheat Sheet](https://docs.docker.com/get-started/docker_cheatsheet.pdf)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

## Contributing

Found an issue? Have a suggestion? Open an issue or PR on the course repository.
