FROM node AS build

WORKDIR /src
COPY . .
RUN npm i && npm run build

FROM nginx:alpine

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy React build files to Nginx
COPY --from=build /src/dist/ /usr/share/nginx/html
COPY others/nginx.conf /etc/nginx/conf.d/default.conf

# Copy custom Nginx config if needed
# COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
