# monome-lmq-helpers-22.rb
define :set_pos do | lst, pos, val |
  # puts "List: #{lst}"
  # puts "Position: #{pos}"
  # puts "Value: #{val}"
  item = [val]
  if pos + 1 == get(lst).size
    # position + 1 is out of bounds; just drop last element
    rest = []
  else
    rest = get(lst)[pos + 1..-1]
  end
  if pos == 0
    first = item
    set lst, first + rest
  elsif pos < get(lst).size
    first = get(lst)[0..pos - 1]
    set lst, first + item + rest
  elsif pos >= get(lst).size
    puts "Error: Position (#{pos.to_s}) for Value (#{val.to_s}) is out of list bounds (#{get(lst).size.to_s})."
  end
end

define :c2n do | x, y |
  num = x.to_i + 16 * y.to_i
  return num
end

define :n2c do | n |
  x = n % 16
  y = n / 16
  coords = [x.to_i, y.to_i]
  return coords
end

# find out to which group a pressed button belongs
# returns index of
define :mem_of_grp do | groups, num |
  groups.size.times do | i |
    if groups[i].member? num
      return i
    end
  end
  # msg "Not member!"
  return false
end

define :load_sample_for_mode do | mode, y |
  sample_free_all # don't know if that makes sense

  case mode
  when "seq" # sample come from defined folders on harddisk
    s = get(:path), y
    set ("sample_" + y.to_s), s
  when "rec" # samples come from .sonicpi cache folder
    i = y    # + 1 # FIXME: rename samples in looper so they start with 0
    s = "~/.sonic-pi/store/default/cached_samples/t" + i.to_s + ".wav"
    set ("sample_" + y.to_s), s
  when "tab" # not yet implemented
    msg "tab mode, don't know what to do yet ..."
  end
end
