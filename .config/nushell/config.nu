# The default config record. This is where much of your global configuration is setup.
$env.config = {
    keybindings: [
        # The following bindings with `*system` events require that Nushell has
        # been compiled with the `system-clipboard` feature.
        # If you want to use the system clipboard for visual selection or to
        # paste directly, uncomment the respective lines and replace the version
        # using the internal clipboard.
        {
            name: copy_selection
            modifier: control_shift
            keycode: char_c
            mode: emacs
            event: { edit: copyselection }
            event: { edit: copyselectionsystem }
        }
        {
            name: cut_selection
            modifier: control_shift
            keycode: char_x
            mode: emacs
            event: { edit: cutselection }
            event: { edit: cutselectionsystem }
        }
        {
            name: paste_system
            modifier: control_shift
            keycode: char_v
            mode: emacs
            event: { edit: pastesystem }
        }
        {
            name: select_all
            modifier: control_shift
            keycode: char_a
            mode: emacs
            event: { edit: selectall }
        }
    ]
}
