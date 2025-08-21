-- Animal Farming Items for ox_inventory
-- Add these items to your ox_inventory/data/items.lua file

-- Animal Feed
['animal_feed'] = {
    label = 'Animal Feed',
    weight = 500,
    stack = true,
    close = true,
    description = 'Nutritious feed for farm animals. Improves health and hunger.',
    client = {
        image = 'animal_feed.png',
    }
},

-- Knife for Butchering
['knife'] = {
    label = 'Butcher Knife',
    weight = 300,
    stack = false,
    close = true,
    description = 'A sharp knife used for butchering animals.',
    client = {
        image = 'knife.png',
    }
},

-- Raw Meat (General)
['raw_meat'] = {
    label = 'Raw Meat',
    weight = 200,
    stack = true,
    close = true,
    description = 'Fresh raw meat from butchered animals. Can be cooked.',
    client = {
        image = 'raw_meat.png',
    }
},

-- Milk from Cows
['milk'] = {
    label = 'Fresh Milk',
    weight = 250,
    stack = true,
    close = true,
    description = 'Fresh milk collected from female cows. Rich in nutrients.',
    client = {
        image = 'milk.png',
    }
},

-- Eggs from Chickens (if you add chickens later)
['eggs'] = {
    label = 'Fresh Eggs',
    weight = 100,
    stack = true,
    close = true,
    description = 'Fresh eggs collected from chickens. Great for cooking.',
    client = {
        image = 'eggs.png',
    }
},

-- Raw Pork from Pigs
['raw_pork'] = {
    label = 'Raw Pork',
    weight = 300,
    stack = true,
    close = true,
    description = 'Fresh raw pork from pigs. Can be processed into various products.',
    client = {
        image = 'raw_pork.png',
    }
},