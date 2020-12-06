## Calculate F0 and breathiness measures from Japanese stops data
## James Tanner
## November 2020

import pandas as pd
import numpy as np
import parselmouth
import os
import re
import time
import traceback

begin = time.time()
## path to the audio files
audioDir = '../data/JapaneseVOTdata_2020NOV20/sound/'

## read dataset
df = pd.read_csv('../data/JP_STOPS_DATA.csv')

## calculate VOT as voicing - release
df['VOT'] =  df['voicing'] - df['release']

## make acoustic measurement columns
df['f0'] = np.nan
df['file_amplitude'] = np.nan
df['burst_amplitude'] = np.nan
df['h1mnh2'] = np.nan
df['h1mna3'] = np.nan

## start processing files
## since measurement requires generating pitch process objects for each file,
## it is faster to perform measurement on a by-file basis (instead of by-observation)
files = np.unique(df['name'].values)
print("Processing {} tokens across {} files".format(len(df), len(files)))

def getF0(pitchobj, ppobj, t):

	## find the glottal pulse closed to the annotated voicing
	nearest_pulse = parselmouth.praat.call(ppobj, "Get nearest index", t)
	pulse_time = parselmouth.praat.call(ppobj, "Get time from index", nearest_pulse)

	F0 = pitchobj.get_value_at_time(pulse_time)

	return F0

def makeVowelSound(sound, start, end):

	## calculate the midpoint of the vowel
	mid = (end - start)/2

	## first extract the vowel token with 5ms buffer
	ExtractedSound = sound.extract_part(
		from_time = (start - 0.05),
		to_time = (end + 0.05),
		window_shape = parselmouth.WindowShape.HAMMING)

	## resample to 16k
	ExtractedSound = ExtractedSound.resample(16000)

	return(mid, ExtractedSound)

def getFormantValues(sound, gender, mid):

	## set gender-specific reference values
	if gender == "M":
		maxf = 5000
		f1ref = 500
		f2ref = 1485
		f3ref = 2475
	else:
		maxf = 5500
		f1ref = 550
		f2ref = 1650
		f3ref = 2750

	## make Formant object
	Formants = sound.to_formant_burg(time_step = 0.05,
		max_number_of_formants = 5,
		maximum_formant = maxf)

	## extract formants (F1-3) from vowel midpoint
	F1 = Formants.get_value_at_time(formant_number = 1, time = mid)
	F2 = Formants.get_value_at_time(formant_number = 2, time = mid)
	F3 = Formants.get_value_at_time(formant_number = 3, time = mid)

	return(F1, F2, F3)

def getVoiceQuality(sound, mid, pfloor, pceiling, f1, f2, f3):

	## create Pitch object from extracted vowel
	ExtractedPitch = sound.to_pitch(pitch_floor = pfloor, pitch_ceiling = pceiling)

	## interpolate pitch
	ExtractedPitch = ExtractedPitch.interpolate()

	## generate spectrum
	ExtractedSpectrum = ExtractedSound.to_spectrum()
	ltas = parselmouth.praat.call(ExtractedSpectrum, "To Ltas (1-to-1)")

	## try calculating F0
	try:
		F0mid = round(ExtractedPitch.get_value_at_time(time = mid))
		p10_F0mid = F0mid/10

		lowerbh1 = F0mid - p10_F0mid
		upperbh1 = F0mid + p10_F0mid
		lowerbh2 = F0mid * 2 - p10_F0mid * 2
		upperbh2 = F0mid * 2 + p10_F0mid * 2

		h1db = parselmouth.praat.call(ltas, "Get maximum...", lowerbh1, upperbh1, "None")
		h1hz = parselmouth.praat.call(ltas, "Get frequency of maximum...", lowerbh1, upperbh1, "None")
		h2db = parselmouth.praat.call(ltas, "Get maximum...", lowerbh2, upperbh2, "None")
		h2hz = parselmouth.praat.call(ltas, "Get frequency of maximum...", lowerbh2, upperbh2, "None")

		p10_f1 = f1 / 10
		p10_f2 = f2 / 10
		p10_f3 = f3 / 10

		lowerba1 = f1 - p10_f1
		upperba1 = f1 + p10_f1
		lowerba2 = f2 - p10_f2
		upperba2 = f2 + p10_f2
		lowerba3 = f3 - p10_f3
		upperba3 = f3 + p10_f3

		a1db = parselmouth.praat.call(ltas, "Get maximum...", lowerba1, upperba1, "None")
		a1hz = parselmouth.praat.call(ltas, "Get frequency of maximum...", lowerba1, upperba1, "None")
		a2db = parselmouth.praat.call(ltas, "Get maximum...", lowerba2, upperba2, "None")
		a2hz = parselmouth.praat.call(ltas, "Get frequency of maximum...", lowerba2, upperba2, "None")
		a3db = parselmouth.praat.call(ltas, "Get maximum...", lowerba3, upperba3, "None")
		a3hz = parselmouth.praat.call(ltas, "Get frequency of maximum...", lowerba3, upperba3, "None")

		h1mnh2 = h1db - h2db
		h1mna1 = h1db - a1db
		h1mna2 = h1db - a2db
		h1mna3 = h1db - a3db

	except Exception as e:
		h1mnh2 = np.nan
		h1mna3 = np.nan

	return (h1mnh2, h1mna3)

for i, f in enumerate(files):

	## read sound file
	fileBegin = time.time()

	for audioFile in os.listdir(audioDir):
		try:
			fileName = re.findall(f + "\.[wav|WAV]+", audioFile)[0]
		except IndexError:
			continue

	sound = parselmouth.Sound(os.path.join(audioDir, fileName))
	print("Processing {} ({}/{}; {} tokens)".format(
	    f, i + 1, len(files), len(df[df['name'] == f])), end = " ")

	## make gender-specific pitch tracks based on recommendations in Eager (2015):
	## specifically, [70,250] for males and [100,300] for females
	to_fix = []
	gender = np.unique(df[df['name'] == f]['gender'].values)[0]
	try:
	    if gender == 'm':
		    pitch_floor, pitch_ceiling = 70.00, 250.00
	    elif gender == 'f':
		    pitch_floor, pitch_ceiling = 100.00, 300.00
	    else:
		    raise Exception("No speaker gender!")
	except:
	    print("No speaker gender for {} -- skipping".format(f))
	    to_fix.append(f)

	pitch = sound.to_pitch_cc(time_step = 0.001,
				  pitch_floor = pitch_floor,
				  pitch_ceiling = pitch_ceiling)

	## generate an intensity object and get the average
	## intensity for the whole file
	intensity = sound.to_intensity(minimum_pitch = pitch_floor)
	file_intensity = parselmouth.praat.call(intensity, "Get mean", sound.start_time, sound.end_time)

	## make PointProcess object
	pulses = parselmouth.praat.call([sound, pitch], "To PointProcess (cc)")

	## start measuring individual tokens
	for index, row in df.iterrows():
		if row['name'] == f:

			## get F0 for the token
			df.loc[index, 'f0'] = getF0(pitch, pulses, row['voicing'])

			## add file-average intensity as well
			## as intensity for the point of release
			df.loc[index, 'file_amplitude'] = file_intensity
			df.loc[index, 'burst_amplitude'] = intensity.get_value(row['release'])

			## calculate voice quality measurements
			V1_mid, ExtractedSound = makeVowelSound(sound, row['V1_start'], row['V1_end'])
			F1, F2, F3 = getFormantValues(ExtractedSound, gender, V1_mid)

			df.loc[index, 'h1mnh2'], df.loc[index, 'h1mna3'] = getVoiceQuality(ExtractedSound,
				V1_mid,
				pitch_floor,
				pitch_ceiling,
				F1, F2, F3)

	fileEnd = time.time()
	print("took {} seconds".format(round(fileEnd - fileBegin, 2)))

end = time.time()
print("Total time: {} minutes".format(round((end - begin)/60, 2)))
print("Files to fix: {}".format(to_fix))

df.to_csv('../data/JP_STOP_MEASURES.csv')
