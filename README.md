# 理想收集所

一个温柔明亮的理想墙，支持投稿、分类筛选、最新／热门排序、气球和列表视图、详情、点赞以及管理员编辑和删除。

## 本地预览

无需构建工具。使用现代浏览器打开 `index.html`，或运行：

```sh
python -m http.server 8000
```

然后访问 http://localhost:8000。

未配置 Supabase 时，页面使用示例理想和浏览器 `localStorage`，只在当前设备有效。管理员登录也是本地演示门禁，不能用于线上安全管理。

## 启用共享投稿、点赞和管理员编辑

本项目使用 Supabase Postgres、匿名 Auth 会话和 RLS。访客可匿名投稿和每人每条理想点赞一次；管理员通过邮箱密码登录，只有数据库中加入 `admin_users` 的账号才能编辑或删除。点赞计数由数据库触发器维护，浏览器不能直接修改。

1. 在 [Supabase](https://supabase.com/dashboard) 创建项目。
2. 打开项目的 **SQL Editor**，运行 [`supabase/schema.sql`](supabase/schema.sql) 全文。脚本会创建安全策略并写入 15 条示例投稿；在同一项目中只运行一次，重复运行会再次加入示例投稿。
3. 在 **Authentication → Sign In / Providers** 启用 **Anonymous Sign-Ins**。访客无需注册，Supabase 会为每台浏览器分配匿名身份，以便跨刷新防止重复点赞。
4. 在 **Authentication → Users** 创建管理员用户，记下其邮箱。然后在 SQL Editor 执行下方语句，把账号加入管理员名单（替换邮箱）：

   ```sql
   insert into public.admin_users (user_id)
   select id from auth.users where lower(email) = lower('你的管理员邮箱')
   on conflict (user_id) do nothing;
   ```

5. 从 Supabase 项目设置复制 **Project URL** 和 **Publishable key**（旧项目也可能标为 `anon` key），填入 `supabase-config.js` 的 `url` 和 `anonKey`。
6. 将更改推送到 GitHub 仓库 `main` 分支。GitHub Actions 会自动重新部署 GitHub Pages。在线页面右下角会显示“共享模式”。

`supabase-config.js` 中的 Project URL 和 publishable/anon key 是浏览器公开配置；**绝不能把 `service_role` 或任何 secret key 放进前端或 GitHub**。数据库通过 RLS 和列级权限限制数据访问。SQL 结构参考 Supabase 的 [RLS 文档](https://supabase.com/docs/guides/database/postgres/row-level-security)。

## 数据表

- `wishes`：理想正文、分类、昵称、点赞数和发布时间。
- `wish_likes`：每个 Supabase 用户对每条理想的点赞记录，`(wish_id, voter_id)` 唯一。
- `admin_users`：获准编辑或删除理想的管理员用户 ID。

## 部署状态与限制

静态页面已配置为由 GitHub Pages Actions 发布；Supabase 后端代码、数据库 SQL 和接入说明已准备好。**共享服务要等你创建 Supabase 项目、运行 SQL 并把 Project URL 与公开 key 填进配置文件后才会真正连通。**没有配置时页面会明确标示为仅本地演示。当前示例数据的点赞数是预置展示值，不是实际访客点赞历史。

相关官方文档：[Supabase Auth](https://supabase.com/docs/guides/auth)、[Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)。

