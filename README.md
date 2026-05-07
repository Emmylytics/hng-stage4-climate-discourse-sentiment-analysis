# 🌍 Climate Discourse Analytics on Twitter

## 🧾 Project Overview

This project analyzes climate-related conversations on Twitter over a 13-year period (2006–2019). The objective is to transform large-scale social media data into actionable insights that reveal patterns in public sentiment, stance, and aggressive discourse.

The work follows an end-to-end analytics workflow, including data cleaning, feature engineering, analytical view creation, and interactive dashboard development for business intelligence reporting.

---

## 🎯 Objectives

The analysis is designed to address key questions:

* How is public sentiment toward climate issues distributed?
* How have stance and sentiment evolved over time?
* Which topics generate the most engagement and hostility?
* Do certain stance groups exhibit more aggressive behavior?
* How does climate discourse vary across geographic regions?

---

## 📁 Dataset Overview

The dataset consists of ~15 million climate-related tweets with the following key attributes:

* `id` – unique tweet identifier  
* `created_at` – timestamp of tweet  
* `tweet_year` – extracted year for time-based analysis  
* `sentiment` – continuous sentiment score (-1 to 1)  
* `sentiment_bucket` – categorized sentiment (positive, neutral, negative)  
* `stance` – classification (believer, denier, neutral)  
* `topic` – assigned discussion topic  
* `aggressiveness` – aggressive vs non-aggressive label  
* `lat`, `lng` – geographic coordinates  
* `is_geo_valid` – flag for valid location data  

---

## 🛠️ Tools & Technologies

- SQL (PostgreSQL) — data cleaning, transformation, analytical modeling  
- Power BI — dashboard design and visualization  

---

## 🧠 Analytical Approach

The analysis is structured into two main layers:

### Descriptive Analytics

Provides a high-level understanding of the dataset:

* Overall tweet volume and engagement trends  
* Distribution of stance, sentiment, and topics  
* Summary statistics (total tweets, average sentiment, aggression rate, geo coverage)

---

### Diagnostic Analytics

Explores deeper relationships and drivers:

* Aggressiveness patterns across topics and stance groups  
* Regional variation in sentiment and hostility  
* Year-over-year sentiment changes  
* Topic–sentiment interaction patterns  

---

## ⚙️ Data Pipeline Strategy

The project follows a structured SQL-first workflow:

* **Extract** → Raw tweet dataset loaded into PostgreSQL  
* **Transform** → Data cleaning, validation, and feature engineering  
* **Load** → Creation of analytical views for reporting  

### Key Transformations

* Extraction of `tweet_year` from timestamps  
* Sentiment categorization into buckets  
* Filtering of invalid or undefined topics  
* Validation of geographic data  
* Creation of derived metrics (e.g., aggression rate, sentiment change)

---

## 📊 Analytical Views

### Descriptive Views

* `vw_summary_stats` → dataset-wide KPIs  
* `vw_tweets_by_year` → annual trends in volume and sentiment  
* `vw_stance_distribution` → stance composition  
* `vw_sentiment_distribution` → sentiment breakdown  
* `vw_topic_distribution` → topic-level engagement  

---

### Diagnostic Views

* `vw_stance_trend_by_year` → stance evolution over time  
* `vw_aggressiveness_by_topic` → hostility drivers by topic  
* `vw_aggressiveness_by_stance` → aggression across stance groups  
* `vw_regional_analysis` → geographic patterns  
* `vw_yoy_sentiment_change` → sentiment shifts year-over-year  
* `vw_topic_sentiment_distribution` → topic vs sentiment breakdown for heatmap analysis  

---

## 📈 Dashboard Structure (Power BI)

The dashboard is organized into three analytical layers:

### Page 1 — At a Glance
* KPI summary (volume, sentiment, aggression, geo coverage)  
* Tweet volume trend over time  
* Distribution of stance, topics, and sentiment  

---

### Page 2 — Trends Over Time
* Stance composition trends across years  
* Year-over-year sentiment change  
* Topic-level sentiment comparison  
* Annual summary table  

---

### Page 3 — Discourse & Division
* Aggressiveness across topics and stance groups  
* Regional sentiment and hostility patterns  
* Topic–sentiment interaction heatmap  

---

## 💡 Key Insights

* Approximately **28–29% of tweets exhibit aggressive language**, indicating notable hostility in climate discourse  
* Climate discussions are dominated by **believer-stance tweets**, though opposing views remain present  
* Certain topics consistently generate **higher levels of aggression**, suggesting areas of contention  
* **Denier-aligned tweets** tend to show higher aggressiveness compared to other groups  
* Sentiment fluctuates over time, reflecting the dynamic nature of public opinion  
* Regional differences highlight the influence of **geographic and socio-political context**  

---

## 📦 Deliverables

* SQL pipeline (`climate_analysis.sql`)  
* Power BI dashboard (`.pbix`)  
* Analytical report (`.docx`)  

---

## 📂 Repository Structure

```bash
climate-twitter-analysis/
├── sql/
│   └── climate_tweet_analysis.sql
├── report/
│   └── Climate_Change_Analysis_Report.docx
├── assets/
│   └── dashboard_preview.png
└── README.md
```

---

## 🚀 Key Takeaway

This project demonstrates how large-scale social media data can be transformed into meaningful analytical insights, enabling a deeper understanding of sentiment dynamics, polarization, and behavioral patterns in climate discourse.

---

## 📚 Dataset Reference

Effrosynidis, D., Karasakalidis, A. I., Sylaios, G., & Arampatzis, A. (2022).
The climate change Twitter dataset. Expert Systems with Applications, 204, 117541.

---

## 🔗 Acknowledgment

Completed as part of the HNG Data Analytics Internship Program.

---

## 👤 Author  
Emmanuel Achugo  
Data Analyst  
SQL • Python • Power BI • Machine Learning
