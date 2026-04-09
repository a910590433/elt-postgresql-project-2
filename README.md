
### **ELT Pipeline: Foreign Spouse in Taiwan**
This project builds an end-to-end ELT pipeline to process and analyze marriage data from Taiwan's government open datasets. It extracts raw CSV data, loads it into a PostgreSQL database, and performs transformations to enable structured analysis of foreign spouse trends in Taiwan. 

#### **Tools**
- Programming Language: Python, SQL
- Data Manipulation: pandas
- Database: PostgreSQL
- Database connection: SQLAlchemy
- Development Environment: PostgreSQL, Visual Studio Code, Jupyter Notebook
- Data Sources: [Taiwan government open datasets](https://data.gov.tw/dataset/13503)

#### **Pipeline**
1. **Extract**: Load raw CSV datasets from local storage
2. **Load**: Store the untransformed data into PostgreSQL
3. **Clean & Transform using SQL (staging layer)**:
   - Split columns using delimiters
   - Remove aggregate (total) rows
   - Reorder columns
   - Replace missing values '-' with NULL
   - Convert data types (text → integer)
   - Unpivot wide-format data into long format
4. **Key Features**:
- Designed using a staging → dimension → fact table architecture
- Implements data cleaning best practices in SQL
- Uses unpivoting techniques to normalize wide datasets
- Optimized with indexes and constraints (PK/FK) for query performance
- Structured for future dashboard integration (e.g., Power BI)

#### **How to Run / Setup**
1. Clone the repository
```bash
git clone https://github.com/a910590433/elt-postgresql-project-2.git
cd elt-postgresql-project-2
```
2. Install dependencies
```bash
pip install pandas sqlalchemy psycopg2
```
3. Set up PostgreSQL
- Create a database (e.g., twmarriage)
- Update your connection settings in the script:
```python
user = "your_username"
password = "your_password"
host = "localhost"
port = "5432"
database = "twmarriage"
engine = create_engine(
    f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database}"
)
```
4. Run the ETL script
- Execute the Python script to load data in PostgreSQL database
- Run SQL scripts to transform and model the data


