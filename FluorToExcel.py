import pandas as pd
import os
import glob
from openpyxl import Workbook
from openpyxl.utils.dataframe import dataframe_to_rows

print("Welcome to FluorToExcel.")
# Get valid path to parent folder
exists = False
while not exists:
    parent_path = input("Full path to parent data folder: ")
    if parent_path[-1] != "/":
        parent_path += "/"
    exists = os.path.exists(parent_path)

# Get name for workbook
wb_name = parent_path[0:-1]
wb_name = wb_name[wb_name.rfind("/") + 1:] + ".xlsx"
print("Your results will be saved as " + wb_name + " in that folder.\n")

# Create Workbook
wb = Workbook()

# Create sheet for each folder
subfolders = [f.path for f in os.scandir(parent_path) if f.is_dir()]
for folder in subfolders:
    # Edit name of folder for suitable spreadsheet name
        # (The Excel file becomes corrupted if the name is > 31 chars,
        #  can still be opened but needs to be "repaired" every time)
    experiment = folder[folder.rfind("/") + 1:]
    experiment = experiment.replace(" ", "")
    experiment = experiment.replace(".lif", "")

    ws = wb.create_sheet(experiment)

    # Merge data from each CSV file in the folder horizontally into dataframe
    files = sorted(glob.glob(os.path.join(folder, '*.csv')))
    all_data = pd.DataFrame()
    labels = [" "]
    for file in files:
        data = pd.read_csv(file, index_col=0)
        label = file[file.rfind("/") + 1:-4]
        labels += ([label] + [" "]*(len(data.columns) - 1))  # label each file dataset
        all_data = pd.concat([all_data, data], axis=1)

    # Print dataframe to spreadsheet, with labels
    ws.append(labels)
    for r in dataframe_to_rows(all_data, index = True, header = True):
        ws.append(r)

first = wb["Sheet"]  # clean up - remove empty first sheet
wb.remove(first)

wb_path = parent_path + wb_name
wb.save(wb_path)
print("\nCompleted. Thank you!")
