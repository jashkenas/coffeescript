##Syntax Highlighting For .coffee Files in vim72

After copying the coffee.vim file into the `syntax` directory for your vim72 install, you have two options for enabling syntax highlighting of .coffee files

### Manually

In the vim console, do:

    :set syntax=coffee

### Automagically
The "least intrusive" way to add syntax highlighting for `.coffee` files in vim72 is to create a file (named, say, `filetype.vim`) in your `~/.vim` (or platform appropriate) folder. In it, you would put someting like:

    if exists("did_load_filetypes")
      finish
    end
    augroup filetypedetect
      au! BufRead,BufNewFile *.coffee setfiletype coffee
    augroup END

And the next time you open a `.coffee` file, voila!
