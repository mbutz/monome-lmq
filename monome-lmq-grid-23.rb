# monome-lmq-grid-22.rb

# Start serialoscd with:
# /usr/bin/serialoscd resp. ~/bin/serialoscd
# config is here: ~/.config/serialoscd

set :host, "localhost"
set :port, 14582
use_osc get(:host), get(:port)
use_bpm 120
set :grid_size, 16
pages = []

#
# Page helper functions
#

define :pages_print do
  get(:pages).length.times do | p |
    row = ""
    puts "Page #{p}: ----------------"
    get(:pages)[0].length.times do | y |
      row += get(:pages)[p][y].to_s
      puts get(:pages)[p][y].to_s
    end
    puts "------------------------"
  end
end

#
# Set grid page item functions
#

# Set single grid page item
# args: x, y, state (0..15), page number (optional)
define :page_set do | x, y, s, page = 0 |
  p = pages[page]
  p[y][x] = s
  pages[page] = p
  #puts "---------------------- Page: #{p} --------------"
  #puts "---------------------- Pages: #{pages} --------------"
  set :pages, pages
end

# Set complete grid page
# args: state (0..15)
define :page_all do | s, page = 0 |
  p = []
  8.times do
    x = []
    get(:grid_size).times do
      x.push(s)
    end
    p.push(x)
  end
  pages[page] = p
  set :pages, pages
end

# Set row of grid page items
# args: y (row number), states (16 values 1..15), page number (optional)
define :page_row do | y, states, page = 0 |
  # FIXME: Errror handling
  if states.length != 16
    puts "ERROR page_row(): We need exactly 16 state values!"
    return
  end
  p = pages[page]
  p[y] = states
  pages[page] = p
  set :pages, pages
end

# Set col of grid page items
# args: x (col number), states (8 values 1..15), page number (optional)
define :page_col do | x, states, page = 0 |
  if states.length != 8
    puts "ERROR page_col(): We need exactly 8 state values!"
    return
  end
  p = pages[page]
  8.times do | i |
    p[i][x] = states[i]
  end
  pages[page] = p
  set :pages, pages
end

#
# Get page functions
#

define :page_get_row do | y, page = 0 |
  row = get(:pages)[page][y]
  return row
end


define :page_get_col do | x, page = 0 |
  p = get(:pages)[page]
  col = []
  8.times do | i |
    c = p[i][x]
    col.push(c)
  end
  return col
end

define :delay do | f = 1 |
  sleep 0.0625 * f
end

# Set single led
# args: x, y, state 0 or 1, page number (optional)
define :osc_set do | x, y, s, page = 0 |
  osc "/monome/grid/led/set", x, y, s
end

# Set all leds
# args: state 0 or 1
define :osc_all do | s, page = 0 |
  osc "/monome/grid/led/all", s
end

# Set 8x8 block of leds
# args: x and y offset (multiple of 8; use x_offset for 128 grid),
#       states (64 values 0 or 1), page number (optional)
define :osc_map do | x_offset, y_offset, states, page = 0 |
  state = []
  states.each_with_index do | y, i |
    bin = ""
    states[i].each do | x |
      bin += x.to_s
    end
    dec = bin.reverse.to_i(2)
    state.push(dec)
  end
  osc "/monome/grid/led/map", x_offset, y_offset, *state
end

# Set row of leds
# args: x_offset, y (row number), states (16 values 0 or 1), page number (optional)
define :osc_row do | x_offset, y, states, page = 0 |
  state = []
  state = states.join.reverse.to_i(2)
  osc "/monome/grid/led/row", x_offset, y, state
end

# Set col of leds
# args: x (col number), y_offset, states (8 values 0 or 1), page number (optional)
define :osc_col do | x, y_offset, states, page = 0|
  state = []
  state = states.join.reverse.to_i(2)
  osc "/monome/grid/led/col", x, y_offset, state
end

#
# Varibright level functions (state = [0..15]
#

# FIXME: Probably param page will not be needed in level functions

define :osc_set_level do | x, y, s, page = 0 |
  osc "/monome/grid/led/level/set", x, y, s
end

define :osc_all_level do | s |
  osc "/monome/grid/led/level/all", s
end

define :osc_map_level do | x_offset, y_offset, states, page = 0 |
  osc "/monome/grid/led/level/map", x_offset, y_offset, *states
end

define :osc_row_level do | x_offset, y, states, page = 0 |
  osc "/monome/grid/led/level/row", x_offset, y, *states
end

define :osc_col_level do | x, y_offset, states, page = 0|
  osc "/monome/grid/led/level/col", x, y_offset, *states
end

# page -> nested page array 8 lines, 16 vals per line
define :osc_page_level do | page |
  a, b = [], []
  page.each_with_index do | line |
    sides = line.each_slice(8).to_a
    a += sides[0] # left side of 128-key-monome
    b += sides[1] # right sideh
  end
  osc_map_level(0, 0, a) # x_offset, y_offset, states
  osc_map_level(8, 0, b)
end

#set :num_pages, 2
#init_pages()

# optional params:
# page: which page should be updated
# group: if != nil all leds from group will be reset
define :toggle do | x, y, lo = 0, hi = 15, page = 0, group = nil |
  # puts "Called 'toggle':__________________"
  # puts "X/Y: #{x}/#{y}"
  # get last state
  if page.is_a? Integer
    last_state = get(:pages)[page][y][x]
  elsif page == "all"
    last_state = get(:pages)[0][y][x]
  end
  # set state and handle led
  if last_state > lo
    osc_set_level(x, y, lo)
    state = lo
  else
    if group != nil
      group.each do | n |
        osc_set_level(n2c(n)[0], n2c(n)[1], lo)
        page_set(n2c(n)[0], n2c(n)[1], lo, page)
        delay()
      end
    end
    osc_set_level(x, y, hi)
    state = hi
  end
  # update pages
  if page.is_a? Integer
    # update only given page
    page_set(x, y, state, page)
  elsif page == "all"
    get(:num_pages).times do | i |
      page_set(x, y, state, i)
    end
  end
end

# // Init Pages ///////////////////////////////////////////////////

# FIXME: There must be a way to do this more elegantly
page0 = [
  [ 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2],
  [ 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2],
  [ 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2],
  [ 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2],
  [15,  0,  0,  0,  0,  0,  2,  0,  4,  0,  0,  0,  0,  0,  2,  0],
  [15,  0,  0,  0,  0,  0,  2,  0,  4,  0,  0,  0,  0,  0,  2,  0],
  [15,  0,  0,  0,  0,  0,  2,  0,  4,  0,  0,  0,  0,  0,  2,  0],
  [15,  0,  0,  0,  0,  0,  2,  0,  4,  0,  0,  0,  0,  0,  2,  0]
]
page1 = [
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0, 15,  0,  0, 15,  4,  4,  4,  4,  4,  4,  4,  0],
  [ 2,  0,  0,  0,  0, 15,  0,  4,  4,  4,  4,  4,  4,  4,  4,  0]
]
page2 = [
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0, 15,  0,  0, 15,  4,  4,  4,  4,  4,  4,  4,  0],
  [ 2,  0,  0,  0,  0, 15,  0,  4,  4,  4,  4,  4,  4,  4,  4,  0]
]
page3 = [
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  15, 0,  0, 15,  4,  4,  4,  4,  4,  4,  4,  0],
  [ 2,  0,  0,  0,  0, 15,  0,  4,  4,  4,  4,  4,  4,  4,  4,  0]
]
page4 = [
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0, 15,  0,  0, 15,  4,  4,  4,  4,  4,  4,  4,  0],
  [ 2,  0,  0,  0,  0, 15,  0,  4,  4,  4,  4,  4,  0,  4,  4,  0]
]
page5 = [
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0, 15,  0,  0,  2,  2,  2,  2,  2,  2,  2,  2,  0],
  [ 2,  0,  0,  0,  0, 15,  0,  2,  2,  2,  2,  2,  2,  2,  2,  0]
]
page6 = [
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0, 15,  0,  0,  2,  2,  2,  2,  2,  2,  2,  2,  0],
  [ 2,  0,  0,  0,  0, 15,  0,  2,  2,  2,  2,  2,  2,  2,  2,  0]
]
page7 = [
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0, 15,  0,  0,  2,  2,  2,  2,  2,  2,  2,  2,  0],
  [ 2,  0,  0,  0,  0, 15,  0,  2,  2,  2,  2,  2,  2,  2,  2,  0]
]
page8 = [
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0,  0,  0,  0,  0, 15,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
  [ 2,  0,  0,  0, 15,  0,  0,  2,  2,  2,  2,  2,  2,  2,  2,  0],
  [ 2,  0,  0,  0,  0, 15,  0,  2,  2,  2,  2,  2,  2,  2,  2,  0]
]


pages.push(page0)
pages.push(page1)
pages.push(page2)
pages.push(page3)
pages.push(page4)
pages.push(page5)
pages.push(page6)
pages.push(page7)
pages.push(page8)

set :pages, pages

pages_print()
