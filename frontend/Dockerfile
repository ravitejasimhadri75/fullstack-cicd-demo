# Build step not included here — assume frontend build artifacts are present in ./frontend/build or ./frontend/dist
FROM nginx:stable-alpine
# Remove default html
RUN rm -rf /usr/share/nginx/html/*
# Copy build output if exists (adjust below if your frontend build outputs to 'dist' instead)
COPY build/ /usr/share/nginx/html/
# expose http
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
