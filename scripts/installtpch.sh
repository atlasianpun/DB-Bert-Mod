echo "Using local data files for TPC-H benchmark ..."

# Navigate to the folder where the TPC-H data files are stored (assuming /home/dbbert/dbbert/data/tpchdata/)
cd /home/dbbert/scripts/tpchdata

echo "Installing TPC-H on PostgreSQL ..."
sudo -u dbbert createdb tpch

echo "Creating database schema in PostgreSQL ..."
sudo -u dbbert psql -f schema.sql tpch

echo "Loading data into PostgreSQL ..."
sudo -u dbbert psql -f loadpg.sql tpch

echo "Indexing data in PostgreSQL ..."
sudo -u dbbert psql -f index.sql tpch

echo "Installing TPC-H on MySQL ..."
echo "Copying data files to MySQL data directory ..."
cp *.tsv /var/lib/mysql-files

echo "Creating database schema in MySQL ..."
mysql -u dbbert -pdbbert -e "create database tpch;"

echo "Applying schema in MySQL ..."
mysql -u dbbert -pdbbert tpch < schema.sql

echo "Loading data into MySQL ..."
mysql -u dbbert -pdbbert tpch < loadms.sql

echo "Indexing data in MySQL ..."
mysql -u dbbert -pdbbert tpch < index.sql