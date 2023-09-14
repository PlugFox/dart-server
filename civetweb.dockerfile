FROM debian:bullseye-slim

# Устанавливаем необходимые зависимости и средства сборки
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    wget

# Загружаем исходный код Civetweb
WORKDIR /src
RUN wget https://github.com/civetweb/civetweb/archive/refs/tags/v1.16.tar.gz \
    && tar xzf v1.16.tar.gz && rm v1.16.tar.gz

# Компилируем и устанавливаем Civetweb
WORKDIR /src/civetweb-1.16
RUN make lib WITH_SSL=1 && make install-lib

# Возвращаемся обратно в /src
WORKDIR /src

# Копируем наш обработчик в контейнер
COPY hello_handler.c .

# Собираем наше приложение
RUN gcc -o hello_server hello_handler.c -Icivetweb-1.16/include -lcivetweb -lpthread -ldl -lssl -lcrypto

# Запускаем сервер при запуске контейнера
CMD ["./hello_server"]
