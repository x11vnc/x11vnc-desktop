#!/usr/bin/python3

"""
Stop VNC server and exit Docker desktop
"""

try:
    import tkinter as tk
except:
    import Tkinter as tk
import os

def clickLogout():
    import subprocess
    if os.getenv('SESSION_PID'):
        subprocess.call(['pkill', '-P', os.getenv('SESSION_PID')])
    else:
        subprocess.call(['sudo', 'kill', 'my_init'])


bgc = "steelblue3"
app = tk.Tk()
screen_width = app.winfo_screenwidth()
screen_height = app.winfo_screenheight()
app.title("Log out")
app.geometry("400x250+" + str(screen_width // 2 - 200) + '+' +
             str(screen_height // 2 - 125))

app.configure(bg=bgc)

tk.Label(app, text="", height=3, bg=bgc).pack()
tk.Label(app, text="Are you sure you want to quit all\n" +
         "applications and log out now?", fg='white', bg=bgc,
         font=("Sans-serif", 12, "bold"), height=2, width=100).pack()

tk.Label(app, text="Make sure you have saved your code and data to\n" +
         "a shared or a mounted folder before logging out.",
         fg='white', bg=bgc,
         font=("Sans-serif", 10), height=0, width=100).pack()

button_shutdown = tk.Button(app, text="Log out",
                            width=20, command=clickLogout)

button_cancel = tk.Button(app, text="Cancel",
                          width=20, command=app.destroy)

button_cancel.pack(side='bottom', pady=20)
button_shutdown.pack(side='bottom', pady=5)

app.bind("<Escape>", lambda e: e.widget.quit())

app.mainloop()
