import pymysql
from pymysql.cursors import DictCursor

class DatabaseRouter:
    def __init__(self):
        self.master = {
            'host': 'master.db.example.com',
            'user': 'app',
            'password': 'password',
            'database': 'app_db'
        }
        self.slaves = [
            {'host': 'slave1.db.example.com', 'user': 'app', 'password': 'password', 'database': 'app_db'},
            {'host': 'slave2.db.example.com', 'user': 'app', 'password': 'password', 'database': 'app_db'},
        ]
        self.slave_index = 0
    
    def get_master_connection(self):
        return pymysql.connect(**self.master, cursorclass=DictCursor)
    
    def get_slave_connection(self):
        conn = pymysql.connect(**self.slaves[self.slave_index], cursorclass=DictCursor)
        self.slave_index = (self.slave_index + 1) % len(self.slaves)
        return conn
    
    def execute_write(self, sql, params=None):
        with self.get_master_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(sql, params)
                conn.commit()
                return cursor.lastrowid
    
    def execute_read(self, sql, params=None):
        with self.get_slave_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(sql, params)
                return cursor.fetchall()

router = DatabaseRouter()

users = router.execute_read("SELECT * FROM users WHERE status = %s", ('active',))
router.execute_write("INSERT INTO logs (message) VALUES (%s)", ('User login',))