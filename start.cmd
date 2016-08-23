docker rm -f domain
docker run -p80:80 -p222:22 -v helpavol:/data -v /user/local_drive:/data/sites/domain/public_html --name domain domain/v1
