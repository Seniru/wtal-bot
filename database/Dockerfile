FROM mysql:5.7

WORKDIR /database

ADD *.sql /docker-entrypoint-initdb.d/
ADD /run-til-midnight.sh /
RUN chmod +x /run-til-midnight.sh

EXPOSE 3306
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/run-til-midnight.sh", "mysqld"]
