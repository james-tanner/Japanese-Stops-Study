## Calculate F0 and breathiness measures from Japanese stops data
## James Tanner
## November 2020

import pandas as pd
import numpy as np
import parselmouth
import os
import time

begin = time.time()
## path to the audio files
audio = '../data/JapaneseVOTdata_2020NOV20/sound/'

## read dataset
df = pd.read_csv('../data/JP_STOPS_DATA.csv')

## calculate VOT as voicing - release
df['VOT'] =  df['voicing_x'] - df['release']

## make acoustic measurement columns
df['F0'] = np.nan

## start processing files
## since measurement requires generating pitch process objects for each file,
## it is faster to perform measurement on a by-file basis (instead of by-observation)
files = np.unique(df['name'].values)
print("Processing {} tokens across {} files".format(len(df), len(files)))

def getF0(pitchobj, ppobj, t):

	## find the glottal pulse closed to the annotated voicing
	nearest_pulse = parselmouth.praat.call(ppobj, "Get low index", t)
	pulse_time = parselmouth.praat.call(ppobj, "Get time from index", nearest_pulse)

	F0 = pitchobj.get_value_at_time(pulse_time)

	return F0

for file in files:
		
	print("Processing {} ({} tokens)".format(file, len(df[df['name'] == file])), end = " ")

	## read sound file
	fileBegin = time.time()
	sound = parselmouth.Sound(os.path.join(audio, file + ".WAV"))

	## make gender-specific pitch tracks based on recommendations in Eager (2015):
	## specifically, [70,250] for males and [100,300] for females
	to_fix = []
	gender = np.unique(df[df['name'] == file]['gender'].values)[0]
	try:
	    if gender == 'm':
		    pitch_floor, pitch_ceiling = 70.00, 250.00
	    elif gender == 'f':
		    pitch_floor, pitch_ceiling = 100.00, 300.00
	    else:
		    raise Exception("No speaker gender!")
	except:
	    print("No speaker gender for {} -- skipping".format(file))
	    to_fix.append(file)

	pitch = sound.to_pitch_cc(time_step = 0.001,
				  pitch_floor = pitch_floor,
				  pitch_ceiling = pitch_ceiling)

	## make PointProcess object
	pulses = parselmouth.praat.call([sound, pitch], "To PointProcess (cc)")

	## start measuring individual tokens
	for index, row in df.iterrows():
		if row['name'] == "acmry2":

			## get F0 for the token
			df.loc[index, 'F0'] = getF0(pitch, pulses, row['voicing_x'])

	fileEnd = time.time()
	print("took {} seconds".format(round(fileEnd - fileBegin, 2)))

end = time.time()
print("Total time: {} minutes".format(round((end - begin)/60, 2)))
print("Files to fix: {}".format(to_fix))

