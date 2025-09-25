package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/zhanglegen/go_task/go_gin/handlers"
	"github.com/zhanglegen/go_task/go_gin/login"
	"github.com/zhanglegen/go_task/go_gin/middleware"
)

// SetupRouter 设置路由
func SetupRouter() *gin.Engine {
	router := gin.Default()

	// 公共路由
	public := router.Group("/api")
	{
		// 用户认证
		public.POST("/register", login.Register)
		public.POST("/login", login.Login)

		// 文章相关（无需认证）
		public.GET("/posts", handlers.GetPosts)
		public.GET("/posts/:id", handlers.GetPost)
		public.GET("/posts/:postId/comments", handlers.GetComments)
	}

	// 需要认证的路由
	protected := router.Group("/api")
	protected.Use(middleware.AuthMiddleware())
	{
		// 文章管理
		protected.POST("/posts", handlers.CreatePost)
		protected.PUT("/posts/:id", handlers.UpdatePost)
		protected.DELETE("/posts/:id", handlers.DeletePost)

		// 评论管理
		protected.POST("/posts/:postId/comments", handlers.CreateComment)
	}

	return router
}