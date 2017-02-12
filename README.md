# dockerstead
Homestead like environment for Docker

**Default Softwares Installed**

    Ubuntu 16.04
    Git
    PHP 7.1
    Nginx 1.11.8
    MySQL 5.7.17
    Sqlite3 3.11.0
    Composer
    Node (With Yarn, web pack, Bower, and Gulp)
    Redis
    Memcached
    Beanstalkd

**Steps to setup the docker environment**

    1. git clone https://github.com/majuansari/dockerstead.git
    2. cd dockerstead
    3. Edit docker-compose.yml file and configure your project path under volumes
    4. To bootup the docker env run - docker-compose up -d
    5. To ssh into the server run - docker-compose exec homestead bash


> http://app.dev:8000  is the default url to run the site

Open your `/etc/hosts` file and map your localhost address `127.0.0.1` to the `app.dev` domain, by adding the following:

```bash
127.0.0.1    app.dev
```
If you prefer a different domain name, you can configure that within nginx configuration

**Default db config**

    username: homestead
    password: secret
