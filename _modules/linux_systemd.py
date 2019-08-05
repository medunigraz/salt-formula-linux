import re

def escape_path(path):
    return re.sub('[^A-Za-z0-9_\/]', r'\\x2d', path.strip('/')).replace('/', '-')
