package go_base

import (
	"fmt"
	"strconv"
	"sync"
	"sync/atomic"
	"time"
)

// 111编写一个Go程序，定义一个函数，该函数接收一个整数指针作为参数，在函数内部将该指针指向的值增加10，然后在主函数中调用该函数并输出修改后的值。
func add(num *int) int {
	*num += 50
	return *num
}

// 222实现一个函数，接收一个整数切片的指针，将切片中的每个元素乘以2。
func mut2(slice *[]int) {
	for i := range *slice {
		(*slice)[i] *= 2
	}
}

// 333编写一个程序，使用 go 关键字启动两个协程，一个协程打印从1到10的奇数，另一个协程打印从2到10的偶数。
func printOdd(wg *sync.WaitGroup) {
	for i := 1; i <= 10; i += 2 {
		fmt.Println("111", i)
	}
}

func printOdd1(wg *sync.WaitGroup) {
	for i := 2; i <= 10; i += 2 {
		fmt.Println("222", i)
	}
}

// 444设计一个任务调度器，接收一组任务（可以用函数表示），并使用协程并发执行这些任务，同时统计每个任务的执行时间。
// Task 定义任务类型，接收任务名称和任务函数
type Task struct {
	Name string
	Func func() // 任务执行函数
}

// TaskResult 定义任务结果，包含任务名称和执行时间
type TaskResult struct {
	TaskName  string
	Duration  time.Duration
	Completed bool
}

// Scheduler 任务调度器
type Scheduler struct {
	tasks   []Task
	results chan TaskResult // 用于收集任务结果
	wg      sync.WaitGroup
}

// NewScheduler 创建新的调度器
func NewScheduler() *Scheduler {
	return &Scheduler{
		results: make(chan TaskResult, 100), // 缓冲通道，避免阻塞
	}
}

// AddTask 向调度器添加任务
func (s *Scheduler) AddTask(task Task) {
	s.tasks = append(s.tasks, task)
}

// runTask 执行单个任务并记录时间
func (s *Scheduler) runTask(task Task) {
	defer s.wg.Done()

	start := time.Now()
	defer func() {
		// 捕获任务执行中的panic，避免单个任务崩溃影响整体
		if err := recover(); err != nil {
			s.results <- TaskResult{
				TaskName:  task.Name,
				Duration:  time.Since(start),
				Completed: false,
			}
		}
	}()

	// 执行任务
	task.Func()

	// 记录执行时间
	s.results <- TaskResult{
		TaskName:  task.Name,
		Duration:  time.Since(start),
		Completed: true,
	}
}

// 555 定义一个 Shape 接口，包含 Area() 和 Perimeter() 两个方法。然后创建 Rectangle 和 Circle 结构体，实现 Shape 接口。在主函数中，创建这两个结构体的实例，并调用它们的 Area() 和 Perimeter() 方法。
type Shape interface {
	Area() float64
	Perimeter() float64
}

type Rectangle struct {
}

func (r Rectangle) Area() float64 {
	return 0
}

func (r Rectangle) Perimeter() float64 {
	return 0
}

type Circle struct {
}

func (c Circle) Area() float64 {
	return 1
}

func (c Circle) Perimeter() float64 {
	return 1
}

// Start 启动调度器，并发执行所有任务
func (s *Scheduler) Start() []TaskResult {
	// 注册等待的任务数量
	s.wg.Add(len(s.tasks))

	// 启动协程执行所有任务
	for _, task := range s.tasks {
		go s.runTask(task)
	}

	// 等待所有任务完成后关闭结果通道
	go func() {
		s.wg.Wait()
		close(s.results)
	}()

	// 收集所有任务结果
	var results []TaskResult
	for res := range s.results {
		results = append(results, res)
	}

	return results
}

// 666 使用组合的方式创建一个 Person 结构体，包含 Name 和 Age 字段，再创建一个 Employee 结构体，组合 Person 结构体并添加 EmployeeID 字段。为 Employee 结构体实现一个 PrintInfo() 方法，输出员工的信息。
type Person struct {
	Name string
	Age  int
}

type Employee struct {
	employeeID int
	person     Person
}

func (e Employee) PrintInfo() string {
	return "ID: " + strconv.Itoa(e.employeeID) + ", Name: " + e.person.Name + ", Age: " + string(e.person.Age)
}

// 777 实现一个带有缓冲的通道，生产者协程向通道中发送100个整数，消费者协程从通道中接收这些整数并打印。
func channelTest() {
	chan1 := make(chan int)

	go func() {
		for i := 0; i < 10; i++ {
			chan1 <- i
			//fmt.Println("send ", i)
		}
		close(chan1)
	}()

	go func() {
		for i := 0; i < 10; i++ {
			num := <-chan1
			fmt.Println("receive ", num)
		}
	}()

	time.Sleep(20000 * time.Second)
}

// 888 实现一个带有缓冲的通道，生产者协程向通道中发送100个整数，消费者协程从通道中接收这些整数并打印。
func channelNoCache() {
	chan1 := make(chan int, 100)

	go func() {
		for i := 0; i < 100; i++ {
			chan1 <- i
			//fmt.Println("send ", i)
		}
		close(chan1)
	}()

	go func() {
		for i := 0; i < 10; i++ {
			num := <-chan1
			fmt.Println("receive ", num)
		}
	}()

	time.Sleep(20000 * time.Second)

}

// 编写一个程序，使用 sync.Mutex 来保护一个共享的计数器。启动10个协程，每个协程对计数器进行1000次递增操作，最后输出计数器的值。
func add1(mu *sync.Mutex, num *int) {
	mu.Lock()
	defer mu.Unlock()
	for i := 0; i < 1000; i++ {
		*num++
	}
}

func testAdd1() {
	count := 10
	num2 := 0
	mu := sync.Mutex{}

	for i := 0; i < count; i++ {
		go add1(&mu, &num2)
	}
	// 等待所有协程完成
	time.Sleep(2 * time.Second)
	fmt.Println("Final num:", num2)
}

// 使用原子操作（ sync/atomic 包）实现一个无锁的计数器。启动10个协程，每个协程对计数器进行1000次递增操作，最后输出计数器的值。
func atomicTest() {
	var counter int64 // 计数器变量，必须使用int64以适配atomic包
	var wg sync.WaitGroup

	// 启动10个协程
	wg.Add(10)
	for i := 0; i < 10; i++ {
		go func() {
			defer wg.Done()
			// 每个协程递增1000次
			for j := 0; j < 1000; j++ {
				// 原子递增操作：将counter加1，返回新值
				atomic.AddInt64(&counter, 1)
			}
		}()
	}

	// 等待所有协程完成
	wg.Wait()

	// 原子加载操作：安全读取最终值
	finalValue := atomic.LoadInt64(&counter)
	fmt.Printf("最终计数器值: %d\n", finalValue) // 预期输出：10000
}

// 单元测试函数
func init() {

	wg := sync.WaitGroup{}
	wg.Add(2)

	go printOdd(&wg)
	go printOdd1(&wg)
	wg.Wait()
	fmt.Println("main over")

}
