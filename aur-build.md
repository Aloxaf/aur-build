Requirements
------------

### VPS

For example, ArchLinux VPS

    ssh root@your_vps
    pacman -S nginx
    mkdir /usr/share/nginx/html/repo
    mkdir /usr/share/nginx/html/script

### SSH secret key

Create a ssh key and update it to VPS

    ssh-keygen -t ed25519 -f ~/.ssh/vps
    # show the content of vps.pub
    cat ~/.ssh/vps.pub
    ssh root@your_vps
    vim ~/.ssh/hugo_authorized
    # input the content of ~/.ssh/vps.pub

### GPG key

#### Generate

    ssh root@your_vps
    gpg --full-gen-key
    
    # Output is following. All settings are default.
    
    gpg (GnuPG) 2.2.28; Copyright (C) 2021 Free Software Foundation, Inc.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.
    
    Please select what kind of key you want:
       (1) RSA and RSA (default)
       (2) DSA and Elgamal
       (3) DSA (sign only)
       (4) RSA (sign only)
      (14) Existing key from card
    Your selection? 
    RSA keys may be between 1024 and 4096 bits long.
    What keysize do you want? (3072) 
    Requested keysize is 3072 bits
    Please specify how long the key should be valid.
             0 = key does not expire
          <n>  = key expires in n days
          <n>w = key expires in n weeks
          <n>m = key expires in n months
          <n>y = key expires in n years
    Key is valid for? (0) 
    Key does not expire at all
    Is this correct? (y/N) y
    
    GnuPG needs to construct a user ID to identify your key.
    
    Real name: 
    Email address: 
    Comment: 
    You selected this USER-ID:
        " "
    
    Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
    We need to generate a lot of random bytes. It is a good idea to perform
    some other action (type on the keyboard, move the mouse, utilize the
    disks) during the prime generation; this gives the random number
    generator a better chance to gain enough entropy.
    We need to generate a lot of random bytes. It is a good idea to perform
    some other action (type on the keyboard, move the mouse, utilize the
    disks) during the prime generation; this gives the random number
    generator a better chance to gain enough entropy.

Then you can get your GPG key ID after `gpg: key YOUR_GPG_KEY_ID marked as ultimately trusted`.

#### Subkey

And you also need a subkey of your GPG key.

    gpg --edit-key YOUR_GPG_KEY_ID
    
    # Output is following. All settings are default.
                                   
    gpg (GnuPG) 2.2.28; Copyright (C) 2021 Free Software Foundation, Inc.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.
    
    Secret key is available.
    
    gpg: checking the trustdb
    gpg: marginals needed: 3  completes needed: 1  trust model: pgp
    gpg: depth: 0  valid:   2  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 2u
    gpg: next trustdb check due at 2023-07-14
    sec  rsa3072/XXXXXXX
         created: 2021-07-14  expires: never       usage: SC  
         trust: ultimate      validity: ultimate
    ssb  rsa3072/XXXXXXX
         created: 2021-07-14  expires: never       usage: E   
    [ultimate] (1).  < >
    
    # Inptut command, the settings are custom.
    
    gpg> addkey
    Please select what kind of key you want:
       (3) DSA (sign only)
       (4) RSA (sign only)
       (5) Elgamal (encrypt only)
       (6) RSA (encrypt only)
      (14) Existing key from card
    Your selection? 5
    ELG keys may be between 1024 and 4096 bits long.
    What keysize do you want? (3072) 
    Requested keysize is 3072 bits
    Please specify how long the key should be valid.
             0 = key does not expire
          <n>  = key expires in n days
          <n>w = key expires in n weeks
          <n>m = key expires in n months
          <n>y = key expires in n years
    Key is valid for? (0) 6y
    Key expires at Tue 13 Jul 2027 16:54:27 CST
    Is this correct? (y/N) y
    Really create? (y/N) y
    We need to generate a lot of random bytes. It is a good idea to perform
    some other action (type on the keyboard, move the mouse, utilize the
    disks) during the prime generation; this gives the random number
    generator a better chance to gain enough entropy.
    
    sec  rsa3072/XXXXXXX
         created: 2021-07-14  expires: never       usage: SC  
         trust: ultimate      validity: ultimate
    ssb  rsa3072/XXXXXXX
         created: 2021-07-14  expires: never       usage: E   
    ssb  elg3072/XXXXXXX
         created: 2021-07-14  expires: 2027-07-13  usage: E   
    [ultimate] (1).  < >

#### Upload your GPG Key

    gpg --keyserver hkp://keyserver.ubuntu.com --send-keys YOUR_GPG_KEY_ID

### GitHub Repository

You can directly fork the aur-build repository and change it.

Configure
---------

### Keys

    cd
    git clone git@github.com:YOUR_USERNAME/YOUR_REPOSITORY.git
    cd YOUR_REPOSITORY
    mkdir script/data
    gpg --export-secret-subkeys YOUR_GPG_KEY_ID > ~/YOUR_REPOSITORY/script/data/private.key
    # Then you will be asked to input the password used to create your GPG key. This password will be called YOUR_GPG_KEY_PASSPHRASE
    echo -n 'YOUR_GPG_KEY_PASSPHRASE' > ~/YOUR_REPOSITORY/script/data/private.passphrase
    cp ~/.ssh/vps ~/YOUR_REPOSITORY/script/data/deploy_key
    cd ~/.ssh/vps ~/YOUR_REPOSITORY/script/data/
    chmod 600 deploy_key

### script.conf

    mv ~/YOUR_REPOSITORY/script/script.conf.sample ~/YOUR_REPOSITORY/script/script.conf

Use your edit software to modify it, such as vim or nano.

#### Essential Change

You must modify the following settings.

*   `GPGKEY` : Replace it with your GPG key.
*   `SERVER` : the dir you want to save the repo, for example, I have created a dir called repo under `/usr/share/nginx/html`, so you can input `root@YOUR_DOMAIN:/usr/share/nginx/html/repo`.
*   `SCRIPT` : the dir you update your script.zip,  for example, I have created a dir called script under `/usr/share/nginx/html`, so you can input `root@YOUR_DOMAIN:/usr/share/nginx/html/script/scr.7z`.

#### Recommended Change

You'd better to change the following settings.

*   `REPO_NAME` : The name will be present in \[REPO\_NAME\] server = xxxx .
*   `PACKAGER` : your name.
*   `PASSWORD` : Your password for the zip file.

#### Others

Other settings can be default.

### GitHub Actions Secret

Point out your repository page. `Settings` > `Secrets` > `New Repository Secret`. You need two secrets.

*   `SCRIPT_URL` : Your scr.zip download URL which is configured in script.conf, if you follow this guide, you should input `YOUR_DOMAIN/script/scr.7z`.
*   `PASSWORD` : It is configured in script.conf.

### Your Packages

#### AUR

Just make a dir under `~/YOUR_REPOSITORY/script/packages/`, and mv a empty `.gitignore` into this dir. But the dir name must be the same as the packages in the AUR.

#### PKGBUILD

Also, you can give a PKGBUILD into the created dir, just like what AUR does.

#### build.zsh

build.zsh shell script is also supported, but you need to make a dir and mv the zsh script into it.

Test
----

### Run upload\_script.zsh

    cd ~/YOUR_REPOSITORY/script/
    chmod +x upload_script.zsh
    ./upload_script.zsh

### Git

    cd ~/YOUR_REPOSITORY/
    git add .
    git commit -m "WHAT YOU WANT TO COMMIT"
    git push

This step is just to create a GitHub Action.

Repository
----------

### Nginx

When all the things are finished, you can configure Nginx to make your repository work.

Change the `/etc/nginx/nginx.conf`, add the following word to http module.

    http {
        # Add the follwing to http
        include       sites-enabled/*.conf;
        # Finished
    }

Then you need to mkdir and input configure script

    cd /etc/nginx
    mkdir sites-enabled
    cd sites-enabled
    vim www.conf

And add the following to www.conf

    server {
        listen 80;
        server_name YOUR_DOMAIN; # CHANGE IT
        return 301 https://$host$request_uri;
    }
    server {
        listen 443 ssl http2;
        server_name malacology.net;
        ssl_certificate /etc/nginx/web_ssl/net_bundle.crt; # CHANGE IT, the location of your crt file for SSL
        ssl_certificate_key /etc/nginx/web_ssl/net.key; # CHANGE IT, the location of your key file for SSL
        ssl_session_cache builtin:1000 shared:SSL:10m;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
        ssl_prefer_server_ciphers on;
        access_log /var/log/nginx/access.log;
        
      # If your root dir is not /usr/share/nginx/html, change it
      
         location / {
                root   /usr/share/nginx/html;
                index  index.html index.htm;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
    	    
         }    
         
        # repo is the subdir you want to store your ArchLinux repository, if you don't want to use dir under root dir to store them, delete the follwing module. But you nned add the conent to the previous location module.
        
            location /repo/ { 
                    autoindex on;
                    autoindex_exact_size off;
                    autoindex_localtime on;
                    root /usr/share/nginx/html;
            }  
    }

Final, you need to test nginx configure due to the version change and make it work.

    nginx -t
    systemctl enable nginx
    systemctl restart nginx

### pacman

    vim /etc/pacman.conf

Add the following to it

    [REPO_NAME]
    Server = https://YOUR_DOMAIN/repo 
    # If you use x86_64 or any other classification, use $arch or other $name to the URL. If you follow this guide, don't add other symbol, just change the REPO_NAME and YOUR_DOMAIN

Import your GPG key

    sudo pacman-key --recv-keys YOUR_GPG_KEY_ID --keyserver hkp://keyserver.ubuntu.com
    sudo pacman-key --lsign-key YOUR_GPG_KEY_ID
