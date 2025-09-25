# 个人博客系统后端

基于 Go + Gin + GORM 开发的个人博客系统后端，支持用户认证、文章管理和评论功能。

## 功能特性

- ✅ 用户注册和登录（JWT认证）
- ✅ 博客文章的CRUD操作
- ✅ 文章评论功能
- ✅ 用户权限管理（只能编辑/删除自己的文章）
- ✅ 统一错误处理和日志记录
- ✅ 数据库关系设计

## 项目结构

```
go_gin/
├── main.go              # 主程序入口
├── model/
│   └── models.go        # 数据库模型定义
├── handlers/
│   ├── post.go         # 文章处理函数
│   └── comment.go      # 评论处理函数
├── middleware/
│   └── auth.go         # JWT认证中间件
├── login/
│   └── login.go        # 用户认证处理
├── routes/
│   └── routes.go       # 路由配置
└── utils/
    ├── logger.go       # 日志工具
    └── error_handler.go # 错误处理工具
```

## 数据库设计

### Users 表
- id: 主键
- username: 用户名（唯一）
- password: 密码（加密存储）
- email: 邮箱（唯一）
- created_at: 创建时间
- updated_at: 更新时间
- deleted_at: 软删除时间

### Posts 表
- id: 主键
- title: 文章标题
- content: 文章内容
- user_id: 关联用户ID
- created_at: 创建时间
- updated_at: 更新时间
- deleted_at: 软删除时间

### Comments 表
- id: 主键
- content: 评论内容
- user_id: 关联用户ID
- post_id: 关联文章ID
- created_at: 创建时间
- deleted_at: 软删除时间

## API 接口文档

### 用户认证

#### 用户注册
```http
POST /api/register
Content-Type: application/json

{
    "username": "testuser",
    "password": "password123",
    "email": "test@example.com"
}
```

响应：
```json
{
    "message": "User registered successfully"
}
```

#### 用户登录
```http
POST /api/login
Content-Type: application/json

{
    "username": "testuser",
    "password": "password123"
}
```

响应：
```json
{
    "message": "Login successful",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
        "id": 1,
        "username": "testuser",
        "email": "test@example.com"
    }
}
```

### 文章管理

#### 获取所有文章
```http
GET /api/posts
```

响应：
```json
{
    "posts": [
        {
            "id": 1,
            "title": "文章标题",
            "content": "文章内容...",
            "user_id": 1,
            "created_at": "2023-09-24T10:00:00Z",
            "updated_at": "2023-09-24T10:00:00Z",
            "user": {
                "id": 1,
                "username": "testuser",
                "email": "test@example.com"
            }
        }
    ],
    "count": 1
}
```

#### 获取单个文章详情
```http
GET /api/posts/:id
```

响应：
```json
{
    "post": {
        "id": 1,
        "title": "文章标题",
        "content": "文章内容...",
        "user_id": 1,
        "created_at": "2023-09-24T10:00:00Z",
        "updated_at": "2023-09-24T10:00:00Z",
        "user": {
            "id": 1,
            "username": "testuser"
        },
        "comments": [
            {
                "id": 1,
                "content": "评论内容",
                "user_id": 2,
                "created_at": "2023-09-24T11:00:00Z",
                "user": {
                    "id": 2,
                    "username": "commenter"
                }
            }
        ]
    }
}
```

#### 创建文章（需要认证）
```http
POST /api/posts
Authorization: Bearer {token}
Content-Type: application/json

{
    "title": "新文章标题",
    "content": "新文章内容..."
}
```

响应：
```json
{
    "message": "Post created successfully",
    "post": {
        "id": 2,
        "title": "新文章标题",
        "content": "新文章内容...",
        "user_id": 1,
        "created_at": "2023-09-24T12:00:00Z",
        "updated_at": "2023-09-24T12:00:00Z"
    }
}
```

#### 更新文章（需要认证，只能更新自己的文章）
```http
PUT /api/posts/:id
Authorization: Bearer {token}
Content-Type: application/json

{
    "title": "更新后的标题",
    "content": "更新后的内容..."
}
```

响应：
```json
{
    "message": "Post updated successfully",
    "post": {
        "id": 1,
        "title": "更新后的标题",
        "content": "更新后的内容...",
        "user_id": 1,
        "created_at": "2023-09-24T10:00:00Z",
        "updated_at": "2023-09-24T13:00:00Z"
    }
}
```

#### 删除文章（需要认证，只能删除自己的文章）
```http
DELETE /api/posts/:id
Authorization: Bearer {token}
```

响应：
```json
{
    "message": "Post deleted successfully"
}
```

### 评论功能

#### 获取文章评论
```http
GET /api/posts/:postId/comments
```

响应：
```json
{
    "comments": [
        {
            "id": 1,
            "content": "评论内容",
            "user_id": 2,
            "post_id": 1,
            "created_at": "2023-09-24T11:00:00Z",
            "user": {
                "id": 2,
                "username": "commenter"
            }
        }
    ],
    "count": 1
}
```

#### 创建评论（需要认证）
```http
POST /api/posts/:postId/comments
Authorization: Bearer {token}
Content-Type: application/json

{
    "content": "新评论内容"
}
```

响应：
```json
{
    "message": "Comment created successfully",
    "comment": {
        "id": 2,
        "content": "新评论内容",
        "user_id": 1,
        "post_id": 1,
        "created_at": "2023-09-24T14:00:00Z"
    }
}
```

## 安装和运行

### 环境要求
- Go 1.19+
- MySQL 5.7+

### 安装依赖
```bash
cd go_gin
go mod tidy
```

### 配置数据库
确保MySQL服务正在运行，并创建数据库：
```sql
CREATE DATABASE gorm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 运行应用
```bash
go run main.go
```

服务器将在 http://localhost:8080 启动

## 测试示例

### 1. 注册用户
```bash
curl -X POST http://localhost:8080/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123","email":"test@example.com"}'
```

### 2. 用户登录
```bash
curl -X POST http://localhost:8080/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'
```

### 3. 创建文章（使用返回的token）
```bash
curl -X POST http://localhost:8080/api/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"title":"我的第一篇文章","content":"这是文章内容..."}'
```

### 4. 获取所有文章
```bash
curl http://localhost:8080/api/posts
```

### 5. 添加评论
```bash
curl -X POST http://localhost:8080/api/posts/1/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"content":"很棒的文章！"}'
```

## 错误处理

系统使用统一的错误处理机制，所有错误响应都遵循以下格式：

```json
{
    "error": "具体错误信息",
    "message": "用户友好的错误描述",
    "code": 400
}
```

常见的HTTP状态码：
- 200: 请求成功
- 201: 创建成功
- 400: 请求参数错误
- 401: 未认证（需要登录）
- 403: 无权限（只能操作自己的资源）
- 404: 资源不存在
- 500: 服务器内部错误

## 日志记录

系统会自动记录日志到 `logs/` 目录：
- `info_YYYY-MM-DD.log`: 一般信息日志
- `error_YYYY-MM-DD.log`: 错误日志

## 安全特性

1. **密码加密**: 使用 bcrypt 加密存储用户密码
2. **JWT认证**: 使用JWT token进行用户认证
3. **权限控制**: 用户只能编辑/删除自己的文章
4. **输入验证**: 对所有输入进行验证和清理
5. **错误信息**: 不暴露敏感的错误信息给客户端

## 扩展建议

1. 添加文章分类和标签功能
2. 实现文章搜索和过滤
3. 添加用户头像和个人信息
4. 实现文章点赞和收藏功能
5. 添加邮件通知功能
6. 实现文章草稿和发布状态
7. 添加API限流和防刷机制