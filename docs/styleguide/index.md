# Style Guide

This is the style guide for applying ttkbootstrap styles in Tcl/Tk. All styles are applied using `ttkbootstrap::bootstyle`, which translates keywords into ttk style strings.

## Colors

The following color keywords are available on all widgets and can be combined with widget-specific type keywords.

| Keyword      | Description                          |
|--------------|--------------------------------------|
| `primary`    | The default color for most widgets   |
| `secondary`  | Typically a grey color               |
| `success`    | Typically a green color              |
| `info`       | Typically a blue or teal color       |
| `warning`    | Typically an orange color            |
| `danger`     | Typically a red color                |
| `light`      | Typically a light grey color         |
| `dark`       | Typically a dark grey/black color    |

```tcl
# Info colored button
ttk::button .b -style [ttkbootstrap::bootstyle info TButton]

# Warning colored scale
ttk::scale .s -style [ttkbootstrap::bootstyle warning TScale]

# Success colored progressbar
ttk::progressbar .pb -style [ttkbootstrap::bootstyle success TProgressbar]
```

## Widget Style Pages

- [Button](button.md)
- [Checkbutton](checkbutton.md)
- [Combobox](combobox.md)
- [DateEntry](dateentry.md)
- [Entry](entry.md)
- [Frame](frame.md)
- [Label](label.md)
- [Labelframe](labelframe.md)
- [Menubutton](menubutton.md)
- [Meter](meter.md)
- [Notebook](notebook.md)
- [Panedwindow](panedwindow.md)
- [Progressbar](progressbar.md)
- [Radiobutton](radiobutton.md)
- [Scale](scale.md)
- [Scrollbar](scrollbar.md)
- [Separator](separator.md)
- [Sizegrip](sizegrip.md)
- [Spinbox](spinbox.md)
- [Treeview](treeview.md)
