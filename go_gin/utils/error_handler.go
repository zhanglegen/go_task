package utils

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// ErrorResponse 错误响应结构
type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message,omitempty"`
	Code    int    `json:"code"`
}

// HandleError 统一的错误处理函数
func HandleError(c *gin.Context, err error, message string, code int) {
	LogErrorWithDetails(message, err)

	response := ErrorResponse{
		Error:   err.Error(),
		Message: message,
		Code:    code,
	}

	c.JSON(code, response)
}

// HandleDBError 处理数据库错误
func HandleDBError(c *gin.Context, err error, message string) {
	if err == gorm.ErrRecordNotFound {
		HandleError(c, err, "Record not found", http.StatusNotFound)
		return
	}

	HandleError(c, err, message, http.StatusInternalServerError)
}

// HandleValidationError 处理验证错误
func HandleValidationError(c *gin.Context, err error) {
	HandleError(c, err, "Validation failed", http.StatusBadRequest)
}

// HandleUnauthorized 处理未授权错误
func HandleUnauthorized(c *gin.Context, message string) {
	c.JSON(http.StatusUnauthorized, gin.H{
		"error":   "Unauthorized",
		"message": message,
	})
}

// HandleForbidden 处理权限错误
func HandleForbidden(c *gin.Context, message string) {
	c.JSON(http.StatusForbidden, gin.H{
		"error":   "Forbidden",
		"message": message,
	})
}

// SuccessResponse 成功响应结构
type SuccessResponse struct {
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// SendSuccess 发送成功响应
func SendSuccess(c *gin.Context, message string, data interface{}) {
	response := SuccessResponse{
		Message: message,
		Data:    data,
	}
	c.JSON(http.StatusOK, response)
}

// SendCreated 发送创建成功响应
func SendCreated(c *gin.Context, message string, data interface{}) {
	response := SuccessResponse{
		Message: message,
		Data:    data,
	}
	c.JSON(http.StatusCreated, response)
}