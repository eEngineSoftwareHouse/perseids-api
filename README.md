# Perseids API

#### Postman sample API calls collection:
[https://www.getpostman.com/collections/24115356834c4a64c5d4](https://www.getpostman.com/collections/24115356834c4a64c5d4)

#### Postman API docs:
[https://goo.gl/fZPJWF](https://goo.gl/fZPJWF)

## Running in development
Create file with environment variables to be used by docker-compose in future:
```
cp .env.sample .env
```

Run containers:
```
docker-compose up -d
```

Make sure to append filter query to a database:
```
docker-compose exec mongo mongo --eval "$(< productFilter.js)"
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



## Some examples

Ask for all products with size **104/110** and colour **Bianco** and limit the results to **5**:
```
GET localhost:4000/api/v1/products/?filter[params.size][]=104/110&filter[params.colour][]=Bianco&limit=5
```

For more examples go to API documentation (link at the top)


## API methods which calls Magento under the hood

To use methods such as `/api/v1/status/magento` you have to provide magento access data, such as host and admin credentials in your `.env` file.
See `.env.sample` for details.


## MongoDB required indexes:

1. Text index on product title and description field for searching (for each language):
```
db.pl_products.createIndex( { descritpion: "text", name: "text" } )
db.en_products.createIndex( { descritpion: "text", name: "text" } )
```

2. Params, which will be used for filtering, e.g.:
```
db.pl_products.createIndex( { "params.size": 1, "params.color": 1 } )
db.en_products.createIndex( { "params.size": 1, "params.color": 1 } )

db.pl_products.createIndex( { "categories.id": 1 } )
db.en_products.createIndex( { "categories.id": 1 } )
```

3. Other indexes
```
db.pl_pages.createIndex( { "slug": 1 } )
db.en_pages.createIndex( { "slug": 1 } )
```
