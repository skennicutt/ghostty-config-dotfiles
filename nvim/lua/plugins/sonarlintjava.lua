return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "sonarsource/sonarlint-language-server",
      "mfussenegger/nvim-jdtls", -- for Java LSP
    },
    opts = {
      servers = {
        sonarlint = {},
      },
    },
  },
}
