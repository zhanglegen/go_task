@echo off
REM 测试脚本 - 个人博客系统API测试 (Windows版本)

set BASE_URL=http://localhost:8080/api
echo === 个人博客系统API测试 ===
echo Base URL: %BASE_URL%
echo.

REM 测试注册用户
echo 1. 测试用户注册...
curl -s -X POST "%BASE_URL%/register" ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"testuser\",\"password\":\"password123\",\"email\":\"test@example.com\"}"
echo.
echo.

REM 测试用户登录
echo 2. 测试用户登录...
curl -s -X POST "%BASE_URL%/login" ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"testuser\",\"password\":\"password123\"}"
echo.
echo.

REM 注意：Windows批处理脚本不支持直接提取JSON值
REM 请手动复制登录响应中的token，然后设置到下面的TOKEN变量中

echo 请手动设置TOKEN变量，然后继续测试...
echo 示例：set TOKEN=your_token_here
echo.

REM 测试创建文章（需要手动设置TOKEN）
echo 3. 测试创建文章（需要TOKEN）...
echo curl -X POST "%BASE_URL%/posts" ^
echo   -H "Content-Type: application/json" ^
echo   -H "Authorization: Bearer %TOKEN%" ^
echo   -d "{\"title\":\"我的第一篇文章\",\"content\":\"这是文章内容，包含了丰富的信息。\"}"
echo.

REM 测试获取所有文章
echo 4. 测试获取所有文章...
curl -s -X GET "%BASE_URL%/posts"
echo.
echo.

REM 测试获取单个文章
echo 5. 测试获取单个文章详情...
curl -s -X GET "%BASE_URL%/posts/1"
echo.
echo.

REM 测试添加评论
echo 6. 测试添加评论（需要TOKEN）...
echo curl -X POST "%BASE_URL%/posts/1/comments" ^
echo   -H "Content-Type: application/json" ^
echo   -H "Authorization: Bearer %TOKEN%" ^
echo   -d "{\"content\":\"很棒的文章！学到了很多。\"}"
echo.

REM 测试获取评论
echo 7. 测试获取文章评论...
curl -s -X GET "%BASE_URL%/posts/1/comments"
echo.
echo.

echo === API测试完成 ===
echo 注意：如果某些测试失败，请确保：
echo 1. 服务器正在运行 (go run main.go)
echo 2. MySQL数据库已正确配置
echo 3. 端口8080没有被占用
echo.
echo 对于需要token的测试，请手动设置TOKEN变量并执行相应的curl命令
pause