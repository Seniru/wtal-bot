FROM mysql:5.7

WORKDIR /database

ADD *.sql /docker-entrypoint-initdb.d/

EXPOSE 3306
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mysqld"]
