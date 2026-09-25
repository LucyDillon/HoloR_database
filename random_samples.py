import pandas as pd
import numpy as np

df = pd.read_csv("datasets_for_sampling.csv")

# Randomly select 20 samples from all datasets combined
sampled = df.sample(n=20, random_state=42)

# Save the selected samples
sampled.to_csv("random_20_samples.csv", index=False)

print(sampled)
