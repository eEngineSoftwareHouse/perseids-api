// Set default DB
db = db.getSiblingDB('perseids');

// Create indexes
db.pl_pln_products.createIndex( { descritpion: "text", name: "text" } );
db.en_usd_products.createIndex( { descritpion: "text", name: "text" } );
db.en_gbp_products.createIndex( { descritpion: "text", name: "text" } );
db.en_eur_products.createIndex( { descritpion: "text", name: "text" } );

db.pl_pln_products.createIndex( { "categories.id": 1 } );
db.en_usd_products.createIndex( { "categories.id": 1 } );
db.en_gbp_products.createIndex( { "categories.id": 1 } );
db.en_eur_products.createIndex( { "categories.id": 1 } );

db.pl_pln_products.createIndex( { "params.product_size": 1 } );
db.en_usd_products.createIndex( { "params.product_size": 1 } );
db.en_gbp_products.createIndex( { "params.product_size": 1 } );
db.en_eur_products.createIndex( { "params.product_size": 1 } );

db.pl_pln_products.createIndex( { "params.url_key": 1 } );
db.en_usd_products.createIndex( { "params.url_key": 1 } );
db.en_gbp_products.createIndex( { "params.url_key": 1 } );
db.en_eur_products.createIndex( { "params.url_key": 1 } );

db.pl_pln_products.createIndex( { "params.color": 1 } );
db.en_usd_products.createIndex( { "params.color": 1 } );
db.en_gbp_products.createIndex( { "params.color": 1 } );
db.en_eur_products.createIndex( { "params.color": 1 } );

db.pl_pln_products.createIndex( { "params.pattern": 1 } );
db.en_usd_products.createIndex( { "params.pattern": 1 } );
db.en_gbp_products.createIndex( { "params.pattern": 1 } );
db.en_eur_products.createIndex( { "params.pattern": 1 } );

db.pl_pln_products.createIndex( { "url_key": 1 } );
db.en_usd_products.createIndex( { "url_key": 1 } );
db.en_gbp_products.createIndex( { "url_key": 1 } );
db.en_eur_products.createIndex( { "url_key": 1 } );


db.pl_pln_products.createIndex({ "recommended": 1 });
db.en_usd_products.createIndex({ "recommended": 1 });
db.en_gbp_products.createIndex({ "recommended": 1 });
db.en_eur_products.createIndex({ "recommended": 1 });

// Add custom filtering function
db.system.js.remove({"_id" : "productFilter"});
db.system.js.save(
    {
        _id: "productFilter",
        value: function (filters, filterable, selectedFields, keywords, lang, skip, limit, sortDirection) {
            for (var f of filterable) {
                filters.push({"name": "params." + f, "content": null});
            }

            var productQuery = {};

            if (keywords) {
                productQuery['$text'] = {$search: keywords};
            }

            var visibleParameters = {};
            var categoryIds = null;
            for (var filter of filters) {
                if (filter.content) {
                    productQuery[filter.name] = {$in: filter.content};
                }
                if (filter.name === "categories.id") {
                    categoryIds = filter.content;
                }
                visibleParameters[filter.name] = 1;
            }

            var unmergedParameterSets = [];
            var filterableParams = {};
            filterableParams["category_ids"] = [];
            for (var filter of filters) {
                if (filter.name === "categories.id") {
                    continue;
                }
                var parameters = {};
                if (categoryIds) {
                    parameters["params.category_ids"] = {$in: categoryIds};
                }
                if (keywords) {
                    parameters['$text'] = {$search: keywords};
                }
                if (filter.content) {
                    parameters[filter.name] = {$in: filter.content};
                }
                unmergedParameterSets.push(...db.getCollection(lang + '_products').find(parameters, visibleParameters).toArray());

                filterableParams[filter.name.substring(7)] = [];
            }

            for (var parameterSet of unmergedParameterSets) {
                for (var filter of filters) {
                    var paramName = (filter.name === "categories.id") ? filter.name : filter.name.substring(7);
                    if (parameterSet["params"]) {
                        if (parameterSet["params"][paramName]) {
                            filterableParams[paramName] = [...new Set([...parameterSet["params"][paramName], ...filterableParams[paramName]])];
                        }
                    }
                }
            }

            var selectedFieldsQuery = {};
            for (var field of selectedFields) {
                selectedFieldsQuery[field.name] = field.content;
            }

            var output = {
                    count: db.getCollection(lang + '_products').find(productQuery).length(),
                    params: filterableParams,
                    products: db.getCollection(lang + '_products').find(productQuery, selectedFieldsQuery).sort({listing_position: sortDirection}).skip(skip).limit(limit).toArray()
            }

            return output;
        }
    }
)
