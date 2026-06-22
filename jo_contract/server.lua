-- ==========================================
-- كود السيرفر (Server Side) - سكربت العقود jojo_contract
-- ==========================================

local Framework = nil

-- الجسر التلقائي للتعرف على نوع السيرفر
if GetResourceState('qb-core') == 'started' then
    Framework = 'QBCore'
    QBCore = exports['qb-core']:GetCoreObject()
elseif GetResourceState('es_extended') == 'started' then
    Framework = 'ESX'
    ESX = exports['es_extended']:getSharedObject()
end

local DiscordWebhook = "ضع_رابط_الويب_هوك_هنا"

-- دالة إرسال التوثيق للديسكورد
function sendToDiscord(title, message, color)
    if DiscordWebhook == "ضع_رابط_الويب_هوك_هنا" then return end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = message,
            ["color"] = color,
            ["footer"] = { ["text"] = "jojo_contract - نظام العقود" },
            ["timestamp"] = os.date("!Y-%m-%dT%H:%M:%SZ")
        }
    }
    PerformHttpRequest(DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({username = "عقود jojo الرسمية", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

-- حدث إرسال العقد للمشتري
RegisterNetEvent('jojo_contract:server:sendContract', function(targetId, itemName, price)
    local src = source
    local target = tonumber(targetId)
    
    if not GetPlayerName(target) then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'اللاعب غير موجود في السيرفر!'})
        return
    end

    TriggerClientEvent('jojo_contract:client:receiveContract', target, src, itemName, price)
    TriggerClientEvent('ox_lib:notify', src, {type = 'inform', description = 'تم إرسال العقد، في انتظار توقيع المشتري...'})
end)

-- حدث موافقة المشتري وإتمام المعاملة المالية
RegisterNetEvent('jojo_contract:server:acceptContract', function(sellerId, itemName, price)
    local buyerId = source
    local seller = tonumber(sellerId)
    price = tonumber(price)

    local buyerMoney = 0
    local buyerName = GetPlayerName(buyerId)
    local sellerName = GetPlayerName(seller)

    -- نظام QBCore
    if Framework == 'QBCore' then
        local PlayerBuyer = QBCore.Functions.GetPlayer(buyerId)
        local PlayerSeller = QBCore.Functions.GetPlayer(seller)
        
        buyerMoney = PlayerBuyer.Functions.GetMoney('bank')
        
        if buyerMoney >= price then
            PlayerBuyer.Functions.RemoveMoney('bank', price, "شراء عقد")
            PlayerSeller.Functions.AddMoney('bank', price, "بيع عقد")
            
            TriggerClientEvent('ox_lib:notify', buyerId, {type = 'success', description = 'تمت الموافقة وشراء ' .. itemName})
            TriggerClientEvent('ox_lib:notify', seller, {type = 'success', description = 'وافق المشتري وتم تحويل المبلغ: ' .. price .. '$'})
            
            sendToDiscord("عقد بيع ناجح (QBCore)", string.format("المشتري: %s\nالبائع: %s\nالشيء المباع: %s\nالسعر: %s$", buyerName, sellerName, itemName, price), 65280)
        else
            TriggerClientEvent('ox_lib:notify', buyerId, {type = 'error', description = 'ليس لديك مال كافي في البنك!'})
            TriggerClientEvent('ox_lib:notify', seller, {type = 'error', description = 'تم رفض العقد لعدم توفر المال عند المشتري.'})
        end

    -- نظام ESX
    elseif Framework == 'ESX' then
        local xPlayerBuyer = ESX.GetPlayerFromId(buyerId)
        local xPlayerSeller = ESX.GetPlayerFromId(seller)
        
        buyerMoney = xPlayerBuyer.getAccount('bank').money
        
        if buyerMoney >= price then
            xPlayerBuyer.removeAccountMoney('bank', price)
            xPlayerSeller.addAccountMoney('bank', price)
            
            TriggerClientEvent('ox_lib:notify', buyerId, {type = 'success', description = 'تمت الموافقة وشراء ' .. itemName})
            TriggerClientEvent('ox_lib:notify', seller, {type = 'success', description = 'وافق المشتري وتم تحويل المبلغ: ' .. price .. '$'})
            
            sendToDiscord("عقد بيع ناجح (ESX)", string.format("المشتري: %s\nالبائع: %s\nالشيء المباع: %s\nالسعر: %s$", buyerName, sellerName, itemName, price), 65280)
        else
            TriggerClientEvent('ox_lib:notify', buyerId, {type = 'error', description = 'ليس لديك مال كافي في البنك!'})
            TriggerClientEvent('ox_lib:notify', seller, {type = 'error', description = 'تم رفض العقد لعدم توفر المال عند المشتري.'})
        end
    end
end)

-- حدث رفض العقد
RegisterNetEvent('jojo_contract:server:rejectContract', function(sellerId)
    local seller = tonumber(sellerId)
    TriggerClientEvent('ox_lib:notify', seller, {type = 'error', description = 'تم رفض عقد البيع من قبل المشتري.'})
end)