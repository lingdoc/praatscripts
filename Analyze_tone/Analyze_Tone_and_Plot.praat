#    <Analyze_Tone_and_Plot.praat>
#    Extracts duration and F0 across a duration defined by the TextGrid for a wav file.
#    Writes results to a tab-delimited CSV file with the same name as the wav file.
#    Allows the user to plot pitch traces in the Praat picture window.
#
#    Copyright (C) 2017  Hiram Ring <hiram1 AT ntu DOT edu DOT sg>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    A copy of the GNU General Public License can be found at <http://www.gnu.org/licenses/>.
#
#    Based in part on Praat scripts by Christian DiCanio, 2012 & 2013.
#    <http://www.acsu.buffalo.edu/~cdicanio/scripts.html>
#    Borrowing from scripts by Mietta Lennes, 2006.
#    <http://www.helsinki.fi/~lennes/praat-scripts/public/>
#    And following the excellent tutorials at <http://praatscripting.lingphon.net/>.
#    Normalization uses José Joaquín Atria’s procedure for ignoring NA values.
#    <http://uk.groups.yahoo.com/neo/groups/praat-users/conversations/topics/>
#
#    A more detailed description of this script is found at <http://github.com/lingdoc/praatscripts/tree/master/Analyze_tone>.
#
# The script begins below. Running the script brings up a form window for setting parameters.

# This form allows the user to set parameters.
# Changing the numbers in the script below will change the default parameters.
form Extract Pitch data from labeled points
  sentence Directory_name:
  sentence Sound_file_extension: .wav
  positive Labeled_tier_number 2
  optionmenu Analysis_type: 4
    option Raw for CSV
    option Percentage for CSV
    option Normalize for Drawing
    option Normalize by tone for Drawing
    option Only plot
  comment Settings for raw measurement:
  positive Analysis_points_time_step_in_seconds 0.01
  positive Number_of_intervals 50
  positive Record_with_precision 1
  comment Settings for percentage measurement:
  positive Percentage_increments 20
  comment Pitch Settings (m 75-300, f 100-500):
  positive F0_minimum 75
  positive F0_maximum 500
  comment Resample settings:
  choice Resample: 2
    button Yes
    button No
  positive Sample_rate 22000
  positive Sampling_quality 50
endform

pitch_redraw = 1

if analysis_type = 1
  # do nothing
  call makeWAVs
elsif analysis_type = 2
  # do nothing
  call makeWAVs
elsif analysis_type = 5
  normDir$ = directory_name$
  newDir$ = directory_name$
  fileNameNoWav$ = "File"
  label$ = "Label"
  call drawPitch
  the_loop = 1

  while the_loop = 1
    call reset
  endwhile
else
  call makeWAVs
  call drawPitch
  call draw_and_plot

  the_loop = 1

  while the_loop = 1
    call reset
  endwhile
endif

# End of main script. The rest of the script defines procedures.

# This procedure finds all wav files in the specified directory, and does
# analysis on the file if it has a corresponding TextGrid with the same name.
#-----------------
procedure makeWAVs
  Create Strings as file list... list 'directory_name$'*'sound_file_extension$'
  num = Get number of strings
  select Strings list
  for ifile to num
  	fileName$ = Get string... ifile
  	Read from file... 'directory_name$''fileName$'
    fileNameNoWav$ = fileName$ - sound_file_extension$
    soundName$ = directory_name$ + fileName$ - sound_file_extension$
    csvName$ = soundName$ + ".csv"
    textGridname$ = soundName$ + ".TextGrid"
    select Sound 'fileNameNoWav$'
  	soundID1 = selected("Sound")
    soundID1$ = selected$("Sound")
  	if resample$ = "Yes"
  		Resample... sample_rate sampling_quality
      soundID1 = selected("Sound")
      soundID1$ = selected$("Sound")
  	else
  		# do nothing
  	endif

    if fileReadable (soundName$+".TextGrid")
      Read from file... 'directory_name$''soundID1$'.TextGrid
    	textGridID = selected("TextGrid")
    	num_labels = Get number of intervals... labeled_tier_number

      if fileReadable (csvName$)
      	pause Older CSV 'csvName$' will be overwritten! Are you sure?
      	printline Older CSV 'csvName$' will be overwritten!
      	printline
      	filedelete 'csvName$'
      endif
      fileappend 'csvName$' label'tab$'dur'tab$'

      labconds = 0
      labcond$ = ""
      labLatest$ = ""

      if analysis_type = 1
        call analyzeRaw
      elsif analysis_type = 2
        call analyzePerc
      elsif analysis_type = 4
        call findLabels
        call analyzeNormTone
      else
        call analyzeNorm
      endif

      select 'textGridID'
      Remove
      select 'soundID1'
      Remove
    endif
    select Strings list
  endfor

  select Strings list
  Remove
endproc

# This procedure does analysis on files in the folder according to timesteps
# and outputs the results for each file to a CSV.
#-----------------
procedure analyzeRaw
  numintervals = number_of_intervals
  steps = analysis_points_time_step_in_seconds
  # Raw
  size = steps

  for q to numintervals
    start = (q-1) * size
    end = q * size
    # for display of timestep in seconds, uncomment the following two lines:
    #val_F0 = start
    #fileappend 'directory_name$''fileName$'.csv 'val_F0''tab$'
    # for display of timestep in milliseconds, uncomment the following two lines:
    reval_F0 = round (start * 1000)
    fileappend 'csvName$' 'reval_F0''tab$'
  endfor
  fileappend 'csvName$' 'newline$'

  labelcount = 0
  for i to num_labels
    select 'textGridID'
    label$ = Get label of interval... labeled_tier_number i
      if label$ <> ""
        labelcount = labelcount + 1
        fileappend 'csvName$' 'label$''tab$'
        intvl_start = Get starting point... labeled_tier_number i
        intvl_end = Get end point... labeled_tier_number i
        select 'soundID1'
        Extract part... intvl_start intvl_end Rectangular 1 no
        intID = selected("Sound")
        dur = Get total duration
        newDir$ = "'directory_name$''fileNameNoWav$'_tones/"
        createDirectory: newDir$
        Save as WAV file... 'newDir$''label$'_'fileNameNoWav$'_'labelcount'.wav
        fileappend 'csvName$' 'dur''tab$'

        #Pitch analysis
        select 'intID'
        To Pitch... 0 f0_minimum f0_maximum
        pitchID = selected("Pitch")
        size = steps
        for q to numintervals
          start = (q-1) * size
          end = q * size
          val_F0 = Get mean... start end Hertz
          if val_F0 = undefined
            fileappend 'csvName$' NA'tab$'
          else
            fileappend 'csvName$' 'val_F0''tab$'
          endif
        endfor
        fileappend 'csvName$' 'newline$'

        select 'pitchID'
        Remove
        select 'intID'
        Remove
      else
        #do nothing
      endif
  endfor
endproc

# This procedure does analysis on files in the folder according to percentage
# increments and outputs the results for each file to a CSV.
#-----------------
procedure analyzePerc
  numintervals = percentage_increments
  steps = percentage_increments
  size = 100/numintervals

  for q to numintervals
    start = (q-1) * size
    end = q * size
    val_F0 = start
    fileappend 'csvName$' 'val_F0''tab$'
  endfor
  fileappend 'csvName$' 'newline$'

  labelcount = 0
  for i to num_labels
    select 'textGridID'
    label$ = Get label of interval... labeled_tier_number i
      if label$ <> ""
        labelcount = labelcount + 1
        fileappend 'csvName$' 'label$''tab$'
        intvl_start = Get starting point... labeled_tier_number i
        intvl_end = Get end point... labeled_tier_number i
        select 'soundID1'
        Extract part... intvl_start intvl_end Rectangular 1 no
        intID = selected("Sound")
        dur = Get total duration
        newDir$ = "'directory_name$''fileNameNoWav$'_tones/"
        createDirectory: newDir$
        Save as WAV file... 'newDir$''label$'_'fileNameNoWav$'_'labelcount'.wav
        fileappend 'csvName$' 'dur''tab$'

        #Pitch analysis
        select 'intID'
        To Pitch... 0 f0_minimum f0_maximum
        pitchID = selected("Pitch")

        # Dicanio percentage
        size = dur/numintervals

        for q to numintervals
          start = (q-1) * size
          end = q * size
          val_F0 = Get mean... start end Hertz
          if val_F0 = undefined
            fileappend 'csvName$' NA'tab$'
          else
            fileappend 'csvName$' 'val_F0''tab$'
          endif
        endfor
        fileappend 'csvName$' 'newline$'

        select 'pitchID'
        Remove
        select 'intID'
        Remove
      else
        #do nothing
      endif
  endfor
endproc

# This procedure does analysis on files in the folder according to percentage
# and creates a WAV file for all files in the folder that is normalized
# according to pitch height and duration.
#-----------------
procedure analyzeNorm
  numintervals = percentage_increments
  steps = percentage_increments
  size = 100/numintervals

  int = 0

  for q to numintervals
    start = (q-1) * size
    end = q * size
    int'q' = int
    dataexist'q' = int
    # for display of timestep in seconds, uncomment the following two lines:
    val_F0 = start
    fileappend 'csvName$' 'val_F0''tab$'
  endfor
  fileappend 'csvName$' 'newline$'

  durtotal = 0
  labelcount = 0
  ; Create a table for each label, named i.e. 'label_1' etc, with one row and as many columns as intervals # string$(1)
  Create Table with column names: "label_'lab'", 1, "dur"
  tableID = selected("Table")
  for numint to numintervals
    Append column: string$(numint)
  endfor
  select 'textGridID'

  for i to num_labels
    select 'textGridID'
    label$ = Get label of interval... labeled_tier_number i
      if label$ <> ""
        labelcount = labelcount + 1
        fileappend 'csvName$' 'label$''tab$'
        ; select the table
        select 'tableID'
        if labelcount > 1
          ; append a new row
          Append row
        else
          ; do nothing
        endif
        ; select the current textGrid
        select 'textGridID'

        intvl_start = Get starting point... labeled_tier_number i
        intvl_end = Get end point... labeled_tier_number i
        select 'soundID1'
        Extract part... intvl_start intvl_end Rectangular 1 no
        intID = selected("Sound")
        dur = Get total duration
        newDir$ = "'directory_name$''fileNameNoWav$'/"
        createDirectory: newDir$
        Save as WAV file... 'newDir$''label$'_'fileNameNoWav$'_'labelcount'.wav
        fileappend 'csvName$' 'dur''tab$'
        ; select the table
        select 'tableID'
        ; set the numeric value of the current label's duration
        Set numeric value: labelcount, "dur", dur

        #Pitch analysis
        select 'intID'
        To Pitch... 0 f0_minimum f0_maximum
        pitchID = selected("Pitch")

        ; durtotal = durtotal + dur

        # Dicanio percentage
        size = dur/numintervals

        for q to numintervals
          dataexist = 0
          start = (q-1) * size
          end = q * size
          val_F0 = Get mean... start end Hertz
          if val_F0 = undefined
            fileappend 'csvName$' NA'tab$'
            start = q * size
            end = (q+1) * size
            val_F0 = Get mean... start end Hertz
            ; select the table
            select 'tableID'
            ; set the numeric value of the current label
            Set numeric value: labelcount, string$(q), val_F0
            select 'pitchID'
          else
            fileappend 'csvName$' 'val_F0''tab$'
            ; select the table
            select 'tableID'
            ; set the numeric value of the current label
            Set numeric value: labelcount, string$(q), val_F0
            select 'pitchID'
            ; dataexist'q' = dataexist'q' + 1
          ; int'q' = int'q' + val_F0
          endif
        endfor
        fileappend 'csvName$' 'newline$'

        select 'pitchID'
        Remove
        select 'intID'
        Remove
      endif
  endfor
  select 'tableID'
  @colMeanNARM: "dur"
  durnorm = colMeanNARM.return

  select 'tableID'
  for q to numintervals
    col$ = string$(q)
    @colMeanNARM: col$
    int'q' = colMeanNARM.return
  endfor
  select 'tableID'
  Remove

  Create Sound as pure tone: "Norm", 1, 0, durnorm, 44100, 440, 0.2, 0.01, 0.01

  Create PitchTier... Norm 0.0 durnorm
  select PitchTier Norm
  size = durnorm/numintervals
  for q to numintervals
    spot = q * size
    Add point... spot int'q'
  endfor
  select Sound Norm
  To Manipulation... analysis_points_time_step_in_seconds f0_minimum f0_maximum
  selectObject: "Manipulation Norm", "PitchTier Norm"
  Replace pitch tier
  select Manipulation Norm
  Get resynthesis (PSOLA)
  normDir$ = "'directory_name$''fileNameNoWav$'_norm/"
  createDirectory: normDir$
  Save as WAV file... 'normDir$''fileNameNoWav$'_norm.wav
  Remove
  selectObject: "Sound Norm", "Manipulation Norm", "PitchTier Norm";, "Strings newlist"
  Remove
endproc

# This procedure does analysis on files in the folder according to percentage
# and creates a WAV file for all files in the folder that are have the same label.
# Each label WAV file is normalized according to pitch height and duration.
#-----------------
procedure analyzeNormTone
  numintervals = percentage_increments
  steps = percentage_increments
  size = 100/numintervals

  int = 0

  for q to numintervals
    start = (q-1) * size
    end = q * size
    int'q' = int
    ; dataexist'q' = dataexist
    ; valexist'q' = int
    val_F0 = start
    fileappend 'csvName$' 'val_F0''tab$'
  endfor
  fileappend 'csvName$' 'newline$'

  for lab to labconds
    durtotal = 0
    labelcount = 0
    ; Create a table for each label, named i.e. 'label_1' etc, with one row and as many columns as intervals
    Create Table with column names: "label_'lab'", 1, "dur"
    tableID = selected("Table")
    for numint to numintervals
      Append column: string$(numint)
    endfor
    select 'textGridID'

    for i to num_labels
      select 'textGridID'
      label$ = Get label of interval... labeled_tier_number i
      labelCondition$ = labcond'lab'$

      if label$ = labelCondition$
        labelcount = labelcount + 1
        fileappend 'csvName$' 'label$''tab$'
        ; select the table
        select 'tableID'
        if labelcount > 1
          ; append a new row
          Append row
        else
          ; do nothing
        endif
        ; select the current textGrid
        select 'textGridID'

        intvl_start = Get starting point... labeled_tier_number i
        intvl_end = Get end point... labeled_tier_number i
        select 'soundID1'
        Extract part... intvl_start intvl_end Rectangular 1 no
        intID = selected("Sound")
        dur = Get total duration
        baseDir$ = directory_name$ + fileNameNoWav$
        createDirectory: baseDir$
        newDir$ = baseDir$ + "/" + labelCondition$ + "/"
        createDirectory: newDir$
        Save as WAV file... 'newDir$''label$'_'fileNameNoWav$'_'labelcount'.wav
        fileappend 'csvName$' 'dur''tab$'
        ; select the table
        select 'tableID'
        ; set the numeric value of the current label's duration
        Set numeric value: labelcount, "dur", dur

        #Pitch analysis
        select 'intID'
        To Pitch... 0 f0_minimum f0_maximum
        pitchID = selected("Pitch")

        durtotal = durtotal + dur

        # Dicanio percentage
        size = dur/numintervals


        for q to numintervals
          start = (q-1) * size
          end = q * size
          val_F0 = Get mean... start end Hertz
          if val_F0 = undefined
            fileappend 'csvName$' NA'tab$'
            start = q * size
            end = (q+1) * size
            val_F0 = Get mean... start end Hertz
            ; select the table
            select 'tableID'
            ; set the numeric value of the current label
            Set numeric value: labelcount, string$(q), val_F0
            select 'pitchID'
          else
            fileappend 'csvName$' 'val_F0''tab$'
            ; select the table
            select 'tableID'
            ; set the numeric value of the current label
            Set numeric value: labelcount, string$(q), val_F0
            select 'pitchID'
          ;   dataexist'q' = dataexist'q' + 1
          ;   ; valexist'q' = valexist'q' + 1
          ; int'q' = int'q' + val_F0
          ; ; theone = int'q'

          endif
        endfor
        fileappend 'csvName$' 'newline$'

        select 'pitchID'
        Remove
        select 'intID'
        Remove
      endif
    endfor
    select 'tableID'
    @colMeanNARM: "dur"
    durnorm = colMeanNARM.return

    select 'tableID'
    for q to numintervals
      col$ = string$(q)
      @colMeanNARM: col$
      type'q' = colMeanNARM.return
    endfor
    select 'tableID'
    Remove

    Create Sound as pure tone: "Norm", 1, 0, durnorm, 44100, 440, 0.2, 0.01, 0.01

    Create PitchTier... Norm 0.0 durnorm
    select PitchTier Norm
    size = durnorm/numintervals
    for q to numintervals
      spot = q * size
      ; Add point... spot int'q'
      Add point... spot type'q'
    endfor
    select Sound Norm
    To Manipulation... analysis_points_time_step_in_seconds f0_minimum f0_maximum
    selectObject: "Manipulation Norm", "PitchTier Norm"
    Replace pitch tier
    select Manipulation Norm
    Get resynthesis (PSOLA)
    normDir$ = "'baseDir$'/'fileNameNoWav$'_norm/"
    createDirectory: normDir$
    Save as WAV file... 'normDir$''labelCondition$'_'fileNameNoWav$'_norm.wav
    Remove
    selectObject: "Sound Norm", "Manipulation Norm", "PitchTier Norm";, "Strings newlist"
    Remove
    ; select 'soundID03'
    ; Remove
  endfor
endproc

# This procedure gets means from columns while ignoring bad values
#-----------------
procedure colMeanNARM: .col$
  .id = selected("Table")
  .subset = Extract rows where column (text): .col$, "is not equal to", "--undefined--"
  .return = Get mean: .col$
  removeObject: .subset
  selectObject: .id
endproc

# This procedure finds all the labels in the tone-annotated TextGrid tier and
# outputs the labels to a window for the user's verification.
#-----------------
procedure findLabels
  ; labconds = 0
  ; labLatest$ = ""
  for i to num_labels
    select 'textGridID'
    label$ = Get label of interval... labeled_tier_number i

    if label$ <> ""
      labcond$ = label$
      # if this label is not the same as the previous
    	if labcond$ <> labLatest$
        if labconds = 0
          labconds = labconds + 1
          labcond'labconds'$ = labcond$
        else
          there = 1
          notthere = 1
          for lab to labconds
            if labcond'lab'$ = labcond$
              there = 0
            else
              notthere = 1
            endif
          endfor
          increment = there * notthere
          if increment = 1
            labconds = labconds + increment
            labcond'labconds'$ = labcond$
          endif
        endif
      endif
      labLatest$ = labcond$
    endif
  endfor

  for lab to labconds
    thisone$ = labcond'lab'$
  endfor

  theTextGrid$ = selected$("TextGrid")
  beginPause: "Check labels"
    comment: "The following labels were found in the TextGrid for file: 'theTextGrid$''sound_file_extension$'"
    comment: "Is this correct? If so, continue, if not, stop and fix your TextGrid."
    for lab to labconds
      thisone$ = labcond'lab'$
      comment: "Label_'lab': 'thisone$' "
    endfor
  clicked = endPause: "Stop", "Continue", 2, 1
    if clicked = 1
      exitScript ()
    elsif clicked = 2
      writeInfo: "Continuing..."
    endif
endproc

# This procedure gets the initial settings for drawing the pitch tracks.
#-----------------
procedure drawPitch
  ; sound_file_extension$ = ".wav"
  pitch_file_extension$ = ".Pitch"
  time_step = 0.01
  default_minimum_pitch = 60
  default_maximum_pitch = 400
  pitch_parameter_file$ = ""
  minimum_pitch_for_drawing = 50
  maximum_pitch_for_drawing = 200
  hz_time_step = 50
  seconds_time_step = 0.05
  normalize_time = 0
  frequency_scale_for_the_picture = 1
  draw_as = 1
  line_style = 1
  smooth_pitch_curves = 0

  if analysis_type = 1
    ; call analyzeRaw
    sound_file_directory$ = "'newDir$'"
    picture_file$ = "'directory_name$''fileNameNoWav$'.png"
    pitch_data_file$ = "'directory_name$''fileNameNoWav$'.txt"
  elsif analysis_type = 2
    ; call analyzePerc
    sound_file_directory$ = "'newDir$'"
    picture_file$ = "'directory_name$''fileNameNoWav$'.png"
    pitch_data_file$ = "'directory_name$''fileNameNoWav$'.txt"
  elsif analysis_type = 3
    ; call analyzeNorm
    sound_file_directory$ = "'newDir$'"
    picture_file$ = "'directory_name$''fileNameNoWav$'_norm.png"
    pitch_data_file$ = "'directory_name$''fileNameNoWav$'_norm.txt"
  elsif analysis_type = 4
    ; call findLabels
    ; call analyzeNormTone
    sound_file_directory$ = "'normDir$'"
    picture_file$ = "'directory_name$''fileNameNoWav$'_'label$'_norm.png"
    pitch_data_file$ = "'directory_name$''fileNameNoWav$'_'label$'_norm.txt"
  elsif analysis_type = 5
    ; call findLabels
    ; call analyzeNormTone
    sound_file_directory$ = "'normDir$'"
    picture_file$ = "'directory_name$''fileNameNoWav$'_'label$'_norm.png"
    pitch_data_file$ = "'directory_name$''fileNameNoWav$'_'label$'_norm.txt"
  endif

  beginPause: "Draw pitch curves from all sound files in a directory"
  	comment: "Sound file directory (use '*_norm' to plot normalized):"
  	text: "Sound file directory", sound_file_directory$
  	; sentence: "Sound file extension", sound_file_extension$
  	; sentence: "Pitch file extension", pitch_file_extension$
  	boolean: "Normalize time", normalize_time
  	optionMenu: "Frequency scale for the picture", frequency_scale_for_the_picture
  		option: "Linear (Hertz)"
  		option: "Logarithmic"
  		option: "Semitones (re 100 Hz)"
  		option: "Mel"
  		option: "Erb"
  	optionMenu: "Draw as", draw_as
  		option: "Pitch object, plain line"
  		option: "Pitch object, speckle"
  		option: "PitchTier object"
  	optionMenu: "Line style", line_style
  		option: "Switch colours between file groups"
  		option: "Switch line style (only Pitch, plain line)"
  		option: "Keep basic line style and colour for all groups and files"
  	boolean: "Smooth pitch curves", smooth_pitch_curves
  	comment: "Pitch parameters:"
    boolean: "Redraw pitch", pitch_redraw
  	real: "Time step", time_step
  	real: "Default minimum pitch", default_minimum_pitch
  	real: "Default maximum pitch", default_maximum_pitch
  	; comment: "Pitch parameter file (optional):"
  	; text: "Pitch parameter file (optional)", pitch_parameter_file$
    comment: "Plot parameters:"
  	positive: "Minimum pitch for drawing", minimum_pitch_for_drawing
  	positive: "Maximum pitch for drawing", maximum_pitch_for_drawing
  	positive: "Hz time step", hz_time_step
  	positive: "Seconds time step", seconds_time_step
  	comment: "Output files:"
  	text: "Picture file", picture_file$
  	text: "Pitch data file", pitch_data_file$
  clicked = endPause: "Stop", "Continue", 2, 1
  if clicked = 1
    exitScript ()
  elsif clicked = 2
    ; if soundDir$ <> ""
    ;   sound_file_directory$ = soundDir$
    ; else
    ;   sound_file_directory$ = soundDir$
    ; endif
    if normalize_time = 0
      normalize_time = 0
    else
      normalize_time = 1
    endif
    if frequency_scale_for_the_picture = 1
      frequency_scale_for_the_picture = 1
    elsif frequency_scale_for_the_picture = 2
      frequency_scale_for_the_picture = 2
    elsif frequency_scale_for_the_picture = 3
      frequency_scale_for_the_picture = 3
    elsif frequency_scale_for_the_picture = 4
      frequency_scale_for_the_picture = 4
    else
      frequency_scale_for_the_picture = 5
    endif
    if draw_as = 1
      draw_as = 1
    elsif draw_as = 2
      draw_as = 2
    else
      draw_as = 3
    endif
    if line_style = 1
      line_style = 1
    elsif line_style = 2
      line_style = 2
    else
      line_style = 3
    endif
    if smooth_pitch_curves = 0
      smooth_pitch_curves = 0
    else
      smooth_pitch_curves = 1
    endif
    # do nothing
  endif

endproc

  # The optional pitch parameter file should be in the format:
  #groupcode	minimumpitch(Hz)	maximumpitch(Hz)
  # E.g.,
  #S1	75	500
  #S2	120	300
  # etc.

# This procedure actually draws the pitch tracks.
#--------------
procedure draw_and_plot
	echo Drawing pitch curves for sound files in 'sound_file_directory$'...
	printline

	group_id$ = ""
	# Here you can define where in the file name string the group code is given (file extension not included).
	# You can also use this parameter to switch between different conditions, e.g., read/spontaneous speech.
	# The example below will consider the first two characters of the filename as the group ID code.
	# Edit and uncomment the next line, if you wish to use this option!
	group_id$ = "left$ (filename$, 2)"

	# Pitch smoothing:
	smoothing_by_bandwidth = 10

	latestcondition$ = ""
	conditions = 0
	newcolour = 0
	newstyle = 0
	condition$ = ""

	########## This is where the actual script begins

	# Check whether the given files already exist:
	if fileReadable (picture_file$)
		pause Older picture 'picture_file$' will be overwritten! Are you sure?
		printline Older picture file 'picture_file$' will be overwritten!
		printline
		filedelete 'picture_file$'
	endif
	if fileReadable (pitch_data_file$)
		pause Older data file 'pitch_data_file$' will be overwritten! Are you sure?
		printline Older data file 'pitch_data_file$' will be overwritten!
		printline
		filedelete 'pitch_data_file$'
		titleline$ = "File
			...	Duration (s)	"
		if frequency_scale_for_the_picture = 1
		titleline$ = titleline$ + "
			...	F0min (Hz)
			...	F0max (Hz)
			...	F0mean (Hz)
			...	F0median (Hz)
			...	F0stdev (Hz)"
		elsif frequency_scale_for_the_picture = 2
		titleline$ = titleline$ + "
			...	F0min (logHz)
			...	F0max (logHz)
			...	F0mean (logHz)
			...	F0median (logHz)
			...	F0stdev (logHz)"
		elsif frequency_scale_for_the_picture = 3
		titleline$ = titleline$ + "
			...	F0min (ST)
			...	F0max (ST)
			...	F0mean (ST)
			...	F0median (ST)
			...	F0stdev (ST)"
		elsif frequency_scale_for_the_picture = 4
		titleline$ = titleline$ + "
			...	F0min (mel)
			...	F0max (mel)
			...	F0mean (mel)
			...	F0median (mel)
			...	F0stdev (mel)"
		else
		titleline$ = titleline$ + "
			...	F0min (ERB)
			...	F0max (ERB)
			...	F0mean (ERB)
			...	F0median (ERB)
			...	F0stdev (ERB)"
		endif
		titleline$ = titleline$ + "	MinPitchParam(Hz)	MaxPitchParam(Hz)	Drawing colour in 'picture_file$'"
		if group_id$ <> ""
			titleline$ = titleline$ + "	Group"
		endif
		titleline$ = titleline$ + newline$
		fileappend 'pitch_data_file$' 'titleline$'
	endif
	if pitch_parameter_file$ <> ""
		if fileReadable (pitch_parameter_file$)
			Read Strings from raw text file... 'pitch_parameter_file$'
			Rename... parameters
			printline Individualized pitch parameters read from 'pitch_parameter_file$'.
		else
			printline Individualized pitch parameter file 'pitch_parameter_file$' was not found.
			printline    (Individual pitch parameters will not be used!)
		endif
	endif

	filenumber = 0
	colour = 0
  ; The script was modified to not output the color Black for pitch tracks.
  ; See Mietta Lennes' script for the original form.
	; colour$ = "Black"
	colour$ = "Red"
	style = 0
	maxduration = 0
	minfreq = minimum_pitch_for_drawing
	maxfreq = maximum_pitch_for_drawing
	textpos1 = 4
	textpos2 = 4.2

	# Read lists of sound and Pitch files from the given directory:
	Create Strings as file list... soundfiles 'sound_file_directory$'*'sound_file_extension$'
	Sort
	numberOfSoundFiles = Get number of strings
	maxduration = 0

	# Open any existing Pitch files and calculate Pitch from sounds without Pitch
	select Strings soundfiles
	for ifile to numberOfSoundFiles
		soundfilename$ = Get string... ifile
    filename$ = soundfilename$ - sound_file_extension$
		pitchfilepath$ = sound_file_directory$ + filename$ + pitch_file_extension$
    if pitch_redraw = 0
  		if fileReadable (pitchfilepath$)
  			Read from file... 'pitchfilepath$'
  			call PreAnalysis
        Remove
  		else
        #
      endif
    else
  		Read from file... 'sound_file_directory$''soundfilename$'
  		if group_id$ <> "" and pitch_parameter_file$ <> ""
  			# Get pitch parameters:
  			call GetPitchParameters
  		else
  			min_pitch = default_minimum_pitch
  			max_pitch = default_maximum_pitch
  		endif
  		# Calculate and save pitch
  		To Pitch... time_step min_pitch max_pitch
  		Write to short text file... 'pitchfilepath$'
  		Remove
  		select Sound 'filename$'
  		if normalize_time = 0
  			call PreAnalysis
  		endif
  		Remove
  	endif
		filenumber = filenumber + 1
		text'filenumber'$ = ""
		select Strings soundfiles
	endfor

	# Remove the sound file list:
	Remove

	# Build a new list of Pitch files:
	Create Strings as file list... pitchfiles 'sound_file_directory$'*'pitch_file_extension$'
	Sort
	numberOfPitchFiles = Get number of strings

	call PictureWindow

	filenumber = 0
	# make a second round through the files, now to draw everything as requested:
	for ifile to numberOfPitchFiles
		pitchfilename$ = Get string... ifile
		Read from file... 'sound_file_directory$''pitchfilename$'
		dur = Get total duration
		filenumber = filenumber + 1
    filename$ = pitchfilename$ - pitch_file_extension$
		if group_id$ <> ""
			call GetConditionFromFilename
		elsif line_style = 1
			colour = colour + 1
		elsif line_style = 2
			style = style + 1
		endif
		if group_id$ <> "" and pitch_parameter_file$ <> ""
			# Get pitch parameters:
			call GetPitchParameters
		else
			min_pitch = default_minimum_pitch
			max_pitch = default_maximum_pitch
		endif
		select Pitch 'filename$'
		call Drawing
    select Pitch 'filename$'
		call SaveStatistics
    Remove
		select Strings pitchfiles
	endfor

	hz_time_step_semitones = hz_time_step/10

	if frequency_scale_for_the_picture = 1
		Text left... yes Pitch (Hz)
		Marks left every... 1 hz_time_step yes yes yes
	elsif frequency_scale_for_the_picture = 2
		Text left... yes Pitch (log Hz)
		Marks left every... 1 hz_time_step yes yes yes
	elsif frequency_scale_for_the_picture = 3
		Text left... yes Pitch (semitones re 100Hz)
		Marks left every... 1 hz_time_step_semitones yes yes yes
	elsif frequency_scale_for_the_picture = 4
		Text left... yes Pitch (mel)
		Marks left every... 1 hz_time_step yes yes yes
	elsif frequency_scale_for_the_picture = 5
		Text left... yes Pitch (erb)
		Marks left every... 1 hz_time_step yes yes yes
	else
		Text left... yes Pitch (Hz)
		Marks left every... 1 hz_time_step yes yes yes
	endif

	if normalize_time = 1
		Text bottom... yes Normalized time (seconds)
		Marks bottom every... 1.0 seconds_time_step yes yes yes
	else
		Text bottom... yes Time (seconds)
		Marks bottom every... 1.0 seconds_time_step yes yes yes
	endif

	Viewport... 0 7 0 textpos2
  ;Write to PDF file... 'picture_file$' ; This function only works on Mac, the function below works on both
	Save as 600-dpi PNG file... 'picture_file$'

	select Strings pitchfiles
	Remove

	printline 'filenumber' F0 curves were drawn and saved to 'picture_file$'.
	printline Finished!
endproc

# This procedure creates the repeating plot window
#--------------
procedure reset
  # including these variable definitions allows the plot window to save settings from previous runs
  wav_folder$ = sound_file_directory$
	image_file$ = picture_file$
	data_file$ = pitch_data_file$
	minimum_pitch = minimum_pitch_for_drawing
	maximum_pitch = maximum_pitch_for_drawing
	hz_markers = hz_time_step
	seconds_markers = seconds_time_step
  redraw_pitch = pitch_redraw

	beginPause: "Adjust parameters"
    comment: "File parameters (directory, image, datafile):"
    text: "Sound file directory", wav_folder$
    text: "Picture file", image_file$
    text: "Pitch data file", data_file$
    boolean: "Normalize time", normalize_time
  	optionMenu: "Frequency scale for the picture", frequency_scale_for_the_picture
  		option: "Linear (Hertz)"
  		option: "Logarithmic"
  		option: "Semitones (re 100 Hz)"
  		option: "Mel"
  		option: "Erb"
  	optionMenu: "Draw as", draw_as
  		option: "Pitch object, plain line"
  		option: "Pitch object, speckle"
  		option: "PitchTier object"
  	optionMenu: "Line style", line_style
  		option: "Switch colours between file groups"
  		option: "Switch line style (only Pitch, plain line)"
  		option: "Keep basic line style and colour for all groups and files"
  	boolean: "Smooth pitch curves", smooth_pitch_curves
    comment: "Pitch parameters:"
    boolean: "Redraw pitch", redraw_pitch
    real: "Time step", time_step
  	real: "Default minimum pitch", default_minimum_pitch
  	real: "Default maximum pitch", default_maximum_pitch
		comment: "Plot parameters:"
    real: "Minimum pitch", minimum_pitch
		real: "Maximum pitch", maximum_pitch
		real: "Hz markers", hz_markers
		positive: "Seconds markers", seconds_markers
	clicked = endPause: "Stop", "Continue", 2, 1
  if clicked = 1
    # react to cancel
    exitScript ()
  elsif clicked = 2
		sound_file_directory$ = wav_folder$
		picture_file$ = image_file$
		pitch_data_file$ = data_file$
		minimum_pitch_for_drawing = minimum_pitch
		maximum_pitch_for_drawing = maximum_pitch
		hz_time_step = hz_markers
		seconds_time_step = seconds_markers
    if redraw_pitch = 0
      pitch_redraw = 0
    else
      pitch_redraw = 1
    endif
    if normalize_time = 0
      normalize_time = 0
    else
      normalize_time = 1
    endif
    if frequency_scale_for_the_picture = 1
      frequency_scale_for_the_picture = 1
    elsif frequency_scale_for_the_picture = 2
      frequency_scale_for_the_picture = 2
    elsif frequency_scale_for_the_picture = 3
      frequency_scale_for_the_picture = 3
    elsif frequency_scale_for_the_picture = 4
      frequency_scale_for_the_picture = 4
    else
      frequency_scale_for_the_picture = 5
    endif
    if draw_as = 1
      draw_as = 1
    elsif draw_as = 2
      draw_as = 2
    else
      draw_as = 3
    endif
    if line_style = 1
      line_style = 1
    elsif line_style = 2
      line_style = 2
    else
      line_style = 3
    endif
    if smooth_pitch_curves = 0
      smooth_pitch_curves = 0
    else
      smooth_pitch_curves = 1
    endif

		call draw_and_plot
  endif

endproc

# This procedure runs a simple duration query for the pitch track.
#--------------
procedure PreAnalysis

duration = Get duration
if duration > maxduration
	maxduration = duration
endif

endproc

# This procedure actually plots the pitches.
#--------------
procedure Drawing

duration = Get total duration
# Get values in Hertz
if frequency_scale_for_the_picture = 1
	max = Get maximum... 0 0 Hertz None
	min = Get minimum... 0 0 Hertz None
	mean = Get mean... 0 0 Hertz
	median = Get quantile... 0 0 0.5 Hertz
	stdev = Get standard deviation... 0 0 Hertz
# Get values in log(Hertz)
elsif frequency_scale_for_the_picture = 2
	max = Get maximum... 0 0 logHertz None
	min = Get minimum... 0 0 logHertz None
	mean = Get mean... 0 0 logHertz
	median = Get quantile... 0 0 0.5 logHertz
	stdev = Get standard deviation... 0 0 Hertz
# Get values in semitones (re 100 Hz)
elsif frequency_scale_for_the_picture = 3
	max = Get maximum... 0 0 "semitones re 100 Hz" None
	min = Get minimum... 0 0 "semitones re 100 Hz" None
	mean = Get mean... 0 0 semitones re 100 Hz
	median = Get quantile... 0 0 0.5 semitones re 100 Hz
	stdev = Get standard deviation... 0 0 semitones
# Get values in mels:
elsif frequency_scale_for_the_picture = 4
	max = Get maximum... 0 0 mel None
	min = Get minimum... 0 0 mel None
	mean = Get mean... 0 0 mel
	median = Get quantile... 0 0 0.5 mel
	stdev = Get standard deviation... 0 0 mel
# Get values in ERB:
else
	max = Get maximum... 0 0 ERB None
	min = Get minimum... 0 0 ERB None
	mean = Get mean... 0 0 ERB
	median = Get quantile... 0 0 0.5 ERB
	stdev = Get standard deviation... 0 0 ERB
endif

if smooth_pitch_curves = 1
  pitchID3 = selected("Pitch")
	Smooth... smoothing_by_bandwidth
else
  #
endif

if normalize_time = 0
	xmax = maxduration
else
	xmax = Get total duration
endif

if line_style = 1
	call SwitchColours
elsif line_style = 2 and draw_as = 1
	call SwitchLineStyles
else
	Black
	Plain line
	Line width... 2
endif

# minfreq and maxfreq are the global minimum and maximum.

if draw_as = 1
	if frequency_scale_for_the_picture = 1
		Draw... 0 xmax minfreq maxfreq no
	elsif frequency_scale_for_the_picture = 2
		Draw logarithmic... 0 xmax minfreq maxfreq no
	elsif frequency_scale_for_the_picture = 3
		bottomfreq = hertzToSemitones (minfreq)
		topfreq = hertzToSemitones (maxfreq)
		Draw semitones... 0 xmax bottomfreq topfreq no
	elsif frequency_scale_for_the_picture = 4
		bottomfreq = hertzToMel (minfreq)
		topfreq = hertzToMel (maxfreq)
		Draw mel... 0 xmax bottomfreq topfreq no
	elsif frequency_scale_for_the_picture = 5
		bottomfreq = hertzToErb (minfreq)
		topfreq = hertzToErb (maxfreq)
		Draw erb... 0 xmax bottomfreq topfreq no
	endif
elsif draw_as = 2
	if frequency_scale_for_the_picture = 1
		Speckle... 0 xmax minfreq maxfreq no
	elsif frequency_scale_for_the_picture = 2
		Speckle logarithmic... 0 xmax minfreq maxfreq no
	elsif frequency_scale_for_the_picture = 3
		bottomfreq = hertzToSemitones (minfreq)
		topfreq = hertzToSemitones (maxfreq)
		Speckle semitones... 0 xmax bottomfreq topfreq no
	elsif frequency_scale_for_the_picture = 4
		bottomfreq = hertzToMel (minfreq)
		topfreq = hertzToMel (maxfreq)
		Speckle mel... 0 xmax bottomfreq topfreq no
	elsif frequency_scale_for_the_picture = 5
		bottomfreq = hertzToErb (minfreq)
		topfreq = hertzToErb (maxfreq)
		Speckle erb... 0 xmax bottomfreq topfreq no
	endif
else
	Down to PitchTier
	Draw... 0 xmax minfreq maxfreq no
	Remove
endif

Line width... 2

endproc

# This procedure switches colours between labels.
#------------
procedure SwitchColours

if colour = 1
	# renumbered to get rid of Black
; 	colour$ = "Black"
; 	Black
; elsif colour = 2
	colour$ = "Red"
	Red
elsif colour = 2
	colour$ = "Green"
	Green
elsif colour = 3
	colour$ = "Blue"
	Blue
elsif colour = 4
	colour$ = "Magenta"
	Magenta
elsif colour = 5
	colour$ = "Cyan"
	Cyan
elsif colour = 6
	colour$ = "Maroon"
	Maroon
elsif colour = 7
	colour$ = "Navy"
	Navy
elsif colour = 8
	colour$ = "Lime"
	Lime
elsif colour = 9
	colour$ = "Teal"
	Teal
elsif colour = 10
	colour$ = "Purple"
	Purple
elsif colour = 11
	colour$ = "Olive"
	Olive
elsif colour = 12
	colour$ = "Silver"
	Silver
elsif colour = 13
	colour$ = "Grey"
	Grey
elsif colour = 14
	colour$ = "Yellow"
	Yellow
else
	colour = 1
	colour$ = "Red"
	Red
; else
; 	colour = 1
; 	colour$ = "Black"
; 	Black
endif


endproc

# This procedure switches line styles between labels.
#------------
procedure SwitchLineStyles

if style = 1
	Line width... 3
	Plain line
elsif style = 2
	Line width... 3
	Dashed line
elsif style = 3
	Line width... 3
	Dotted line
elsif style = 4
	Line width... 5
	Plain line
elsif style = 5
	Line width... 5
	Dashed line
elsif style = 6
	Line width... 5
	Dotted line
else
	style = 1
	Line width... 3
	Plain line
endif

endproc

# This procedure draws the background and frame of the plot.
#---------------
procedure PictureWindow

Erase all
Viewport... 0 7 0 4
Black
Helvetica
Font size... 14
Plain line
Line width... 1
Draw inner box
Line width... 3
if frequency_scale_for_the_picture = 1
	name_of_process$ = "Hertz"
# Get values in log(Hertz)
elsif frequency_scale_for_the_picture = 2
	name_of_process$ = "log(Hertz)"
# Get values in semitones (re 100 Hz)
elsif frequency_scale_for_the_picture = 3
	name_of_process$ = "Semitones"
# Get values in mels:
elsif frequency_scale_for_the_picture = 4
	name_of_process$ = "Mel"
# Get values in ERB:
else
	name_of_process$ = "ERB"
endif

if smooth_pitch_curves = 1
	Text top... yes Comparison of smoothed pitch contours, 'name_of_process$':
else
	Text top... yes Comparison of pitch contours, 'name_of_process$':
endif

endproc


# This procedure saves the statistics of each plot to a text file.
#-----------------
procedure SaveStatistics

	resultline$ = "'filename$'
		...	'dur'
		...	'min'
		...	'max'
		...	'mean'
		...	'median'
		...	'stdev'
		...	'min_pitch'
		...	'max_pitch'
		...	'colour$'"
	if group_id$ <> ""
		resultline$ = resultline$ + "	" + condition$ + newline$
	else
		resultline$ = resultline$ + newline$
	endif
	fileappend 'pitch_data_file$' 'resultline$'

	printline 'filename$': 'condition$' 'colour$' (dur 'dur' s)
  if smooth_pitch_curves = 1
    Remove
    select 'pitchID3'
  endif

endproc

# This procedure gets the label from the filename of the soundfile.
# This needs to be updated to function as well as the findLabels procedure.
#-----------------
procedure GetConditionFromFilename

	condition$ = 'group_id$'
	if condition$ <> latestcondition$
		# check if the group was already encountered
		for cond to conditions
			if condition'cond'$ = condition$
				colour = colour'condition'
				style = style'condition'
			endif
		endfor
		#otherwise
		if colour = 0 and style = 0
			newcolour = newcolour + 1
			; reduced colours from 16 to 15 by getting rid of black
			if newcolour = 15
				newcolour = 1
			endif
			newstyle = newstyle + 1
			if newstyle = 6
				newstyle = 1
			endif
			conditions = conditions + 1
			condition'conditions'$ = condition$
			colour'conditions' = newcolour
			style'conditions' = newstyle
			colour = newcolour
			style = newstyle
		else
			newcolour = newcolour + 1
			; reduced colours from 16 to 15 by getting rid of black
			if newcolour = 15
				newcolour = 1
			endif
			newstyle = newstyle + 1
			if newstyle = 6
				newstyle = 1
			endif
			conditions = conditions + 1
			condition'conditions'$ = condition$
			colour'conditions' = newcolour
			style'conditions' = newstyle
			colour = newcolour
			style = newstyle
		endif
		if line_style = 1
			call SwitchColours
		elsif line_style = 2
			call SwitchLineStyles
		endif
	endif
	latestcondition$ = condition$

endproc

# This procedure gets all the parameters necessary for Praat's automatic
# pitch identification from a file, if a file exists with this information.
#-----------------
procedure GetPitchParameters

group$ = 'group_id$'
min_pitch = default_minimum_pitch
max_pitch = default_maximum_pitch

select Strings parameters
numberOfGroups = Get number of strings
for group to numberOfGroups
	groupline$ = Get string... group
	if left$ (groupline$, (index(groupline$,"	")-1)) = group$
		parameters$ = right$ (groupline$, length (groupline$) - index (groupline$, "	"))
		min_pitch$ = left$ (parameters$, (index (parameters$, "	") - 1))
		min_pitch = 'min_pitch$'
		max_pitch$ = right$ (parameters$, length (parameters$) - (index (parameters$, "	")))
		max_pitch = 'max_pitch$'
		group = numberOfGroups
	endif
endfor

endproc
