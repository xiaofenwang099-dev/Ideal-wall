# 理想收集所

## 当前功能

无需安装依赖的静态页面原型，支持投稿、分类筛选、最新／热门排序、气球和列表视图、详情、点赞以及本地管理员编辑和删除。页面初次打开会放入示例愿望。

使用现代浏览器打开 `index.html`，或在此目录运行：

```sh
python -m http.server 8000
```

然后访问 http://localhost:8000。

投稿、点赞、示例数据的修改与管理员密码摘要都保存在当前浏览器的 `localStorage`。管理员入口首次使用时设置密码。**这是仅用于本地演示的管理员门禁，不是安全的线上管理员账户**：数据不共享，浏览器用户可以绕过前端限制或修改本地数据。清除此站点存储会重置内容和密码。

## 发布给其他人

此目录已经附带 GitHub Pages 的 Actions 工作流（`.github/workflows/pages.yml`）。把本目录内容放进 GitHub 仓库的 `main` 分支后，进入仓库 **Settings → Pages**，将构建来源设为 **GitHub Actions**。之后每次推送到 `main` 都会自动部署，Actions 完成后可以从 Pages 设置页获取访问地址。

发布的是静态前端。访客可在 GitHub Pages 上打开页面，但投稿、点赞和管理员编辑仍然是各自设备本地数据，不会跨访客共享。多人共享仍需后端，见下文。

要实现多人共享，推荐补上 Supabase 后端，再把前端部署至 Vercel 或 Netlify：

1. 在 Supabase 创建项目和 `wishes`、`likes` 表。
2. 配置 Supabase Auth 管理员账户，并将投稿编辑／删除策略限制为管理员角色。
3. 投稿允许匿名插入，但由数据库策略校验正文长度和分类；点赞由唯一约束防重。
4. 前端通过 Supabase JS 读取投稿、提交愿望、点赞和管理员编辑；项目 URL 与公开 anon key 可放在前端环境配置里，`service_role` 密钥绝不能放入网页。
5. 在托管平台设置前端配置、部署，之后可绑定自有域名并启用 HTTPS。

建议的数据结构：`wishes(id, text, category, nickname, created_at, updated_at)`，`likes(wish_id, voter_id, created_at)`，并对 `(wish_id, voter_id)` 建唯一约束。线上管理员身份必须由 Supabase Auth 和数据库 RLS 验证，不能由前端按钮或本地密码决定。匿名用户防重复可用匿名登录用户 ID；若用纯设备 ID，只能提供尽力而为的去重，用户清理存储后即可重置。

当前没有 Supabase 项目凭据，也尚未把前端接到线上数据库，所以部署静态文件后不会自动变成多人共享服务。要完成真正的多人版，需要先创建 Supabase 项目，再配置前端适配和 RLS 策略。

