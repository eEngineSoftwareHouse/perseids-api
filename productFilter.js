db.system.js.save(
    {
        _id: "productFilter",
        value: function (filters, filterable, lang, skip, limit) {

            for (var f of filterable) {
                if (f === "category_ids") {
                    continue;
                }
                f = "params." + f;
                if (!filters.find((x) => x["name"] === f)) {
                    filters.push({"name": f, "content": null});
                }
            }

            var productQuery = {};
            var visibleParameters = {};
            
            for (var filter of filters) {
                if (filter["content"]) {
                    productQuery[filter["name"]] = {$in: filter["content"]};
                }
                visibleParameters[filter["name"]] = 1;
            }
            
            var unmergedParameters = [];
            var categoryIds = filters.find((x) => x["name"] === "categories.id")["content"];
            for (var filter of filters) {
                if (filter["name"] === "categories.id") {
                    continue;
                }
                var parameters = {};
                parameters["categories.id"] = {$in: categoryIds};
                if (filter["content"]) {
                    parameters[filter["name"]] = {$in: filter["content"]};
                }
                
                unmergedParameters = [...new Set([
                    ...db.getCollection(lang + '_products').find(parameters, visibleParameters).toArray(), 
                    ...unmergedParameters
                ])];
            }
            var filterableParams = {};
            filterableParams["category_ids"] = [];
            for (var filter of filters) {
                if (filter["name"] !== "categories.id") {
                    filterableParams[filter["name"].substring(7)] = [];
                }
            }
            for (var parameter of unmergedParameters) {
                for (var filter of filters) {
                    if (filter["name"] === "categories.id") {
                        var ids = [];
                        for (var t of parameter["categories"]) {
                            ids.push(t.id);
                        }
                        filterableParams["category_ids"] = [...new Set([...ids, ...filterableParams["category_ids"]])];
                    } else {
                        var paramName = filter["name"].substring(7);
                        if (parameter["params"][paramName]) {
                            filterableParams[paramName] = [...new Set([...parameter["params"][paramName], ...filterableParams[paramName]])];
                        }
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