#!/bin/bash
service mysql start
service nginx start
service php7.1-fpm start
while true; do sleep 1d; done
