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
| `sfx` | String | 否 | 音效路径，填 `STOP` 停止当前音效，留空不操作 |
| `isEND` | Bool | 否 | 是否为剧情终点 |
| `group_to` | String | 否 | 该组结束后自动跳转的目标 group_id（非 END 时生效） |
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

#### 示例1：无条件选项

```json
[
  {
	"text": "帮助她",
	"text_en": "Help her",
	"result_group": "ch1_help",
	"affection": [{"char": "sakura", "value": 5}]
  }
]
```

#### 示例2：硬锁定（不满足条件 → 不可点击）

```json
[
  {
	"text": "表白",
	"text_en": "Confess",
	"result_group": "confess",
	"affection": [{"char": "sakura", "value": 10}],
	"condition": {"type": "affection", "char": "sakura", "op": ">=", "value": 20},
	"lock_reason": "需要与樱的好感度达到20",
	"lock_reason_en": "Sakura affection must reach 20"
  }
]
```

#### 示例3：软锁定（不满足条件 → 仍可点击，走失败分支）

```json
[
  {
	"text": "表白",
	"text_en": "Confess",
	"result_group": "confess_success",
	"affection": [{"char": "sakura", "value": 10}],
	"condition": {"type": "affection", "char": "sakura", "op": ">=", "value": 20},
	"lock_reason": "好感不足",
	"lock_reason_en": "Not enough affection",
	"fail_group": "confess_rejected",
	"fail_affection": [{"char": "sakura", "value": -5}]
  }
]
```

#### 字段说明

| 字段 | 必填 | 说明 |
|------|------|------|
| `text` | 是 | 选项文本（默认语言） |
| `text_en` | 否 | 英文翻译 |
| `result_group` | 是 | 条件满足时的跳转目标 group_id |
| `affection` | 否 | 条件满足时的好感值变化 |
| `condition` | 否 | 前置条件。不填则始终可选 |
| `lock_reason` | 否 | 条件不满足时显示的提示文本 |
| `lock_reason_en` | 否 | 提示文本英文翻译 |
| `fail_group` | 否 | 条件不满足时的替代跳转目标（有此字段=软锁定，无=硬锁定） |
| `fail_affection` | 否 | 条件不满足时的好感值变化 |

#### condition 格式

```json
{"type": "affection", "char": "角色ID", "op": "运算符", "value": 阈值}
```

| 参数 | 说明 |
|------|------|
| `type` | 条件类型，目前支持 `affection`（好感值判定） |
| `char` | 角色 ID，如 `"sakura"` |
| `op` | 比较运算符：`>=` `>` `<=` `<` `==` `!=` |
| `value` | 比较阈值（整数） |

#### 锁定行为对比

| 模式 | 条件 | 按钮表现 |
|------|------|----------|
| 无条件 | 不填 `condition` | 正常显示，可点击 → `result_group` |
| 硬锁定 | 有 `condition`，无 `fail_group` | 不满足时显示 `[lock_reason]`，置灰不可点击 |
| 软锁定 | 有 `condition`，有 `fail_group` | 不满足时选项文本后附加 `[lock_reason]`，可点击 → `fail_group` |

### affection_json 格式

```json
[{"char": "sakura", "value": 3}, {"char": "rival", "value": -1}]
```

用于非选项对话自动触发的好感值变化。

### group_to 对话组跳转

`group_to` 用于控制对话组播放完毕后自动跳转到下一个对话组。只需在该组**任意一行**（推荐最后一行）的 `group_to` 列填写目标 group_id 即可。

| 场景 | isEND | group_to | 行为 |
|------|-------|----------|------|
| 普通对话结束，自动接续下一段 | `false` | `ch1_part2` | 播完后自动跳转到 `ch1_part2` |
| 剧情结局 | `true` | (留空) | 播完后触发结局流程 |
| 对话组以选项结尾（选项自带跳转） | `false` | (留空) | 选项的 `result_group` 已处理跳转 |

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
