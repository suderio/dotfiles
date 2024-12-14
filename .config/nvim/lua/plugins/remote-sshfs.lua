return {
  "nosduco/remote-sshfs.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  opts = { connections = {
    sshfs_args = {
      "-o StrictHostKeyChecking=accept-new",
    },
  } },
}
