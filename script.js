// Pet Status Management System
class PetStatus {
    constructor() {
        this.stats = {
            health: 100,
            hungry: 0,
            thirsty: 0,
            level: 1,
            exp: 0,
            maxExp: 100
        };
        
        this.init();
        this.startStatusDecay();
    }

    init() {
        this.updateDisplay();
        this.bindEvents();
    }

    bindEvents() {
        document.getElementById('feed-btn').addEventListener('click', () => this.feed());
        document.getElementById('water-btn').addEventListener('click', () => this.giveWater());
    }

    feed() {
        // Reduce hunger and add experience
        this.stats.hungry = Math.max(0, this.stats.hungry - 30);
        this.addExperience(10);
        
        // Improve health if well-fed
        if (this.stats.hungry < 20) {
            this.stats.health = Math.min(100, this.stats.health + 5);
        }
        
        this.updateDisplay();
        this.showFeedback('🍖 Fed! Hunger reduced!', 'success');
    }

    giveWater() {
        // Reduce thirst and add experience
        this.stats.thirsty = Math.max(0, this.stats.thirsty - 35);
        this.addExperience(8);
        
        // Improve health if well-hydrated
        if (this.stats.thirsty < 20) {
            this.stats.health = Math.min(100, this.stats.health + 3);
        }
        
        this.updateDisplay();
        this.showFeedback('💧 Hydrated! Thirst reduced!', 'success');
    }

    addExperience(amount) {
        this.stats.exp += amount;
        
        // Level up check
        while (this.stats.exp >= this.stats.maxExp) {
            this.stats.exp -= this.stats.maxExp;
            this.stats.level++;
            this.stats.maxExp = Math.floor(this.stats.maxExp * 1.2); // Increase exp requirement
            this.showFeedback(`🎉 Level Up! Now Level ${this.stats.level}!`, 'levelup');
        }
    }

    updateDisplay() {
        // Update health bar
        const healthBar = document.getElementById('health-bar');
        const healthText = document.getElementById('health-text');
        healthBar.style.width = `${this.stats.health}%`;
        healthText.textContent = `${this.stats.health}%`;
        
        // Update hungry bar
        const hungryBar = document.getElementById('hungry-bar');
        const hungryText = document.getElementById('hungry-text');
        hungryBar.style.width = `${this.stats.hungry}%`;
        hungryText.textContent = `${this.stats.hungry}%`;
        
        // Update thirsty bar
        const thirstyBar = document.getElementById('thirsty-bar');
        const thirstyText = document.getElementById('thirsty-text');
        thirstyBar.style.width = `${this.stats.thirsty}%`;
        thirstyText.textContent = `${this.stats.thirsty}%`;
        
        // Update level
        document.getElementById('level').textContent = this.stats.level;
        
        // Update experience bar
        const expBar = document.getElementById('exp-bar');
        const expText = document.getElementById('exp-text');
        const expPercentage = (this.stats.exp / this.stats.maxExp) * 100;
        expBar.style.width = `${expPercentage}%`;
        expText.textContent = `${this.stats.exp} / ${this.stats.maxExp}`;
        
        // Update health based on hunger and thirst
        this.updateHealthBasedOnNeeds();
    }

    updateHealthBasedOnNeeds() {
        // Health decreases if pet is too hungry or thirsty
        if (this.stats.hungry > 80 || this.stats.thirsty > 80) {
            this.stats.health = Math.max(0, this.stats.health - 1);
        }
        
        // Update health bar color based on value
        const healthBar = document.getElementById('health-bar');
        if (this.stats.health < 30) {
            healthBar.className = 'status-fill health-fill low';
        } else if (this.stats.health < 70) {
            healthBar.className = 'status-fill health-fill medium';
        } else {
            healthBar.className = 'status-fill health-fill high';
        }
    }

    startStatusDecay() {
        // Gradually increase hunger and thirst over time
        setInterval(() => {
            this.stats.hungry = Math.min(100, this.stats.hungry + 0.5);
            this.stats.thirsty = Math.min(100, this.stats.thirsty + 0.7);
            this.updateDisplay();
        }, 3000); // Every 3 seconds for demo purposes
    }

    showFeedback(message, type) {
        // Create feedback element
        const feedback = document.createElement('div');
        feedback.className = `feedback ${type}`;
        feedback.textContent = message;
        
        // Style the feedback
        feedback.style.cssText = `
            position: fixed;
            top: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: ${type === 'success' ? '#4CAF50' : type === 'levelup' ? '#9C27B0' : '#FF5722'};
            color: white;
            padding: 15px 25px;
            border-radius: 25px;
            font-weight: bold;
            z-index: 1000;
            animation: slideDown 0.3s ease, slideUp 0.3s ease 2.7s;
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        `;
        
        document.body.appendChild(feedback);
        
        // Remove after 3 seconds
        setTimeout(() => {
            if (feedback.parentNode) {
                feedback.parentNode.removeChild(feedback);
            }
        }, 3000);
    }
}

// Add CSS animations for feedback
const style = document.createElement('style');
style.textContent = `
    @keyframes slideDown {
        from {
            opacity: 0;
            transform: translateX(-50%) translateY(-20px);
        }
        to {
            opacity: 1;
            transform: translateX(-50%) translateY(0);
        }
    }
    
    @keyframes slideUp {
        from {
            opacity: 1;
            transform: translateX(-50%) translateY(0);
        }
        to {
            opacity: 0;
            transform: translateX(-50%) translateY(-20px);
        }
    }
`;
document.head.appendChild(style);

// Initialize the pet status system when page loads
document.addEventListener('DOMContentLoaded', () => {
    new PetStatus();
});