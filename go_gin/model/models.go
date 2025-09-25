package model

import (
	"log"
	"time"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

// User 模型表示系统中的用户
type User struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	Username  string         `gorm:"size:50;not null;unique" json:"username"` // 用户名，唯一
	Password  string         `gorm:"size:100;not null" json:"password"`      // 密码
	Email     string         `gorm:"size:100;not null;unique" json:"email"`   // 邮箱，唯一
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"` // 软删除字段
	Posts     []Post         `gorm:"foreignKey:UserID" json:"posts,omitempty"` // 用户的文章
	Comments  []Comment      `gorm:"foreignKey:UserID" json:"comments,omitempty"` // 用户的评论
}

// Post 模型表示博客文章
type Post struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	Title     string         `gorm:"size:200;not null" json:"title"`    // 文章标题
	Content   string         `gorm:"type:text;not null" json:"content"` // 文章内容
	UserID    uint           `gorm:"not null" json:"user_id"`           // 关联的用户ID
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"` // 软删除字段
	User      User           `gorm:"foreignKey:UserID" json:"user,omitempty"` // 文章作者
	Comments  []Comment      `gorm:"foreignKey:PostID" json:"comments,omitempty"` // 文章的评论
}

// Comment 模型表示文章评论
type Comment struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	Content   string         `gorm:"size:500;not null" json:"content"` // 评论内容
	UserID    uint           `gorm:"not null" json:"user_id"`          // 关联的用户ID
	PostID    uint           `gorm:"not null" json:"post_id"`          // 关联的文章ID
	CreatedAt time.Time      `json:"created_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"` // 软删除字段
	User      User           `gorm:"foreignKey:UserID" json:"user,omitempty"` // 评论作者
	Post      Post           `gorm:"foreignKey:PostID" json:"post,omitempty"` // 评论的文章
}

func InitDb() error {
	// 数据库连接配置
	// 格式: username:password@tcp(host:port)/dbname?charset=utf8mb4&parseTime=True&loc=Local
	dsn := "root:123321as@tcp(127.0.0.1:3306)/gorm?charset=utf8mb4&parseTime=True&loc=Local"

	// 连接数据库
	var err error
	DB, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info), // 显示SQL日志
	})
	if err != nil {
		return err
	}

	// 自动迁移创建表
	// AutoMigrate会根据模型结构创建表，已存在的表会被修改但不会删除数据
	err = DB.AutoMigrate(
		&User{},
		&Post{},
		&Comment{},
	)
	if err != nil {
		return err
	}

	log.Println("数据库表创建/迁移成功")
	return nil
}
