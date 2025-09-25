package utils

import (
	"log"
	"os"
	"path/filepath"
	"time"
)

var (
	InfoLogger  *log.Logger
	ErrorLogger *log.Logger
)

func InitLogger() error {
	// 创建logs目录
	logDir := "logs"
	if err := os.MkdirAll(logDir, 0755); err != nil {
		return err
	}

	// 获取当前日期用于日志文件名
	currentDate := time.Now().Format("2006-01-02")

	// 创建info日志文件
	infoLogPath := filepath.Join(logDir, "info_"+currentDate+".log")
	infoFile, err := os.OpenFile(infoLogPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		return err
	}

	// 创建error日志文件
	errorLogPath := filepath.Join(logDir, "error_"+currentDate+".log")
	errorFile, err := os.OpenFile(errorLogPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		infoFile.Close()
		return err
	}

	// 初始化logger
	InfoLogger = log.New(infoFile, "INFO: ", log.Ldate|log.Ltime|log.Lshortfile)
	ErrorLogger = log.New(errorFile, "ERROR: ", log.Ldate|log.Ltime|log.Lshortfile)

	return nil
}

// LogInfo 记录信息日志
func LogInfo(message string) {
	if InfoLogger != nil {
		InfoLogger.Println(message)
	}
}

// LogError 记录错误日志
func LogError(message string) {
	if ErrorLogger != nil {
		ErrorLogger.Println(message)
	}
}

// LogErrorWithDetails 记录带详细信息的错误日志
func LogErrorWithDetails(message string, err error) {
	if ErrorLogger != nil {
		ErrorLogger.Printf("%s: %v", message, err)
	}
}