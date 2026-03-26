require('dotenv').config();
const express = require('express');
const morgan = require('morgan');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
// Лучше брать порт из переменных окружения, если нет - использовать 3000
const port = process.env.PORT || 3000;

// Подключение middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Маршруты
app.get('/', (req, res) => {
    res.send('Hello World!');
});

// Запуск сервера
app.listen(port, () => {
    // Исправлено: используются обратные кавычки (`) для подстановки переменной
    console.log(`Example app listening on port ${port}`);
});