
import pg from 'pg';
import 'dotenv/config';

const { Pool } = pg;

// Проверяем, что строка подключения загружена (для отладки, можно убрать позже)
if (!process.env.DATABASE_URL) {
  console.error('❌ КРИТИЧЕСКАЯ ОШИБКА: DATABASE_URL не найдена в .env');
  process.exit(1);
}

// СОЗДАЁМ ПУЛ ПОДКЛЮЧЕНИЙ
const pool = new Pool({
  connectionString: process.env.DATABASE_URL, // Берём строку из .env
  ssl: {
    rejectUnauthorized: false 
  }
});

// ПРОВЕРКА ПОДКЛЮЧЕНИЯ (события пула)
pool.on('connect', () => {
  console.log('✅ База данных подключена');
});

pool.on('error', (err) => {
  console.error('❌ Ошибка пула:', err.message);
});

// проверка
export async function testConnection() {
  try {
    const result = await pool.query('SELECT NOW()');    
    return true;
  } catch (err) {
    console.error('❌ Ошибка подключения:', err.message);
    throw err; // Пробрасываем ошибку дальше
  }
}

// ЭКСПОРТИРУЕМ пул и функцию
export { pool };