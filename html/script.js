// ============================================================================
// Animal Farm NUI - JavaScript Functionality
// ============================================================================

// Global variables
let isMenuOpen = false;
let currentAnimalData = null;
let notificationTimeout = null;

// DOM Elements
const animalMenu = document.getElementById('animalMenu');
const closeBtn = document.getElementById('closeBtn');
const loadingOverlay = document.getElementById('loadingOverlay');

// Animal data elements
const animalTitle = document.getElementById('animalTitle');
const animalType = document.getElementById('animalType');
const animalGender = document.getElementById('animalGender');
const animalAge = document.getElementById('animalAge');
const animalId = document.getElementById('animalId');
const despawnTime = document.getElementById('despawnTime');
const lastUpdated = document.getElementById('lastUpdated');

// Status elements
const hungerBar = document.getElementById('hungerBar');
const hungerValue = document.getElementById('hungerValue');
const waterBar = document.getElementById('waterBar');
const waterValue = document.getElementById('waterValue');

// Product section
const productSection = document.getElementById('productSection');
const productReady = document.getElementById('productReady');

// Action buttons
const feedBtn = document.getElementById('feedBtn');
const milkBtn = document.getElementById('milkBtn');
const infoBtn = document.getElementById('infoBtn');

// ============================================================================
// Utility Functions
// ============================================================================

// Show loading overlay
function showLoading() {
    loadingOverlay.classList.remove('hidden');
}

// Hide loading overlay
function hideLoading() {
    loadingOverlay.classList.add('hidden');
}

// Show notification
function showNotification(message, type = 'success', duration = 5000) {
    const notificationsContainer = document.getElementById('notifications');
    
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = `
        <div style="display: flex; align-items: center; gap: 10px;">
            <i class="fas fa-${getNotificationIcon(type)}"></i>
            <span>${message}</span>
        </div>
    `;
    
    notificationsContainer.appendChild(notification);
    
    // Auto remove after duration
    setTimeout(() => {
        if (notification.parentNode) {
            notification.style.animation = 'slideInRight 0.3s ease-out reverse';
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.remove();
                }
            }, 300);
        }
    }, duration);
}

// Get notification icon based on type
function getNotificationIcon(type) {
    switch (type) {
        case 'success': return 'check-circle';
        case 'error': return 'exclamation-triangle';
        case 'warning': return 'exclamation-circle';
        case 'info': return 'info-circle';
        default: return 'bell';
    }
}

// Format time for display
function formatTime(minutes) {
    if (minutes < 60) {
        return `${minutes} min`;
    } else {
        const hours = Math.floor(minutes / 60);
        const mins = minutes % 60;
        return `${hours}h ${mins}m`;
    }
}

// Update status bar
function updateStatusBar(element, valueElement, percentage) {
    const clampedPercentage = Math.max(0, Math.min(100, percentage));
    element.style.width = `${clampedPercentage}%`;
    valueElement.textContent = `${Math.round(clampedPercentage)}%`;
    
    // Add visual feedback based on percentage
    if (clampedPercentage < 25) {
        element.style.filter = 'brightness(0.7)';
    } else if (clampedPercentage < 50) {
        element.style.filter = 'brightness(0.9)';
    } else {
        element.style.filter = 'brightness(1.1)';
    }
}

// ============================================================================
// Menu Management
// ============================================================================

// Open animal menu with data
function openAnimalMenu(data) {
    console.log('[AnimalFarm] Opening menu with data:', data);
    
    if (!data) {
        console.error('[AnimalFarm] No data provided to openAnimalMenu');
        return;
    }
    
    currentAnimalData = data;
    
    // Update animal information
    animalTitle.textContent = data.animalLabel || data.animalType || 'Unknown Animal';
    animalType.textContent = (data.animalType || 'Unknown').charAt(0).toUpperCase() + (data.animalType || 'Unknown').slice(1);
    animalGender.textContent = data.gender || (data.isFemale ? 'Female' : 'Male');
    animalAge.textContent = data.age || 'Unknown';
    animalId.textContent = `#${data.animalId || 'Unknown'}`;
    despawnTime.textContent = formatTime(data.despawnTime || 60);
    lastUpdated.textContent = new Date().toLocaleTimeString();
    
    // Update status bars
    updateStatusBar(hungerBar, hungerValue, data.hunger || 0);
    updateStatusBar(waterBar, waterValue, data.water || 0);
    
    // Update gender icon
    const genderIcon = document.querySelector('.gender-icon i');
    if (data.isFemale) {
        genderIcon.className = 'fas fa-venus';
        document.querySelector('.gender-icon').style.background = 'linear-gradient(135deg, #e74c3c, #c0392b)';
    } else {
        genderIcon.className = 'fas fa-mars';
        document.querySelector('.gender-icon').style.background = 'linear-gradient(135deg, #3498db, #2980b9)';
    }
    
    // Show/hide product section
    if (data.productReady && data.isFemale) {
        productSection.classList.remove('hidden');
        productReady.querySelector('h4').textContent = 'Milk Ready!';
        productReady.querySelector('p').textContent = 'This animal is ready for milk collection';
    } else {
        productSection.classList.add('hidden');
    }
    
    // Update action buttons
    feedBtn.querySelector('span').textContent = `Feed ${data.animalLabel || data.animalType || 'Animal'}`;
    
    // Show/hide milk button based on gender
    if (data.isFemale) {
        milkBtn.classList.remove('hidden');
        milkBtn.disabled = !data.productReady;
        if (data.productReady) {
            milkBtn.querySelector('span').textContent = 'Collect Milk';
        } else {
            milkBtn.querySelector('span').textContent = 'Not Ready';
        }
    } else {
        milkBtn.classList.add('hidden');
    }
    
    // Show menu with animation
    animalMenu.classList.remove('hidden');
    isMenuOpen = true;
    
    // Add click outside to close
    setTimeout(() => {
        animalMenu.addEventListener('click', handleOutsideClick);
    }, 100);
    
    console.log('[AnimalFarm] Menu opened successfully');
}

// Close animal menu
function closeAnimalMenu() {
    console.log('[AnimalFarm] Closing animal menu');
    
    if (!isMenuOpen) {
        console.log('[AnimalFarm] Menu already closed');
        return;
    }
    
    // Add closing animation
    const modalContent = animalMenu.querySelector('.modal-content');
    modalContent.classList.add('closing');
    animalMenu.classList.add('closing');
    
    // Remove event listeners
    animalMenu.removeEventListener('click', handleOutsideClick);
    
    // Hide after animation
    setTimeout(() => {
        animalMenu.classList.add('hidden');
        animalMenu.classList.remove('closing');
        modalContent.classList.remove('closing');
        isMenuOpen = false;
        currentAnimalData = null;
        
        // Notify Lua script
        fetch(`https://${GetParentResourceName()}/closeMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({})
        }).catch(err => console.error('Error closing menu:', err));
        
        console.log('[AnimalFarm] Menu closed successfully');
    }, 300);
}

// Handle click outside modal
function handleOutsideClick(event) {
    if (event.target === animalMenu) {
        closeAnimalMenu();
    }
}

// ============================================================================
// Event Listeners
// ============================================================================

// Close button click
closeBtn.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    closeAnimalMenu();
});

// Feed button click
feedBtn.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    
    if (!currentAnimalData) return;
    
    showLoading();
    
    // Send feed request to Lua
    fetch(`https://${GetParentResourceName()}/feedAnimal`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            animalId: currentAnimalData.animalId,
            animalType: currentAnimalData.animalType
        })
    }).then(() => {
        hideLoading();
        showNotification(`Fed ${currentAnimalData.animalLabel || currentAnimalData.animalType}!`, 'success');
        
        // Update hunger bar (simulate increase)
        const newHunger = Math.min(100, (currentAnimalData.hunger || 0) + 25);
        updateStatusBar(hungerBar, hungerValue, newHunger);
        currentAnimalData.hunger = newHunger;
        
    }).catch(err => {
        hideLoading();
        console.error('Error feeding animal:', err);
        showNotification('Failed to feed animal', 'error');
    });
});

// Milk button click
milkBtn.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    
    if (!currentAnimalData || !currentAnimalData.isFemale) return;
    
    showLoading();
    
    // Send milk collection request to Lua
    fetch(`https://${GetParentResourceName()}/collectMilk`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            animalId: currentAnimalData.animalId,
            animalType: currentAnimalData.animalType
        })
    }).then(() => {
        hideLoading();
        showNotification('Milk collected successfully!', 'success');
        
        // Hide product ready section
        productSection.classList.add('hidden');
        milkBtn.disabled = true;
        milkBtn.querySelector('span').textContent = 'Not Ready';
        currentAnimalData.productReady = false;
        
    }).catch(err => {
        hideLoading();
        console.error('Error collecting milk:', err);
        showNotification('Failed to collect milk', 'error');
    });
});

// Info button click
infoBtn.addEventListener('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
    
    if (!currentAnimalData) return;
    
    const animalInfo = `
        Animal ID: ${currentAnimalData.animalId}
        Type: ${currentAnimalData.animalType}
        Gender: ${currentAnimalData.isFemale ? 'Female' : 'Male'}
        Age: ${currentAnimalData.age || 'Unknown'}
        Hunger: ${currentAnimalData.hunger || 0}%
        Water: ${currentAnimalData.water || 0}%
        Product Ready: ${currentAnimalData.productReady ? 'Yes' : 'No'}
    `;
    
    showNotification(animalInfo.replace(/\n/g, '<br>'), 'info', 8000);
});

// Keyboard event handlers
document.addEventListener('keydown', (e) => {
    if (!isMenuOpen) return;
    
    switch (e.key) {
        case 'Escape':
            e.preventDefault();
            closeAnimalMenu();
            break;
        case 'f':
        case 'F':
            e.preventDefault();
            if (!feedBtn.disabled) {
                feedBtn.click();
            }
            break;
        case 'm':
        case 'M':
            e.preventDefault();
            if (!milkBtn.disabled && !milkBtn.classList.contains('hidden')) {
                milkBtn.click();
            }
            break;
        case 'i':
        case 'I':
            e.preventDefault();
            infoBtn.click();
            break;
    }
});

// ============================================================================
// NUI Message Handlers
// ============================================================================

// Listen for messages from Lua script
window.addEventListener('message', (event) => {
    const data = event.data;
    
    console.log('[AnimalFarm] Received message:', data);
    
    switch (data.action) {
        case 'openAnimalMenu':
            openAnimalMenu(data);
            break;
            
        case 'closeAnimalMenu':
            closeAnimalMenu();
            break;
            
        case 'updateAnimalStatus':
            updateAnimalStatus(data);
            break;
            
        case 'showNotification':
            showNotification(data.message, data.type || 'info', data.duration || 5000);
            break;
            
        case 'showLoading':
            showLoading();
            break;
            
        case 'hideLoading':
            hideLoading();
            break;
            
        default:
            console.warn('[AnimalFarm] Unknown action:', data.action);
            break;
    }
});

// Update animal status (for real-time updates)
function updateAnimalStatus(data) {
    if (!isMenuOpen || !currentAnimalData) return;
    
    console.log('[AnimalFarm] Updating animal status:', data);
    
    // Update current data
    Object.assign(currentAnimalData, data);
    
    // Update status bars
    if (data.hunger !== undefined) {
        updateStatusBar(hungerBar, hungerValue, data.hunger);
    }
    
    if (data.water !== undefined) {
        updateStatusBar(waterBar, waterValue, data.water);
    }
    
    // Update product ready status
    if (data.productReady !== undefined) {
        if (data.productReady && currentAnimalData.isFemale) {
            productSection.classList.remove('hidden');
            milkBtn.disabled = false;
            milkBtn.querySelector('span').textContent = 'Collect Milk';
        } else {
            productSection.classList.add('hidden');
            milkBtn.disabled = true;
            milkBtn.querySelector('span').textContent = 'Not Ready';
        }
    }
    
    // Update last updated time
    lastUpdated.textContent = new Date().toLocaleTimeString();
}

// ============================================================================
// Resource Management
// ============================================================================

// Get parent resource name for fetch requests
function GetParentResourceName() {
    return window.location.hostname;
}

// Initialize NUI
function initializeNUI() {
    console.log('[AnimalFarm] NUI Initialized');
    
    // Ensure menu is closed on load
    animalMenu.classList.add('hidden');
    isMenuOpen = false;
    currentAnimalData = null;
    
    // Hide loading overlay
    hideLoading();
    
    // Send ready signal to Lua
    fetch(`https://${GetParentResourceName()}/nuiReady`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ ready: true })
    }).catch(err => {
        console.warn('[AnimalFarm] Could not send ready signal:', err);
    });
}

// Cleanup function
function cleanup() {
    console.log('[AnimalFarm] Cleaning up NUI');
    
    // Close menu if open
    if (isMenuOpen) {
        closeAnimalMenu();
    }
    
    // Clear notifications
    const notificationsContainer = document.getElementById('notifications');
    if (notificationsContainer) {
        notificationsContainer.innerHTML = '';
    }
    
    // Hide loading
    hideLoading();
    
    // Reset variables
    isMenuOpen = false;
    currentAnimalData = null;
    
    // Clear timeouts
    if (notificationTimeout) {
        clearTimeout(notificationTimeout);
        notificationTimeout = null;
    }
}

// ============================================================================
// Animation and Visual Effects
// ============================================================================

// Add hover effects to buttons
function addButtonEffects() {
    const buttons = document.querySelectorAll('.action-btn');
    
    buttons.forEach(button => {
        button.addEventListener('mouseenter', () => {
            if (!button.disabled) {
                button.style.transform = 'translateY(-2px)';
            }
        });
        
        button.addEventListener('mouseleave', () => {
            button.style.transform = 'translateY(0)';
        });
        
        button.addEventListener('mousedown', () => {
            if (!button.disabled) {
                button.style.transform = 'translateY(0) scale(0.98)';
            }
        });
        
        button.addEventListener('mouseup', () => {
            if (!button.disabled) {
                button.style.transform = 'translateY(-2px) scale(1)';
            }
        });
    });
}

// Animate status bars
function animateStatusBars() {
    const statusFills = document.querySelectorAll('.status-fill');
    
    statusFills.forEach(fill => {
        const width = fill.style.width;
        fill.style.width = '0%';
        
        setTimeout(() => {
            fill.style.width = width;
        }, 100);
    });
}

// ============================================================================
// Error Handling and Fallbacks
// ============================================================================

// Handle fetch errors
function handleFetchError(error, action) {
    console.error(`[AnimalFarm] Fetch error for ${action}:`, error);
    hideLoading();
    showNotification(`Network error: ${action} failed`, 'error');
}

// Fallback for missing elements
function validateElements() {
    const requiredElements = [
        'animalMenu', 'closeBtn', 'animalTitle', 'animalType',
        'hungerBar', 'waterBar', 'feedBtn', 'milkBtn'
    ];
    
    const missing = requiredElements.filter(id => !document.getElementById(id));
    
    if (missing.length > 0) {
        console.error('[AnimalFarm] Missing required elements:', missing);
        return false;
    }
    
    return true;
}

// ============================================================================
// Window Event Handlers
// ============================================================================

// Window load event
window.addEventListener('load', () => {
    console.log('[AnimalFarm] Window loaded');
    
    if (!validateElements()) {
        console.error('[AnimalFarm] Required elements missing - NUI may not work properly');
        return;
    }
    
    addButtonEffects();
    initializeNUI();
});

// Window beforeunload event
window.addEventListener('beforeunload', () => {
    cleanup();
});

// Handle window focus/blur for better resource management
window.addEventListener('focus', () => {
    console.log('[AnimalFarm] Window focused');
});

window.addEventListener('blur', () => {
    console.log('[AnimalFarm] Window blurred');
});

// ============================================================================
// Development and Debug Functions
// ============================================================================

// Debug function to test menu (only for development)
function debugOpenMenu() {
    const testData = {
        animalId: 999,
        animalType: 'cow',
        animalLabel: 'Bessie',
        isFemale: true,
        productReady: true,
        hunger: 75,
        water: 60,
        age: '2 Years',
        gender: 'Female',
        despawnTime: 45
    };
    
    openAnimalMenu(testData);
}

// Make debug function available globally (remove in production)
window.debugOpenMenu = debugOpenMenu;

// Console commands for debugging
console.log('[AnimalFarm] NUI Script loaded successfully');
console.log('[AnimalFarm] Available debug commands:');
console.log('  - debugOpenMenu() - Test open menu');
console.log('  - cleanup() - Force cleanup');

// ============================================================================
// Prevent Context Menu and Text Selection
// ============================================================================

// Disable right-click context menu
document.addEventListener('contextmenu', (e) => {
    e.preventDefault();
});

// Disable text selection
document.addEventListener('selectstart', (e) => {
    e.preventDefault();
});

// Disable drag and drop
document.addEventListener('dragstart', (e) => {
    e.preventDefault();
});

// ============================================================================
// Performance Optimizations
// ============================================================================

// Throttle function for performance
function throttle(func, limit) {
    let inThrottle;
    return function() {
        const args = arguments;
        const context = this;
        if (!inThrottle) {
            func.apply(context, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    }
}

// Debounce function for performance
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Optimized resize handler
const handleResize = debounce(() => {
    console.log('[AnimalFarm] Window resized');
    // Add any resize logic here if needed
}, 250);

window.addEventListener('resize', handleResize);