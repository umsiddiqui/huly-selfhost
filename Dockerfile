FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY /path/to/your/static/files /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
