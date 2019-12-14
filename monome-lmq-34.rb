# monome-lmq-34.rb
#
# changelog:
# integrate live looper
#
set :host, "localhost"
set :port, 14582
use_bpm 120

use_cue_logging false
use_debug false
use_midi_logging false
use_osc_logging false

set :lib_path, "~/projects/sonicpi/github/monome-lib/"
set :include_path, "~/projects/sonicpi/github/monome-lmq/"
# ------ no further adjustment neccessary ----------------------------------------
use_osc get(:host), get(:port)
run_file get(:lib_path) + "monome-lib-23.rb"
sleep 1
osc_all(0)
sleep 1
run_file get(:include_path) + "monome-lmq-settings-30.rb"
run_file get(:lib_path) + "monome-helpers-22.rb"
run_file get(:include_path) + "monome-live-looper-01.rb"
osc_page_level(get(:pages)[0])
sleep 1

# Keep these local vars close to ll :listen_to_monome
start_y = nil # remember last rows for start
end_y = nil   # ... and end in case of double press
keys_held = 0 # track double press
seq_rec_score = [[ ], [ ], [ ], [ ]]

live_loop :listen_to_monome do
  use_real_time
  x, y, s = sync "/osc/monome/grid/key"
  pressed = c2n(x, y)
  # Page 0 //////////////////////////////////////////////////////////////////////
  if get(:current_page) == 0
    # // clips on and off /////////////////////////////////////////////
    if y <= 3 and s == 1
      keys_held = keys_held + s
      # single key press/no key held: set start position
      if keys_held == 1
        osc_set_level(x, y, 15)
        # remember last start key toggled
        set_pos(:seq_start_x, y, x)
        set_pos(:firing, y, true)
        # remember last row for start
        start_y = y
      elsif keys_held == 2
        # double press detected/first key held: set end
        osc_set_level(x, y, 15)
        # remember last end key toggled
        set_pos(:seq_end_x, y, x)
        set_pos(:firing, y, false)
        end_y = y
      end
      # record key presses
      if get(:seq_rec)[y] == true
        seq_rec_score[y].push(x)
        set_pos(:seq_rec_score, y, seq_rec_score[y])
      end
    elsif y <= 3 and s == 0 # on key up
      # clear key press cache
      keys_held = 0
      set_pos(:firing, y, false)
      osc_set_level(x, y, 2)
    end
    # // set score for current clip ///////////////////////////////////////////
    if y <= 3
      if get(:seq_start_x)[y] == get(:seq_end_x)[y]
        set_pos(:seq_score, y, (ring get(:seq_start_x)[y]))
      else
        set_pos(:seq_score, y, (range get(:seq_start_x)[y], get(:seq_end_x)[y], inclusive: true))
      end
    end
    # // Start sample loops /////////////////////////////////////////////////////
    if s == 1 and get(:toggle_grps)[0].member? pressed
      toggle(x, y, 2, 15)
      if get(:pages)[0][y][x] == 15
        set_pos(:seq_start, y-4, true)
      elsif get(:pages)[0][y][x] == 2
        set_pos(:seq_start, y-4, false)
      end
    end
    # // amp ///////////////////////////////////////////////////////////////////
    if s == 1 and get(:amp_grps).flatten.member? pressed
      grp = mem_of_grp(get(:amp_grps), pressed)
      y2 = y - 4 # y minus offset
      # toggle key if it's not the same just pressed or the first of group
      if pressed != get(:last_pressed)[y2] or pressed == get(:amp_grps)[grp][0]
        toggle(x, y, 0, 7, 0, get(:amp_grps)[grp])
        if [0, 1, 2, 3].member? grp
          set_pos(:seq_amp, y2, get(:amps)[x])
        elsif [4, 5, 6, 7].member? grp
          set_pos(:rec_amp, y2, get(:amps)[x-8])
        end
        #puts "----- #{get(:seq_amp)} / #{get(:rec_amp)} -----"
        # first fader key will toggle 0/0.25
        if x == 1 and get(:pages)[0][y][1] == 0
          set_pos(:seq_amp, y2, get(:amps)[0])
        elsif x == 9 and get(:pages)[0][y][9] == 0
          set_pos(:rec_amp, y2, get(:amps)[0])
        end
        set_pos(:last_pressed, y2, pressed)
      end
      puts "-------------> Rec Amp: #{get(:rec_amp)}"
    end # /amp
    # // Seq loop source ////////////////////////////////////////////////////
    if s == 1 and get(:toggle_grps)[3].member? pressed
      toggle(x, y, 4, 15)
      if get(:pages)[0][y][8] == 4
        set_pos(:seq_src_rec, y-4, false)
      elsif get(:pages)[0][y][8] == 15
        set_pos(:seq_src_rec, y-4, true)
      end
      pages_print()
      puts "-------------> Seq Source: #{get(:seq_src_rec)}"
    end
    # // Arm for Recording //////////////////////////////////////////////////////
    if s == 1 and get(:toggle_grps)[4].member? pressed
      toggle(x, y, 2, 15, 0, get(:toggle_grps)[4])
      if get(:pages)[0][y][14] == 2
        set_pos(:looper_rec, y-4, false)
      elsif get(:pages)[0][y][14] == 15
        set_pos(:looper_rec, y-4, true)
      end
      pages_print()
      puts "-------------> Arm for Recording: #{get(:looper_rec)}"
    end
    # // Load param pages from Main page / Record seq key presses ///////////////
    if (get(:toggle_grps)[6].member? pressed or get(:toggle_grps)[5].member? pressed) and get(:came_from_main_page) == false
      if s == 1 and x == 6 # Arm for seq recording
        keys_held = keys_held + s
        toggle(x, y, 2, 15)
        if get(:pages)[0][y][6] == 2
          set_pos(:seq_rec, y-4, false)
        elsif get(:pages)[0][y][6] == 15
          set_pos(:seq_rec, y-4, true)
        end
      elsif
        keys_held = 0
      end
      if s == 1 and (x == 7 or x == 15) # Param page
        keys_held = keys_held + s
        osc_set_level(x, y, 15)
      elsif  s == 0
        # seq param pages triggered by keys: x: 7; y: 4..7; page: 1..4; -> current_page = y-3
        if x == 7 and get(:ignore_key) == false
          set :current_page, y-3 # set current page
          page_set(0, get(:current_page)-1, 8, get(:current_page))
          osc_page_level(get(:pages)[y-3]) # load current page leds
        # rec param pages triggered by keys: x: 15; y: 4..7; page: 5..8; -> current_page = y+1
        elsif x == 7 and get(:ignore_key) == true
          set :ignore_key, false
          osc_set_level(x, y, 0)
        elsif x == 15
          set :current_page, y+1
          page_set(0, get(:current_page)-1, 8, get(:current_page))
          osc_page_level(get(:pages)[y+1])
        end
        keys_held = 0
      end
      if s == 1 and keys_held == 2 # Delete recorded seq score
        set :ignore_key, true
        seq_rec_score[y-4] = [ ]
        set_pos(:seq_rec_score, y-4, seq_rec_score[y-4])
      elsif s == 0 and keys_held == 2
        keys_held = 0
      end
    end
    #pages_print()
  end # page0 == true
  # Page 1..8 ///////////////////////////////////////////////////////////////////
  if get(:current_page) != 0
    # param page selector for pages 1..8
    if x == 0
      if s == 1
        set :current_page, y+1
        toggle(x, y, 0, 8, get(:current_page), get(:par_toggle_grps)[9])
      elsif s == 0
        page_col(x, [2, 2, 2, 2, 2, 2, 2, 2], get(:current_page)) # reset page selector
        page_set(x, y, 8, get(:current_page)) # set selector to current page
        osc_page_level(get(:pages)[get(:current_page)])  # set leds for current page
      end
    end

    if s == 1
      # lpf filter
      if get(:par_toggle_grps)[0].member? pressed
        toggle(x, y, 0, 15, get(:current_page), get(:par_toggle_grps)[0])
        set_pos(:lpf, get(:current_page)-1, get(:lpfs)[x-1])
      end
      # hpf filter
      if get(:par_toggle_grps)[1].member? pressed
        toggle(x, y, 0, 15, get(:current_page), get(:par_toggle_grps)[1])
        set_pos(:hpf, get(:current_page)-1, get(:hpfs)[x-1])
      end
      # rate
      if get(:par_toggle_grps)[2].member? pressed
        toggle(x, y, 0, 15, get(:current_page), get(:par_toggle_grps)[2])
        set_pos(:rate, get(:current_page)-1, get(:rates)[x-1])
      end
      # rpitch
      if get(:par_toggle_grps)[3].member? pressed
        toggle(x, y, 0, 15, get(:current_page), get(:par_toggle_grps)[3])
        set_pos(:rpitch, get(:current_page)-1, get(:rpitchs)[x-1])
      end
      # attack
      if get(:par_toggle_grps)[4].member? pressed
        toggle(x, y, 0, 15, get(:current_page), get(:par_toggle_grps)[4])
        set_pos(:attack, get(:current_page)-1, get(:attacks)[x-1])
      end
      # sustain (seq) / release (rec)
      if get(:par_toggle_grps)[5].member? pressed
        toggle(x, y, 0, 15, get(:current_page) , get(:par_toggle_grps)[5])
        set_pos(:sus_rel, get(:current_page)-1, get(:sus_rels)[x-1])
      end
      # beat_stretch
      if get(:par_toggle_grps)[7].member? pressed
        toggle(x, y, 2, 15, get(:current_page), get(:par_toggle_grps)[7])
        set_pos(:beat_stretch, get(:current_page)-1, get(:beat_stretchs)[x-1])
      end
      # quantization
      if get(:par_toggle_grps)[8].member? pressed
        toggle(x, y, 2, 15, get(:current_page), get(:par_toggle_grps)[8])
        set_pos(:quant, get(:current_page)-1, get(:quants)[x-1])
      end
      # sample selection
      if get(:par_toggle_grps)[6].member? pressed
        toggle(x, y, 4, 15, get(:current_page), get(:par_toggle_grps)[6])
        if y == 6 # check which row and set x-offset accordingly
          i = x - 7 # keys from 7..14 should deliver i from 0..7
        elsif y == 7
          i = x + 1 # keys from 7..14 should deliver i from 8..15
        end
        set_pos(:seq_samples, get(:current_page)-1, get(:samples)[get(:current_page)-1][i])
      end
      # toggle metronome
      if x == 15 and y == 6
        osc_set_level(x, y, 0, 15)
        # switch on/off metronome
      end

    end # s == 1

    # ESC key
    if s == 1 and x == 15 and y == 7
      set :came_from_main_page, true # force key to behave like ESC and not like param page switch
    elsif s == 0 and x == 15 and y == 7 and get(:came_from_main_page) == true # back to page 0
      osc_set_level(x, y, 0)
      osc_page_level(get(:pages)[0])
      page_set(0, get(:current_page)-1, 2, get(:current_page))
      set :current_page, 0
      set :came_from_main_page, false
    end
    #pages_print()
  end
end

define :init_seq do | y |
  live_loop ("seq_" + y.to_s).to_sym do
    # synced to: sync: ("looper_record_" + y.to_s).to_sym
    use_real_time
    if get(:seq_start)[y] == true and get(:seq_rec)[y] == false
      if get(:firing)[y]
        i = get(:seq_start_x)[y]
        set_pos(:last_slice_played, y, (get(:seq_start_x)[y] % get(:grid_size)))
        with_fx :sound_out_stereo, output: get(:outputs)[y] do
          s = sample get(:seq_samples)[y], amp: get(:seq_amp)[y], beat_stretch: get(:beat_stretch)[y], num_slices: get(:num_slices)[y], slice: i, lpf: get(:lpf)[y], hpf: get(:hpf)[y], attack: get(:attack)[y] / 2.0, sustain: get(:sus_rel)[y] / 4.0, rate: get(:rate)[y], rpitch: get(:rpitch)[y]
        end
        if get(:current_page) == 0 # display only if page 0 is active
          osc_set_level(i, y, 6)
        end
        sleep get(:quant)[y] / 6.0 * 5
        if get(:current_page) == 0 # display only if page 0 is active
          if get(:pages)[0][y][i] == 6
            osc_set_level(i, y, get(:pages)[0][y][i])
          else
            osc_set_level(i, y, 2)
          end
        end
        sleep get(:quant)[y] / 6.0 * 1
        # no button pressed
      elsif !get(:firing)[y]
        if get(:last_slice_played)[y] != nil
          tick_set 1
          set_pos(:last_slice_played, y, nil)
        end
        # let tick count from seq_start_x to seq_end_x
        i = tick % get(:seq_score)[y].size
        # fixme: not sure if I will need this as
        # grid rows/samples continue running
        if get(:fresh_start)[y]
          tick_set 1
          current = get(:seq_start_x)[y]
          # fresh_start[y] = false
          # set :fresh_start, fresh_start
          set_pos(:fresh_start, y, false)
        elsif
          current = get(:seq_score)[y][i].to_i
        end
        with_fx :sound_out_stereo, output: get(:outputs)[y] do
          s = sample get(:seq_samples)[y], amp: get(:seq_amp)[y], beat_stretch:get(:beat_stretch)[y], num_slices: get(:num_slices)[y], slice: current, lpf: get(:lpf)[y], hpf: get(:hpf)[y], attack: get(:attack)[y] / 2.0, sustain: get(:sus_rel)[y] / 4.0, rate: get(:rate)[y], rpitch: get(:rpitch)[y]
        end
        if get(:current_page) == 0 # display only if page 0 is active
          osc_set_level(current, y, 6)
        end
        sleep get(:quant)[y] / 6.0 * 5
        if get(:current_page) == 0 # display only if page 0 is active
          if get(:pages)[0][y][current] == 6
            osc_set_level(current, y, get(:pages)[0][y][current])
          else
            osc_set_level(current, y, 2)
          end
        end
        sleep get(:quant)[y] / 6.0 * 1
      end

    elsif get(:seq_start)[y] == true and get(:seq_rec)[y] == true and get(:seq_rec_score)[y].empty? == false
      # play recorded slices
      i = tick % get(:seq_rec_score)[y].size
      current = get(:seq_rec_score)[y][i].to_i
      with_fx :sound_out_stereo, output: get(:outputs)[y] do
        s = sample get(:seq_samples)[y], amp: get(:seq_amp)[y], beat_stretch:get(:beat_stretch)[y], num_slices: get(:num_slices)[y], slice: current, lpf: get(:lpf)[y], hpf: get(:hpf)[y], attack: get(:attack)[y] / 2.0, sustain: get(:sus_rel)[y] / 4.0, rate: get(:rate)[y], rpitch: get(:rpitch)[y]
      end
      if get(:current_page) == 0 # display only if page 0 is active
        osc_set_level(current, y, 6)
      end
      sleep get(:quant)[y] / 6.0 * 5
      if get(:current_page) == 0 # display only if page 0 is active
        if get(:pages)[0][y][current] == 6
          osc_set_level(current, y, get(:pages)[0][y][current])
        else
          osc_set_level(current, y, 2)
        end
      end
      sleep get(:quant)[y] / 6.0 * 1
    else
      # nothing is playing so indicate that next time
      # loop starts again it should start from the beginning
      if get(:fresh_start)[y] != true
        set_pos(:fresh_start, y, true)
      end
      sleep get(:quant)[y]
    end
  end # build seq loop
end
sleep 2
(0..3).each do |i|
  init_seq(i)
end

# /// Live Looper /////////////////////////////////////////////////////////////////

live_loop :beat do
  stop
  s = sample :elec_tick, amp: get(:metro_amp) if get(:metro_on)
  set :beat_metro, s # set pointer for control statement
  if get(:sync_beatstep) == 1
    midi_clock_beat
  end
  sleep 1
end

if get(:sync_beatstep) == 1
  midi_start
end

# Metronome                                                        #
live_loop :metro_marking_one do
  sync :rec
  s = sample :elec_tick, amp: get(:metro_amp), rate: 0.75 if get(:metro_on) == true
  set :marker_metro, s
  sleep get(:default_len_track)
end

(0..3).each do | i |
  build_playback_loop(i)
  build_recording_loop(i)
end
