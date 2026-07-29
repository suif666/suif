print("[RangeEnlarge] 远程脚本已执行")

local Tab = getgenv().Tabs and getgenv().Tabs.RangeTab
print("[RangeEnlarge] 拿到的 Tab =", Tab)
print("[RangeEnlarge] Tab.Toggle =", Tab and Tab.Toggle)

if not Tab then
    warn("[RangeEnlarge] Tab 是 nil！")
    return
end

if not Tab.Toggle then
    warn("[RangeEnlarge] Tab.Toggle 是 nil！你的 WindUI 方法可能不同")
    return
end

print("[RangeEnlarge] 准备添加测试开关")

Tab:Toggle({
    Title = "测试开关（远程）",
    Desc = "如果能看到这个开关，说明远程挂载成功",
    Value = false,
    Callback = function(v)
        print("测试开关状态:", v)
    end
})

print("[RangeEnlarge] 测试开关已添加")
