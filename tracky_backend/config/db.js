
const mysql = require('mysql2/promise');
require('dotenv').config();

let dbConfig;

if (process.env.DATABASE_URL) {
    const dbUrl = new URL(process.env.DATABASE_URL);

    dbConfig = {
        host: dbUrl.hostname,
        port: Number(dbUrl.port || 3306),
        user: decodeURIComponent(dbUrl.username),
        password: decodeURIComponent(dbUrl.password),
        database: decodeURIComponent(dbUrl.pathname.replace(/^\//, '')),
        waitForConnections: true,
        connectionLimit: 5,
        queueLimit: 0
    };
} else {
    // Local development configuration
    dbConfig = {
        host: process.env.DB_HOST || 'localhost',
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD || '',
        database: process.env.DB_NAME || 'tracky_db',
        port: Number(process.env.DB_PORT || 3306),
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0
    };
}

const pool = mysql.createPool(dbConfig);

module.exports = pool;
