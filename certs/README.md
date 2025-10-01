# Cloudflare Origin Certificates

This directory should contain your Cloudflare Origin Certificates for TLS termination at the Gateway.

## Required Files

You need to place the following files in this directory:

- `tls.crt` - Cloudflare Origin Certificate (public certificate)
- `tls.key` - Cloudflare Origin Certificate private key

## How to Obtain Cloudflare Origin Certificates

1. Log in to your Cloudflare dashboard
2. Go to your domain
3. Navigate to SSL/TLS → Origin Server
4. Click "Create Certificate"
5. Choose:
   - Generate private key and CSR with Cloudflare
   - Hostnames: `*.yourdomain.com`, `yourdomain.com`
   - Key type: RSA (2048)
   - Certificate Validity: 15 years
6. Copy the certificate content to `tls.crt`
7. Copy the private key content to `tls.key`

## File Format

The files should be in PEM format:

### tls.crt
```
-----BEGIN CERTIFICATE-----
[Certificate content]
-----END CERTIFICATE-----
```

### tls.key
```
-----BEGIN PRIVATE KEY-----
[Private key content]
-----END PRIVATE KEY-----
```

## Security Notes

- Keep the private key (`tls.key`) secure and never commit it to version control
- Add `certs/` to your `.gitignore` if these certificates contain sensitive data
- Cloudflare Origin Certificates are only valid when traffic is proxied through Cloudflare