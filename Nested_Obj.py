def get_nested_value(obj, key):
    keys = key.split('.')
    current = obj
    for k in keys:
        if not isinstance(current, dict) or k not in current:
            return None
        current = current[k]
    return current