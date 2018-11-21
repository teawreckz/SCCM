Unzip latest stable InfluxDB to location of your choosing
Set up service for InfluxDB with NSSM
Create database and user
Go to install location and start influx.exe from cmd/PS
Create Database/user (be more secure than this :) ):
create database SCCM
create user "SCCM" with Password '1234'
grant all on SCCM to SCCM
Unzip/install latest stable Telegraf to location of your choosing
Install instructions here
Edit telegraf.conf to point to correct server/database


Unzip/install latest stable Grafana to location of your choosing
Install instructions here
Create data source (configure for your InfluxDB instance)
Create your first Dashboard or import one
Recommend this one for performance counters



MSSQL server monitoring
Follow these instructions
But make sure!!
query_version = 1
In your telegraf.conf file
Import Grafana.com dashboard no: 409 
