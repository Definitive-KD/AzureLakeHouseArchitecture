# Lake House Architecture with Azure

## Problem Statement

This project demonstrates the implementation of a Lake House Architecture using various Azure services. The primary goal is to move data from an on-premise SQL Server database to Azure Data Lake Storage Gen2, perform transformations using Azure Databricks, and visualize the data using Power BI. The project also sports the automation of the ETL pipeline and Successfully passes the testing. 


## Project Plan, Approach, and Objective

- Objective

The primary goal of this project is to implement a robust data pipeline using Azure services, following the Lake House Architecture. This architecture will facilitate seamless data ingestion, transformation, and visualization, providing a scalable solution for big data analytics and business intelligence. 


- Project Plan

        1. Setup On-Premise SQL Server Database
        2. Ingest Data to Azure Data Lake Storage Gen2 using Azure Data Factory
        3. Transform Data in Azure Databricks
        4. Load Transformed Data to Azure Synapse Analytics
        5. Visualize Data using Power BI
        6. Automate Pipelines and Ensure End-to-End Data Flow

- Approach

        Data Ingestion: Use Azure Data Factory to copy data from an on-premise SQL Server database to Azure Data Lake Storage Gen2 (Bronze Layer).
        Data Transformation: Utilize Azure Databricks for transforming and cleansing data, moving it from the Bronze to Silver and then to the Gold Layer.
        Data Analytics: Use Azure Synapse Analytics to create views and queries for data analysis.
        Data Visualization: Integrate Power BI with Azure Synapse Analytics for real-time data visualization.
        Automation and Monitoring: Automate data pipelines and set up triggers to ensure continuous data flow and synchronization.



- Tools and Services Used

        1. Azure Data Factory: Orchestrates data movement and transformation.
        2. Azure Data Lake Storage Gen2: Stores raw and transformed data.
        3. Azure Databricks: Performs data transformation and big data analytics.
        4. Azure Synapse Analytics: Provides advanced data analytics and SQL capabilities.
        5. Azure Key Vault: Secures sensitive information such as passwords and secrets.
        6. Azure Active Directory (AAD): Manages identities and access control.
        7. Microsoft Power BI: Visualizes data and provides business intelligence.


## Project Steps

Step 1: Setup On-Premise SQL Server

Prepare the on-premise SQL Server database for data extraction
- Restore Backup and Create Login:

        create Login ks with password = 'Migrationproject#login';
        create user ks for login ks;

- Configuration Checks:

        Ensure SQL Server and Windows Authentication are enabled.
        Ensure port 1433 allows inbound connections.
        Assign the data reader role to the user.




![image](https://github.com/Definitive-KD/AzureLakeHouseArchitecture/assets/54216704/10d9b5d3-405e-4682-bb1f-f0a898fdaeb8)


Step 2: Azure Key Vault Configuration

Securely store and manage sensitive information required for data access and transfer.
- Assign Access to IAM:

        Assign the user necessary access for creating secrets in Key Vault.
        Ensure the Azure AD user account has the "Key Vault Administrator" or "Key Vault Secrets Operator" role.




- Create Secrets:

        Create secrets for the username and password in Azure Key Vault.


Step 3: Azure Data Factory Configuration

Use Azure Data Factory (ADF) to copy data from the on-premise SQL Server to Azure Data Lake Storage Gen2.

- Install Self-Hosted Integration Runtime (SHIR):

        Install SHIR on the machine hosting the Azure SQL Server database.
        Under Data Factory > Manage > Integration Runtimes, create a new "Azure Self-Hosted" runtime.


![image](https://github.com/Definitive-KD/AzureLakeHouseArchitecture/assets/54216704/900f1dee-82a6-4bb4-b5ea-e471c579b3ae)




- Create Data Pipeline:

        Author a pipeline with a copy data activity to ingest data from on-premise SQL Server to Azure Data Lake Gen2 (Bronze Layer).
        Configure linked services and set up secrets from Azure Key Vault.


![image](https://github.com/Definitive-KD/AzureLakeHouseArchitecture/assets/54216704/cf8076f5-9d58-428c-bc1a-cfb9949b440d)



Step 4: Configure Azure Data Lake Storage Gen2

Mount the Azure Data Lake in Azure Databricks to access and process data.

- Mount Data Lake in Azure Databricks:

        storage_account_name = "dataMigrationKS"
        storage_account_access_key = "<your_storage_account_access_key>"

        configs = {
        "fs.azure.account.auth.type.migrationstorageks.dfs.core.windows.net": "OAuth",
        "fs.azure.account.oauth.provider.type.migrationstorageks.dfs.core.windows.net": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
        "fs.azure.account.oauth2.client.id.migrationstorageks.dfs.core.windows.net": "<your_client_id>",
        "fs.azure.account.oauth2.client.secret.migrationstorageks.dfs.core.windows.net": "<your_client_secret>",
        "fs.azure.account.oauth2.client.endpoint.migrationstorageks.dfs.core.windows.net": "https://login.microsoftonline.com/<your_tenant_id>/oauth2/token"
        }

        for k, v in configs.items():
        spark.conf.set(k, v)

        spark.conf.set(
        f"fs.azure.account.key.{storage_account_name}.dfs.core.windows.net",
        storage_account_access_key
        )



Step 5: Data Transformation in Azure Databricks

Transform and cleanse data, moving it through the Bronze, Silver, and Gold layers.

- Transform Data from Bronze to Silver Layer:

        from pyspark.sql.functions import from_utc_timestamp, date_format
        from pyspark.sql.types import TimestampType

        for i in table_name:
        path = bronzePath + i + '/' + i + '.parquet'
        df = spark.read.format('parquet').load(path)
        column = df.columns

        for col in column:
                if "Date" in col or "date" in col:
                df = df.withColumn(col, date_format(from_utc_timestamp(df[col].cast(TimestampType()), "UTC"), "yyyy-MM-dd"))
        
        output_path = silverPath + i + '/'
        df.write.format('delta').mode("overwrite").save(output_path)


- Transform Data from Silver to Gold Layer:

        for name in table_name:
        path = silverPath + name
        df = spark.read.format('delta').load(path)

        column_names = df.columns

        for old_col_name in column_names:
                new_col_name = "".join(["_" + char if char.isupper() and not old_col_name[i-1].isupper() else char for i, char in enumerate(old_col_name)]).lstrip("_")
                df = df.withColumnRenamed(old_col_name, new_col_name)
        
        output_path = goldPath + name + '/'
        df.write.format('delta').mode("overwrite").save(output_path)



![image](https://github.com/Definitive-KD/AzureLakeHouseArchitecture/assets/54216704/63c575b3-03e7-45b4-a2f1-979e7fd9b05d)



Step 6: Configure Azure Synapse Analytics

Load transformed data into Azure Synapse Analytics for advanced analytics and SQL querying
- Create a Serverless SQL Database.

- Create a Stored Procedure to Dynamically Create Views:

        USE gold_db
        GO

        CREATE OR ALTER PROC CreateSQLServerlessView_gold 
        @ViewName nvarchar(100)
        AS
        BEGIN
        DECLARE @statement VARCHAR(MAX)
        SET @statement = N'CREATE OR ALTER VIEW ' + @ViewName + ' AS
                SELECT *
                FROM
                OPENROWSET(
                BULK ''https://migrationstorageks.dfs.core.windows.net/gold/SalesLT/' + @ViewName + '/'',
                FORMAT = ''DELTA''
                ) as [result]'
        EXEC (@statement)
        END
        GO



![image](https://github.com/Definitive-KD/AzureLakeHouseArchitecture/assets/54216704/24300f42-d62b-478f-8751-198c21d5265e)



Step 7: Integrate with Power BI

Visualize data using Power BI, providing business intelligence and insights.

- Connect Power BI to Azure Synapse Analytics:

        Use the serverless SQL endpoint from Synapse Workspace properties.
        Load the data and design the Power BI dashboard as per the required KPIs.


![image](https://github.com/Definitive-KD/AzureLakeHouseArchitecture/assets/54216704/615977ac-6e05-4098-8c02-509905d8ad0d)

### Dashboard Link : https://app.powerbi.com/groups/me/reports/1dc83904-a082-4f2d-8b3b-d160c7b66ed4/54deb341271d941e4291?experience=power-bi


Step 8: End-to-End Testing

Ensure the entire pipeline is automated and functioning correctly.

- Automate Pipelines in Azure Data Factory:

        Configure a scheduled trigger to automate data ingestion and transformation.


![image](https://github.com/Definitive-KD/AzureLakeHouseArchitecture/assets/54216704/6f4b61fe-fe7c-451b-9a78-3598c219ee6e)




- Update Data and Verify:

        Insert new data into the SQL Server database.
        Verify the updated data in Power BI to ensure the pipeline runs successfully.


![image](https://github.com/Definitive-KD/AzureLakeHouseArchitecture/assets/54216704/afac6e46-a5f1-4c29-bcb9-de9e4d47d214)

