// Modern Crafting UI Script
var recipes = {}, inventory = {}, names = {}, job = "", grade = 0;
var categories = {}, workbenchType = "", workbenchName = "";
var hidecraft = false;
var currentRecipe = null;
var craftingQueue = {};
var queueTimer = null;
var audioEnabled = true;

// Audio System
const Audio = {
    sounds: {},
    init() {
        this.sounds.click = document.getElementById('clickaudio');
        this.sounds.success = document.getElementById('successaudio');
        this.sounds.error = document.getElementById('erroraudio');
    },
    play(type) {
        if (this.sounds[type]) {
            this.sounds[type].currentTime = 0;
            this.sounds[type].play().catch(() => {});
        }
    }
};

// Notifications
const Notify = {
    show(msg, type = 'info') {
        const container = document.getElementById('notifications');
        const div = document.createElement('div');
        div.className = `notification ${type}`;
        
        const icons = {
            success: 'fas fa-check-circle',
            error: 'fas fa-times-circle',
            warning: 'fas fa-exclamation-triangle',
            info: 'fas fa-info-circle'
        };
        
        div.innerHTML = `<i class="${icons[type]}"></i> <span>${msg}</span>`;
        container.appendChild(div);
        
        if (type === 'success') Audio.play('success');
        if (type === 'error') Audio.play('error');
        
        setTimeout(() => {
            div.style.opacity = '0';
            div.style.transform = 'translateY(-20px)';
            setTimeout(() => div.remove(), 300);
        }, 3000);
    }
};

// Core Functions
function showUI() {
    $("#app-container").fadeIn(200);
    $("#workbench-title").text(workbenchName || "WORKBENCH");
    renderRecipes();
    updateQueuePanel();

    // Set focus to capture keyboard events
    setTimeout(() => {
        document.body.focus();
        $("#app-container").focus();
    }, 100);
}

function closeUI() {
    $("#app-container").fadeOut(200);
    $.post('https://dost-crafting/close', JSON.stringify({}));
    currentRecipe = null;
    $("#details-panel").html(`
        <div class="empty-state">
            <i class="fas fa-cube"></i>
            <p>Select an item to view details</p>
        </div>
    `);
}

function renderRecipes(filter = "") {
    const container = $("#main_container");
    container.empty();
    
    const sortedKeys = Object.keys(recipes).sort((a, b) => {
        const nameA = (names[a] || a).toLowerCase();
        const nameB = (names[b] || b).toLowerCase();
        return nameA.localeCompare(nameB);
    });

    let hasItems = false;

    sortedKeys.forEach(key => {
        const item = recipes[key];
        const name = (names[key] || key).toUpperCase();
        
        if (filter && !name.includes(filter.toUpperCase())) return;
        
        const req = checkRequirements(item, key);
        const isLocked = !req.canCraft;
        
        // If hidecraft is true and locked, skip
        if (hidecraft && isLocked) return;
        
        hasItems = true;
        
        const card = $(`
            <div class="recipe-card ${isLocked ? 'locked' : ''}" data-key="${key}">
                <div class="recipe-icon" style="background-image: url('img/${key}.png')"></div>
                <div class="recipe-name">${name}</div>
                ${item.Amount > 1 ? `<div class="recipe-badge">x${item.Amount}</div>` : ''}
            </div>
        `);
        
        card.click(() => selectRecipe(key, card));
        container.append(card);
    });

    if (!hasItems) {
        container.html('<div style="grid-column: 1/-1; text-align: center; color: var(--text-muted); padding: 2rem;">No recipes found</div>');
    }
}

function checkRequirements(item, key) {
    let canCraft = true;
    let reason = "";
    
    // Job Check
    if (item.Jobs && item.Jobs.length > 0) {
        const hasJob = Array.isArray(item.Jobs) ? item.Jobs.includes(job) : item.Jobs[job];
        if (!hasJob) { canCraft = false; reason = "Job Restricted"; }
    }
    
    // Grade Check
    if (item.JobGrades && item.JobGrades.length > 0) {
        const hasGrade = Array.isArray(item.JobGrades) ? item.JobGrades.includes(grade) : item.JobGrades[grade];
        if (!hasGrade) { canCraft = false; reason = "Rank Restricted"; }
    }
    
    // Blueprint Check
    if (item.requireBlueprint && (!inventory[key + '_blueprint'] || inventory[key + '_blueprint'] < 1)) {
        canCraft = false;
        reason = "Blueprint Required";
    }
    
    // Skill Check (if passed in recipe)
    if (item.SkillLocked) {
        canCraft = false;
        reason = "Skill Locked";
    }
    
    // Ingredients Check
    if (item.Ingredients) {
        for (const [ing, amount] of Object.entries(item.Ingredients)) {
            if ((inventory[ing] || 0) < amount) {
                canCraft = false;
                reason = "Missing Materials";
                break; // One missing is enough to fail
            }
        }
    }

    return { canCraft, reason };
}

function selectRecipe(key, cardElement) {
    Audio.play('click');
    $(".recipe-card").removeClass("selected");
    cardElement.addClass("selected");
    currentRecipe = key;
    
    const item = recipes[key];
    const name = (names[key] || key).toUpperCase();
    const req = checkRequirements(item, key);
    
    renderDetails(key, item, name, req);
}

function renderDetails(key, item, name, req) {
    const panel = $("#details-panel");
    
    let ingredientsHtml = "";
    let maxCraftable = 999;
    
    if (item.Ingredients) {
        for (const [ing, amount] of Object.entries(item.Ingredients)) {
            const has = inventory[ing] || 0;
            const needed = amount;
            const isEnough = has >= needed;
            
            // Calculate max craftable based on this ingredient
            const possible = Math.floor(has / needed);
            if (possible < maxCraftable) maxCraftable = possible;
            
            ingredientsHtml += `
                <div class="ingredient-row ${isEnough ? 'has-enough' : 'missing'}">
                    <div class="ing-icon" style="background-image: url('img/${ing}.png')"></div>
                    <div class="ing-name">${(names[ing] || ing).toUpperCase()}</div>
                    <div class="ing-count ${isEnough ? 'green' : 'red'}">${has} / ${needed}</div>
                </div>
            `;
        }
    }
    
    if (maxCraftable === 0) maxCraftable = 0; // Can't craft any
    
    const html = `
        <div class="detail-header">
            <div class="detail-title">
                <h2>${name}</h2>
                <div class="detail-meta">
                    <div class="meta-item"><i class="fas fa-clock"></i> ${formatTime(item.Time)}</div>
                    <div class="meta-item"><i class="fas fa-weight-hanging"></i> x${item.Amount}</div>
                </div>
            </div>
        </div>
        
        <div class="ingredients-list">
            ${ingredientsHtml}
        </div>
        
        <div class="action-area">
            <div class="quantity-selector">
                <button class="qty-btn" onclick="adjustQty(-1)">-</button>
                <input type="number" id="craft-qty" class="qty-input" value="1" min="1" max="${maxCraftable || 1}" readonly>
                <button class="qty-btn" onclick="adjustQty(1, ${maxCraftable})">+</button>
            </div>
            
            <button class="craft-btn" onclick="startCraft()" ${!req.canCraft ? 'disabled' : ''}>
                ${req.canCraft ? '<i class="fas fa-hammer"></i> CRAFT' : `<i class="fas fa-lock"></i> ${req.reason || 'LOCKED'}`}
            </button>
        </div>
    `;
    
    panel.html(html);
}

function adjustQty(delta, max) {
    const input = $("#craft-qty");
    let val = parseInt(input.val()) || 1;
    val += delta;
    if (val < 1) val = 1;
    if (max !== undefined && val > max) val = max;
    input.val(val);
    Audio.play('click');
}

function startCraft() {
    if (!currentRecipe) return;

    const qty = parseInt($("#craft-qty").val()) || 1;
    const item = recipes[currentRecipe];

    for (let i = 0; i < qty; i++) {
        $.post('https://dost-crafting/craft', JSON.stringify({ item: currentRecipe }));
    }

    Notify.show(`Added ${qty}x to queue`, 'success');

    // Update local inventory to reflect pending crafts
    if (item.Ingredients) {
        for (const [ing, amount] of Object.entries(item.Ingredients)) {
            if (inventory[ing]) inventory[ing] -= (amount * qty);
        }
    }

    const req = checkRequirements(item, currentRecipe);
    renderDetails(currentRecipe, item, (names[currentRecipe] || currentRecipe).toUpperCase(), req);
}

function updateQueuePanel() {
    const panel = $("#queue-panel");
    const list = $("#queue-items");
    const count = Object.keys(craftingQueue).length;
    
    $("#queue-count").text(count);
    
    if (count === 0) {
        panel.fadeOut();
        return;
    }
    
    panel.fadeIn();
    list.empty();

    for (const [id, data] of Object.entries(craftingQueue)) {
        const percent = ((data.totalTime - data.time) / data.totalTime) * 100;
        
        list.append(`
            <div class="queue-item">
                <div class="q-info">
                    <span class="q-name">${(names[data.item] || data.item).toUpperCase()}</span>
                    <span class="q-time">${formatTime(data.time)}</span>
                </div>
                <div class="q-progress-bg">
                    <div class="q-progress-bar" style="width: ${percent}%"></div>
                </div>
            </div>
        `);
    }
}

function formatTime(seconds) {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s.toString().padStart(2, '0')}`;
}

// Event Listeners
$(document).ready(() => {
    Audio.init();

    $("#search-input").on("input", function() {
        renderRecipes($(this).val());
    });

    // Handle escape key
    $(document).on('keydown keyup', function(e) {
        if (e.key === "Escape" || e.keyCode === 27) {
            e.preventDefault();
            e.stopPropagation();
            closeUI();
            return false;
        }
    });

    window.addEventListener('keydown', function(e) {
        if (e.key === "Escape" || e.keyCode === 27) {
            e.preventDefault();
            closeUI();
        }
    }, true);
});

// Message Handler
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.type === "open") {
        recipes = data.recipes;
        inventory = data.inventory;
        names = data.names;
        job = data.job;
        grade = data.grade;
        workbenchType = data.workbenchType;
        workbenchName = data.workbenchName;
        hidecraft = data.hidecraft;
        
        showUI();
    } else if (data.type === "addqueue") {
        if (!craftingQueue[data.id]) {
            craftingQueue[data.id] = {
                item: data.item,
                time: data.time,
                totalTime: data.time
            };
        } else {
            craftingQueue[data.id].time = data.time;
        }

        if (data.time <= 0) {
            Notify.show(`Crafted ${(names[data.item] || data.item).toUpperCase()}`, 'success');
            delete craftingQueue[data.id];
        }

        updateQueuePanel();
    } else if (data.type === "forceClose") {
        $("#app-container").fadeOut(200);
        currentRecipe = null;
    }
});