# telescope-sonictemplate

Integration for [sonictemplate-vim](https://github.com/mattn/vim-sonictemplate) with [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).

## Requirements

* [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
* [sonictemplate-vim](https://github.com/mattn/vim-sonictemplate)


## Installation

```
Plug 'telescope-sonictemplate'

lua require'telescope'.load_extensions('sonictemplate')
```

## Usage

```
lua require'telescope'.extensions.sonictemplate.templates{}
```

or

```
Telescope sonictemplate templates
```



## License

MIT
