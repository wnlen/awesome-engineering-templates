# Awesome Engineering Templates

<p align="center">
English | <a href="README.zh-CN.md">简体中文</a>
</p>

<p align="center">

<a href="https://github.com/wnlen/awesome-engineering-templates/stargazers">
<img src="https://img.shields.io/github/stars/wnlen/awesome-engineering-templates?style=flat-square" />
</a>

<a href="https://github.com/wnlen/awesome-engineering-templates/network/members">
<img src="https://img.shields.io/github/forks/wnlen/awesome-engineering-templates?style=flat-square" />
</a>

<a href="https://github.com/wnlen/awesome-engineering-templates/issues">
<img src="https://img.shields.io/github/issues/wnlen/awesome-engineering-templates?style=flat-square" />
</a>

<a href="https://github.com/wnlen/awesome-engineering-templates/blob/main/LICENSE">
<img src="https://img.shields.io/github/license/wnlen/awesome-engineering-templates?style=flat-square" />
</a>

</p>

A curated collection of **production-ready engineering templates** for backend, frontend, DevOps and deployment.

The goal is to reduce the cost of starting new projects by reusing **battle-tested engineering infrastructure**.

---

# Table of Contents

- Features
- Repository Structure
- Available Templates
- Quick Start
- Documentation
- Related Repository
- Philosophy
- Contributing
- License

---

# Features

- Production-ready engineering templates  
- Backend, frontend and DevOps infrastructure  
- Deployment scripts and CI/CD examples  
- Reusable configuration and code snippets  
- Real-world engineering patterns  

---

# Repository Structure

```text
engineering-assets
│
├─ README.md            # Project overview and usage guide
├─ LICENSE              # License information (MIT recommended)
├─ .gitignore           # Git ignore rules
├─ .editorconfig        # Editor formatting rules
├─ CHANGELOG.md         # Version history
├─ CONTRIBUTING.md      # Contribution guidelines
├─ CODEOWNERS           # Maintainers / reviewers
│
├─ docs                 # Documentation
│  ├─ 00-quickstart.md            # Quick start guide
│  ├─ 01-how-to-use-templates.md  # How to use templates
│  ├─ 02-deployment-playbook.md   # Deployment instructions
│  └─ 03-style-guide.md           # Coding / project style guide
│
├─ templates            # Reusable project templates
│  ├─ backend           # Backend project templates
│  │  ├─ springboot-api            # Spring Boot API starter
│  │  └─ springboot-multi-module   # Spring Boot multi-module structure
│  │
│  ├─ frontend          # Frontend project templates
│  │  ├─ vue3-vite-admin           # Vue 3 + Vite admin template
│  │  └─ uniapp                    # UniApp application template
│  │
│  └─ database          # Database related templates
│     ├─ mysql                     # MySQL schema examples
│     └─ migration                 # Migration scripts templates
│
├─ deploy               # Deployment scripts
│  ├─ linux             # Native Linux deployment
│  │  ├─ java-api                 # Java API deployment scripts
│  │  └─ vue-admin                # Vue admin deployment scripts
│  │
│  └─ docker            # Docker deployment examples
│     ├─ java                     # Dockerfile for Java apps
│     └─ compose                  # Docker Compose templates
│
├─ devops               # DevOps infrastructure templates
│  ├─ nginx             # Nginx reverse proxy configs
│  │
│  ├─ ci                # CI/CD pipelines
│  │  ├─ github-actions           # GitHub Actions templates
│  │  └─ jenkins                  # Jenkins pipeline templates
│  │
│  └─ monitoring        # Monitoring utilities
│     ├─ healthcheck             # Service health check scripts
│     └─ logrotate               # Log rotation configs
│
├─ snippets             # Reusable code snippets
│  ├─ maven             # Maven build snippets
│  ├─ spring            # Spring Boot configuration snippets
│  ├─ bash              # Shell script snippets
│  └─ vue               # Vue frontend snippets
│
└─ tools                # Helper tools for template usage
   ├─ init-project.sh   # Initialize a project from templates
   ├─ render-template.sh# Render template variables
   └─ validate.sh       # Validate template structure
```

---

# Available Templates

## Backend

Templates for backend services.

Examples:

- Spring Boot API project structure
- Spring Boot multi-module architecture
- Maven build configuration
- Redis integration

---

## Frontend

Templates for modern frontend applications.

Examples:

- Vue3 + Vite admin template
- UniApp project structure
- Axios wrapper
- Permission guard

---

## Deployment

Production deployment patterns.

Examples:

- Linux deployment scripts
- systemd service templates
- rollback scripts
- release directory structure

---

## DevOps

Infrastructure templates.

Examples:

- Nginx reverse proxy configs
- HTTPS configuration
- CI/CD pipelines
- monitoring scripts

---

## Database

Reusable database templates.

Examples:

- MySQL schema template
- migration template

---

## Snippets

Reusable engineering snippets.

Examples:

- Maven plugins
- Spring configuration
- Bash scripts
- Vue utilities

---

## Quick Start

Example: start a new backend service using a template.

### 1. Copy backend template

```bash
cp -r templates/backend/springboot-api my-api
```

### 2. Add deploy scripts

```bash
cp -r deploy/linux/java-api my-api/scripts
```
### 3. Follow the deployment guide
See the deployment playbook:

```bash
docs/02-deployment-playbook.md
```

## Documentation

Engineering guides and playbooks are located in:

docs/

```
Recommended reading order:

1. **Quick Start**  
   `docs/00-quickstart.md`

2. **Project Structure**  
   `docs/01-how-to-use-templates.md`

3. **Deployment Playbook**  
   `docs/02-deployment-playbook.md`
```



## Related Repository

Looking for **ready-to-run project starters**?

👉 See:  
https://github.com/yourname/project-starters

---

## Philosophy

This repository follows a simple engineering principle:

> **Automate repetition.  
Reuse infrastructure.  
Focus on building real features.**

---

## Contributing

Contributions are welcome.

You can contribute by:

- improving templates
- adding new infrastructure patterns
- fixing documentation
- sharing production-tested scripts

---

## License

MIT