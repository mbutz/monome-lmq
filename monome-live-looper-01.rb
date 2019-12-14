# (Re)Play and Record Functions
define :build_playback_loop do | i |
  track_sample = buffer["t" + i.to_s, get(:looper_len)[i]]
  # controls start with 4 because param 1..3 are for seq
  j = i + 4
  ctrl = ("t" + i.to_s).to_sym
  live_loop ("looper_play" + i.to_s).to_sym do
    on get(:looper_rec)[i] do
      cue :rec # let rec loop start with next run
      cnt = tick % 2
      in_thread do
        if cnt < 1
          n = get(:looper_len)[i] / 2.0
          sleep n
          n.times do
            m = sample :elec_tick, rate: 1.5, amp: get(:metro_amp) if get(:metro_on)
            set :mute_metro, m
            sleep 1
          end
        end
      end
    end #on :looper_rec[n]
      time_warp get(:time_fix_play) do
        s = sample track_sample,
          amp: get(:rec_amp)[i],
          lpf: get(:lpf)[j],
          hpf: get(:hpf)[j],
          attack: get(:attack)[j] * get(:looper_len)[i] / 2.0,
          release: get(:sus_rel)[j] * get(:looper_len)[i] / 2.0,
          rpitch: get(:rpitch)[j]

        set ctrl, s
      end # time_warp
    sleep get(:looper_len)[i]
  end
end

define :build_recording_loop do |i| # 0..3
  track_sample = buffer["t" + i.to_s, get(:looper_len)[i]]
  audio = ("audio_" + i.to_s).to_sym
  live_loop ("looper_record_" + i.to_s).to_sym do
   if get(:looper_rec)[i]
      sync :rec
      set_pos(:looper_rec, i, false)
      in_thread do
        t = get(:looper_len)[i]
        (2 * t).times do
          osc_set_level(14, i+4, 15)
          sleep 0.25
          osc_set_level(14, i+4, 0)
          sleep 0.25
        end
      end
      live_audio :mon, :stop
      with_fx :record, buffer: track_sample, pre_amp: get(:master_amp_rec) do
        live_audio audio, stereo: true
      end
      sleep get(:looper_len)[i]
      live_audio audio, :stop
      osc_set_level(14, i+4, 2)
    elsif
      if get(:monitor)
        live_audio :mon, stereo: true # switch monitor on
      end
      sleep get(:looper_len)[i]
    end
  end
end
