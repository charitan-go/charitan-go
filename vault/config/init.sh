#!/bin/sh
set -e

export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="root"

echo "=== Enabling KV Secrets Engine ==="
vault secrets enable -path=keys kv-v2

echo "=== Generating initial RSA Key Pair ==="
openssl genpkey -algorithm RSA -out private.pem -pkeyopt rsa_keygen_bits:2048
openssl rsa -in private.pem -pubout -out public.pem

echo "=== Storing initial keys in Vault ==="
vault kv put keys/rsa private="$(cat private.pem)" public="$(cat public.pem)"

echo "=== Creating Policies ==="
# Policy for auth-server: full read access (private and public)
vault policy write auth-server-policy - <<EOF
path "keys/data/rsa" {
  capabilities = ["read"]
}
EOF

# Policy for microservices: only public key access
vault policy write microservice-policy - <<EOF
path "keys/data/rsa" {
  capabilities = ["read"],
  allowed_parameters = {
    "public"
  }
}
EOF

echo "=== Enabling AppRole Authentication ==="
vault auth enable approle

echo "=== Creating AppRole for auth-server ==="
vault write auth/approle/role/auth-server-role \
  policies="auth-server-policy" \
  token_ttl=15m \
  token_max_ttl=1h

echo "=== Creating AppRole for microservices ==="
vault write auth/approle/role/microservice-role \
  policies="microservice-policy" \
  token_ttl=15m \
  token_max_ttl=1h

echo "Vault initialization completed!"
