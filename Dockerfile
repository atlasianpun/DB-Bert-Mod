FROM ubuntu:20.04

# Set non-interactive mode for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
        python3.9 \
        python3-pip \
        postgresql-12 \
        mysql-server-8.0 \
        libpq-dev \
        sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a user named 'dbbert' with password 'dbbert'
RUN useradd -m -s /bin/bash dbbert && \
    echo "dbbert:dbbert" | chpasswd && \
    adduser dbbert sudo

# Switch to the 'dbbert' user
USER dbbert
WORKDIR /home/dbbert

# Copy DB-BERT source code and data files
COPY --chown=dbbert:dbbert . .
COPY --chown=dbbert:dbbert tpchdata /home/dbbert/scripts/tpchdata
COPY --chown=dbbert:dbbert jobdata /home/dbbert/scripts/jobdata

# Make scripts executable
RUN chmod +x /home/dbbert/scripts/installtpch.sh /home/dbbert/scripts/installjob.sh

# Install Python dependencies
RUN pip3 install --user -r requirements.txt
RUN pip3 install --user protobuf==3.20.*

# Add local bin to PATH
ENV PATH="/home/dbbert/.local/bin:${PATH}"
ENV PYTHONPATH="${PYTHONPATH}:/home/dbbert/src"

# Temporarily switch to root to set up databases
USER root

# Copy custom MySQL configuration without "skip-grant-tables"
COPY my.cnf /etc/mysql/my.cnf

# Start MySQL and initialize root user without "skip-grant-tables"
RUN service mysql start && \
    until mysqladmin ping --silent; do echo 'Waiting for MySQL...'; sleep 2; done && \
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'rootpassword'; FLUSH PRIVILEGES;" && \
    service mysql stop

# Start PostgreSQL and MySQL services, create users, and run installation scripts
RUN service postgresql start && \
    sudo -u postgres psql -c "CREATE USER dbbert WITH SUPERUSER PASSWORD 'dbbert';" && \
    service mysql start && \
    sleep 10 && \
    mysql -u root -prootpassword -e "CREATE USER 'dbbert'@'localhost' IDENTIFIED BY 'dbbert'; GRANT ALL PRIVILEGES ON *.* TO 'dbbert'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;" && \
    chmod 777 /var/lib/mysql-files && \
    chmod 777 /var/run/mysqld && \
    su - dbbert -c "/home/dbbert/scripts/installtpch.sh" && \
    su - dbbert -c "/home/dbbert/scripts/installjob.sh"

# Switch back to dbbert user for running application
USER dbbert

# Expose port for Streamlit GUI
EXPOSE 8501

# Set entrypoint to start Streamlit
ENTRYPOINT ["streamlit", "run", "src/run/interface.py"]