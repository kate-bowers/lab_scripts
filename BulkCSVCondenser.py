# Kate Bowers
# Levin Lab, Tufts University (undergraduate)
# July 2019
# Program to convert folder of Scimagine bounding box CSVs into one master CSV
#   with centroid coordinates and timepoints, to be fed into TrackMate
# More efficient than ScimagineCSVCondenser - processes columnwise rather than rowwise

import pandas as pd
import sys
import glob
import os
import datetime

if len(sys.argv) > 1:
    folder = sys.argv[1]
else:
    folder = input("Path to parent CSV folder:")

# print("program starts at " + str(datetime.datetime.now()))
# Read in all bounding box files
files = sorted(glob.iglob(os.path.join(folder, '*.csv')))
master = pd.DataFrame()

# files = files[::2] # Change me for different FPS! Also change save name line 41

# Convert all bounding box dimensions to centroid coordinates
frame = 0
for f in files:
    # print(f)
    frame += 1  # track timepoint
    data = pd.read_csv(f, header=None)
    data.columns = ['xmin', 'xmax', 'ymin', 'ymax']
    new_df = pd.DataFrame()
    new_df['X'] = data[['xmin', 'xmax']].mean(axis=1)
    new_df['Y'] = data[['ymin', 'ymax']].mean(axis=1)
    new_df['T'] = (frame)
    # print(new_df)
    master = master.append(new_df)

# Saves master file of all centroid coordinates and timepoints into parent folder
master.to_csv(path_or_buf=os.path.join(folder, "annotations-15fps.csv"), index=False, float_format='%g')
# print("done at " + str(datetime.datetime.now()))
