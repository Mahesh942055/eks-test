FROM nginx:1.19.1-alpine
#ARG DOMAIN_NAME=api2.1851franchise.com
COPY ./.docker/nginx/nginx.conf /etc/nginx/conf.d/default.conf
#RUN sed -i 's/domain_name/'"$DOMAIN_NAME"'/g' /etc/nginx/conf.d/default.conf
EXPOSE 80