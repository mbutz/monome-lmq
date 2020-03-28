# monome-lmq-settings-30.rb
#
# changelog:
# integrate live looper
#
set :host, "localhost"
set :port, 14582
use_osc get(:host), get(:port)
use_bpm 120

set :current_page, 0

# group leds for faders
set :amp_grps, [
  (range 65, 70),   # vol0, seq
  (range 81, 86),   # vol1
  (range 97, 102),  # vol2
  (range 113, 118), # vol3
  (range 73, 78),   # vol0, rec
  (range 89, 94),   # vol1
  (range 105, 110), # vol2
  (range 121, 126)  # vol3
]

set :toggle_grps, [
  (ring 64, 80, 96, 112),  # 0: start seq loop
  (ring 70, 86, 102, 118), # 1: rec seq input
  (ring 71, 87, 103, 119), # 2: seq params
  (ring 72, 88, 104, 120), # 3: seq source sam/rec
  (ring 78, 94, 110, 126), # 4: arm for recording
  (ring 79, 95, 111, 127), # 5: rec params
  (ring 70, 86, 102, 118, 71, 87, 103, 119) # 6: delete rec seq input
]

# listed top (0/0) to bottom (15/7)
set :par_toggle_grps, [
  (range 1, 16),                                # 0: lpf
  (range 17, 32),                               # 1: hpf
  (range 33, 48),                               # 2: rate
  (range 49, 64),                               # 3: rpitch
  (range 65, 80),                               # 4: attack
  (range 81, 96),                               # 5: sustain/release
  (ring 103, 104, 105, 106, 107, 108, 109, 110, 119, 120, 121, 122, 123, 124, 125, 126), # 6: sample selector
  (range 97, 103),                              # 7: beat_stretch
  (range 113, 119),                             # 8: quant
  (ring 0, 16, 32, 48, 64, 80, 96, 112)         # 9: page selector (1..4 seq; 5..8 rec)
]

set :lpfs, (ring 130, 120, 110, 100, 95, 90, 87, 83, 80, 67, 64, 60, 57, 54, 50)
set :hpfs, (ring 0, 40, 50, 60, 70, 75, 80, 85, 90, 94, 98, 102, 106, 110, 115)
set :rates, (ring -0.125, -0.25, -0.5, -1, -2, -4, -8, 1, 0.125, 0.25, 0.5, 1, 2, 4, 8)
set :rpitchs, (ring -12, -10, -9, -7, -5, -4, -2, 0, 2, 4, 5, 7, 9, 10, 12)
set :attacks, (ring 0.0, 0.015, 0.02, 0.025, 0.03, 0.035, 0.04, 0.045, 0.05, 0.06, 0.07, 0.08, 0.09, 0.11, 0.125)
set :sus_rels, (ring 1, 0.125, 0.11, 0.1, 0.08, 0.07, 0.06, 0.05, 0.04, 0.03, 0.02, 0.01, 0.0075, 0.005, 0.0025)
set :beat_stretchs, (ring 64, 32, 16, 8, 4, 2)
set :quants, (ring 2, 1, 0.75, 0.5, 0.25, 0.125)
set :param_page, false # main or param page selected?
set :amps, (line 0.0, 1.0, steps: 6, inclusive: true)
# // sample colector
# expects 4 folders to be (set one and the same folder
# for the 4 slots; will take 16 samples per folder or wrap
# around if the folder contains less than 16 samples)
sample_free_all
set :folder_paths, ["~/projects/sonicpi/audio/samples/mb/lmq-test/01/",
                    "~/projects/sonicpi/audio/samples/mb/lmq-test/02/",
                    "~/projects/sonicpi/audio/samples/mb/lmq-test/03/",
                    "~/projects/sonicpi/audio/samples/mb/lmq-test/04/"]

samples_per_folder = []
samples = []

get(:folder_paths).each_with_index do | path, i |
  16.times do | j |
    p = path, j
    samples_per_folder.push(p)
  end
  samples.push(samples_per_folder)
  samples_per_folder = []
end

# Debug sample collector
# 4.times do | k |
#   puts "- Folder #{k} -------------------"
#   16.times do | l |
#     puts samples[k][l]
#   end
# end

set :samples, samples

# initially assigned sample
set :seq_samples, [
  get(:samples)[0][0],
  get(:samples)[1][0],
  get(:samples)[2][0],
  get(:samples)[3][0]
]

puts get(:seq_samples)
# // /sample collector

set :seq_amp, [0, 0, 0, 0]
set :rec_amp, [0, 0, 0, 0]
set :lpf, [130, 130, 130, 130, 130, 130, 130, 130]
set :hpf, [0, 0, 0, 0, 0, 0, 0, 0]
set :attack, [0, 0, 0, 0, 0, 0, 0, 0]
set :sus_rel, [1, 1, 1, 1, 0, 0, 0, 0]
set :rpitch, [0, 0, 0, 0, 0, 0, 0, 0]
set :rate, [1, 1, 1, 1, 1, 1, 1, 1]
set :beat_stretch, [8, 8, 8, 8]
set :quant, [0.25, 0.25, 0.25, 0.25]
set :num_slices, [16, 16, 16, 16]
set :seq_source, [2, 2, 2, 2] # 2 = inactive key = initial source are seq samples
set :seq_start, [true, true, true, true]
set :seq_rec, [false, false, false, false]
# set :seq_rec_score, [nil, nil, nil, nil]
# set :seq_rec_score, [(ring), (ring), (ring), (ring)] # initialze empty
set :seq_start_x, [0, 0, 0, 0]
set :seq_end_x, [15, 15, 15, 15]
set :firing, [false, false, false, false]
set :seq_mode, ["seq", "seq", "seq", "seq"]
set :came_from_main_page, false
set :ignore_key, false

# initial loading of sample in mode: seq
# set :path, get(:folders)[0]
# (0..3).each do | i |
#   load_sample_for_mode(get(:seq_mode)[i], i)
# end

# initialize default score 0..15
seq_score = []
4.times do
  score = []
  16.times do | i |
    score.push(i)
  end
  seq_score.push(score)
end
set :seq_score, seq_score
set :seq_rec_score, [[ ], [ ], [ ], [ ]]
set :fresh_start, [false, false, false, false]
set :last_slice_played, [nil, nil, nil, nil]
set :last_pressed, [nil, nil, nil, nil]
set :default_output, false
if get(:default_output)
  set :outputs, [1, 1, 1, 1]
else
  set :outputs, [3, 5, 7, 9]
end

# Live looper initialisation
set :default_len_track, 8 # default track length
set :monitor, true
set :time_fix_play, -0.025 # latency fix
set :rec_metro, get(:metro_amp) # recording metro volume
set :master_amp_rec, 2.0 # recording master volume
set :master_amp_play, 1.0 # playback master volume
set :sync_beatstep, 0
set :looper_len, [8, 8, 8, 8]
set :looper_play, [false, false, false, false]
set :looper_rec, [false, false, false, false]
set :seq_src_rec, [false, false, false, false]
set :metro_on, true
set :metro_amp, 1
# /looper initialisation

# // Init Pages ///////////////////////////////////////////////////

# FIXME: There must be a way to do this more elegantly
pages = []
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
