--// Default Constants & Configuration

return {
    -- Player Settings
    PLAYER = {
        WALK_SPEED_MIN = 16,
        WALK_SPEED_MAX = 100,
        WALK_SPEED_DEFAULT = 16,
        WALK_SPEED_STEP = 1,
        
        JUMP_POWER_MIN = 50,
        JUMP_POWER_MAX = 200,
        JUMP_POWER_DEFAULT = 50,
        JUMP_POWER_STEP = 1,
    },

    -- Visual/Lighting Settings
    VISUAL = {
        BRIGHTNESS_MIN = 0,
        BRIGHTNESS_MAX = 10,
        BRIGHTNESS_DEFAULT = 2,
        BRIGHTNESS_STEP = 0.1,
        
        CLOCK_TIME_MIN = 0,
        CLOCK_TIME_MAX = 24,
        CLOCK_TIME_DEFAULT = 14,
        CLOCK_TIME_STEP = 0.5,
        
        FOG_END_MIN = 100,
        FOG_END_MAX = 100000,
        FOG_END_DEFAULT = 100000,
        FOG_END_STEP = 1000,
    },

    -- UI Settings
    UI = {
        WINDOW_TITLE = "Suture Hub",
        WINDOW_AUTHOR = "by suif",
        WINDOW_FOLDER = "SutureHub",
        WINDOW_SIZE = UDim2.fromOffset(620, 460),
        WINDOW_MIN_SIZE = Vector2.new(560, 350),
        WINDOW_MAX_SIZE = Vector2.new(900, 600),
        WINDOW_TOGGLE_KEY = Enum.KeyCode.RightShift,
        
        DEFAULT_THEME = "Dark",
        DEFAULT_TRANSPARENT = true,
        DEFAULT_SIDEBAR_WIDTH = 180,
        HIDE_SEARCH_BAR = false,
    },

    -- Notification Defaults
    NOTIFY = {
        DURATION_SHORT = 3,
        DURATION_MEDIUM = 4,
        DURATION_LONG = 5,
    },

    -- API Endpoints
    API = {
        COUNTER_URL = "https://suture-hub-counter.sfbdsl666.workers.dev/count",
    },

    -- Author Info
    AUTHOR = {
        BILIBILI = "https://space.bilibili.com/3493268314655259",
    },
}
