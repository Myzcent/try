let currentAnimalId = null;
let currentAnimalData = null;
let currentAnimalConfig = null;

// Listen for NUI messages
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'showStats':
            showAnimalStats(data.animalId, data.data, data.config);
            break;
        case 'hide':
            hideStats();
            break;
    }
});

// Show animal stats
function showAnimalStats(animalId, animalData, animalConfig) {
    currentAnimalId = animalId;
    currentAnimalData = animalData;
    currentAnimalConfig = animalConfig;
    
    // Update animal info
    document.getElementById('animalTitle').textContent = `${animalData.gender} ${animalConfig.label}`;
    document.getElementById('animalType').textContent = animalConfig.label;
    document.getElementById('animalGender').textContent = animalData.gender;
    document.getElementById('animalLevel').textContent = `${animalData.level} (${animalData.experience} XP)`;
    
    // Update stats
    updateStatBar('health', animalData.health, animalConfig.maxHealth);
    updateStatBar('hunger', animalData.hunger, animalConfig.maxHunger);
    updateStatBar('thirst', animalData.thirst, animalConfig.maxThirst);
    
    // Calculate experience for next level
    const expForNextLevel = animalData.level * 100; // Assuming 100 XP per level
    const currentLevelExp = animalData.experience % 100;
    updateStatBar('experience', currentLevelExp, 100);
    document.getElementById('experienceValue').textContent = `${currentLevelExp}/100`;
    
    // Update production info
    document.getElementById('lastFed').textContent = animalData.lastFed ? formatDate(animalData.lastFed) : 'Never';
    document.getElementById('lastProduction').textContent = animalData.lastProduction ? formatDate(animalData.lastProduction) : 'Never';
    
    // Check production readiness
    const productionReady = checkProductionReadiness(animalData, animalConfig);
    const productionStatus = document.getElementById('productionStatus');
    if (productionReady) {
        productionStatus.style.display = 'flex';
    } else {
        productionStatus.style.display = 'none';
    }
    
    // Update buttons
    updateButtons(animalData, animalConfig);
    
    // Show the panel
    document.getElementById('animalStatsContainer').classList.remove('hidden');
}

// Update stat bar
function updateStatBar(statType, current, max) {
    const percentage = Math.max(0, Math.min(100, (current / max) * 100));
    const bar = document.getElementById(`${statType}Bar`);
    const value = document.getElementById(`${statType}Value`);
    
    bar.style.width = `${percentage}%`;
    value.textContent = `${current}/${max}`;
    
    // Add color coding based on percentage
    bar.classList.remove('low', 'medium', 'high');
    if (percentage <= 25) {
        bar.classList.add('low');
    } else if (percentage <= 60) {
        bar.classList.add('medium');
    } else {
        bar.classList.add('high');
    }
}

// Check if animal is ready for production
function checkProductionReadiness(animalData, animalConfig) {
    // Check if animal is healthy enough
    if (animalData.health < 50 || animalData.hunger < 30 || animalData.thirst < 30) {
        return false;
    }
    
    // Check gender requirements for production
    if (animalConfig.genderProduction && animalData.gender !== 'Female') {
        return false;
    }
    
    // Check production cooldown
    if (animalData.lastProduction) {
        const lastProduction = new Date(animalData.lastProduction);
        const now = new Date();
        const timeDiff = now.getTime() - lastProduction.getTime();
        return timeDiff >= animalConfig.productionTime;
    }
    
    return true;
}

// Update button states
function updateButtons(animalData, animalConfig) {
    const feedBtn = document.getElementById('feedBtn');
    const collectBtn = document.getElementById('collectBtn');
    const butcherBtn = document.getElementById('butcherBtn');
    
    // Feed button - always enabled if animal is alive
    feedBtn.disabled = animalData.health <= 0;
    
    // Collect button - enabled if production ready
    const productionReady = checkProductionReadiness(animalData, animalConfig);
    collectBtn.disabled = !productionReady;
    
    // Butcher button - only shown if animal is dead
    if (animalData.health <= 0) {
        butcherBtn.style.display = 'block';
        butcherBtn.disabled = false;
    } else {
        butcherBtn.style.display = 'none';
    }
}

// Format date for display
function formatDate(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);
    
    if (diffMins < 1) {
        return 'Just now';
    } else if (diffMins < 60) {
        return `${diffMins} minutes ago`;
    } else if (diffHours < 24) {
        return `${diffHours} hours ago`;
    } else {
        return `${diffDays} days ago`;
    }
}

// Hide stats panel
function hideStats() {
    document.getElementById('animalStatsContainer').classList.add('hidden');
    currentAnimalId = null;
    currentAnimalData = null;
    currentAnimalConfig = null;
}

// Event listeners
document.getElementById('closeBtn').addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/closeStats`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
});

document.getElementById('feedBtn').addEventListener('click', function() {
    if (currentAnimalId && !this.disabled) {
        fetch(`https://${GetParentResourceName()}/feedAnimal`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                animalId: currentAnimalId
            })
        });
    }
});

document.getElementById('collectBtn').addEventListener('click', function() {
    if (currentAnimalId && !this.disabled) {
        fetch(`https://${GetParentResourceName()}/collectProducts`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                animalId: currentAnimalId
            })
        });
    }
});

document.getElementById('butcherBtn').addEventListener('click', function() {
    if (currentAnimalId && !this.disabled) {
        fetch(`https://${GetParentResourceName()}/butcherAnimal`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                animalId: currentAnimalId
            })
        });
    }
});

// Close on ESC key
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/closeStats`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    }
});

// Prevent right-click context menu
document.addEventListener('contextmenu', function(event) {
    event.preventDefault();
});

// Helper function to get parent resource name
function GetParentResourceName() {
    return window.location.hostname;
}