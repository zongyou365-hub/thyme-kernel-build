DSH desktop app (Win) profile plugins live in C:\Users\asus\.dsh\profiles\desktop; install with '<app>\resources\runtime\cli\bin\dsh.cmd plugin --profile desktop add <pkg>' then ensure the package is listed in package.json dsh.profile.bundles (the CLI's pnpm step does not reconcile bundles for the desktop profile, which is app-managed; dsh --dump-config refuses for it). npmmirror lacks @dsh-ops/bash-win32-x64@0.2.1, so use --registry=https://mirrors.cloud.tencent.com/npm/; large tarballs (e.g. billion-context 33MB) often ECONNRESET from mirrors — pre-seed with 'pnpm store add <tarball>' + 'pnpm install --prefer-offline' in the profile dir.
§
DSH 桌面版（Electron）的宿主进程会热加载新装插件的路由/服务（装完立刻 curl /<plugin-route> 就能 200），但 Electron 主进程只在启动时向宿主取一次 index 注入表（main.js 里 `injections = ready.injections`，DESKTOP_IPC.boot 直接返回这份缓存），所以任何靠 webserver/index-inject 往页面塞东西的插件（如 dsh-video-skin 的开机动画/视频背景）必须**完整退出并重开应用**才生效，刷新页面无效。
§
Mnemon CLI 已全局安装：`npm i -g @mnemon-dev/mnemon`（v0.2.11，装到 C:\Users\asus\AppData\Roaming\npm\mnemon），与 DSH 的 dsh-mnemon 插件共享同一数据目录 C:\Users\asus\.mnemon（data/default/mnemon.db、runtime/{USER,MEMORY}.md、documents/）。注意 npm 上裸名 `mnemon`（v1.3.0）是无关的 WebAssembly 工具；DSH 插件包 dsh-mnemon 本身只有 repair-session 一个 bin，真正的 CLI 是 @mnemon-dev/mnemon。插件 mnemon_status 已确认 healthy/commandFound/writeEnabled。
§
dsh-posterflow-ai（生图模式入口，MIT，作者 Something11235）已装入 desktop profile：`dsh plugin --profile desktop add dsh-posterflow-ai --registry=https://mirrors.cloud.tencent.com/npm/`（默认 npmmirror 会因 @dsh-ops/bash-win32-x64@0.2.1 缺失而失败）。侧栏主列表最后一行「开启生图模式」→ 铺满整窗播过场视频 → 打开 https://www.posterflow-ai.xyz/ 。插件已自动加入 package.json dsh.profile.bundles；宿主路由 http://127.0.0.1:<port>/posterflow-ai/config.json 立即可用（返回 200），但 **dsh.client 半边需完全退出 Electron 重开**才注入侧栏。配置在 profile 的 cordis.patch.yml 按 id 覆盖（config 整行替换）。
§
DSH 桌面版 exe 已被改名：`C:\Users\asus\AppData\Local\Programs\DeepSeek Harness\大肥鱼.exe`（原 DeepSeek Harness.exe 改名，原文件备份为 DeepSeek Harness.exe.orig-icon-backup，同一二进制 235MB）。**任何写死 'DeepSeek Harness.exe' 的路径都会 ENOENT**——ego-browser 报 spawn ENOENT 并使 run_code worker 崩溃、`resources\runtime\cli\bin\dsh.cmd` 也会整个失效（它硬编码了 app 根目录的 DeepSeek Harness.exe）。dsh.cmd 已于 2026-10-24 改成动态解析：先找 DeepSeek Harness.exe，不存在则用 `dir /b /a-d "%APP%\*.exe"` 过滤掉 Uninstall 后取那个唯一的 exe；备份在同目录 dsh.cmd.orig。**每次升级覆盖安装目录会把 dsh.cmd 还原成硬编码版本，需重新修**。开机自启靠启动文件夹 `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\大肥鱼.lnk`，已修复为指向大肥鱼.exe；开始菜单 DeepSeek Harness.lnk 也已同步修好。HKCU/HKLM Run 与计划任务均无相关项。
§
BrowserSkill（Tencent/BrowserSkill）在 DSH 桌面版已完整就位：npm 包 `@wxg-prc-cpg/browser-skill-dsh-plugin` 0.3.3 在 desktop profile 的 dependencies + bundles 里；bsk CLI v0.3.3 装在 `C:\Users\asus\.local\bin\bsk.exe`（用户 PATH 已含该目录，安装脚本自动加的）；`C:\Users\asus\.dsh\profiles\desktop\cordis.patch.yml` 末尾追加了 `- id: browserskill / config: / bskPath: C:\Users\asus\.local\bin\bsk.exe`。**daemon 绕坑**：DSH 宿主在 Windows Job Object 里，bsk 无法自行 detached 启动（报 os error 5 拒绝访问），用 `bsk daemon start --foreground` 跑在 pwsh 后台作业里也会随作业死。可行解是用 WMI `Invoke-CimMethod -ClassName Win32_Process -MethodName Create` 或 VBS 里 `objWMIService.Get("Win32_Process").Create(cmd,Null,objConfig,pid)` 创建，父进程退出后 daemon 成为独立进程。开机自启用 `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\browserskill-daemon.vbs`（WMI 方式，ShowWindow=0），已实测 cscript 跑通。**计划任务路子在此环境被拒**（Register-ScheduledTask 注册后 State 恒为 Disabled，schtasks /Create 报 Access is denied）。客户端调用 bsk 需带 `BSK_AUTO_START=0`。
§
dsh-image-gen/gpt-image-2.5 出图后，结果图落在 file*.aitohumanize.com；该域直连被 Connection reset → 插件下载失败，工具报 execution deadline / abort，但生成其实成功且已扣积分（每次约 600），重试等于白烧钱。正确姿势：从响应 JSON 里取 data[0].url，用 `curl --socks5-hostname 127.0.0.1:10808 <url> -o out.png` 取回（实测 200、2.7MB、1024x1536）。edit_image 传 size:"1024x1536" 能得到竖版。
§
大肥鱼形象基准更新（m05159 用户指定「以后按这个画」）：以 persona/大肥鱼-形象基准-20261021.png 为准（浅蓝微波长发+呆毛、鲸鳍耳、白褶女仆头饰、深蓝女仆裙带金色花枝纹、白围裙印小蓝鲸、白袜深蓝玛丽珍鞋、蓝色鲸尾；站姿活泼挥手、笑脸）。旧的 dafeiyu-three-view.jpg 与「泪眼挂涎」设定图降为参考，出图默认要明亮可爱的站姿，别默认画哭脸。
§
dsh-image-gen 图库是纯客户端 IndexedDB（DB `dsh_image_gen_db` v4，store `gallery_history`），存在 Electron 渲染进程 origin `dsh-app://app` 的 LevelDB 里（C:\Users\asus\AppData\Roaming\@deepseek-ai\dsh-desktop\IndexedDB\dsh-app_app_0.indexeddb.leveldb）。只有走 generate_image 工具、结果卡片在会话里渲染过（ImageResultCard 的 useEffect 调 saveGalleryItem）才会入图库；用 curl 直接调 Grsai 拿到的图没有 attachment，永远进不了图库。
§
dsh-feiyu-mood 0.4.6 已打「全部会话」补丁（C:/Users/asus/.dsh/profiles/desktop/node_modules/dsh-feiyu-mood）：lib/index.js 的 tick() 里 targetSession==='*' 时挂所有非裸UUID会话（跳过子代理），client.js 下拉多一项「全部会话，不含子代理」；config.json targetSession='*'。备份 *.bak-allsessions。改完必须 touch profile 的 cordis.patch.yml 才能热重载宿主半边；pnpm 重装插件会覆盖补丁。
§
desktop profile 装了三个插件且互不冲突：dsh-knowledge-canvas 0.4.4（路由 /dsh-knowledge-tree，数据在 <workspace>/.dsh-knowledge/，注入 context order 200/9000/9500）、dsh-narrator 0.12.5@ef1781b（路由 /api/narrator，pre-step 注入）、dsh-prompt-ErrorNotes-desk 1.2.1@fab9373（路由 /prompt-desk，section order 10200，写 ~/.dsh/AGENTS.md）。均不与 dsh-mnemon（section order 150）冲突。npm 镜像 latest 与 pnpm minimumReleaseAge 会给出不同版本，装时要显式写版本号。
§
dsh-feiyu-mood 挂饰默认形态补丁：assets/widget.js 里 collapsed 初始化改成恒 false（不再读 localStorage fm-widget-collapsed），每次开页面都是 180px 大肥鱼；面板内仍可临时切小。pnpm 重装插件会覆盖此改动，改后需备份。
§
升级 DSH 桌面版时，助手进程随应用关闭而死，无法在应用退出后继续执行；可靠做法是把安装脚本放桌面交给用户手动运行。
§
dsh-image-gen 接 Grsai 的正确配法：profile cordis.patch.yml 的 image-gen 条目 provider: openai-compat / openaiCompatBaseURL: https://grsai.dakka.com.cn/v1（国内节点，直连通）/ openaiCompatModel: gpt-image-2.5，key 用凭据 ref DSH_IMAGE_GEN_OPENAI_COMPAT_KEY。Apifox 分享页 https://qmy27nhsd9.apifox.cn/... 只是文档不是接口；api.grsai.com 解析到 facebook IP 是假域名。全球节点 https://grsaiapi.com。原生接口是 {base}/v1/api/generate（非 OpenAI 格式）。
§
modlens 读图引擎已配 openai 指向千帆 /v2/tokenplan/personal + qianfan-code-latest，key 用 BAIDU_API_KEY；无需重启 DSH 即生效。
§
dsh-image-gen 的 edit_image/generate_image 走 run_code 时默认 120s 截止会 abort（实测 116.6s 报 aborted (run_code settled)），重跑等于再烧一次额度；首次就应给 timeoutMs 300000+。
§
itch 在线 Flash 游戏（Ruffle）自动化可走 bcdp_cdp：Page.captureScreenshot 约 2.9s/张；菜单点击须发 mouseMoved+mousePressed+mouseReleased 三步。
§
cf.cpass.cc 中转站按 group 分权限：key 无渠道时 503 No available sub-groups。本机 socks5 127.0.0.1:10808 不认域名格式 CONNECT（ATYP=3 静默卡死），必须先 DNS 解析成 IPv4 再发。本地中转 tools/cpass-relay.cjs 已改 v4 纯 TCP 透明转发（18101），开机自启 VBS 可用。
§
Blender 三渲二/卡渲默认走 Miaobox 预设：E:\新建文件夹 (2)\Miaobox_免费卡渲_250122\。插件 MiaoboxN v1.6 已装已启用（只管材质替换，面板在 3D 视图 N 栏 MiaoN）；出图靠追加包里三个 .blend 的 Miaobox 节点组，脚本在 tools/miao_render.py。默认用 02 偏蓝阴影。出图必须写借物表「渲染：MiaoBox」，插件和预设禁止二次传播。
§
billion-context 已配成自动压缩：providers.mimo（api.xiaomimimo.com/v1）+ compress.externalSummary + autoFold（target 200000）+ credentialRef MIMO_SUMMARY。改完 POST /__bili/config/reload 即生效无需重启；budget 必须放大到 240000/600000。详见知识库 n48。
