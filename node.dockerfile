# Используем официальный образ Node.js
FROM node:16

# Создаем директорию приложения
WORKDIR /usr/src/app

# Копируем package.json и package-lock.json
COPY package*.json ./

# Устанавливаем зависимости приложения
RUN npm install

# Если вы хотите установить nodemon для разработки, можете добавить:
# RUN npm install -g nodemon

# Копируем исходный код приложения
COPY . .

# Объявляем порт, на котором работает приложение
EXPOSE 8080

# Запускаем приложение
CMD [ "node", "server.js" ]
