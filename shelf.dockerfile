# Используйте официальный образ Dart
FROM dart:latest AS build

# Установите рабочий каталог
WORKDIR /app

# Копируйте все файлы приложения в контейнер
COPY example/shelf/ .

RUN ls -la

# Получите зависимости и скомпилируйте приложение
RUN dart pub get
RUN dart compile exe bin/server.dart -o bin/server

# Создайте новый этап с минимальным образом
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# Укажите команду для запуска приложения
CMD ["/app/bin/server"]
