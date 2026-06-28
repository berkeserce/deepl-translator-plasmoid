# DeepL Translator Plasmoid

A small KDE Plasma panel widget for translating typed text with the DeepL API.

This project is an independent widget and is not affiliated with DeepL SE.

## Features

- Panel icon with a compact popup translator
- DeepL API Free and Pro endpoint selection
- Configurable source and target language
- Local 128 KiB request size guard
- Friendly DeepL error messages
- Copyable translation result
- Optional automatic copy after translation
- Recent translation history in the popup
- Paste-and-translate and keyboard shortcuts

## Requirements

- KDE Plasma 6 or newer
- `kpackagetool6`
- A DeepL API key
- `plasmoidviewer` from `plasma-sdk` for local previewing

## Install

From the repository root:

```sh
kpackagetool6 --type Plasma/Applet --install .
```

After editing files, update the installed widget:

```sh
kpackagetool6 --type Plasma/Applet --upgrade .
```

Then add **DeepL Translator** from the Plasma widget picker.

## Test

```sh
plasmoidviewer -a .
```

If Plasma keeps an old version loaded, restart Plasma Shell:

```sh
kquitapp6 plasmashell
plasmashell > /dev/null 2>&1 & disown
```

## Settings

Open the widget settings and enter your DeepL API key. Use the Free endpoint
for DeepL API Free accounts and the Pro endpoint for paid API accounts.

Set default source and target languages in the widget settings. The translator
popup lets you override both languages for each translation. Choose **Auto
detect** as the source language to let DeepL detect the input language.

The popup shows the current request size and blocks requests that exceed
DeepL's 128 KiB text translation limit. Successful translations show the
detected source language and billed character count when DeepL returns them.

Enable automatic copy in the widget settings if you want successful
translations copied to the clipboard immediately. The popup keeps a local
recent translation history so previous source/result pairs can be restored
quickly. Use the paste button to translate the current clipboard contents.

Keyboard shortcuts in the popup:

- `Enter`: translate
- `Shift+Enter`: insert a new line
- `Ctrl+Enter`: translate
- `Ctrl+L`: focus and select the source text
- `Ctrl+C`: copy the translation when no text selection is active

The API key is stored in the widget's local Plasma configuration. Do not commit
your personal Plasma config files to this repository.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE)
