# Example TLS Certificates

### DON'T use these files in production

These files are meant to be used only for the example-with-encryption cluster. They're not secure and you shouldn't use them for production services.

### Files

- **ca.crt.pem**: The public certificate of the Certificate Authority used to create these files.
- **consul.crt.pem:** The TLS public certificate issued by the Certificate Authority of the Consul server.
- **consul.key.pem:** The TLS private key that corresponds to the TLS public certificate.

The TLS files are configured as follows:

- The only authorized IP address is `127.0.0.1` and no domains are authorized at all, so you might not be able to use them for host verification.
- The TLS certificate is valid until April 4 2038.

### How to create your own certificates

Since you're already using Terraform, it's probably easiest to use the [TLS Provider](https://www.terraform.io/docs/providers/tls/index.html) to generate your own certificates. You can find a good working example in the [private-tls-cert module](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/private-tls-cert) within the [terraform-aws-vault repo](https://github.com/hashicorp/terraform-aws-vault).