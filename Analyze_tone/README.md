# Analyze_Tone_and_Plot.praat
## A Praat script for tonal exploration and analysis.

To cite this script and manual:
- Ring, Hiram. 2017. Analyze Tone and Plot: A Praat script for tonal exploration and analysis. Url: http://github.com/lingdoc/praatscripts/Analyze_tone.

This script has two main processes, the **segmentation/analysis** process and the **drawing** process.

## Segmentation and Analysis:
This script:
1. uses WAV/TextGrid pairs to track pitch values of segments incrementally according to time-steps or percentage.
2. places the measurements in a CSV for further analysis.
3. saves the segments in subfolders for the second process.

## Drawing:
This script:
1. plots the pitch of sound files that have been grouped together.
2. allows the user to re-draw sets of sound files with differing plot/analysis criteria.

##### The option *'Plot only'* skips the analysis portion and goes directly to the second process. This is useful if you don't want to re-run the first process.

Crucially, options for the second process are constrained by the user's choice in the first form/window. The key selections are:

*Labeled tier number:*

- this tells the script which tier of your TextGrid to search for segmented tone categories

*Analysis type:*
  - this tells the script whether you want to output raw data to a tab-delimited CSV file, or if you want to plot the tones in the Praat picture window. Options are explained further below.

    - *Raw for CSV* = you want the raw pitch measurements at set increments over time.

    - *Percentage for CSV* = you want pitch measurements at set percentages over time.

    - *Normalize for Drawing* = you want individual tone sound files for each segmented tone. This option is good for plotting all the pitch traces in your data in order to explore things like length and pitch height. It also creates a single normalized WAV file Based on all the labeled segments in the "labeled_tier_number" identified above.

    - *Normalize by tone for Drawing* = you want individual tone sound files, but organized by label. This option is good if you've mostly identified the tonal categories in your data, as it creates a single normalized sound file for each tonal category, based on the properties of the labeled segments in each category.

    - *Plot only* = you already have tonal audio files in the folder and you just want to plot them.

#### A few notes regarding the other options:

*"Analysis points time step"*
- defines the increment (in seconds) at which raw measurements are taken. This means that segments in your TextGrids may be of differing lengths. As noted above, the measurements are only taken in the tier number identified, and only of TextGrid segments that have been labeled; empty/unlabeled segments and other tiers will be ignored.

*"Number of intervals"*
- refers to the number of interval values extracted within a single label. Defaults are currently set at tier '2', and taken every '0.01' seconds (10ms) for '50' intervals. With these defaults the F0 will be measured every 10ms from the start of the textgrid, a total of 50 times, or 500 ms (50 x 10ms = 500ms). This should be long enough for most tone-bearing-units. This will require some fine-tuning by the user for their particular data set, as different users will want to measure segments of differing lengths. It also requires the user to segment their textgrid according to what they want to measure, but allows for some flexibility.

*"Percentage increments"*
- defines the locations within the label to sample for pitch when the user prefers a more normalized analysis. If at '10' (the current default), for example, the audio will be sampled at 10 equidistant points within the label, or at 10 percent increments. If at '20', the audio will be sampled at 20 equidistant points, or at 5 percent increments.

#### The *"Percentage increments"* value is used by both *'Normalize'* options.

  - The user is also able to choose whether to resample the audio. Resampling is done for LPC analysis, to make sure all sound files have the same specs. If your computer can handle higher sample rates, such as 44.1 kHz, and your sound files are already in that format, the default of 'No' can be used. Skipping resampling will speed up the script processing, so you can view your data sooner.

  - The *"Sample rate"* of 22000 samples/sec (22kHz) is a good rate for most analyses, as higher sample rates don't necessarily improve the analysis of speech (rates above 16kHz are recommended). Increasing the sample rate may increase processing time, but can be worth playing around with for your particular use case, especially if you have lots of processing power. The quality level of the resampling (50) is the Praat default.

  - There are various form windows that pop up to query the user. Some deal with overwriting files. If you have selected one of the **Normalize** options, you will be shown a follow-up window that tells you what the unique *label* values are in your script. This can help you fix issues or errors in transcription within the script, or indicate that you are not analyzing the correct tier of the TextGrid.

  - In the two **Normalize** options, folders are automatically created to store new WAV files for plotting in the Praat drawing window. The base folder created has the same name as the sound file that the script has analyzed. So if a file (with corresponding TextGrid) is named *'Speaker01'*, the labeled tonal segments will all be placed in a subfolder named *'Speaker01/'*.

  - The first **Normalize** option (*Normalize for Drawing*) places all sound files in the same base folder, as well as creating a subfolder named according to the name of the analyzed sound file/TextGrid pair with the text *'\_norm'* attached. So from our example above, *'Speaker01_norm'*. This folder contains a single sound file normalized (by both pitch and length) based on all the tone-labeled segments. The second **Normalize** option (*Normalize by tone for Drawing*) creates a new subdirectory for each tone label, and places all the corresponding labeled tones inside the respective subdirectory. If there are two labeled tones in the *'Speaker01'* file (*'one'* and *'two'*), the subdirectories will be *'Speaker01/one/'* and *'Speaker01/two'*, respectively. It will also create a subdirectory called *'Speaker01/Speaker01_norm/'* in which it will deposit a normalized sound file (by pitch and length) for each respective tone category/label.

  - The second form window is displayed after all the label analyses have been run. In this second window the user can set parameters that affect the way files are drawn in the Praat picture window. Options include *'Normalize time'*, for viewing all plotted audio files as if they were the same length, various frequency options and drawing options, whether or not to *'Smooth pitch curves'*, the *'time step'* at which to sample pitch, the range in which to sample pitch, and the plot options for the vertical scale (Hz) and the horizontal scale (seconds). There is also an option to *'Redraw pitch'*, which re-analyzes each sound file's pitch based on new user settings - helpful if your initial pitch targets for a speaker result in mis-analyzed pitch tracks.

  - Arguably, the most important options to configure are the *'Sound file directory'* at the top of the window, and the *'Output files'* fields. This tells the script where to look for audio files that you want to plot, and where to save the picture that gets plotted and the details of the pitch analyses.

  - If the user chose the first Normalize option in the previous window (Normalize for Drawing), the *'Sound file directory'* field defaults to the base subdirectory of the most recently analyzed audio file. Simply add *'\_norm'* to the end of the directory (before the *'/'*) in order to plot just the normalized file.

  - If the user chose the second **Normalize** option in the previous window (*Normalize by tone for Drawing*), the *'Sound file directory'* field defaults to the normalized subdirectory of the most recently analyzed audio file (i.e. *'Speaker01/Speaker01_norm/'* from our example above). To plot the individual plot traces from each labeled segment, the user will need to change the directory to the respective directory that contains the segments the user wants to plot.

  - Fortunately, the **Drawing** window will repeat after every drawing. This allows the user to fine-tune their analysis, draw a different set of tone files, and output new drawings with different settings or overwrite previous pictures that they created.
