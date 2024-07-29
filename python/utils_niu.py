import os
import glob
import pandas as pd

def load_csv_files(path):
    files = glob.glob(os.path.join(path, "*.csv"))
    return pd.concat([pd.read_csv(f) for f in files], ignore_index=True)
