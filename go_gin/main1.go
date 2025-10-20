package main

import (
	//_ "github.com/gin-gonic/gin
	"log"

	"github.com/zhanglegen/go_task/go_gin/model"
	_ "github.com/zhanglegen/go_task/go_gin/model"
	"github.com/zhanglegen/go_task/go_gin/routes"
	"github.com/zhanglegen/go_task/go_gin/utils"
)

func main() {
	// router := gin.Default()
	// router.GET("/ping", func(c *gin.Context) {
	// 	c.JSON(200, gin.H{
	// 		"message": "pong",
	// 	})
	// })
	// router.Run() // 默认监听 0.0.0.0:8080
	//model.InitDb()

	// 初始化日志
	if err := utils.InitLogger(); err != nil {
		log.Fatalf("Failed to initialize logger: %v", err)
	}

	// 初始化数据库
	if err := model.InitDb(); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	utils.LogInfo("Blog system starting...")

	// 设置路由
	router := routes.SetupRouter()

	utils.LogInfo("Server starting on port 8080...")

	// 启动服务器
	if err := router.Run(":8080"); err != nil {
		utils.LogErrorWithDetails("Failed to start server", err)
		log.Fatalf("Failed to start server: %v", err)
	}
}
