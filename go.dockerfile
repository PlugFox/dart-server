# Стартуем с официального базового образа Go
FROM golang:1.17 AS builder

# Устанавливаем рабочую директорию внутри контейнера
WORKDIR /app

# Копируем go mod и sum файлы и загружаем зависимости
COPY go.* ./
RUN go mod init go_hello
RUN go get github.com/valyala/fasthttp
RUN go mod download

# Копируем исходный код в контейнер
COPY . .

# Собираем приложение
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# Запуск нового этапа на основе образа scratch
FROM scratch
COPY --from=builder /app/main .
EXPOSE 8080

# Запуск бинарного файла
ENTRYPOINT ["./main"]
