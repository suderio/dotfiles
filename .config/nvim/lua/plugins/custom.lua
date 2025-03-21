local HOME = os.getenv("HOME")
return {
  {
    "snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = [[
          
 _   _                 _           
| \ | |               (_)          
|  \| | ___  _____   ___ _ __ ___  
| . ` |/ _ \/ _ \ \ / / | '_ ` _ \ 
| |\  |  __/ (_) \ V /| | | | | | |
\_| \_/\___|\___/ \_/ |_|_| |_| |_|
                                   
                                   

 ]],
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = { "--config", HOME .. "/.config/markdownlint-cli2.yaml", "--" },
        },
      },
    },
  },
}
