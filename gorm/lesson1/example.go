// package lesson1

// import (
// 	_ "database/sql"
// 	"fmt"
// 	_ "time"

// 	"gorm.io/gorm"
// )

// type Employees struct {
// 	id         int `gorm:"primaryKey"`
// 	name       string
// 	department string
// 	salary     float64
// }

// func Run(db *gorm.DB) {
// 	users := db.Where("name = ?", "技术部").Find(&[]User{})
// 	fmt.Println(users.Error, users.RowsAffected)

// }
