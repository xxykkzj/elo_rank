import pandas as pd
import os

# Define the full directory where your files are located
input_dir = "C:/Users/biand/Documents/project/elo_rank/tennis_bet/"
output_dir = "C:/Users/biand/Documents/project/elo_rank/tennis_bet_csv/"

# Create the output directory if it doesn't exist
os.makedirs(output_dir, exist_ok=True)

# Define the years and corresponding file extensions
files = {
    "2010": ".xls",
    "2011": ".xls",
    "2012": ".xls",
    "2013": ".xlsx",
    "2014": ".xlsx",
    "2015": ".xlsx",
    "2016": ".xlsx",
    "2017": ".xlsx",
    "2018": ".xlsx",
    "2019": ".xlsx"
}

# Loop over the files, read them and export as CSV
for year, ext in files.items():
    input_file = f"{input_dir}{year}{ext}"
    output_file = f"{output_dir}{year}.csv"
    
    # Read the Excel file
    df = pd.read_excel(input_file, na_values="N/A")
    
    # Handle NA values
    df.dropna(inplace=True)  # Option 1: Remove rows with any NA values
    # df.fillna(0, inplace=True)  # Option 2: Fill NA values with 0 (or any specific value)
    # df.fillna(df.mean(), inplace=True)  # Option 3: Fill NA values with the mean of the column
    
    # Save to CSV
    df.to_csv(output_file, index=False)
    print(f"Converted {input_file} to {output_file}")

print("All files converted and NA values handled successfully!")
