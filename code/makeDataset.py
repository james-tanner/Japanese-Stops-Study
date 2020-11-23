## Extract segmentation information from Praat TextGrids
## James Tanner
## November 2020

import os
import textgrid
import argparse
import pandas as pd

## Process command line arguments:
## directory containing TextGrids
## and where to write CSV
parser = argparse.ArgumentParser()
parser.add_argument("inputDir", help = "Path to the list of formant datasets")
parser.add_argument("OutputFile", help = "Filename and path to write out CSV")
args = parser.parse_args()


def getIntervalValues(interval):
	"""Get the start, end, and label
	   from an interval"""

	Start = interval.minTime
	End = interval.maxTime
	Label = interval.mark

	return(Start, End, Label)

def getPointValues(point):
	"""Get the time and label
	   from a point"""

	Time = point.time
	Label = point.mark

	return(Time, Label)

def ProcessUtterance(utterance):
	"""Pass utterance interval to value extraction"""

	uttStart, uttEnd, uttLabel = getIntervalValues(utterance)

	return(uttStart, uttEnd, uttLabel)

def ProcessSegments(segments, label, uttStart, uttEnd):
	"""Get segment values for segments with the right label"""

	Start, End, Label = None, None, None

	for segment in segments[0]:

		if segment.mark == label and segment.minTime > uttStart and segment.maxTime < uttEnd:
			Start, End, Label = getIntervalValues(segment)
		else:
			pass

	return (Start, End, Label)

def ProcessPoint(pointtier, uttStart, uttEnd):
	"""Get point values for a particular tier"""

	Time, Label = None, None

	for point in pointtier[0]:
		if point.time > uttStart and point.time < uttEnd:
			Time, Label = getPointValues(point)

	return (Time, Label)

def makeRow(file, utterance, segments, release, voicing):
	"""Get the values from each tier in the TextGrid"""

	## get utterance values
	uttStart, uttEnd, uttLabel = ProcessUtterance(utterance)

	## get segment labels for {C1-V2}
	C1Start, C1End, C1Label = ProcessSegments(segments, "C1", uttStart, uttEnd)
	V1Start, V1End, V1Label = ProcessSegments(segments, "V1", uttStart, uttEnd)
	C2Start, C2End, C2Label = ProcessSegments(segments, "C2", uttStart, uttEnd)
	V2Start, V2End, V2Label = ProcessSegments(segments, "V2", uttStart, uttEnd)

	## get the voicing and release labels
	rTime, rLabel = ProcessPoint(release, uttStart, uttEnd)
	vTime, vLabel = ProcessPoint(voicing, uttStart, uttEnd)

	## put them all in a dict
	row = {'name' : file,
		   'utterance_label' : uttLabel,
		   'utterance_start' : uttStart,
		   'utterance_end' : uttEnd,
		   'C1_start' : C1Start,
		   'C1_end' : C1End,
		   'V1_start' : V1Start,
		   'V1_end' : V1End,
		   'C2_start' : C2Start,
		   'C2_end' : C2End,
		   'V2_start' : V2Start,
		   'V2_end' : V2End,
		   'release' : rTime,
		   'voicing' : vTime}

	return row

def load_textgrid(file):
	"""Open the TextGrid and get the
	   correct tier names"""

	tg = textgrid.TextGrid()
	tg.read(file)
	names = tg.getNames()

	## some utterance tiers are called
	## 'sound' and 'word', so parse
	## appropriately
	if 'sound' in names:
		utt = tg.getList('sound')
	elif 'word' in names:
		utt = tg.getList('word')
	else:
		utt = tg.getList('utt')

	if 'seg' in names:
		segments = tg.getList('seg')
	else:
		segments = tg.getList('segment')

	release = tg.getList('release')
	voicing = tg.getList('voicing')

	return(utt, segments, release, voicing)

def processfile(dir, file):
	"""Pass the file to the TextGrid parser
	   and write out a list of rows for each
	   observation in the TextGrid"""

	rows = None

	## ignore audio files
	if file.endswith(".TextGrid"):
		utt, segments, release, voicing = load_textgrid(os.path.join(dir, file))
		print(file)
		
		## need to exception-handle because some grids are empty
		try:
			rows = ([makeRow(os.path.splitext(file)[0], utterance, segments, release, voicing) for utterance in utt[0]])
		except IndexError:
			print("{} is broken".format(file))

	return(rows)

df = pd.DataFrame(columns = ['name', 'utterance_label', 'utterance_start', 'utterance_end',
							 'C1_start', 'C1_end', 'V1_start', 'V1_end', 'C2_start',
							 'C2_end', 'V2_start', 'V2_end', 'release', 'voicing'])

rows = [processfile(args.inputDir, file) for file in os.listdir(args.inputDir)]

## since this returns a multi-embedded list,
## slight hack to get simple list of observations
observations = []
for row in rows:
	if row is not None:
		for obs in row:
			observations.append(obs)

## write each observation to a dataframe
## ignoring the rows which don't contain
## any utterances
print("Building dataset...")
for obs in observations:
	if obs['utterance_label'] != "":
		df = df.append(obs, ignore_index = True)

## write the CSV to file
df.to_csv(args.OutputFile, index = False)
