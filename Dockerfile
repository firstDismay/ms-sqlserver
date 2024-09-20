# Maintainers: Microsoft Corporation 
FROM ubuntu:22.04

# copy in supervisord conf file
COPY ./supervisord.conf /usr/local/etc/supervisord.conf

ENV PATH=$PATH:/usr/bin

# install supporting packages
RUN apt-get update && \
    apt-get install -y apt-transport-https \
                       curl \
                       supervisor \
                       fakechroot \
                       locales \
                       iptables \
                       sudo \
                       wget \
                       curl \
                       zip \
                       unzip \
                       make \ 
                       bzip2 \ 
                       m4 \
                       apt-transport-https \
                       tzdata \
                       libnuma-dev \
                       libssl-dev \
                       libsss-nss-idmap-dev \
                       software-properties-common

# Adding custom MS repository
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list > /etc/apt/sources.list.d/mssql-server-2022.list

# install SQL Server ML services R and Python packages which will also install the mssql-server pacakge, the package for SQL Server itself
# if you want to install only Python or only R, you can add/remove the package as needed below
RUN apt-get update && \
    apt-get install -y mssql-server-extensibility
    #apt install -y mssql-server-configuration mssql-tools && \
    # Настройка экземпляра SQL Server
    #mssql-conf set default-backup-dir /backup

# update repositories
RUN apt-get update && \
    apt-get upgrade -y

# setting python3.10 as default install dependens    
RUN apt-get install -y python3-pip && \
    pip3 install --upgrade pip && \
    pip3 install dill numpy==1.22.0 pandas patsy python-dateutil openpyxl && \
    mkdir -p /usr/lib/python3.10/dist-packages && \
    pip install https://aka.ms/sqlml/python3.10/linux/revoscalepy-10.0.1-py3-none-any.whl --target=/usr/lib/python3.10/dist-packages

RUN /opt/mssql/bin/mssql-conf set extensibility pythonbinpath /usr/bin/python3.10 && \
    /opt/mssql/bin/mssql-conf set extensibility datadirectories /usr/lib:/usr/lib/python3.10/dist-packages    

# run checkinstallextensibility.sh
RUN /opt/mssql/bin/checkinstallextensibility.sh && \
    # set/fix directory permissions and create default directories
    chown -R root:root /opt/mssql/bin/launchpadd && \
    chown -R root:root /opt/mssql/bin/setnetbr && \
    mkdir -p /var/opt/mssql-extensibility/data && \
    mkdir -p /var/opt/mssql-extensibility/log && \
    chown -R root:root /var/opt/mssql-extensibility && \
    chmod -R 777 /var/opt/mssql-extensibility && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    # locale-gen
    locale-gen ru_RU.UTF-8 && \
    locale-gen en_US.UTF-8 



# Cleanup the Dockerfile
RUN apt-get clean && \
rm -rf /var/apt/cache/* /tmp/* /var/tmp/* /var/lib/apt/lists    


# expose SQL Server port
EXPOSE 1433

# start services with supervisord
CMD /usr/bin/supervisord -n -c /usr/local/etc/supervisord.conf
