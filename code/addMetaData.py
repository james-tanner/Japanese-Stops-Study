## Add the speaker and stimulus metadata files into main dataset
## James Tanner
## November 2020

import re
import pandas as pd
import numpy as np

## load main dataset
df = pd.read_csv("../data/JP_STOPS.csv",
	dtype = {'name' : np.object,
			 'utterance_label' : np.int,
			 'utterance_start' : np.float,
			 'utterance_end' : np.float})

## split ID into name and trial number
df[['speaker', 'speaker_trial']] = df['name'] \
	.apply(lambda x : re.match("(.*)(\d)", x).groups()) \
	.apply(pd.Series)

df['speaker_trial'] = df['speaker_trial'].astype(np.int)

## Add speakers first
speakers = pd.read_excel('../data/JapaneseVOTdata_2020NOV20/subject_infomation_2020NOV20.xls')
df = pd.merge(df, speakers, how = 'left', left_on = 'speaker', right_on = 'speaker_id')

## Add word/trial information
words = pd.read_excel('../data/JapaneseVOTdata_2020NOV20/TestWords_2020NOV20.xlsx')
df = pd.merge(df, words, how = 'left', left_on = ['utterance_label', 'speaker_trial'], right_on = ['label(order_in_a_trial)', 'trial'])

## write CSV to file
df.to_csv('../data/JP_STOPS_DATA.csv')