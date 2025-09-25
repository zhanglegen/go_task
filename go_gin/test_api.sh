#!/bin/bash

# 测试脚本 - 个人博客系统API测试

BASE_URL="http://localhost:8080/api"
echo "=== 个人博客系统API测试 ==="
echo "Base URL: $BASE_URL"
echo

# 测试注册用户
echo "1. 测试用户注册..."
curl -s -X POST "$BASE_URL/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123","email":"test@example.com"}' | jq .
echo

# 测试用户登录
echo "2. 测试用户登录..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}')
echo "$LOGIN_RESPONSE" | jq .

# 提取token
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
echo "获取到的Token: $TOKEN"
echo

# 测试创建文章
echo "3. 测试创建文章..."
curl -s -X POST "$BASE_URL/posts" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"我的第一篇文章","content":"这是文章内容，包含了丰富的信息。"}' | jq .
echo

# 测试获取所有文章
echo "4. 测试获取所有文章..."
curl -s -X GET "$BASE_URL/posts" | jq .
echo

# 测试获取单个文章
echo "5. 测试获取单个文章详情..."
curl -s -X GET "$BASE_URL/posts/1" | jq .
echo

# 测试添加评论
echo "6. 测试添加评论..."
curl -s -X POST "$BASE_URL/posts/1/comments" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"content":"很棒的文章！学到了很多。"}' | jq .
echo

# 测试获取评论
echo "7. 测试获取文章评论..."
curl -s -X GET "$BASE_URL/posts/1/comments" | jq .
echo

echo "=== API测试完成 ==="
echo "注意：如果某些测试失败，请确保："
echo "1. 服务器正在运行 (go run main.go)"
echo "2. MySQL数据库已正确配置"
echo "3. 端口8080没有被占用"