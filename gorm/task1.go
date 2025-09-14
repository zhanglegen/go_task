package lesson1

import (
	_ "database/sql"
	"fmt"
	_ "time"

	"gorm.io/gorm"
)

// 假设有一个名为 students 的表，包含字段 id （主键，自增）、 name （学生姓名，字符串类型）、 age （学生年龄，整数类型）、 grade （学生年级，字符串类型）。
func usersql() {

	// INSERT into users values(1,'张三',20,'三年级')

	// SELECT * from users where age > 18

	// update users set grade = '四年级' where name = '张三'

	// delete from users where age < 15

}

// 假设有两个表： accounts 表（包含字段 id 主键， balance 账户余额）和 transactions 表（包含字段 id 主键， from_account_id 转出账户ID， to_account_id 转入账户ID， amount 转账金额）。
func transactionsql() {
	// -- 开始事务
	// BEGIN TRANSACTION;

	// -- 声明变量存储账户A、B的ID（假设A的ID为1，B的ID为2，可根据实际情况修改）
	// DECLARE @from_account_id INT = 1;
	// DECLARE @to_account_id INT = 2;
	// DECLARE @transfer_amount DECIMAL(10, 2) = 100.00;

	// -- 1. 检查账户A的余额是否足够（加排他锁防止并发修改，FOR UPDATE 是MySQL语法，其他数据库可能用 WITH (UPDLOCK)）
	// SELECT balance
	// INTO @a_balance
	// FROM accounts
	// WHERE id = @from_account_id
	// FOR UPDATE; -- 锁定该行，防止其他事务同时修改

	// -- 2. 判断余额是否充足
	// IF @a_balance >= @transfer_amount
	// BEGIN
	//     -- 3. 从账户A扣除100元
	//     UPDATE accounts
	//     SET balance = balance - @transfer_amount
	//     WHERE id = @from_account_id;

	//     -- 4. 向账户B增加100元
	//     UPDATE accounts
	//     SET balance = balance + @transfer_amount
	//     WHERE id = @to_account_id;

	//     -- 5. 记录转账交易
	//     INSERT INTO transactions (from_account_id, to_account_id, amount)
	//     VALUES (@from_account_id, @to_account_id, @transfer_amount);

	//     -- 提交事务（所有操作生效）
	//     COMMIT TRANSACTION;
	//     PRINT '转账成功';
	// END
	// ELSE
	// BEGIN
	//     -- 余额不足，回滚事务（所有操作取消）
	//     ROLLBACK TRANSACTION;
	//     PRINT '余额不足，转账失败';
	// END;
}

type Employees struct {
	ID         uint
	Name       string
	Department string
	Salary     float64
}

// 编写Go代码，使用Sqlx查询 employees 表中所有部门为 "技术部" 的员工信息，并将结果映射到一个自定义的 Employee 结构体切片中。
func Demo1(db *gorm.DB) {
	var techEmployees []Employees
	db.Debug().Where("department = ?", "技术部").Find(&techEmployees)
	for _, emp := range techEmployees {
		fmt.Printf("ID: %d, 姓名: %s, 部门: %s, 薪资: %.2f\n",
			emp.ID, emp.Name, emp.Department, emp.Salary)
	}
}

// 假设有一个 books 表，包含字段 id 、 title 、 author 、 price 。
func Demo2(db *gorm.DB) {
	type Books struct {
		ID     uint
		Title  string
		Author string
		Price  float64
	}
	var books []Books
	db.Debug().Where("price > ?", 50).Find(&books)
	for _, book := range books {
		fmt.Printf("ID: %d, 书名: %s, 作者: %s, 价格: %.2f\n",
			book.ID, book.Title, book.Author, book.Price)
	}
}

// 进阶GORM 模型定义
func Demo3(db *gorm.DB) {

	// 自动迁移：根据模型创建或更新数据库表结构
	// 会创建users、posts、comments三张表，并建立外键关系
	db.AutoMigrate(&User{}, &Post{}, &Comment{})

	// 输出成功信息
	println("数据库表创建/更新成功")

}

// User 模型定义（用户）
type User struct {
	gorm.Model        // 嵌入GORM默认模型，包含ID、CreatedAt、UpdatedAt、DeletedAt字段
	Username   string `gorm:"size:50;not null;unique"`  // 用户名，唯一且非空
	Email      string `gorm:"size:100;not null;unique"` // 邮箱，唯一且非空
	Posts      []Post `gorm:"foreignKey:UserID"`        // 一对多关系：一个用户有多篇文章
}

// Post 模型定义（文章）
type Post struct {
	gorm.Model             // 嵌入GORM默认模型
	Title        string    `gorm:"size:200;not null"` // 文章标题，非空
	Content      string    `gorm:"type:text"`         // 文章内容
	UserID       uint      `gorm:"not null"`          // 外键：关联用户ID
	User         User      `gorm:"foreignKey:UserID"` // 关联用户（反向引用）
	Comments     []Comment `gorm:"foreignKey:PostID"` // 一对多关系：一篇文章有多个评论
	CommentState string
}

// Comment 模型定义（评论）
type Comment struct {
	gorm.Model        // 嵌入GORM默认模型
	Content    string `gorm:"size:500;not null"` // 评论内容，非空
	PostID     uint   `gorm:"not null"`          // 外键：关联文章ID
	Post       Post   `gorm:"foreignKey:PostID"` // 关联文章（反向引用）
	UserID     uint   `gorm:"not null"`          // 外键：关联用户ID（评论者）
	User       User   `gorm:"foreignKey:UserID"` // 关联用户（评论者，反向引用）
}

// 编写Go代码，使用Gorm查询某个用户发布的所有文章及其对应的评论信息。
// 编写Go代码，使用Gorm查询评论数量最多的文章信息。
func Demo4(db *gorm.DB) {
	// 1. 查询指定用户的所有文章及其评论（示例用户ID=1）
	userID := uint(1)
	userPosts, err := getUserPostsWithComments(db, userID)
	if err != nil {
		fmt.Printf("查询用户文章失败: %v\n", err)
	} else {
		printUserPostsWithComments(userPosts)
	}

	// 2. 查询评论数量最多的文章
	topPost, err := getPostWithMostComments(db)
	if err != nil {
		fmt.Printf("查询评论最多的文章失败: %v\n", err)
	} else if topPost.ID == 0 {
		fmt.Println("没有找到文章")
	} else {
		printTopPost(topPost)
	}
}

// 1. 查询指定用户的所有文章及其评论
func getUserPostsWithComments(db *gorm.DB, userID uint) ([]Post, error) {
	var posts []Post
	// 使用Preload预加载关联的评论和用户信息
	result := db.Debug().Preload("Comments").Preload("User").
		Where("user_id = ?", userID).
		Find(&posts)
	return posts, result.Error
}

// 打印用户文章及评论
func printUserPostsWithComments(posts []Post) {
	fmt.Println("\n===== 用户的文章及评论 =====")
	for _, post := range posts {
		fmt.Printf("\n文章ID: %d, 标题: %s\n", post.ID, post.Title)
		fmt.Printf("内容: %s\n", post.Content)
		fmt.Printf("评论数: %d\n", len(post.Comments))
		fmt.Println("评论列表:")
		for _, comment := range post.Comments {
			fmt.Printf("- 评论ID %d: %s (评论者ID: %d)\n", comment.ID, comment.Content, comment.UserID)
		}
	}
}

// 2. 查询评论数量最多的文章
func getPostWithMostComments(db *gorm.DB) (Post, error) {
	var topPost Post
	// 子查询：统计每篇文章的评论数
	subQuery := db.Model(&Comment{}).
		Select("post_id, count(*) as comment_count").
		Group("post_id").
		Order("comment_count DESC").
		Limit(1)

	// 主查询：关联文章信息
	result := db.Model(&Post{}).
		Joins("JOIN (?) as comment_counts ON posts.id = comment_counts.post_id", subQuery).
		Preload("User").
		Preload("Comments").
		First(&topPost)

	return topPost, result.Error
}

// 打印评论最多的文章
func printTopPost(post Post) {
	fmt.Println("\n===== 评论最多的文章 =====")
	fmt.Printf("文章ID: %d\n", post.ID)
	fmt.Printf("标题: %s\n", post.Title)
	fmt.Printf("作者: %s\n", post.User.Username)
	fmt.Printf("评论总数: %d\n", len(post.Comments))
}

// Post模型的创建前钩子：在文章创建前执行
func (p *Post) BeforeCreate(tx *gorm.DB) error {
	// 这里仅做准备，实际更新在AfterCreate中
	return nil
}

// Post模型的创建后钩子：文章创建成功后更新用户的文章数量
func (p *Post) AfterCreate(tx *gorm.DB) error {
	// 给对应用户的文章数量加1
	return tx.Model(&User{}).
		Where("id = ?", p.UserID).
		Update("post_count", gorm.Expr("post_count + ?", 1)).Error
}

// Comment模型的删除后钩子：评论删除后检查文章评论数量
func (c *Comment) AfterDelete(tx *gorm.DB) error {
	// 1. 查询该评论所属的文章
	var post Post
	if err := tx.First(&post, c.PostID).Error; err != nil {
		return err
	}

	// 2. 统计该文章剩余的评论数量
	var commentCount int64
	if err := tx.Model(&Comment{}).
		Where("post_id = ?", c.PostID).
		Count(&commentCount).Error; err != nil {
		return err
	}

	// 3. 如果评论数量为0，更新文章的评论状态
	if commentCount == 0 {
		return tx.Model(&Post{}).
			Where("id = ?", c.PostID).
			Update("comment_state", "无评论").Error
	} else if post.CommentState != "有评论" {
		// 如果还有评论但状态不是"有评论"，则更新为"有评论"
		return tx.Model(&Post{}).
			Where("id = ?", c.PostID).
			Update("comment_state", "有评论").Error
	}
	return nil
}

// 初始化文章评论状态的钩子（创建文章时）
func (p *Post) AfterSave(tx *gorm.DB) error {
	// 新文章默认评论状态为"无评论"
	if p.CommentState == "" {
		return tx.Model(p).Update("comment_state", "无评论").Error
	}
	return nil
}
