# 🏦 Analytical CRM Development for a Bank
### A Data Analytics Capstone Project

> **Project by:** Vivek Ajay Patil  
> **Tools Used:** MySQL · Microsoft Excel · Power BI · PowerPoint  
> **Domain:** Banking · Customer Relationship Management · Churn Analytics

---

## 📋 Project Overview

A leading bank engaged a CRM analytics specialist to extract actionable insights from customer data. The goal: **reduce customer churn, improve service delivery, and enhance customer satisfaction** using end-to-end data analytics.

This project covers the full analytics pipeline — from raw data ingestion and SQL-based cleaning to Power BI dashboards and executive storytelling.

---

## 🗂️ Files in This Repository

| File | Description |
|------|-------------|
| `BankCRM_SQL.sql` | Full MySQL script — schema, data import, cleaning, and all 26+ objective & subjective queries |
| `BankCRM_EXCEL.xlsx` | Consolidated workbook — cleaned data, helper columns, pivot tables |
| `BankCRM_POWERBI.pbix` | Interactive Power BI dashboard with KPIs, slicers, and visualizations |
| `BankCRM_PPT.pptx` | Executive presentation — data story with insights and recommendations |
| `BankCRM_DOC.docx` | Detailed answers to all 26 objective + 14 subjective questions |
| `BankCRM_rawData.zip` | Original 7 CSV source files |

---

## 📊 Dataset at a Glance

**Source tables (7 CSVs):**

| Table | Rows | Type |
|-------|------|------|
| `Bank_Churn` | 10,000 | Fact — account & churn details |
| `CustomerInfo` | 10,000 | Dimension — demographics |
| `Gender` | 2 | Lookup |
| `Geography` | 3 | Lookup |
| `CreditCard` | 2 | Lookup |
| `ActiveCustomer` | 2 | Lookup |
| `ExitCustomer` | 2 | Lookup |

**Key columns:** `CustomerId`, `CreditScore`, `Tenure`, `Balance`, `NumOfProducts`, `HasCrCard`, `IsActiveMember`, `Exited`, `EstimatedSalary`, `Age`, `Bank_DOJ`, `GeographyID`, `GenderID`

---

## 📈 Key KPIs (Verified from Raw Data)

| Metric | Value |
|--------|-------|
| **Total Customers** | 10,000 |
| **Churned Customers** | 2,037 |
| **Overall Churn Rate** | **20.37%** |
| **Active Members** (post-fix) | **4,416** |
| **Credit Card Holders** | 7,055 (70.55%) |
| **Avg Account Balance** | ₹76,485.89 |
| **Avg Credit Score** | 650.53 |
| **Avg Estimated Salary** | ₹1,00,090.24 |

---

## 🔍 Key Findings & Insights

### 1. Churn by Gender
| Gender | Customers | Churned | Churn Rate |
|--------|-----------|---------|------------|
| Female | 4,543 | 1,139 | **25.07%** |
| Male | 5,457 | 898 | 16.46% |

> ⚠️ Female customers churn at **1.5× the rate** of male customers — a critical retention target.

### 2. Churn by Geography
| Region | Customers | Churned | Churn Rate |
|--------|-----------|---------|------------|
| Germany | 2,509 | 814 | **32.44%** |
| Spain | 2,477 | 413 | 16.67% |
| France | 5,014 | 810 | 16.15% |

> ⚠️ Germany's churn rate is **2× the average** — immediate intervention required.

### 3. Churn by Credit Score Segment
| Segment | Customers | Churned | Churn Rate |
|---------|-----------|---------|------------|
| Poor (300–579) | 2,362 | 520 | **22.02%** |
| Fair (580–669) | 3,331 | 685 | 20.56% |
| Very Good (740–799) | 1,224 | 252 | 20.59% |
| Excellent (800–850) | 655 | 128 | 19.54% |
| Good (670–739) | 2,428 | 452 | 18.62% |

> The "Poor" credit score segment has the **highest absolute + relative churn**.

### 4. Products Held by Exited Customers
| Products | Exited Customers |
|----------|-----------------|
| 1 product | 1,409 (69.2%) |
| 2 products | 348 (17.1%) |
| 3 products | 220 (10.8%) |
| 4 products | 60 (2.9%) |

> Customers with **only 1 product are most likely to churn** — cross-selling is key.

### 5. Credit Card Impact on Churn
| Card Status | Customers | Churn Rate |
|-------------|-----------|------------|
| Non-holders | 2,945 | 20.81% |
| Holders | 7,055 | 20.18% |

> Credit card ownership shows **minimal churn difference** (~0.6%) — not a strong retention lever alone.

### 6. Active Members by Region (Tenure > 5 yrs)
| Region | Active Members (Tenure > 5) |
|--------|-----------------------------|
| **France** | 797 |
| Spain | 431 |
| Germany | 399 |

### 7. Gender vs Avg Salary & Active Accounts
| Gender | Avg Salary | Active Members |
|--------|-----------|----------------|
| Female | ₹1,00,601.54 | 1,870 |
| Male | ₹99,664.58 | 2,546 |

> Females earn slightly more on average yet have a significantly higher churn rate.

### 8. Data Discrepancy Found & Fixed
- **735 rows** had `Exited = 1` AND `IsActiveMember = 1` — logically impossible.
- Resolution: `IsActiveMember` was corrected to `0` for all exited customers.
- Original data preserved in `Bank_Churn_backup` table for audit trail.

---

## 🛠️ Technical Architecture

```
Raw CSVs (7 files)
       │
       ▼
  Excel Workbook
  ─ Data consolidation
  ─ Missing value handling
  ─ Helper columns (Age Bucket, Credit Bucket, etc.)
       │
       ▼
  MySQL Database (bank_churn_db)
  ─ Normalized schema (FK constraints)
  ─ Data cleaning queries
  ─ 26+ analytical queries
  ─ Master view: vw_customer_master
       │
       ▼
  Power BI Dashboard
  ─ KPI cards
  ─ Churn analysis visuals
  ─ Geographic & demographic breakdowns
  ─ Slicers for interactivity
       │
       ▼
  PowerPoint Presentation
  ─ Executive storytelling
  ─ Data-backed recommendations
```

---

## 🗃️ SQL Database Schema

```sql
bank_churn_db
├── Gender           (GenderID PK, GenderCategory)
├── Geography        (GeographyID PK, GeographyLocation)
├── CreditCard       (CreditID PK, Category)
├── ActiveCustomer   (ActiveID PK, ActiveCategory)
├── ExitCustomer     (ExitID PK, ExitCategory)
├── CustomerInfo     (CustomerId PK → FK: Gender, Geography)
├── Bank_Churn       (CustomerId PK/FK → FK: CreditCard, ActiveCustomer, ExitCustomer)
├── Bank_Churn_backup (snapshot before IsActiveMember fix)
└── vw_customer_master (denormalized view — all 7 tables joined)
```

---

## 🧹 Data Cleaning Steps

1. **Excel:** Imported all 7 CSVs into a single workbook; created calculated columns (Age Bucket, Credit Score Bucket, CustomerID_Surname, IsActive_Corrected).
2. **SQL:** `TRIM()` applied to `Surname`; duplicate check run on `CustomerId`.
3. **SQL:** 735 discrepant `IsActiveMember` rows corrected (backup preserved).
4. **SQL:** Column renamed: `HasCrCard` → `Has_creditcard` (Q14).

---

## 📑 Questions Answered

### Objective Questions (26)
All 26 objective questions answered with SQL queries, backed by numeric evidence in the Word document, and visualized in Power BI where applicable.

**Highlights:**
- Q2: Top 5 highest-salary customers joining in Q4 2019
- Q7: "Poor" credit score segment has the highest exit rate
- Q11: Customer joining trend — Year-over-year growth peaking in 2019
- Q15: Gender-wise income ranked within each geography
- Q22: `CustomerID_Surname` composite key format via `CONCAT()`
- Q23: `ExitCategory` fetched via correlated subquery — **no JOIN used**
- Q26: Identified and fixed 735-row discrepancy in `IsActiveMember`

### Subjective Questions (14)
Data-backed narrative answers covering:
- Customer behavior & loyalty patterns (S1)
- Product affinity & cross-selling opportunities (S2)
- Geographic market trends & economic indicators (S3)
- Risk management & demographic segmentation (S4)
- Customer tenure value & predictive retention framework (S5)
- Marketing campaign effectiveness proxy analysis (S6)
- Customer exit characteristics & commonalities (S7)
- Predictor feature evaluation (Tenure, Products, Activity, Salary) (S8)
- Multi-dimensional demographic & account segmentation (S9)
- Conditional formatting setup & early warning risk matrix (S10)
- Annual & overall churn trends with strategic roadmap (S11)
- Comprehensive KPI dashboard architecture & slicer design (S12)
- Open-ended analytical CRM methodology (S13)
- Schema evolution & column renaming (S14)

---

## 💡 Recommendations to the Bank

1. **Target German female customers aged 50+ and 31–50** — women aged 50+ in Germany face the highest churn risk (67.03%), while the 31–50 bracket represents the largest absolute balance at risk ($65.43M).
2. **Accelerate cross-selling** to single-product customers — 69% of churners held only 1 product.
3. **Re-engage inactive members** — post-fix, only 4,416 of 10,000 customers are truly active.
4. **Investigate Germany operations** — 32.44% churn vs 16.15% France suggests service/competitive issues.
5. **Design female-targeted retention programs** — loyalty rewards, premium services, or tailored communication.
6. **Monitor Q4 joiners** — highest salary concentration; strategic acquisition period.

---

## 🚀 How to Run This Project

### SQL Setup
```sql
-- 1. Run BankCRM_SQL.sql in MySQL Workbench (v8.0+)
-- 2. Update LOAD DATA paths to your local CSV location
-- 3. Run Part A → B → C → D → E in order
-- 4. Part E renames HasCrCard — run LAST
```

### Power BI
```
1. Open BankCRM_POWERBI.pbix in Power BI Desktop
2. If prompted, update data source to local Excel/MySQL
3. Refresh to load latest data
```

### Excel
```
Open BankCRM_EXCEL.xlsx — contains:
- Raw consolidated data sheet
- Cleaned data with helper columns
- Pivot summary tables
```

---

## 📁 Credit Score Legend

| Score Range | Category |
|------------|----------|
| 800 – 850 | Excellent |
| 740 – 799 | Very Good |
| 670 – 739 | Good |
| 580 – 669 | Fair |
| 300 – 579 | Poor |

---

## 👤 Author

**Vivek Ajay Patil**  
Data Analytics · SQL · Power BI · Excel  

---

*This project was developed as a Capstone for an Analytical CRM module, demonstrating end-to-end data analytics skills across SQL, Excel, Power BI, and business storytelling.*
