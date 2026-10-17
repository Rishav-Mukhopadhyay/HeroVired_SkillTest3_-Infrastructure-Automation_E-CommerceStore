# ---------- Stage 1: build the React app ----------
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Tell React to call APIs on the SAME address it was loaded from
ENV REACT_APP_USER_SERVICE_URL=/
ENV REACT_APP_PRODUCT_SERVICE_URL=/
ENV REACT_APP_CART_SERVICE_URL=/
ENV REACT_APP_ORDER_SERVICE_URL=/
ENV DISABLE_ESLINT_PLUGIN=true
RUN npm run build

# ---------- Stage 2: serve the built files with nginx ----------
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
