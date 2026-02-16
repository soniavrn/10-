import { pool, testConnection } from './db.js';

async function main() {
    console.log('🔄 Запуск проверки...');
    
    try {
        await testConnection();
        
        // Получаем время
        const result = await pool.query('SELECT NOW() as current_time');
        const serverTime = new Date(result.rows[0].current_time);
        
        // форматированный вывод
        console.log('📅 Время на сервере:', serverTime.toUTCString());
        console.log('🕒 Время по нашему часовому поясу:', serverTime.toLocaleString('ru-RU', { 
            timeZone: 'Europe/Moscow',
            dateStyle: 'full',
            timeStyle: 'medium'
        }));
        
    } catch (error) {
        console.log('❌ ОШИБКА:', error.message);
    } finally {
        await pool.end();
        console.log('👋 Соединение закрыто');
    }
}

main();