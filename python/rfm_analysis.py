import pandas as pd
import datetime as dt
import os
from sqlalchemy import create_engine

# ---------------------------
# Database Connection
# ---------------------------

username = os.getenv("DB_USER")
password = os.getenv("DB_PASSWORD")
host = "localhost"
database = "retail_analytics"

engine = create_engine(f"mysql+pymysql://{username}:{password}@{host}/{database}")

# ---------------------------
# Extract Data
# ---------------------------

query = """
SELECT 
    c.customer_unique_id,
    o.order_purchase_timestamp,
    oi.price
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
"""

df = pd.read_sql(query, engine)

# ---------------------------
# Build RFM Metrics
# ---------------------------

df['order_purchase_timestamp'] = pd.to_datetime(df['order_purchase_timestamp'])

snapshot_date = df['order_purchase_timestamp'].max() + dt.timedelta(days=1)

rfm = df.groupby('customer_unique_id').agg({
    'order_purchase_timestamp': lambda x: (snapshot_date - x.max()).days,
    'customer_unique_id': 'count',
    'price': 'sum'
})

rfm.columns = ['Recency', 'Frequency', 'Monetary']

# ---------------------------
# Create RFM Scores (1–5)
# ---------------------------

rfm['R_score'] = pd.qcut(rfm['Recency'], 5, labels=[5,4,3,2,1])
rfm['F_score'] = pd.qcut(rfm['Frequency'].rank(method='first'), 5, labels=[1,2,3,4,5])
rfm['M_score'] = pd.qcut(rfm['Monetary'], 5, labels=[1,2,3,4,5])

rfm['RFM_Score'] = (
    rfm['R_score'].astype(str) +
    rfm['F_score'].astype(str) +
    rfm['M_score'].astype(str)
)

# ---------------------------
# Segment Assignment
# ---------------------------

def segment(row):
    if row['R_score'] == 5 and row['F_score'] >= 4:
        return 'Champions'
    elif row['F_score'] >= 4:
        return 'Loyal Customers'
    elif row['R_score'] <= 2:
        return 'At Risk'
    else:
        return 'Regular'

rfm['Segment'] = rfm.apply(segment, axis=1)

# ---------------------------
# Segment Summary
# ---------------------------

segment_summary = rfm.groupby('Segment').agg({
    'Recency': 'mean',
    'Frequency': 'mean',
    'Monetary': 'mean'
}).round(2)

print(segment_summary)

# ---------------------------
# Export to CSV
# ---------------------------

rfm.to_csv("rfm_segments.csv")

# ---------------------------
# Push Back to MySQL
# ---------------------------

rfm.reset_index(inplace=True)

rfm.to_sql(
    name='customer_rfm_segments',
    con=engine,
    if_exists='replace',
    index=False
)

print("RFM segmentation successfully pushed to MySQL.")