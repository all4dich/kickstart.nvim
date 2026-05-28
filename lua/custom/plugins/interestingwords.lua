return {
  'Mr-LLLLL/interestingwords.nvim',
  opts = {
    -- Optional: Customize the highlight group for interesting words
    colors = { '#aeee00', '#ff0000', '#0000ff', '#b88823', '#ffa724', '#ff2c4b' },
    search_count = true,
    navigation = true,
    scroll_center = true,
    search_key = "<leader>m",
    cancel_search_key = "<leader>M",
    color_key = "<leader>k",
    cancel_color_key = "<leader>K",
    select_mode = "random",  -- random or loop
  },
}
