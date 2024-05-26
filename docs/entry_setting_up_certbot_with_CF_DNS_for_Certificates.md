# Setting Up Certbot with Cloudflare DNS for SSL/TLS Certificates

Created: 2024-05-26

In this blog post, we'll walk through the process of setting up Certbot, a tool that automates the process of obtaining and renewing SSL/TLS certificates from Let's Encrypt. We will also cover how to use the Cloudflare DNS plugin for DNS-01 challenges.

## Step-by-Step Guide

### 1. Create a Python Virtual Environment

First, we need to create an isolated environment for our Certbot installation. This ensures that any dependencies required by Certbot do not interfere with other Python projects on your system.

```bash
python3 -m venv /opt/certbot/
```

### 2. Upgrade `pip` within the Virtual Environment

Next, upgrade `pip`, the Python package installer, to the latest version within the virtual environment:

```bash
/opt/certbot/bin/pip install --upgrade pip
```

### 3. Install Certbot

Now, install Certbot in the virtual environment:

```bash
/opt/certbot/bin/pip install certbot
```

### 4. Create a Symbolic Link for Certbot

Create a symbolic link from the Certbot executable in the virtual environment to `/usr/bin/certbot`, making it accessible system-wide:

```bash
ln -s /opt/certbot/bin/certbot /usr/bin/certbot
```

### 5. Verify Certbot Installation

Check the installed version of Certbot to ensure it is installed correctly:

```bash
certbot --version
```

### 6. List Existing Certificates

To list all SSL/TLS certificates currently managed by Certbot, use the following command:

```bash
certbot certificates
```

### 7. Install the Cloudflare DNS Plugin for Certbot

Install the Cloudflare DNS plugin for Certbot. This allows you to use DNS-01 challenges for domain validation via Cloudflare:

```bash
/opt/certbot/bin/pip install certbot-dns-cloudflare
```

### 8. Edit the Cloudflare Credentials File

Create or edit the `flare.ini` file to include your Cloudflare API token and other necessary credentials. Open the file in the `vim` text editor:

```bash
vim flare.ini
```

An example `flare.ini` file might look like this:

```
dns_cloudflare_email=your@email.com
dns_cloudflare_api_key=your-cloudflare-api-key
```
OR

```
dns_cloudflare_api_token=your-cloudflare-api-key
```

### 9. Set File Permissions for the Credentials File

Secure your credentials file by setting its permissions so it is readable and writable only by the file's owner.

```bash
chmod 600 flare.ini
```

### 10. Verify the Cloudflare API Token

Verify that the provided Cloudflare API token is valid with the following command. Replace `<TOKEN>` with your actual API token:

```bash
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer <TOKEN>" -H "Content-Type:application/json"
```

### 11. Obtain a Certificate Using the Cloudflare DNS Plugin

Request a new certificate for your domain using the Cloudflare DNS plugin. Replace `<DOMAIN>` with your actual domain name:

```bash
certbot certonly --dns-cloudflare --dns-cloudflare-credentials ./flare.ini --dns-cloudflare-propagation-seconds 60 -d <DOMAIN>
```

### 12. List the Newly Obtained Certificates

Finally, list all certificates managed by Certbot, including the one just obtained:

```bash
certbot certificates
```

## Conclusion

By following these steps, you can set up Certbot to automate SSL/TLS certificate management using Cloudflare DNS for domain validation. This setup ensures your website remains secure with up-to-date certificates from Let's Encrypt.


[filename](footnote.md ':include')