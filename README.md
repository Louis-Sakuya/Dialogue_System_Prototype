# Visual Novel Framework (视觉小说框架)

基于 Godot 4.6 的视觉小说游戏框架，支持 CSV 数据驱动的对话系统。

## 功能一览

| 功能 | 说明 |
|------|------|
| 对话展示 | 打字效果、角色名、左右头像、背景切换 |
| 立绘系统 | 中央立绘展示，支持表情替换（整张替换），支持 7 种动画效果 |
| 动态选项 | 不限数量的对话选项，每个选项可触发好感值变化并跳转不同分支 |
| 好感值系统 | 按角色 ID 记录好感值，选项/固定对话均可触发，用于结局判定 |
| 多语言本地化 | 中英双语，CSV 和代码双通道翻译，运行时可切换 |
| 故事回溯 (Log) | 玩家可随时查看之前的对话历史，包括选择记录 |
| 章节选择 | 通关后解锁章节列表，可从关键节点重新开始 |
| 存档系统 | 5 个存档槽位，保存对话进度、好感值、Log 历史 |
| BGM 管理 | 按 ID 播放/停止/淡入淡出 |

## 目录结构

```
├── Scripts/                    # 核心脚本
│   ├── dialogue.gd             # Dialogue 资源定义
│   ├── DialogueGroup.gd        # DialogueGroup 资源定义
│   ├── dialogue_choice.gd      # DialogueChoice 选项资源
│   ├── affection_change.gd     # AffectionChange 好感值变化资源
│   ├── dialogue_csv_importer.gd# CSV 解析与导入
│   ├── csv_importer.gd         # 导入入口（工具用）
│   ├── global_game_data.gd     # 全局游戏状态 (Autoload)
│   ├── audio_manager.gd        # BGM 管理器 (Autoload)
│   ├── localization_manager.gd # 本地化管理器 (Autoload)
│   ├── affection_manager.gd    # 好感值管理器 (Autoload)
│   └── chapter_manager.gd      # 章节管理器 (Autoload)
├── Scenes/
│   ├── main_menu.tscn / .gd    # 主菜单场景
│   ├── main_scene.tscn         # 对话场景
│   ├── dialog_manager.gd       # 对话 UI 管理
│   ├── game_save_manager.gd    # 存档管理
│   └── importDBtool.tscn       # CSV 导入工具
├── Dialogues/
│   ├── Database/
│   │   └── MainStory.csv       # 主线剧情 CSV
│   └── *.tres                  # 生成的对话组资源
├── Localization/
│   └── dialogue_translations.csv  # 翻译文件
└── assets/
    ├── BG/                     # 背景图
    ├── avatars/                # 头像
    ├── sprites/                # 角色立绘（按 角色名_表情.png 命名）
    └── music/                  # BGM 音乐文件
```

## CSV 格式说明

### 列定义

| 列名 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `group_id` | String | 是 | 对话组 ID，同组对话归为一个 DialogueGroup |
| `dialogue_id` | Int | 是 | 组内序号，用于排序 |
| `character_name` | String | 是 | 角色名（默认语言） |
| `content` | String | 是 | 对话正文（默认语言） |
| `content_en` | String | 否 | 英文翻译（留空则使用 content） |
| `avatar_path` | String | 否 | 头像路径，如 `res://assets/avatars/sakura.png` |
| `show_on_left` | Bool | 否 | 头像显示在左侧 `true`/`false`，默认 `false` |
| `bg_path` | String | 否 | 背景图路径（留空保持上一帧） |
| `image_path` | String | 否 | 立绘路径，如 `res://assets/sprites/sakura_happy.png` |
| `sprite_anim` | String | 否 | 立绘动画名（见下表），留空=无动画 |
| `is_choice` | Bool | 否 | 是否为选项对话 |
| `choices_json` | String | 否 | 选项 JSON 数组（见格式示例） |
| `bgm` | Int | 否 | BGM ID：>0 播放, =0 停止, 留空或 <0 保持当前 |
| `isEND` | Bool | 否 | 是否为剧情终点 |
| `affection_json` | String | 否 | 非选项好感值变化 JSON |
| `is_checkpoint` | Bool | 否 | 是否为章节存档点 |
| `chapter_id` | String | 否 | 章节 ID，如 `ch_01` |
| `chapter_name` | String | 否 | 章节显示名 |

### 立绘动画名

| 动画名 | 效果 |
|--------|------|
| `shake` | 水平抖动（震惊、生气） |
| `bounce` | 上下弹跳（开心、兴奋） |
| `fade_in` | 从透明渐入（角色登场） |
| `fade_out` | 渐出消失（角色退场） |
| `zoom` | 缩放放大后恢复（强调） |
| `slide_left` | 从右侧滑入 |
| `slide_right` | 从左侧滑入 |
| (空) | 无动画，直接显示 |

### choices_json 格式

```json
[
  {
    "text": "帮助她",
    "text_en": "Help her",
    "result_group": "ch1_help",
    "affection": [
      {"char": "sakura", "value": 5},
      {"char": "rival", "value": -2}
    ]
  },
  {
    "text": "走开",
    "text_en": "Walk away",
    "result_group": "ch1_leave",
    "affection": [{"char": "sakura", "value": -3}]
  },
  {
    "text": "观望",
    "text_en": "Watch",
    "result_group": "ch1_watch",
    "affection": []
  }
]
```

- `text`: 选项文本（默认语言）
- `text_en`: 英文翻译
- `result_group`: 跳转目标的 group_id
- `affection`: 好感值变化数组，`char` 为角色 ID，`value` 为增减值

### affection_json 格式

```json
[{"char": "sakura", "value": 3}, {"char": "rival", "value": -1}]
```

用于非选项对话自动触发的好感值变化。

### CSV 示例

```csv
group_id,dialogue_id,character_name,content,content_en,avatar_path,show_on_left,bg_path,image_path,sprite_anim,is_choice,choices_json,bgm,isEND,affection_json,is_checkpoint,chapter_id,chapter_name
intro,0,旁白,春天的校园里樱花盛开。,Cherry blossoms bloom on the spring campus.,,false,res://assets/BG/school.jpg,,,false,,1,false,,true,ch_01,第一章 相遇
intro,1,樱,你好！你是新转来的同学吗？,Hello! Are you the new transfer student?,res://assets/avatars/sakura.png,true,,res://assets/sprites/sakura_happy.png,fade_in,false,,,false,"[{""char"":""sakura"",""value"":1}]",false,,
intro,2,,,,,,,,,,true,"[{""text"":""是的，你好！"",""text_en"":""Yes, hello!"",""result_group"":""ch1_friendly"",""affection"":[{""char"":""sakura"",""value"":5}]},{""text"":""嗯..."",""text_en"":""Hmm..."",""result_group"":""ch1_cold"",""affection"":[{""char"":""sakura"",""value"":-2}]},{""text"":""（微笑点头）"",""text_en"":""(Smile and nod)"",""result_group"":""ch1_neutral"",""affection"":[]}]",,false,,false,,
```

## 素材路径约定

| 类型 | 路径格式 | 示例 |
|------|---------|------|
| 立绘 | `res://assets/sprites/{角色名}_{表情}.png` | `res://assets/sprites/sakura_happy.png` |
| 头像 | `res://assets/avatars/{角色名}.png` | `res://assets/avatars/sakura.png` |
| 背景 | `res://assets/BG/{场景名}.jpg` | `res://assets/BG/school.jpg` |
| 音乐 | 通过 BGM ID 引用，映射表在 `audio_manager.gd` | BGM ID 1-14 |

## 如何填入剧情

1. **准备素材**：将立绘、头像、背景图放入对应 `assets/` 子目录
2. **编写 CSV**：在 `Dialogues/Database/` 下创建 CSV 文件，按上述列格式填写剧情
3. **导入资源**：在 Godot 中运行 `importDBtool.tscn` 场景（或修改 `csv_importer.gd` 指向你的 CSV 路径），自动生成 `.tres` 资源
4. **设置入口**：在 `main_menu.gd` 中修改 `intro_dialogue_path` 指向你的起始对话组 `.tres` 文件
5. **配置 BGM**：在 `audio_manager.gd` 的 `bgm_paths` 字典中添加/修改音乐映射

## 好感值与结局

- 角色 ID 使用纯英文小写（如 `sakura`, `rival`, `hero`）
- 好感值通过选项的 `affection` 字段或对话的 `affection_json` 字段累积
- 调用 `AffectionManager.get_ending_character()` 获取好感度最高角色，用于结局判定
- 好感值随存档保存/加载

## 章节系统

- 在 CSV 中将关键节点的 `is_checkpoint` 设为 `true`，填写 `chapter_id` 和 `chapter_name`
- 玩家经过该节点时自动解锁
- 剧情终点（`isEND=true`）触发后标记为已通关
- 通关后主菜单显示「章节选择」按钮，可从任何已解锁节点重新开始

## 本地化

- UI 文本翻译在 `localization_manager.gd` 的 `load_menu_translations()` 中定义
- 对话翻译通过 CSV 的 `content_en` 列或 `Localization/dialogue_translations.csv` 文件
- 运行时通过主菜单语言面板切换，设置会持久化保存
