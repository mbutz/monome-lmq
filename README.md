# Monome lmq

An Monome application to manipulate preconfigured or live recorded samples in Sonic Pi. Here is a [short video](https://www.youtube.com/watch?v=1BX77a6eO68) showing lmq in action.

- Numbers in brackets, such as (1), refer to the white numbers in black circles in the illustrations  below.
- The first illustration shows the lmq main page (a), the second shows one of the 8 parameter pages (b).
- Monome keys/leds are referred to as col (x) and row (y) numbers. Keep in mind that the program starts counting from 0 to 7. The following description uses the more intuitive numbering starting with 1. On the whole the 128 key Monome provides 16 columns and 8 rows.

lmq works with two kinds of samples:

1. samples you have stored on your harddisk. Functionality associated with those samples is being referred to as `seq` or `sequencer`.
2. samples you can record live with the live looper referred to as `rec`, `recorded`.

As to 1.: The seq samples are being sliced into a number of slices (16 by default) and will be available for sequencing and other manipulation via the `seq led rows` (1). You can play 4 samples at the same time (row top 4 rows in (a)). In accordance with that you can configure 4 folders in the variable `:folder_paths` in the file `monome-lmq-settings.rb`. The monome interface provides access to 16 samples per track/sequencer row, which means: you can store and access up to 16 samples (no. 0 to 15) in each folder and thus access 64 samples via the interface.

As to 2.: Besides the fact that you have to record these samples before you can play anything the main difference between the `seq` smaples and the `rec` samples is, that the latter will not be sliced but played as a whole. Again there are 4 tracks for recording and/or playback. You can hardcode the length of those track via the variable `:looper_len`; nevertheless in future (not implemented yet) you will also be able to load thoese sample into the sequencer to slice them (`seq track source`).

Interface elements and functions:

## Main Page

![lmp main page (b)](lmq-main-page.png?raw=true "lmq main page (a)")

Illustration (a)

(1) `Seq Tracks`

* If running press any key to set the starting point; 
* press key, hold and press other key on the same track to set playback range.
* You can use a range to reverse the playback direction).
* Hold a key to repeat the respective slice. Slices will always played back with quantisation (see (b)).

(2) Bottom Area of Main Page

On the bottom area (row no. 5-8) of the main page you can control the playback volume of `seq` and `rec` tracks, access the parameter page for each track and some other functions:

(3) Col 1 of row 5-8 is used to start/stop the `seq sample` playback.

(4) + (8) Col 2-6 provide a 6 step volume control for `seq sample` 1-4; the same applies to col 10-15 as volume control for the `rec tracks`. The first of each fader group is a toggle and switches between 0 and 0.2 (as step no. 2 defined in the variable `:amps`), that why you can call it a 6-step fader.

(5) Col 7 provides a toggle `seq track record` for each track setting the respective `seq track` into key press recording mode: If you press one of the toggles the playback of the track will be stopped. Press a number of keys in row 1, 2, 3 or 4 and see the associated slices played back in this custom order. You can delete the recored sequence by using a double key press gesture: press the key just beside (6) the `seq track record` and the `seq track record` key itself (5) (see the label: `seq track record delete`) and the sequence recording for the associated track will be deleted. 

(6) and (10): Go to parameter page for either the `seq samples` (1-4) or the `recorded samples` (5-8). Return with the bottom right key (col 16/row 8) on each parameter page.

(7) Not yet implemented. Toggle to map a `rec sample` as source of the respective `seq track`.

(8) Volume control 6-step fader for the `recorded samples`.

(9) Arm for recording. Will start a metronome beat and mark the beginning of the live looper recording. Implementation is functional but need some refinement. Detailed explanation will follow ...

## Parameter Page(s)

![lmp parameter page (b)](lmq-param-page.png?raw=true "lmq parameter page (b)")

Illustration (b)

(11) `parameter page selection`, same as main page column 8/row 5-8 (param page 1-4) and  colum 16/row 5-8 (param page 5-8).

(12) `parameters`:

In parenthesis you'll find the names of the variables which provide the values assiged to the keys hard coded in `monome-lmq-settings.rb`:

* Row 1/columns 2-16: Low Pass Filter (`:lpfs`)
* Row 2/columns 2-16: High Pass Filter (`:hpfs`)
* Row 3/columns 2-16: Rate (`:rates`)
* Row 4/columns 2-16: RPitch (`:rpitchs`)
* Row 5/columns 2-16: Attack (`attacks`)
* Row 6/columns 2-16: Sustain (`seq samples`) / Release (`rec samples`) (`:sus_rels`)
* Row 7/columns 2-7: Beat Stretch (`beat_stretchs`)
* Row 8/columns 2-7: Quantisation (i. e. seep time for each `seq sample` slice) (`:quants`)

(13) Usually all parametes increase from columns 1 to 16; this is different for `rate` and `rpitch` because there are also negative values.

(14) `seq sample selection`: Depending on which `seq sample param page` is being selected you can choose one of 16 samples.

(15) Key column 16/row 8 is reserved as an ESC key and will on all `param pages` lead back to the main page.

The key above has not yet been assigend to any function but will probably toggle the live looper recording metronome.
