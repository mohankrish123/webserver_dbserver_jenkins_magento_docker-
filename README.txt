DB backups:
- Backups have to be taken from Production servers.

Post build actions:
Using publish over SSH:
- Connect to the VM. (Configure VM)
- Run DB command.
- Place it in a different server.

Steps:
1. Done ssh trusting to the VM.
2. Configured the VM in System configuration.
3. Given Jenkins Private key in the system configuration.
4. Pipeline to take the db backup and copy it to the required server.

pipeline {
    agent any
        stages {
            stage ("Taking DB Backup") {
                steps {
                sshagent(['d3e4a8c2-6473-4398-8866-446bb9cf5cd9']) {
                sh """
                ssh -o StrictHostKeyChecking=no pavan@192.168.8.39 "mysqldump -h localhost --user=magento --password=magento --single-transaction --skip-triggers magento | gzip | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\\*/\\*/' > /tmp/magento_2020_May_27.sql.gz"
                scp -o StrictHostKeyChecking=no pavan@192.168.8.39:/tmp/magento_2020_May_27.sql.gz mohankrishna@192.168.10.95:/tmp
                 """
                }
                }               
            }
        }
   
}

Note: Wherever we have \, use \\ instead of that.


CODE BACKUP:
1. Made docker connection with the remote host using extra_hosts in docker compose file.
2. Successfully established of remote server's mysql connection by changing the my.cnf file (bind address: 0.0.0.0) and created db user with permissions to the docker host server. (Note: not the docker container ip address). 
3. Integrated the git repository with the docker mount. Added the pub key with git. 
4. Changed the .git permission to user given in Jenkins. (eg: pavanj)
5. Changed the web server user as magento inside the docker container as magento is the main user with ID 1000. (Use version 4.0 image).
6. Add magento credentials to auth.json.
7. Changed the PHP user&group, sock. Changed user for nginx as well.
8. Change the db URL to https. (When using Traefik)
8. Traefik 
URL: https://www.digitalocean.com/community/tutorials/how-to-use-traefik-as-a-reverse-proxy-for-docker-containers-on-ubuntu-16-04

Traefik Errors:
- Take Traefik version 1.7.14
- 404 Error - This is because of the Docker version is not compatible. We need Version 3.
- Too many redirects: Change the URLs to https from http

FREESTYLE:

cd /home/pavanj/jenkins/magento225/magento225/magento2/ && git pull origin master && docker exec magento225 bash -c "cd /var/www/html/magento2/ && composer install" && docker exec magento225 bash -c "php /var/www/html/magento2/bin/magento setup:upgrade" && docker exec magento225 bash -c "php /var/www/html/magento2/bin/magento setup:static-content:deploy -f" && docker exec magento225 bash -c "php /var/www/html/magento2/bin/magento c:c" && docker exec magento225 bash -c "php /var/www/html/magento2/bin/magento c:f" 

docker exec magento225 bash -c "service nginx restart" &&  docker exec magento225 bash -c "service php7.1-fpm restart"  && docker exec magento225 bash -c "service mysql restart"  && docker exec magento225 bash -c "cd /var/www/html/magento2/ && chmod -R 777 app/ pub/ var/ && chown -R magento:magento /var/www/html/magento2/" && docker exec magento225 bash -c "php /var/www/html/magento2/bin/magento c:c" && docker exec magento225 bash -c "php /var/www/html/magento2/bin/magento c:f"  

PIPELINE:

pipeline {
  agent any
    stages {
        stage("cloning git repository") {
            steps {
                sshagent(['65af345b-2393-45a2-94e9-927dfe8330d1']) {
                sh """
                ssh -o StrictHostKeyChecking=no -p 2256 pavanj@192.168.8.205 "cd /home/pavanj/jenkins/magento225/magento225/magento2/ && git pull origin master"
                """
                }
              }
            }
            stage ("Composer Install") {
             steps {
                sshagent(['65af345b-2393-45a2-94e9-927dfe8330d1']) {
                sh """
                ssh -o StrictHostKeyChecking=no -p 2256 pavanj@192.168.8.205 "docker exec magento225 bash -c 'cd /var/www/html/magento2/ && composer install'"
                """
                }
             }
         }
        
         stage ("setup:upgrade && static-content:deploy") {
             steps {
                sshagent(['65af345b-2393-45a2-94e9-927dfe8330d1']) {
                sh """
                ssh -o StrictHostKeyChecking=no -p 2256 pavanj@192.168.8.205 "docker exec magento225 bash -c 'php /var/www/html/magento2/bin/magento setup:upgrade'"
                ssh -o StrictHostKeyChecking=no -p 2256 pavanj@192.168.8.205 "docker exec magento225 bash -c 'php /var/www/html/magento2/bin/magento setup:static-content:deploy -f'"
                """
                }
             }
         }
         stage ("Permissions") {
             steps {
                sshagent(['65af345b-2393-45a2-94e9-927dfe8330d1']) {
                sh """
                ssh -o StrictHostKeyChecking=no -p 2256 pavanj@192.168.8.205 "docker exec magento225 bash -c 'cd /var/www/html/magento2/ && chmod -R 777 app/ pub/ var/ generated/ && chown -R magento:magento /var/www/html/magento2/'"
                """
                }
             }
         }
         stage ("Restarting Services") {
             steps {
                sshagent(['65af345b-2393-45a2-94e9-927dfe8330d1']) {
                sh """
                ssh -o StrictHostKeyChecking=no -p 2256 pavanj@192.168.8.205 "docker exec magento225 bash -c 'service nginx restart'"
                ssh -o StrictHostKeyChecking=no -p 2256 pavanj@192.168.8.205 "docker exec magento225 bash -c 'service php7.1-fpm restart'"
                ssh -o StrictHostKeyChecking=no -p 2256 pavanj@192.168.8.205 "docker exec magento225 bash -c 'service nginx restart'"
                """
                }
             }
         }
         stage("Cache clean and flush") {
            steps {
                 sshagent(['65af345b-2393-45a2-94e9-927dfe8330d1']) {
                sh """
                ssh -o StrictHostKeyChecking=no -p 2256 pavanj@192.168.8.205 "docker exec magento225 bash -c 'php /var/www/html/magento2/bin/magento c:c'"
                ssh -o StrictHostKeyChecking=no -p 2256 pavanj@192.168.8.205 "docker exec magento225 bash -c 'php /var/www/html/magento2/bin/magento c:f'"
                """
                }
            }
         }
        
        }
     }

Finally, the worked image version is 7.0.

In docker container,
DB password: magento123
USER and DB: magento

In centralized mysql database,
DB paasword: dbbackup
USER and DB: dbbackup
