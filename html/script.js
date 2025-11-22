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
    console.log('[dost_crafting] closeUI called');
    $("#app-container").fadeOut(200);
    $.post('https://dost-crafting/close', JSON.stringify({}))
        .done(function() { console.log('[dost_crafting] close callback success'); })
        .fail(function() { console.log('[dost_crafting] close callback failed'); });
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
    // Simplified check based on available data
    // Note: Level system seems to be removed/simplified in main.lua, relying on skills/jobs
    // We'll check job, grade, and ingredients
    
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
    
    // Frontend loop for bulk crafting
    // We will add to queue locally and send requests to server
    // Note: Server expects one request per craft usually, or we can send one request and server handles loop?
    // The plan said "looping in the frontend".
    // However, we need to be careful not to spam server if it has checks.
    // The server has a queue system. If we send 5 requests, it adds 5 items to queue.
    
    for (let i = 0; i < qty; i++) {
        $.post('https://dost-crafting/craft', JSON.stringify({ item: currentRecipe }));
    }
    
    Notify.show(`Added ${qty}x to queue`, 'success');
    
    // Optimistically update inventory for display?
    // It's complex because we don't know if server accepted it.
    // But we can deduct temporarily to update the "max craftable" display.
    // For now, let's just rely on server updates or leave it.
    // Actually, let's update local inventory to prevent "infinite" crafting attempts visually
    if (item.Ingredients) {
        for (const [ing, amount] of Object.entries(item.Ingredients)) {
            if (inventory[ing]) inventory[ing] -= (amount * qty);
        }
    }
    
    // Re-render details to update counts/buttons
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
    
    // Sort by time remaining? Or just list them.
    // Queue is an object in this script, but server sends "addqueue" events.
    // We need to sync with server events.
    
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

    // Handle escape key - use keydown for immediate response
    $(document).on('keydown keyup', function(e) {
        if (e.key === "Escape" || e.keyCode === 27) {
            e.preventDefault();
            e.stopPropagation();
            console.log('[dost_crafting] ESC key detected in JS');
            closeUI();
            return false;
        }
    });

    // Also listen on window level
    window.addEventListener('keydown', function(e) {
        if (e.key === "Escape" || e.keyCode === 27) {
            e.preventDefault();
            console.log('[dost_crafting] ESC key detected on window');
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
        // Server sends this periodically for active item?
        // Or once?
        // Looking at main.lua:
        // SendNUIMessage({ type = "addqueue", item = ..., time = ..., id = ... })
        // It sends it every second for the active item (index 1).
        // Wait, only index 1?
        // "if craftingQueue[1] ~= nil ... SendNUIMessage ... table.remove(craftingQueue, 1)"
        // So server only processes one at a time.
        // But if we queue multiple, they are in server memory.
        // The server only sends update for the CURRENT one being crafted.
        // So we only know about the one active item?
        // "SendNUIMessage({ type = "addqueue", item = item, time = recipe.Time, id = id })" is also called on craftStart.
        
        // Let's handle it:
        // If it's a new ID, add it.
        // If it's an update, update time.
        
        if (!craftingQueue[data.id]) {
            craftingQueue[data.id] = {
                item: data.item,
                time: data.time,
                totalTime: data.time // Assume initial time is total
            };
        } else {
            craftingQueue[data.id].time = data.time;
        }
        
        // If time is 0, remove
        if (data.time <= 0) {
            Notify.show(`Crafted ${(names[data.item] || data.item).toUpperCase()}`, 'success');
            delete craftingQueue[data.id];
        }
        
        updateQueuePanel();
    } else if (data.type === "crafting") {
        // Just a notification or sound?
        // We handle queue update via addqueue
    } else if (data.type === "forceClose") {
        // Force close from Lua (escape key handler)
        $("#app-container").fadeOut(200);
        currentRecipe = null;
    }
});