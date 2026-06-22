fx_version 'cerulean'
game 'gta5'

author 'Hanan'
description 'jojo_contract - نظام عقود البيع والشراء الرسمي بميزة التوقيع الواقعي'
version '1.0.0'

-- تحديد الملفات التي يقرأها الخادم للتشغيل
server_script 'server.lua'
client_script 'client.lua'

-- ربط السكربت بمكتبة ox_lib الفعالة للإشعارات والقوائم
shared_scripts {
    '@ox_lib/init.lua'
}