echo "Using local data files for JOB benchmark ..."

# Navigate to the folder where the data files are stored (assuming /home/dbbert/dbbert/data/jobdata/)
cd /home/dbbert/scripts/jobdata

echo "Creating JOB database in PostgreSQL ..."
sudo -u dbbert createdb job

echo "Creating database schema in PostgreSQL ..."
sudo -u dbbert psql -f schema.sql job

echo "Loading data into PostgreSQL ..."
sudo -u dbbert psql -f loadpg.sql job

echo "Indexing data in PostgreSQL ..."
sudo -u dbbert psql -f fkindexes.sql job

echo "Creating JOB database in MySQL ..."
echo "Copying data files to MySQL data directory ..."
cp *.tsv /var/lib/mysql-files

echo "Creating database schema in MySQL ..."
mysql -u dbbert -pdbbert -e "create database job;"

echo "Applying schema in MySQL ..."
mysql -u dbbert -pdbbert -D job < schema.sql

echo "Loading data into MySQL ..."
mysql -u dbbert -pdbbert -D job < loadms.sql

echo "Indexing data in MySQL ..."
mysql -u dbbert -pdbbert -D job < fkindexes.sql