# loglibrary

![logo](docs/assets/logo.png)

## The online AI reference library

Our goal is to help you find what you need and let you learn at your own pace.

## Local Development    

```bash
./start_local.zsh
```
- Starts both terminal server (port 7681) and MkDocs (port 8000)
- Uses basic restricted shell for local testing

## Production Deployment
```bash
cd deploy
sudo ./setup.sh
sudo ./configure-ssl.sh yourdomain.com
```
- Creates ephemeral Docker containers
- Full isolation with sudo/install capabilities
- SSL termination via nginx
