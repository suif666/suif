Library:Notify({
    Title = "警告！",
    Description = "openpaint 是一个旨在扩展 mspaint 支持游戏的插件。由于该插件处于测试阶段且可能包含模组，使用时请自行承担风险。",
    Time = 4,
})

mspaint.AddonInfo = {
    Name = "openpaint", -- 插件名称 (不能包含空格)
    Title = "openpaint (测试版)", -- 分组框名称
    Description = "适用于 sewh 的 openpaint", -- 如果不需要描述可以留空
    Game = "*", -- * 表示所有游戏
}
 
mspaint.Groupbox:AddButton({
    Text = '取消布娃娃效果',
    Tooltip = '让你在布娃娃状态后立即站起来',
 
    Func = function()
        while true do
            local args = {
                "UpdateRagdoll",
                false,
                game:GetService("Players").LocalPlayer.Character
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Communication"):WaitForChild("EventObjects"):WaitForChild("Asynchronous"):FireServer(unpack(args))
            task.wait(0.1)
        end
    end
})
