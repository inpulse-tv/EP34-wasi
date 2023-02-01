#!/bin/sh
api_url=${API_URL:-"localhost:8080"}

sed -i sxAPI_URLx${api_url}xg /usr/share/nginx/html/js/app.js