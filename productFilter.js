db = db.getSiblingDB('perseids');
db.system.js.remove({"_id" : "productFilter"});
db.system.js.save(
    {
        _id: "productFilter",
        value: function (filters, filterable, keywords, lang, skip, limit) {
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
                    if (parameterSet["params"][paramName]) {
                        filterableParams[paramName] = [...new Set([...parameterSet["params"][paramName], ...filterableParams[paramName]])];
                    }
                }
            }

            var output = {
                    count: db.getCollection(lang + '_products').find(productQuery).length(),
                    params: filterableParams,
                    products: db.getCollection(lang + '_products').find(productQuery).skip(skip).limit(limit).toArray()
            }

            return output;
        }
    }
)

