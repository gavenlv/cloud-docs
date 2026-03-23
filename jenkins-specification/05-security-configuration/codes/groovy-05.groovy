// 安装: Role-based Authorization Strategy插件

// 配置步骤:
// 1. Manage Jenkins → Security → Authorization
//    选择: Role-Based Access Control

// 2. Manage and Assign Roles
//    - Manage Roles: 定义全局角色和项目角色
//    - Assign Roles: 分配角色给用户

// 定义全局角色:
// Manage Jenkins → Manage and Assign Roles → Manage Roles
// Global roles:
//   - admin: 所有权限
//   - developer: Job相关权限
//   - viewer: 只读权限

// 定义项目角色:
// Project roles:
//   - frontend-*: 前端项目权限
//   - backend-*: 后端项目权限

// 分配角色:
// Manage Jenkins → Manage and Assign Roles → Assign Roles
//   admin  → admin (global)
//   jane   → developer (global) + frontend-* (project)
//   john   → viewer (global) + backend-* (project)