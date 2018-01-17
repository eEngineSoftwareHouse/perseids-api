# Perseids API

#### Postman sample API calls collection:
[https://www.getpostman.com/collections/24115356834c4a64c5d4](https://www.getpostman.com/collections/24115356834c4a64c5d4)

#### Postman API docs:
[https://goo.gl/fgAtRx](https://goo.gl/fgAtRx)


## Running in development
Create file with environment variables to be used by docker-compose in future:
```
cp .env.sample .env
```

Run containers:
```
docker-compose up -d
```

App will be available at port 4000 on your localhost by default:

* **API**: `http://localhost:4000`
* **MongoDB**: `localhost:27017`

Logs of each container can be seen by typing: `docker-compose logs -f [service name]`, where `[service name]` should be replaced by service name defined in `docker-compose.yml` e.g
```
docker-compose logs -f api
```
```
docker-compose logs -f mongo
```

## Prepare MongoDB
You have to have indexes:

1. Text index on product title and description field for searching (for each language)
2. Params, which will be used for filtering (for each language)
3. Product slugs (url_key)

Be sure to prepare MongoDB (add indexes and custom functions) by running:
```
docker-compose exec mongo mongo --eval "$(< prepare_mongo.js)"
````

See `prepare_mongo.js` file for details.


## Some examples

Ask for all products with size **104/110** and colour **Bianco** and limit the results to **5**:
```
GET localhost:4000/api/v1/products/?filter[params.size][]=104/110&filter[params.colour][]=Bianco&limit=5
```

For more examples go to API documentation (link at the top)


## API methods which calls Magento under the hood

To use methods such as `/api/v1/status/magento` you have to provide magento access data, such as host and admin credentials in your `.env` file.
See `.env.sample` for details.
