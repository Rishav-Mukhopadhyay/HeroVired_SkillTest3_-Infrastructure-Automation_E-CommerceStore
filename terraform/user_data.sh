#!/bin/bash
# Runs ONCE, as root, on the EC2's first boot.
# Everything printed here is saved to /var/log/user-data.log for debugging.
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
set -eu

echo "===== 1. Install Docker ====="
apt-get update -y
apt-get install -y docker.io
systemctl enable --now docker
usermod -aG docker ubuntu

# Values injected by Terraform (templatefile)
HUB="${dockerhub_username}"
TAG="${image_tag}"

echo "===== 2. Create private container network ====="
docker network create ecommerce-net

echo "===== 3. Pull images from Docker Hub ====="
docker pull mongo:7
for svc in user-service product-service cart-service order-service frontend; do
  docker pull "$HUB/ecommerce-$svc:$TAG"
done

echo "===== 4. Run containers (database -> backends -> frontend) ====="
docker run -d --name mongo --network ecommerce-net --restart unless-stopped \
  -v mongo-data:/data/db mongo:7

docker run -d --name user-service --network ecommerce-net --restart unless-stopped \
  -p 3001:3001 \
  -e MONGODB_URI=mongodb://mongo:27017/ecommerce_users \
  -e JWT_SECRET="${jwt_secret}" \
  "$HUB/ecommerce-user-service:$TAG"

docker run -d --name product-service --network ecommerce-net --restart unless-stopped \
  -p 3002:3002 \
  -e MONGODB_URI=mongodb://mongo:27017/ecommerce_products \
  "$HUB/ecommerce-product-service:$TAG"

docker run -d --name cart-service --network ecommerce-net --restart unless-stopped \
  -p 3003:3003 \
  -e MONGODB_URI=mongodb://mongo:27017/ecommerce_carts \
  -e PRODUCT_SERVICE_URL=http://product-service:3002 \
  "$HUB/ecommerce-cart-service:$TAG"

docker run -d --name order-service --network ecommerce-net --restart unless-stopped \
  -p 3004:3004 \
  -e MONGODB_URI=mongodb://mongo:27017/ecommerce_orders \
  -e CART_SERVICE_URL=http://cart-service:3003 \
  -e PRODUCT_SERVICE_URL=http://product-service:3002 \
  -e USER_SERVICE_URL=http://user-service:3001 \
  "$HUB/ecommerce-order-service:$TAG"

docker run -d --name frontend --network ecommerce-net --restart unless-stopped \
  -p 80:80 \
  "$HUB/ecommerce-frontend:$TAG"

echo "===== 5. Done ====="
docker ps
echo "USER-DATA COMPLETE"
