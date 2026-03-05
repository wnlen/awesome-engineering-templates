# Awesome Engineering Templates

<p align="center">
<a href="README.md">English</a> | 简体中文
</p>

一个收集 **生产级工程模板（Engineering Templates）** 的仓库，  
涵盖后端、前端、DevOps 与部署脚本。

本仓库提供可复用的工程模板和基础设施模式，用于帮助开发者更快速地启动和部署现代软件项目。

---

## ✨ 特性

- 生产级工程模板
- 后端、前端与 DevOps 基础设施配置
- 部署脚本与 CI/CD 示例
- 可复用的配置与代码片段
- 来自真实项目的工程实践

---

## 为什么创建这个仓库

在开始一个新项目时，我们通常需要重复做很多相同的事情：

- 项目结构搭建
- 部署脚本编写
- CI/CD 配置
- 基础设施配置
- DevOps 工具链

这些工作往往需要花费大量时间。

这个仓库整理了 **经过实践验证的工程模板与基础设施模式**，  
可以直接复用，而不需要每次从零开始。

---

## 仓库内容

### Backend（后端）

用于后端服务的生产级模板。

例如：

- Spring Boot API 项目结构
- Spring Boot 多模块架构
- Maven 构建模板
- Redis 与安全配置

---

### Frontend（前端）

现代前端项目模板。

例如：

- Vue3 + Vite 管理后台模板
- UniApp 构建配置
- Axios 请求封装
- 权限控制逻辑

---

### Deployment（部署）

生产环境部署脚本与部署模式。

例如：

- Linux 部署脚本
- systemd 服务模板
- 回滚脚本
- release 目录结构

---

### DevOps

基础设施与 DevOps 模板。

例如：

- Nginx 反向代理配置
- HTTPS 配置
- CI/CD pipeline
- 监控与健康检查脚本

---

### Database（数据库）

可复用数据库模板。

例如：

- MySQL Schema 模板
- Migration 模板

---

### Snippets（代码片段）

常见工程代码片段。

例如：

- Maven 插件配置
- Spring 配置模板
- Bash 脚本
- Vue 工具函数

---

## 📦 仓库结构


templates/ 可复用工程模板
deploy/ 部署脚本与部署结构
devops/ CI/CD、Nginx、监控
snippets/ 常用代码片段
docs/ 工程文档与实践指南
tools/ 工具脚本


---

## 🚀 快速开始

示例：使用模板创建一个新的后端服务。

```bash
# 复制后端模板
cp -r templates/backend/springboot-api my-api

# 添加部署脚本
cp -r deploy/linux/java-api my-api/scripts

然后按照部署指南继续：

docs/02-deployment-playbook.md
🔗 相关仓库

如果你需要 可以直接运行的项目脚手架，请查看：

👉 https://github.com/wnlen/project-starters

项目理念

本仓库遵循一个简单的工程原则：

自动化重复工作
复用基础设施
专注于真正的业务功能

贡献

欢迎贡献。

你可以通过以下方式参与：

改进现有模板

添加新的工程实践

修复文档问题

分享生产环境脚本

License

MIT