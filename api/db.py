import os
import mysql.connector
from mysql.connector import pooling
from dotenv import load_dotenv
from typing import Any, Dict, List, Tuple

load_dotenv()

DB_HOST = os.getenv("DB_HOST", "161.132.55.248")
DB_PORT = int(os.getenv("DB_PORT", "3306"))
DB_USER = os.getenv("DB_USER", "admin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "Upt2025")
DB_NAME = os.getenv("DB_NAME", "epis_proyectos")

_pool: pooling.MySQLConnectionPool | None = None


def _init_pool() -> pooling.MySQLConnectionPool:
    global _pool
    if _pool is None:
        _pool = pooling.MySQLConnectionPool(
            pool_name="epis_pool",
            pool_size=int(os.getenv("DB_POOL_SIZE", "5")),
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            autocommit=False,
        )
    return _pool


def get_connection():
    return _init_pool().get_connection()


def query(sql: str, params: Tuple[Any, ...] = ()) -> List[Dict[str, Any]]:
    conn = get_connection()
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(sql, params)
        rows = cur.fetchall()
        return rows
    finally:
        try:
            cur.close()  # type: ignore
        except Exception:
            pass
        conn.close()


def execute(sql: str, params: Tuple[Any, ...] = ()) -> int:
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(sql, params)
        conn.commit()
        return cur.rowcount
    finally:
        try:
            cur.close()
        except Exception:
            pass
        conn.close()


def insert(sql: str, params: Tuple[Any, ...] = ()) -> int:
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(sql, params)
        conn.commit()
        return int(cur.lastrowid or 0)
    finally:
        try:
            cur.close()
        except Exception:
            pass
        conn.close()