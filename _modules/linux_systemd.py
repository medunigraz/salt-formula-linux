import re

def escape_path(path):
    return re.sub('[^A-Za-z0-9\/]', '\\x2d', path.strip('/')).replace('/', '-')
