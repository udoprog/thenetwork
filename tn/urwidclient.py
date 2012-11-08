import urwid

palette = [
    ('banner', 'black', 'light gray'),
    ('streak', 'black', 'dark red'),
    ('bg', 'black', 'dark blue'),
]


def exit_on_q(key):
    if key in ('q', 'Q'):
        raise urwid.ExitMainLoop()


def client_main(args):
    text = urwid.Edit("#> ", align='left', wrap='clip')
    console_text = urwid.Text(('streak', "Hello World"))
    console_filler = urwid.Filler(console_text, 'top')

    frame = urwid.Frame(console_filler, footer=text)

    frame.focus_position = 'footer'

    loop = urwid.MainLoop(frame, palette, unhandled_input=exit_on_q)
    loop.run()
