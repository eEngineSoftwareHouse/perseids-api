db.system.js.save(
    {
        _id: "productFilter",
        value: function (colors, sizes, category_ids, lang, skip, limit) {
            var productQuery = {};
            if (colors != undefined && colors.length != 0) {
                productQuery['params.color'] = {$in: colors};
            } else if (sizes != undefined && sizes.length != 0) {
                productQuery['params.size'] = {$in: sizes};
            } else if (category_ids != undefined && category_ids.length != 0) {
                productQuery['categories.id'] = {$in: category_ids};
            }
            var desiredProducts = db.getCollection(lang + '_products').find(productQuery).skip(skip).limit(limit);

            var visibleParameters = {'params.size': 1, 'params.color': 1, 'categories.id': 1};

            var colorFilter = {};
            if (colors != undefined && colors.length != 0) {
                colorFilter['params.color'] = {$in: colors};
            } else if (category_ids != undefined && category_ids.length != 0) {
                colorFilter['categories.id'] = {$in: category_ids};
            }
            var categoriesFilteredByColor = db.getCollection(lang + '_products').find(colorFilter, visibleParameters);

            var sizeFilter = {};
            if (sizes != undefined && sizes.length != 0) {
                sizeFilter['params.size'] = {$in: sizes};
            } else if (category_ids != undefined && category_ids.length != 0) {
                sizeFilter['categories.id'] = {$in: category_ids};
            }
            var categoriesFiltredBySize = db.getCollection(lang + '_products').find(sizeFilter, visibleParameters);

            var params = [...new Set([...categoriesFilteredByColor.toArray(), ...categoriesFiltredBySize.toArray()])];

            var availableColors = [];
            var availableSizes = [];
            var availableCategories = [];
            for (var p of params) {
                    if (p.params.color !== undefined)
                            availableColors = [...new Set([...availableColors, ...p.params.color])];
                    if (p.params.size !== undefined)
                            availableSizes = [...new Set([...availableSizes, ...p.params.size])];
                    

                    if (p.categories !== undefined) {
                            var t = [];
                            for (var pp of p.categories) {
                                    t.push(pp.id);
                            }
                            availableCategories = [...new Set([...availableCategories, ...t])];
                    }
            }

            var output = {
                    count: db.getCollection(lang + '_products').find(productQuery).length(),
                    params: {
                            category_ids: availableCategories,
                            color: availableColors,
                            size: availableSizes
                    },
                    products: desiredProducts.toArray()
            }

            return output;
        }
    }
)