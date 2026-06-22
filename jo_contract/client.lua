-- ==========================================
-- كود العميل (Client Side) - سكربت العقود jojo_contract
-- ==========================================

-- دالة حركة التوقيع (أنيميشن)
local function startSigningAnimation()
    local playerPed = PlayerPedId()
    local animDict = "amb@code_human_in_car_idles@ver_1@generic@idles@sign_id_clipboard"
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
    end

    -- تشغيل الحركة لمدة ثانيتين
    TaskPlayAnim(playerPed, animDict, "idles_a_ver_1", 8.0, -8.0, 2000, 49, 0, false, false, false)
    lib.notify({type = 'inform', description = 'جاري توقيع العقد رسميًا...'})
    Citizen.Wait(2000)
    StopAnimTask(playerPed, animDict, "idles_a_ver_1", 1.0)
end

-- أمر فتح قائمة إنشاء العقد
RegisterCommand('jojo_contract', function()
    local input = lib.inputDialog('📋 إنشاء عقد بيع وشراء رسمي', {
        {type = 'number', label = 'رقم المشتري (ID)', description = 'أدخل الآيدي الخاص باللاعب المشتري', required = true},
        {type = 'input', label = 'الشيء المباع', description = 'مثال: سيارة نيسان، سلاح، إلخ', required = true},
        {type = 'number', label = 'السعر الإجمالي', description = 'السعر الذي سيتم خصمه من بنك المشتري', required = true}
    })

    if not input then return end -- إذا أقفل القائمة

    local targetId = input[1]
    local itemName = input[2]
    local price = input[3]

    if price <= 0 then
        lib.notify({type = 'error', description = 'المبلغ يجب أن يكون أكبر من صفر!'})
        return
    end

    -- إرسال العقد للسيرفر
    TriggerServerEvent('jojo_contract:server:sendContract', targetId, itemName, price)
end)

-- استقبال العقد من المشتري للموافقة والرفض
RegisterNetEvent('jojo_contract:client:receiveContract', function(sellerId, itemName, price)
    local alert = lib.alertDialog({
        header = '📋 عقد بيع وشراء جديد',
        content = string.format('هل توافق على شراء **%s** بمبلغ **%s$** من اللاعب رقم (%s)؟\n\n سيتم خصم المبلغ من حسابك البنكي.', itemName, price, sellerId),
        centered = true,
        cancel = true,
        labels = { confirm = 'موافقة وتوقيع ✅', cancel = 'رفض العقد ❌' }
    })

    if alert == 'confirm' then
        startSigningAnimation() -- تشغيل الحركة أولاً
        TriggerServerEvent('jojo_contract:server:acceptContract', sellerId, itemName, price)
    else
        lib.notify({type = 'error', description = 'قمت برفض العقد.'})
        TriggerServerEvent('jojo_contract:server:rejectContract', sellerId)
    end
end)