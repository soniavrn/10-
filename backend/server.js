require('dotenv').config();
const express = require('express');
const morgan = require('morgan');
const cors = require('cors');
const helmet = require('helmet');
const axios = require('axios');

const app = express();
const port = 3000;
const YANDEX_API_KEY = '21299fa8-8bb7-40d7-a5e4-ce3dc091b746'; // ⬅️ ВСТАВЬ СВОЙ КЛЮЧ ОТ ЯНДЕКСА

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Функция для получения координат города через Яндекс.Геокодер
async function getCoordinates(city) {
    try {
        const url = `https://geocode-maps.yandex.ru/1.x/?apikey=${YANDEX_API_KEY}&geocode=${encodeURIComponent(city)}&format=json`;
        const response = await axios.get(url);
        const featureMember = response.data.response.GeoObjectCollection.featureMember;
        
        if (featureMember.length === 0) return null;
        
        const pos = featureMember[0].GeoObject.Point.pos;
        const [lon, lat] = pos.split(' ');
        return { lat: parseFloat(lat), lon: parseFloat(lon) };
    } catch (error) {
        console.error('Ошибка геокодирования:', error.message);
        return null;
    }
}

// ✅ ГЛАВНОЕ — МАРШРУТ ДЛЯ ПОСТРОЕНИЯ МАРШРУТА
app.get('/route', async (req, res) => {
    try {
        const from = req.query.from;
        const to = req.query.to;

        if (!from || !to) {
            return res.status(400).json({ error: 'Укажи параметры from и to' });
        }

        console.log(`Запрос маршрута: из ${from} в ${to}`);

        // Получаем координаты
        const fromCoord = await getCoordinates(from);
        const toCoord = await getCoordinates(to);

        if (!fromCoord || !toCoord) {
            return res.status(404).json({ error: 'Один из городов не найден' });
        }

        // Здесь можно добавить запрос к API построения маршрутов
        // Пока возвращаем только координаты
        res.json({
            from: {
                name: from,
                ...fromCoord
            },
            to: {
                name: to,
                ...toCoord
            },
            message: `Маршрут из ${from} в ${to} построен (координаты получены)`
        });

    } catch (error) {
        console.error('Ошибка в /route:', error);
        res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
});

// Тестовый маршрут
app.get('/', (req, res) => {
    res.send('Hello World! Сервер работает');
});

// Запуск сервера
app.listen(port, () => {
    console.log(`🚀 Сервер запущен на http://localhost:${port}`);
});