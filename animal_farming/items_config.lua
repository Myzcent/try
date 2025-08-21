-- Items configuration for ox_inventory
-- Add these items to your ox_inventory/data/items.lua file

-- Animal Feed Item
['animal_feed'] = {
    label = 'Animal Feed',
    weight = 500,
    stack = true,
    close = true,
    description = 'Nutritious feed for farm animals. Increases hunger and health.',
    client = {
        image = 'animal_feed.png', -- Make sure to add this image to ox_inventory/web/images/
    }
},

-- Knife for Butchering
['knife'] = {
    label = 'Butcher Knife',
    weight = 300,
    stack = false,
    close = true,
    description = 'Sharp knife used for butchering dead animals.',
    client = {
        image = 'knife.png',
    }
},

-- Animal Products
['raw_meat'] = {
    label = 'Raw Meat',
    weight = 200,
    stack = true,
    close = true,
    description = 'Fresh raw meat from butchered animals.',
    client = {
        image = 'raw_meat.png',
    }
},

['milk'] = {
    label = 'Fresh Milk',
    weight = 250,
    stack = true,
    close = true,
    description = 'Fresh milk from female cows. Collected every 3 days.',
    client = {
        image = 'milk.png',
    }
},

['eggs'] = {
    label = 'Fresh Eggs',
    weight = 100,
    stack = true,
    close = true,
    description = 'Fresh eggs from female chickens. Collected every 30 minutes.',
    client = {
        image = 'eggs.png',
    }
},

['raw_pork'] = {
    label = 'Raw Pork',
    weight = 300,
    stack = true,
    close = true,
    description = 'Raw pork meat from pigs. Can be processed into food.',
    client = {
        image = 'raw_pork.png',
    }
},

-- Optional: Water bucket for manual watering
['water_bucket'] = {
    label = 'Water Bucket',
    weight = 1000,
    stack = false,
    close = true,
    description = 'Bucket of clean water for hydrating animals.',
    client = {
        image = 'water_bucket.png',
    }
}