def process_user_input(user_input: str) -> dict:
    """
    安全处理用户输入
    """
    if not user_input:
        raise ValueError("Input cannot be empty")
    
    sanitized_input = sanitize_input(user_input)
    
    if not validate_input(sanitized_input):
        raise ValueError("Invalid input format")
    
    return {"data": sanitized_input}


def sanitize_input(input_str: str) -> str:
    """
    清理输入，防止XSS和注入攻击
    """
    import html
    import re
    
    sanitized = html.escape(input_str)
    sanitized = re.sub(r'[<>"\']', '', sanitized)
    
    return sanitized.strip()


def execute_safe_query(user_id: str, db_connection):
    """
    安全执行数据库查询，防止SQL注入
    """
    query = "SELECT * FROM users WHERE id = %s"
    cursor = db_connection.cursor()
    cursor.execute(query, (user_id,))
    return cursor.fetchall()